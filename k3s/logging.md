# Chipster logging configuration
## Introduction

Chipster loggin levels can be configured in file `log4j2.xml`. The [default configuration](https://github.com/chipster/chipster-web-server/blob/master/src/main/resources/log4j2.xml) is included in the jar packages. However, if a file `conf/log4j2.xml` exists, it will be used instead. 

This example shows how to change a logging level of individual library. By default the logging level of LdapExtLoginModule (used in [LDAP instructions](ldap.md) is `debug`. In this example we'll change it to `trace`. 

Open the default configuration from the link above. Click the `Raw` link. Copy the file to your `values.yaml` like shown below. Make sure to indent it with space characters correctly (for example select the whole text in VS Code and hit tab a few times). The example below has the copy of the file when this page was written, but please copy the lates version from the GitHub in case there are changes. 

If you keep a customized log config in your production setup, you may want to also check changes in the default file when updating your Chipster server.

```yaml
deployments:
  auth:
    conf:
      log4j2.xml: |
        <?xml version="1.0" encoding="UTF-8"?>

        <!-- 

        PLEASE NOTE!

        When developing / debugging, copy log4j2.xml to log4j2-test.xml and make development / debugging
        related modifications there.

        If log4j2-test.xml is present, it takes precedence over log4j2.xml. Log4j2-test.xml is excluded 
        when building the jar and it is also ignored in git.

        The idea with this approach is to make it easy to make logging config changes when debugging or
        developing, without having to worry about committing them accidentally. 

        -->


        <!--  level of the log4j2 internal logging -->
        <Configuration status="error">
          <Appenders>
            <Console name="Console" target="SYSTEM_OUT">
              <!--  Detailed pattern for fine tuning logging (with packages and log levels) -->
                <!--  <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>  -->
                <!--  A concise pattern for everything else -->
              <PatternLayout pattern="[%d] %p: %m (in %C{1}:%L)%n" />

            </Console>

            <Console name="WarnConsole" target="SYSTEM_OUT">
              <!--  Detailed pattern for fine tuning logging (with packages and log levels) -->
                <!--  <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>  -->
                <!--  A concise pattern for everything else -->
                <PatternLayout pattern="[%d] %p: %m (in %C{1}:%L)%n" />
                <ThresholdFilter level="warn"/>
            </Console>


            <File name="WarnFile" fileName="logs/error.log">
              <PatternLayout>
                <Pattern>[%d] %m (in %C{1}:%L)%n</Pattern>
              </PatternLayout>
                <ThresholdFilter level="warn"/>
            </File>
          
            <File name="chipster" fileName="logs/chipster.log">
              <PatternLayout>
                <Pattern>[%d] %m (in %C{1}:%L)%n</Pattern>
              </PatternLayout>
            </File>

            <File name="toolbox" fileName="logs/toolbox.log">
              <PatternLayout>
                <Pattern>[%d] %m (in %C{1}:%L)%n</Pattern>
              </PatternLayout>
            </File>


          
          </Appenders>
          <Loggers>
            <!--  hide initialization messages of MLog -->
            <!--  <Logger name="com.mchange.v2" level="warn" /> -->
            <!--  logging level of c3p0 connection pool -->
            <Logger name="com.mchange.v2.c3p0" level="info" />
            <Logger name="com.mchange.v2.resourcepool" level="debug" />

            <Logger name="org.eclipse.jetty" level="warn" />
            
            <!--  log from libraries only when something is wrong -->
            <Logger name="org.glassfish.grizzly" level="warn" />
            <Logger name="org.hibernate" level="warn" />
            <!--  Log sql query parameter values -->
            <!--  <Logger name="org.hibernate.type" level="trace" /> -->
            
            <!--  if this is enabled in the code, we really want to see it's logs -->
            <Logger name="org.glassfish.jersey.filter.LoggingFilter" level="info" />
            
            <!-- hide warnings when we initialize Jersey with resource instances instead of classes -->
            <!-- https://stackoverflow.com/questions/37204930/rest-filter-registered-in-server-runtime-does-not-implement-any-provider-inter -->
            <!-- [2021-01-12 09:17:02,152] WARN: A provider fi.csc.chipster.backup.BackupAdminResource registered in SERVER runtime does not implement any provider interfaces applicable in the SERVER runtime. Due to constraint configuration problems the provider fi.csc.chipster.backup.BackupAdminResource will be ignored.  (in Providers:497) -->    
            <Logger name="org.glassfish.jersey.internal.inject.Providers" level="error" />
            
            <!--  show logs from LdapExtLoginModule -->
            <Logger name="org.jboss.security" level="trace" />
            
            <!--  default level for our code -->
            <Logger name="fi.csc.chipster" level="info" additivity="false">
              <AppenderRef ref="chipster"/>
            <AppenderRef ref="Console"/>
            <AppenderRef ref="WarnFile"/>
            </Logger>

            <!--  ServerLauncher logs to console 
            <Logger name="fi.csc.chipster.rest.ServerLauncher" level="info" >
            <AppenderRef ref="Console"/>
          </Logger>	-->


            <Logger name="fi.csc.chipster.toolbox" level="info" >
            <AppenderRef ref="toolbox"/>
          </Logger>	

                
            <!--  We want to hide these when running tests, but the TestServerLauncher 
            is only able to modify existing loggers. Without this it will get the 
            logger for fi.csc.chipster and disable it. -->
            <Logger name="fi.csc.chipster.rest.websocket" level="info" />
            
            <!--  info level by default so that we see if new libraries have anything interesting to say. Set a higher level for noisy libraries above. -->
            <Root level="info">
              <AppenderRef ref="Console"/>
            </Root>
          </Loggers>
        </Configuration>
```

Thist will create a file `conf/log4j2.xml`.

Deploy the configuration and restart `auth`:

```bash
bash deploy.bash -f ~/values.yaml
kubectl rollout restart deployment/auth
```

See when new auth has started and the old has disappeared:

```bash
kubectl get pod
```

And check auth logs while you try to log in to Chipster, provided you have the LdapExtLoginModule configured. This should now show also some `trace` level messages:

```bash
kubectl logs deployment/auth --follow
```
