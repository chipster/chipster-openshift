# Getting started with K3s
## Some Chipster and Kubernetes terms

* Chipster service
  
  (Mostly) a Java process executing one Chipster component, like auth, toolbox or comp.

* Host

  The Ubuntu server where we K3s is running. Right now we have just one of them, but a Kubernetes or K3s cluster can be scaled to run on several hosts.

* Container
  
  Each Chipster service will run in its own container. For the process it looks like it would be the only process running on that machine. 

* Pod

  A pod contains one or more containers. At this point we will have exactly one container in each pod, so we have one pod for each Chipster service. Usually the other containers in the same pod
  could be used as `sidecar` containers for small background tasks, like collecting logs from the main service. You can scale the number of pods to run several replicas of the same Chipster service.

* Namespace

  Kubernetes project. All containers in the same namespace share the same private network. We'll setup our Chipster to run inside one `namespace`.

* Service

  Generally we wouldn't know, on which host the Kubernetes decides to run our containers. So we need 
  to define a `service` to access it. Service makes the container accessible from other containers in the same namespace. There is an internal DNS service, which resolves service names to the container IP addresses. If you have a web server running in a container and a `service` called `web-server`, you can simply run command `curl http://web-server` on any container (in the same namespace) to query the front page of that web server. When you have multiple instances of the same pod running, the `service` acts as a load-balancer that distributes your (TCP) connections to different pod instances.

* Ingress

  To access a `service` from outside, like from your browser, you have to define an Ingress object. For example, you could setup an Ingress to publish the aforementioned web server in address `http://HOST_ADDRESS/web-server`. The Ingress is implemented as a reverse proxy and can usually pass only HTTP and WebSocket traffic. It can be also configured to terminate HTTPS connections. 

* Deployment

  We don't create pods ourselves, but we define a `deployment`. It takes care of creating and terminating pods when the desired number of pods is changed or new versions are created.

## Debugging commands

What to do when you cannot connect to one of your containers? Let's go through some basic k3s commands. First of all, make sure that you have the container image.

```bash
$ sudo docker images
REPOSITORY                            TAG                   IMAGE ID            CREATED             SIZE
web-server                            latest                64a3a811e3ab        About an hour ago   1.69GB
toolbox                               latest                2956933c6c29        About an hour ago   1.54GB
monitoring                            latest                9e8d24c07209        About an hour ago   269MB
logstash                              latest                837f93356196        About an hour ago   847MB
grafana                               latest                02b1615ee970        About an hour ago   400MB
filebeat                              latest                fefdae346735        About an hour ago   330MB
comp                                  latest                60917780d55a        About an hour ago   2.09GB
cli-client                            latest                46eb367ad2cb        About an hour ago   718MB
chipster-web-server-js                latest                836fbbd198eb        About an hour ago   793MB
chipster-web-server                   latest                e2d42113c682        About an hour ago   1.53GB
chipster-web                          latest                1e34967c30c9        About an hour ago   731MB
chipster-tools                        latest                186e5441ec96        About an hour ago   316MB
base-node                             latest                b43f09279489        About an hour ago   585MB
base-java-comp                        latest                c0201c025732        About an hour ago   1.98GB
base-java                             latest                447600586fa1        2 hours ago         1.22GB
base                                  latest                df3ede002c39        2 hours ago         269MB
bitnami/minideb                       stretch               ed288f60eff7        4 days ago          53.7MB
ubuntu                                16.04                 96da9143fb18        4 weeks ago         124MB
bitnami/postgresql                    11.6.0-debian-9-r48   6db6971e4c89        4 weeks ago         225MB
busybox                               latest                6d5fcfe5ff17        6 weeks ago         1.22MB
traefik                               1.7.19                aa764f7db305        3 months ago        85.7MB
rancher/metrics-server                v0.3.6                9dd718864ce6        4 months ago        39.9MB
rancher/local-path-provisioner        v0.0.11               9d12f9848b99        4 months ago        36.2MB
coredns/coredns                       1.6.3                 c4d3d16fe508        5 months ago        44.3MB
nginx                                 1.16.0                ae893c58d83f        6 months ago        109MB
docker.elastic.co/logstash/logstash   7.1.1                 b0cb1543380d        8 months ago        847MB
docker.elastic.co/beats/filebeat      7.1.1                 0bd69a03e199        8 months ago        288MB
rancher/klipper-lb                    v0.1.2                897ce3c5fc8f        8 months ago        6.1MB
rancher/pause                         3.1                   da86e6ba6ca1        2 years ago         742kB
```

List deployments.

```bash
$ kubectl get deployment
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
type-service      1/1     1            1           56m
auth              1/1     1            1           56m
service-locator   1/1     1            1           56m
web-server        1/1     1            1           56m
backup            1/1     1            1           56m
toolbox           1/1     1            1           56m
session-db        1/1     1            1           56m
session-worker    1/1     1            1           56m
job-history       1/1     1            1           56m
file-broker       1/1     1            1           56m
scheduler         1/1     1            1           56m
comp              1/1     1            1           56m
```

List pods.

```bash
$ kubectl get pod
NAME                                READY   STATUS    RESTARTS   AGE
chipster-session-db-postgresql-0    1/1     Running   1          56m
chipster-job-history-postgresql-0   1/1     Running   1          56m
chipster-auth-postgresql-0          1/1     Running   0          56m
type-service-756ff46c88-gczvr       1/1     Running   0          22m
auth-7dc6ddc787-7fr5b               1/1     Running   0          22m
service-locator-7d696cb7fc-bcq24    1/1     Running   1          22m
backup-7884c69d66-2kxnz             1/1     Running   1          22m
web-server-544d8657d8-cghz5         1/1     Running   2          22m
toolbox-cf85d6678-hmrwk             1/1     Running   2          22m
session-db-865fb5548c-6tlrd         1/1     Running   3          22m
session-worker-5c66957669-z4wdl     1/1     Running   3          22m
job-history-7b66c78569-pgd5g        1/1     Running   3          22m
file-broker-76d6bb7bb5-lwmft        1/1     Running   3          22m
scheduler-5b4d9768c5-xpqj8          1/1     Running   4          22m
comp-6949ffb979-8bjwz               1/1     Running   5          22m
```

See more detailts about the pod. If the pod isn't running, this should tell you the reason.

```bash
$ kubectl describe pod auth-75f564b8dd-xc5t9
Name:         auth-75f564b8dd-xc5t9
Namespace:    default
Priority:     0
Node:         chipster-k3s-petri/192.168.15.2
Start Time:   Thu, 19 Dec 2019 15:35:48 +0000
Labels:       app=chipster
              deployment=auth
              pod-template-hash=75f564b8dd
Annotations:  <none>
Status:       Running
IP:           10.42.0.154
...
```

If the pod is running, check the logs of the container to make sure it started properly.

```bash
$ kubectl logs deployment/auth
---
[2019-12-19 15:36:20,033] INFO: get token from http://localhost:8002 (in AuthenticationClient:124)
[2019-12-19 15:36:21,319] INFO: get cors origin from http://service-locator (in CORSFilter:74)
[2019-12-19 15:36:21,463] WARN: cors headers not yeat available (request took 98ms) (in CORSFilter:84)
authentication service started
```

Sometimes it's necessary to open a shell to the container, for example to see what is inside some files. If there is an error in some file, changing it in the running container won't usually help, because
the next container will be started again from the unchanged container image. You should find out where
that file came from (e.g. code repository, build, or confguration) and change it there instead.

```bash
$ kubectl exec -it deployment/auth bash
I have no name!@auth-75f564b8dd-xc5t9:/opt/chipster$
```

If there is nothing alarming in the logs, make sure you can make a query to the server process from the same container. Use `kubectl describe deployment/auth` to see which port (e.g. 8002 for auth) the server is using. `HTTP 404` is a good sign here, it means that the server process responeded.

```bash
$ curl localhost:8002       
HTTP 404 Not Found
```

List services

```bash
$ kubectl get services
NAME                                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes                                 ClusterIP   10.43.0.1       <none>        443/TCP    21h
chipster-auth-postgresql-headless          ClusterIP   None            <none>        5432/TCP   63m
chipster-job-history-postgresql-headless   ClusterIP   None            <none>        5432/TCP   63m
chipster-session-db-postgresql-headless    ClusterIP   None            <none>        5432/TCP   63m
session-db                                 ClusterIP   10.43.53.123    <none>        80/TCP     63m
auth                                       ClusterIP   10.43.137.79    <none>        80/TCP     63m
service-locator                            ClusterIP   10.43.0.107     <none>        80/TCP     63m
chipster-job-history-postgresql            ClusterIP   10.43.93.255    <none>        5432/TCP   63m
scheduler                                  ClusterIP   10.43.225.83    <none>        80/TCP     63m
toolbox                                    ClusterIP   10.43.235.149   <none>        80/TCP     63m
session-db-events                          ClusterIP   10.43.242.65    <none>        80/TCP     63m
web-server                                 ClusterIP   10.43.187.142   <none>        80/TCP     63m
session-worker                             ClusterIP   10.43.95.159    <none>        80/TCP     63m
file-broker                                ClusterIP   10.43.241.44    <none>        80/TCP     63m
chipster-auth-postgresql                   ClusterIP   10.43.93.48     <none>        5432/TCP   63m
chipster-session-db-postgresql             ClusterIP   10.43.34.78     <none>        5432/TCP   63m
type-service                               ClusterIP   10.43.232.77    <none>        80/TCP     63m
```

Make sure you can access the service from some other pod. Note that the `service` maps the container port `8002` to a default HTTP port `80`, so you don't need to define the port number here anymore. Again, `HTTP 404` here means that the server did respond.

```bash
kubectl exec -it deployment/service-locator bash
I have no name!@service-locator-cb95969c5-fxdgz:/opt/chipster$ curl http://auth
HTTP 404 Not Found
```

List ingresses
```bash
$ kubectl get ingress
NAME                HOSTS   ADDRESS        PORTS   AGE
session-worker      *       192.168.15.5   80      64m
scheduler           *       192.168.15.5   80      64m
type-service        *       192.168.15.5   80      64m
job-history         *       192.168.15.5   80      64m
auth                *       192.168.15.5   80      64m
service-locator     *       192.168.15.5   80      64m
session-db          *       192.168.15.5   80      64m
comp                *       192.168.15.5   80      64m
file-broker         *       192.168.15.5   80      64m
toolbox             *       192.168.15.5   80      64m
backup              *       192.168.15.5   80      64m
session-db-events   *       192.168.15.5   80      64m
web-server          *       192.168.15.5   80      64m
```

Finally you can check that you can connect to your ingress from your laptop. If everything works, the Rest API should respond with `HTTP 404` again.

```bash
$ curl http://HOST_ADDRESS/auth
HTTP 404
```

## View content of Chipster configuration file from a Kubernetes secret

Use `kubectl get secret` to get the secret object. Then use `jq` to pick the correct configuration file. Careful quoting of dots is needed, because the file name unfortunately includes a dot character, which has other meaning in `jq` queries by default. Use `-r` to print the value without quotes. Finally, the values in secrets are base64 encoded and has to be decoded with `base64 -d`. 

For example, view the configuration of the service-locator:

```bash
kubectl get secret service-locator -o json | jq '.data."chipster.yaml"' -r | base64 -d
```

There is a small script that makes this easier.

```bash
bash get-secret.bash service-locator
```

## Build from local sources

 * Copy sources to the host. Run this on your laptop. We'll build the java code in chipster-web-server repository in this example, but the same works also for other Chipster repositories. Replace `USERNAME` and `HOST_ADDRESS` with the values of your host machine.

    ```bash
    remote="USERNAME@HOST_ADDRESS"
    cd ~/git
    rsync -r chipster-web-server/ $remote:git/chipster-web-server --delete
    ```

 * Check the build command on the host

    ```bash
    $ cd ~/git/chipster-openshift/k3s
   $ bash scripts/buildconfig-to-docker.bash ../templates/builds/chipster-web-server
   cat ../templates/builds/chipster-web-server/Dockerfile | sudo docker build -t chipster-web-server -f - https://github.com/chipster/chipster-web-server.git
    ```

 * Run the build, but replace the build context (GitHub URL) with the source dir

    ```bash
    cat templates/builds/chipster-web-server/Dockerfile | sudo docker build -t chipster-web-server -f - ../../chipster-web-server
    ```

 * Restart pods

   ```bash
   bash restart.bash
   ```

## Get a shell to a container that doesn't start

 * Let's edit the deployment a bit.

   ```bash
   kubectl edit deployment/comp
   ```

 * Hit `i` to go to the edit mode. Override the container command (usually defined in the Dockerfile) with infinite sleep to make sure it starts.

  ```yaml
  containers
  - command:
    - sleep
    args:
    - inf
```

 * Hit Esc to go back to the command mode, and `:wq` to save and quit

 * Get a shell

   ```bash
   kubectl exec -it deployment/comp bash
   ```