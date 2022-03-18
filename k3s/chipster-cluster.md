# Chipster cluster

TODO Write complete instructions for setting up a K3s and Chipster cluster. 

Here are some guidelines for the number of pods for each Chipster service.

## Stateless heavy services

- file-broker
- file-storage
- session-worker

You need at least one replica for each of these services and you could add more replicas according to your load and high-availability (HA) needs.

## Stateless light services

- service-locator
- auth
- toolbox
- web-server
- (*)type-service

You need at least one replica and you could add a few more for HA. There could be even more, but usually even one replica is enough to handle the load of a large cluster.

(*) each type-service pod has its own in-memory cache. Adding many type-service replicas doesn't increase the performance that much, because the cache usage becomes less efficient.

## Non-replicated mandatory services

- session-db 

At the moment, session-db serves as a websocket server and doesn't support clustering. Increase the pod resource limits, if there are performance issues.

- scheduler

There should be exactly 1 scheduler pod. This is not a problem for HA, as long as the failed scheduler pods are restarted relatively quickly. When new scheduler pod starts, it will find the new jobs from the session-db and schedule those.

## Optional services

- backup
- job-history

There should be 0 or 1 of replicas for these optional services. Having multiple replicas would create duplicate backups or duplicate entries in the job-history database. These are not a problem for the HA, because all user features work fine without these services.