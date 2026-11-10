"""Collect the status of a Chipster service and save it to InfluxDB.

This runs in the status container next to each service, see
kustomize/builds/monitoring/Dockerfile.
"""

import json
import logging
import os
import signal
import socket
import sys
import time
import urllib.error
import urllib.request
from base64 import b64encode

# seconds between rounds
INTERVAL = 10
# seconds to wait after a failed login, instead of INTERVAL. All the status
# containers log in as the same monitoring account and auth throttles it, so
# they must not retry the login in every round when auth is down.
LOGIN_RETRY_INTERVAL = 60
# seconds for a single read or connect of a request, not for the whole round,
# which makes up to five requests. Long enough for a slow status, e.g. the row
# counts of session-db on a big database, because a failed request loses the
# round: ROUND_TIMEOUT below limits the whole round anyway.
TIMEOUT = 30
# seconds for the whole round. TIMEOUT doesn't limit a peer that keeps sending
# a byte now and then, and a stalled round would stop the collection for good:
# the readiness probe of this container checks the service, not this script.
# Longer than INTERVAL, so that a slow round is allowed to finish, but a
# stalled one loses several values before it's interrupted. Doesn't help if
# the name resolution hangs: the alarm can't interrupt getaddrinfo(), which
# blocks in C until it returns on its own.
ROUND_TIMEOUT = 60

AUTH_URL = "http://auth/tokens"
INFLUXDB_URL = "http://influxdb:8086/write?db=db"


class HttpError(RuntimeError):
    """A HTTP error response, with the status code for the caller to check."""

    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


def request(method, url, credentials, data=None):
    """Make a HTTP request and return the response body as a string.

    The body is sent as bytes, so that nothing parses its quotes or spaces.

    :param credentials: (username, password) for basic authentication
    :param data: request body, or None
    :return: response body
    """

    username, password = credentials
    headers = {
        "Authorization": "Basic " + b64encode(f"{username}:{password}".encode()).decode()
    }

    body = None
    if data is not None:
        body = data.encode()

    req = urllib.request.Request(url, method=method, headers=headers, data=body)

    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            return response.read().decode()

    except urllib.error.HTTPError as e:
        # the response body tells why InfluxDB rejected the write, for example
        raise HttpError(e.code, f"{method} {url} failed: {e.code} {e.read().decode()}") from e


def authenticate():
    """Get a token for the monitoring account."""

    return request("POST", AUTH_URL, ("monitoring", os.environ["password"]))


def get_status(token):
    """Get the status of the service in this pod.

    The admin port is bound to localhost only, so this works only from a
    container in the same pod.
    """

    url = "http://localhost:" + os.environ["admin_port"] + "/admin/status"

    return json.loads(request("GET", url, ("token", token)))


def format_field(value):
    """Format one status value as an InfluxDB line protocol field.

    The field name depends on the type, because InfluxDB fixes the type of a
    field until the end of the current shard: a string written to a field that
    has numbers already would be rejected for a week. The same status value is
    a number in one pod and a string in another, for example mem.max is "max"
    in a container that has no memory limit. Dashboards graph "value", which
    is always a number.

    Strings are quoted, because InfluxDB would try to parse a bare word like
    the chipsterBuildVersion "v4.21.5" as a boolean and reject the whole
    batch. json.dumps() escapes the quotes and newlines of the string, which
    would otherwise break the line.

    Numbers are written without the "i" suffix, i.e. as floats, like the
    earlier versions of this script did. The suffix would change the field
    type of all the existing metrics.

    :return: (field name, field value)
    """

    # bool before int, because in Python a bool is an int
    if isinstance(value, bool):
        return "value_bool", "true" if value else "false"

    if isinstance(value, (int, float)):
        return "value", str(value)

    # not JSON's \uXXXX for non-ASCII characters, because InfluxDB unescapes
    # only \" and \\ and would store those six characters as they are
    return "value_str", json.dumps(str(value), ensure_ascii=False)


def save(status):
    """Save the status values to InfluxDB."""

    # the key is the measurement name and may contain tags already, e.g. "diskFree,fs=root"
    role = os.environ["role"]
    # the pod name in Kubernetes
    host = socket.gethostname()
    # nanoseconds
    timestamp = time.time_ns()

    lines = []

    for key, value in status.items():
        # InfluxDB has no value for null
        if value is None:
            continue

        name, field = format_field(value)

        lines.append(f"{key},role={role},id={host} {name}={field} {timestamp}")

    if not lines:
        logging.warning("the status had no values to save")
        return

    data = "\n".join(lines)

    try:
        request(
            "POST",
            INFLUXDB_URL,
            ("writer", os.environ["influxdb_password"]),
            data=data,
        )

    except HttpError:
        # print the data to see which value InfluxDB didn't like. Only when it
        # answered, so that a connection error doesn't print this every round.
        logging.error("InfluxDB rejected this data:\n%s", data)
        raise


def raise_timeout(signum, frame):
    raise TimeoutError(f"the round didn't finish in {ROUND_TIMEOUT} seconds")


def exit_on_sigterm(signum, frame):
    # As PID 1 of the container, Python ignores a SIGTERM without a handler,
    # and Kubernetes would wait the whole termination grace period before it
    # kills the pod.
    sys.exit(0)


def main():
    signal.signal(signal.SIGTERM, exit_on_sigterm)
    # interrupt a round that takes too long
    signal.signal(signal.SIGALRM, raise_timeout)

    # the token is valid for several rounds
    token = None

    while True:
        start = time.monotonic()

        try:
            signal.alarm(ROUND_TIMEOUT)

            try:
                # The token expires in 3 days. When it's rejected, get a new
                # one and try once more, so that no round is lost. Without a
                # token the next round waits LOGIN_RETRY_INTERVAL, so forget
                # a rejected token before logging in again: then a failed
                # login, or a second rejection, leaves none.
                for attempt in (1, 2):
                    if token is None:
                        token = authenticate()

                    try:
                        status = get_status(token)
                        break

                    except HttpError as e:
                        if e.code not in (401, 403):
                            raise

                        token = None

                        if attempt == 2:
                            raise

                        logging.info("the token was rejected, getting a new one")

                save(status)

            finally:
                # cancel the alarm inside the try below, because the alarm can
                # fire here too, when the round took about ROUND_TIMEOUT
                signal.alarm(0)

        except Exception as e:
            # keep the container running whatever happens. It has the readiness
            # probe of the service, so a crash loop here would take the service
            # out of its Kubernetes service.
            #
            # Keep the token. Only a rejected token is replaced, above: all the
            # status containers log in as the same monitoring account and auth
            # throttles it, so a failing InfluxDB or service must not make all
            # of them log in every round.
            #
            # No traceback: this repeats in every round while a peer is down,
            # and the urllib errors say what failed already.
            logging.error("saving the status failed: %s: %s", type(e).__name__, e)

        # without a token the login failed, so wait longer before trying again
        interval = INTERVAL if token else LOGIN_RETRY_INTERVAL

        # sleep for the rest of the interval, so that the time spent on
        # collecting doesn't delay the next round. Nothing to sleep if the
        # round took longer than the interval.
        time.sleep(max(0, interval - (time.monotonic() - start)))


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    main()
