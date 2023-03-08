# n8n Helm Chart for Kubernetes

[n8n](https://github.com/n8n-io/n8n) is an extendable workflow automation tool.

## Requirements

Before you start make sure you have the following dependencies ready and working:

- Helm > 3

## Configuration

The `values.yaml` file is divided into a n8n specific configuration section, and a Kubernetes deployment specific section.
The shown values represent Helm defaults not application defaults. The comments behind the values provide a description and display the application default.
Every possible n8n config can be set that are also described in the: [n8n configuration options](https://github.com/n8n-io/n8n/blob/master/packages/cli/src/config/schema.ts).

These n8n config options should be attached to Secret or Config.
You decide what should be a secret and what should be a config the options are the same.

# N8N Specific Config Section
This is only an excerpt. All options are supported, see https://github.com/n8n-io/n8n/blob/master/packages/cli/src/config/schema.ts

```yaml
database:
  type:   # Type of database to use - Other possible types ['sqlite', 'mariadb', 'mysqldb', 'postgresdb'] - default: sqlite
  tablePrefix:      # Prefix for table names - default: ''
  postgresdb:
    database:       # PostgresDB Database - default: n8n
    host:           # PostgresDB Host - default: localhost
    password:       # PostgresDB Password - default: ''
    port:           # PostgresDB Port - default: 5432
    user:           # PostgresDB User - default: root
    schema:         # PostgresDB Schema - default: public
    ssl:
      ca:             # SSL certificate authority - default: ''
      cert:           # SSL certificate - default: ''
      key:            # SSL key - default: ''
      rejectUnauthorized:    # If unauthorized SSL connections should be rejected - default: true
  mysqldb:
    database:        # MySQL Database - default: n8n
    host:            # MySQL Host - default: localhost
    password:        # MySQL Password - default: ''
    port:            # MySQL Port - default: 3306
    user:            # MySQL User - default: root
credentials:
  overwrite:
    data:        # Overwrites for credentials - default: "{}"
    endpoint:    # Fetch credentials from API - default: ''

executions:
  process:              # In what process workflows should be executed - possible values [main, own] - default: own
  timeout:              # Max run time (seconds) before stopping the workflow execution - default: -1
  maxTimeout:           # Max execution time (seconds) that can be set for a workflow individually - default: 3600
  saveDataOnError:      # What workflow execution data to save on error - possible values [all , none] - default: all
  saveDataOnSuccess:    # What workflow execution data to save on success - possible values [all , none] - default: all
  saveDataManualExecutions:    # Save data of executions when started manually via editor - default: false
  pruneData:            # Delete data of past executions on a rolling basis - default: false
  pruneDataMaxAge:      # How old (hours) the execution data has to be to get deleted - default: 336
  pruneDataTimeout:     # Timeout (seconds) after execution data has been pruned - default: 3600
generic:
  timezone:       # The timezone to use - default: America/New_York
path:           # Path n8n is deployed to - default: "/"
host:           # Host name n8n can be reached - default: localhost
port:           # HTTP port n8n can be reached - default: 5678
listen_address: # IP address n8n should listen on - default: 0.0.0.0
protocol:       # HTTP Protocol via which n8n can be reached - possible values [http , https] - default: http
ssl_key:        # SSL Key for HTTPS Protocol - default: ''
ssl_cert:       # SSL Cert for HTTPS Protocol - default: ''
security:
  excludeEndpoints: # Additional endpoints to exclude auth checks. Multiple endpoints can be separated by colon - default: ''
  basicAuth:
    active:     # If basic auth should be activated for editor and REST-API - default: false
    user:       # The name of the basic auth user - default: ''
    password:   # The password of the basic auth user - default: ''
    hash:       # If password for basic auth is hashed - default: false
  jwtAuth:
    active:               # If JWT auth should be activated for editor and REST-API - default: false
    jwtHeader:            # The request header containing a signed JWT - default: ''
    jwtHeaderValuePrefix: # The request header value prefix to strip (optional) default: ''
    jwksUri:              # The URI to fetch JWK Set for JWT authentication - default: ''
    jwtIssuer:            # JWT issuer to expect (optional) - default: ''
    jwtNamespace:         # JWT namespace to expect (optional) -  default: ''
    jwtAllowedTenantKey:  # JWT tenant key name to inspect within JWT namespace (optional) - default: ''
    jwtAllowedTenant:     # JWT tenant to allow (optional) - default: ''
endpoints:
  rest:             # Path for rest endpoint  default: rest
  webhook:          # Path for webhook endpoint  default: webhook
  webhookTest:      # Path for test-webhook endpoint  default: webhook-test
externalHookFiles:  # Files containing external hooks. Multiple files can be separated by colon - default: ''
nodes:
  exclude:          # Nodes not to load - default: "[]"
  errorTriggerType: # Node Type to use as Error Trigger - default: n8n-nodes-base.errorTrigger
# the list goes on...
```


### Values
The values file consits of n8n specific sections `config` and `secret` where you paste the n8n config like shown above
A typical example of a config in combination with a secret.


```yaml
# values.yaml

config:
  database:
    type: postgresdb
    postgresdb:
      host: 192.168.0.52
secret:
  database:
    postgresdb:
      password: 'big secret'

```
## Setup

```shell
helm install -f values.yaml -n n8n deploymentname n8n
```

## Scaling

n8n provides a **queue-mode**, where the workload is shared between multiple instances of same n8n installation.   
This provide a shared load over multiple instances and a limited high availability, because the controller instance remain as Single-Point-Of-Failure.  

With the help of an internal/external redis server and by using the excelent BullMQ, the tasks can be shared over different instances, which also can run on different hosts.

[See docs about this Queue-Mode](https://docs.n8n.io/hosting/scaling/queue-mode/)

To enable this mode within this helm chart, you simple should set scaling.enable to true. This chart is configured to spawn by default 2 worker instances.

```yaml
scaling:
  enabled: true
```

You can define to spawn more worker, by set scaling.worker.count to a higher number. Also it is possible to define your own external redis server.

```yaml
externalRedis:
  host: "redis-hostname"
  port: "redis-port"
  password: "redis-password-if-set"
```

If you want to use the internal redis server, set **redis.enable** to "**true**". By default no redis server is spawned.

At last scaling option is it possible to create dedicated webhook instances, which only process the webhooks. If you set **scaling.webhook.enabled** to "true", then webhook processing on main instance is disabled and by default a single webhook instance is started.
