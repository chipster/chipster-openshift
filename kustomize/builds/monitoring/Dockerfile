FROM base-24-04

# python3 isn't in the base image
RUN apt-get update -y \
	&& apt-get install -y python3 \
	&& apt-get clean

WORKDIR /home/user

# only the script, the dashboards in the same directory aren't needed here
COPY monitoring/collect.py /home/user/

# exec form, so that the script is PID 1 and gets the SIGTERM of Kubernetes
CMD ["python3", "/home/user/collect.py"]
