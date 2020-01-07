# Getting started with k3s
## Kubernetes terms

* Chipster service
  
  (Mostly) a Java process executing one Chipster component, like auth, toolbox or comp.

* Host

  The Ubuntu server where we k3s is running. Right now we have just one of them, but a Kubernetes or k3s cluster can be scaled to run on several hosts.

* Container
  
  Each Chipster service will run in its own container. For the process it looks like it would be the only process running on that machine. 

* Pod

  A pod contains one or more containers. At this point we will have exactly one container in each pod, so we have one pod for each Chipster service. Usually the other containers in the same pod
  could be used as `sidecar` containers for small background tasks, like collecting logs from the main service. You can scale the number of pods to run several replicas of the same Chipster service.

* Namespace

  Kubernetes project. All containers in the same namespace share the same private network. We'll setup our Chipster to run inside one `namespace`.

* Service

  Generally we wouldn't know, on which host the Kubernetes decides to run our containers. So we need 
  to define a `service` to access it. Service makes the container accessible from other containers in the same name space. There is a DNS service, which resolves service names to the container IP addresses. If you have a web server running in a container and a `service` called `web-server`, you can simply run command `curl http://web-server` on any container (in the same namespace) to query the front page of that web server. When you have multiple instances of the same pod running, the `service` acts as a load-balancer that distributes your (TCP) connections to different pod instances.

* Ingress

  To access a `service` from outside, like from your browser, you have to define an Ingress object. For example, you could setup an Ingress to publish the aforementioned web server in address `http://HOST_ADDRESS/web-server`. The Ingress is implemented as a reverse proxy and can usually pass only HTTP and WebSocket traffic. It can be also configured to terminate HTTPS connections. 

* Deployment

  We don't create pods ourselves, but we define a `deployment`. It takes care of creating and terminating pods when the desired number of pods is changed or new versions are created.

## Debugging commands

What to do when you cannot connect to one of your containers? Let's go through some basic k3s commands. First of all, make sure that you have the container image.

```bash
$ sudo k3s ctr images list
REF                                                                                                              TYPE                                                      DIGEST                                                                  SIZE      PLATFORMS                                                                   LABELS                          
docker.io/library/base-java:latest                                                                               application/vnd.oci.image.manifest.v1+json                sha256:9d787dc3b55dee00ddac80012868db50d7e92571e573c98945b91ab1dedc35e5 1.2 GiB   linux/amd64                                                                 io.cri-containerd.image=managed 
...
```

List deployments.

```bash
$ sudo kubectl get deployment
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
auth              1/1     1            1           10d
service-locator   1/1     1            1           10d
type-service      1/1     1            1           10d
comp              0/1     1            0           10d
web-server        0/1     1            0           10d
job-history       0/1     1            0           10d
scheduler         0/1     1            0           10d
backup            0/1     1            0           10d
session-db        1/1     1            1           10d
toolbox           0/1     1            0           10d
session-worker    0/1     1            0           10d
file-broker       1/1     1            1           10d
```

List pods.

```bash
$ sudo kubectl get pod
NAME                              READY   STATUS              RESTARTS   AGE
auth-75f564b8dd-xc5t9             1/1     Running             0          10d
comp-567858974f-9jqtq             0/1     ErrImageNeverPull   0          10d
web-server-776885f554-bjqcn       0/1     ErrImageNeverPull   0          10d
service-locator-cb95969c5-fxdgz   1/1     Running             1          10d
type-service-84d6659445-x72z6     1/1     Running             2          10d
backup-6f66dc856c-x2gjn           0/1     CrashLoopBackOff    4443       10d
session-worker-54f5794c98-6bwck   0/1     CrashLoopBackOff    4443       10d
session-db-77878455cb-wsl7g       0/1     CrashLoopBackOff    4446       10d
job-history-7d4849bc97-7lxrc      1/1     Running             4443       10d
file-broker-ddcbb6995-pk9kq       0/1     CrashLoopBackOff    4448       10d
toolbox-76fddcbc74-27tmj          0/1     CrashLoopBackOff    3094       10d
scheduler-54db9ff84d-zpznb        1/1     Running             4450       10d
```

See more detailts about the pod. If the pod isn't running, this should tell you the reason.

```bash
$ sudo kubectl describe pod auth-75f564b8dd-xc5t9
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

If the pod is running, see it's logs of the container to make sure it started properly.

```bash
$ sudo kubectl logs deployment/auth
[2019-12-19 15:36:20,033] INFO: get token from http://localhost:8002 (in AuthenticationClient:124)
[2019-12-19 15:36:21,319] INFO: get cors origin from http://service-locator (in CORSFilter:74)
[2019-12-19 15:36:21,463] WARN: cors headers not yeat available (request took 98ms) (in CORSFilter:84)
authentication service started
```

Sometimes it's necessary to go to the container shell, for example to see what is inside some files. If there is an error in some file, changing it in the running container won't usually help, because
the next container will be started again from the unchanged container image. You should find out where
that file came from (e.g. code repository, build, or confguration) and change it there instead.

```bash
$ sudo kubectl exec -it deployment/auth -- /bin/bash
I have no name!@auth-75f564b8dd-xc5t9:/opt/chipster$
```

If there is nothing alarming in the logs, make sure you can make a query to the server process from the same container (TODO how to find the port of each service?). `HTTP 404` is a good sign here, it means that the server process responeded.

```bash
$ curl localhost:8002       
HTTP 404 Not Found
```

List services

```bash
$ sudo kubectl get service
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes        ClusterIP   10.43.0.1       <none>        443/TCP   14d
service-locator   ClusterIP   10.43.236.240   <none>        80/TCP    10d
session-worker    ClusterIP   10.43.144.120   <none>        80/TCP    10d
auth              ClusterIP   10.43.18.213    <none>        80/TCP    10d
scheduler         ClusterIP   10.43.212.232   <none>        80/TCP    10d
type-service      ClusterIP   10.43.201.163   <none>        80/TCP    10d
file-broker       ClusterIP   10.43.249.25    <none>        80/TCP    10d
session-db        ClusterIP   10.43.183.183   <none>        80/TCP    10d
web-server        ClusterIP   10.43.177.214   <none>        80/TCP    10d
toolbox           ClusterIP   10.43.154.77    <none>        80/TCP    10d
```

Make sure you can access the service from some other pod. Note that the `service` maps the container port `8002` to a default HTTP port `80`, so you don't need to define the port number here anymore. Again, `HTTP 404` here means that the server did respond.

```bash
sudo kubectl exec -it deployment/service-locator -- /bin/bash
I have no name!@service-locator-cb95969c5-fxdgz:/opt/chipster$ curl http://auth
HTTP 404 Not Found
```

List ingresses
```bash
$ sudo kubectl get ingress
NAME              HOSTS   ADDRESS        PORTS   AGE
file-broker       *       192.168.15.2   80      10d
web-server        *       192.168.15.2   80      10d
service-locator   *       192.168.15.2   80      10d
comp              *       192.168.15.2   80      10d
session-db        *       192.168.15.2   80      10d
type-service      *       192.168.15.2   80      10d
scheduler         *       192.168.15.2   80      10d
session-worker    *       192.168.15.2   80      10d
auth              *       192.168.15.2   80      10d
toolbox           *       192.168.15.2   80      10d
job-history       *       192.168.15.2   80      10d
backup            *       192.168.15.2   80      10d
```

Finally you can check that you can connect to your ingress from your laptop. If everything works, the Rest API should respond with `HTTP 404` again.

```bash
$ curl http://HOST_ADDRESS/auth
HTTP 404
```

## Build from local sources

 * Copy sources to the host (run this on your laptop)

    ```bash
    cd ~/git
    rsync -r chipster-web-server/ $remote:git/chipster-web-server --delete
    ```

 * Check the build command

    ```bash
    $ cd ~/git/chipster-openshift
    $ bash k3s/buildconfig_to_docker.bash templates/builds/chipster-web-server
    cat templates/builds/chipster-web-server/Dockerfile | tee /dev/tty | sudo docker build -t chipster-web-server -f - https://github.com/chipster/chipster-web-server.git
    ```

 * Run the build, but replace the build context (GitHub URL) with the source dir

    ```bash
    cat templates/builds/chipster-web-server/Dockerfile | tee /dev/tty | sudo docker build -t chipster-web-server -f - ../chipster-web-server
    ```

  * Re-import the image

    ```bash
    sudo docker save chipster-web-server | sudo k3s ctr images import -
    ````

 * Restart pods

   ```bash
   sudo kubectl delete pod --all
   ```

## Get a shell to a container that doesn't start

 * Let's make sure the container starts

   ```bash
   sudo kubectl edit deployment/comp
   ```

 * Hit `i` to go to the edit mode. Override the container command (defined in the Dockerfile) with infinite sleep

   ```bash
   container
     command:
       - sleep
      args:
        - inf
    ```

 * Hit Esc to go back to the command mode, and `:wq` to save and quit

 * Get a shell

   ```bash
   sudo kubectl exec -it deployment/comp -- bash
   ```