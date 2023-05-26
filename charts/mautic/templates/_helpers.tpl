{{/*
Expand the name of the chart.
*/}}
{{- define "mautic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mautic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mautic site url
*/}}
{{- define "mautic.siteUrl" -}}
{{- if and .Values.ingress.enabled .Values.ingress.hostname }}
{{- if .Values.ingress.tls.enabled }}
{{- printf "https://%s" .Values.ingress.hostname }}
{{- else }}
{{- printf "http://%s" .Values.ingress.hostname }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mautic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mautic.labels" -}}
helm.sh/chart: {{ include "mautic.chart" . }}
{{ include "mautic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mautic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mautic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mautic.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mautic.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pod environments
*/}}
{{- define "mautic.deploymentPodEnvironments" -}}
{{- range $key, $value := .Values.extraEnv }}
- name: {{ $key }}
  value: {{ $value | quote}}
{{- end }}
- name: MAUTIC_DB_HOST
  value: {{ include "mautic.databaseHost" . | quote }}
- name: MAUTIC_DB_PORT
  value: {{ include "mautic.databasePort" . | quote }}
- name: MAUTIC_DB_NAME
  value: {{ include "mautic.databaseName" . | quote }}
- name: MAUTIC_DB_USER
  value: {{ include "mautic.databaseUser" . | quote }}
- name: MAUTIC_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.databaseSecretName" . }}
      key: mariadb-password
- name: MAUTIC_RUN_CRON_JOBS
  value: "false"
{{- if .Values.ingress.enabled }}
- name: MAUTIC_TRUSTED_PROXIES
  value: "[\"0.0.0.0/0\"]"
{{- end }}
{{- if (include "mautic.siteUrl" .) }}
- name: MAUTIC_URL
  value: {{ include "mautic.siteUrl" . | quote }}
- name: MAUTIC_INSTALL_FORCE
  value: "true"
{{- end }}
{{- if .Values.queue.enabled }}
- name: MAUTIC_CONFIG_QUEUE_PROTOCOL
  value: beanstalkd
- name: MAUTIC_CONFIG_BEANSTALKD_HOST
  value: {{ include "mautic.beanstalkdHost" . | quote }}
- name: MAUTIC_CONFIG_BEANSTALKD_PORT
  value: {{ include "mautic.beanstalkdPort" . | quote }}
- name: MAUTIC_CONFIG_MAILER_SPOOL_TYPE
  value: file
- name: MAUTIC_CONFIG_QUEUE_MODE
  value: command_process
{{- end }}
{{- if .Values.cache.enabled }}
- name: "REDIS_HOST"
  value: {{ ternary (include "mautic.redis.fullname" .) .Values.externalRedis.host .Values.redis.enabled | quote }}
- name: "REDIS_PORT"
  value: {{ ternary "6379" .Values.externalRedis.port .Values.redis.enabled | quote }}
- name: "REDIS_PASSWORD"
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.redis.secretName" . }}
      key: redis-password
{{- end }}
- name: MAUTIC_ADMIN_EMAIL
  value: {{ .Values.admin.email | quote }}
- name: MAUTIC_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.fullname" . }}
      key: admin-password
- name: MAUTIC_ADMIN_USERNAME
  value: {{ .Values.admin.username | quote }}
- name: MAUTIC_ADMIN_FIRSTNAME
  value: {{ .Values.admin.firstname | quote }}
- name: MAUTIC_ADMIN_LASTNAME
  value: {{ .Values.admin.lastname | quote }}
- name: MAUTIC_CONFIG_DEFAULT_TIMEZONE
  value: {{ .Values.system.timezone | quote }}
- name: PHP_INI_DATE_TIMEZONE
  value: {{ .Values.system.timezone | quote }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mautic.mariadb.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "mariadb" "chartValues" .Values.mariadb "context" $) -}}
{{- end -}}

{{/*
Return the MariaDB Hostname
*/}}
{{- define "mautic.databaseHost" -}}
{{- if .Values.mariadb.enabled }}
    {{- if eq .Values.mariadb.architecture "replication" }}
        {{- printf "%s-primary" (include "mautic.mariadb.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s" (include "mautic.mariadb.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Port
*/}}
{{- define "mautic.databasePort" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "3306" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Database Name
*/}}
{{- define "mautic.databaseName" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.database -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB User
*/}}
{{- define "mautic.databaseUser" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.username -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Secret Name
*/}}
{{- define "mautic.databaseSecretName" -}}
{{- if .Values.mariadb.enabled }}
    {{- if .Values.mariadb.auth.existingSecret -}}
        {{- printf "%s" .Values.mariadb.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "mautic.mariadb.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- include "common.tplvalues.render" (dict "value" .Values.externalDatabase.existingSecret "context" $) -}}
{{- else -}}
    {{ printf "%s-%s" (include "mautic.fullname" .) "externaldatabase" }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mautic.beanstalkd.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "beanstalkd" "chartValues" .Values.beanstalkd "context" $) -}}
{{- end -}}

{{/*
Return the beanstalkd Hostname
*/}}
{{- define "mautic.beanstalkdHost" -}}
{{- if .Values.beanstalkd.enabled }}
    {{- printf "%s" (include "mautic.beanstalkd.fullname" .) -}}
{{- else -}}
    {{- printf "%s" .Values.externalBeanstalkd.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the beanstalkd Port
*/}}
{{- define "mautic.beanstalkdPort" -}}
{{- if .Values.beanstalkd.enabled }}
    {{- printf "11300" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalBeanstalkd.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mautic.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis-master" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Get the Redis credentials secret.
*/}}
{{- define "mautic.redis.secretName" -}}
{{- if and (.Values.redis.enabled) (not .Values.redis.auth.existingSecret) -}}
    {{/* Create a include for the redis secret
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    */}}
    {{- $name := default "redis" .Values.redis.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else if and (.Values.redis.enabled) ( .Values.redis.auth.existingSecret) -}}
    {{- printf "%s" .Values.redis.auth.existingSecret -}}
{{- else }}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- printf "%s" .Values.externalRedis.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" (include "mautic.fullname" .) "externalredis" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "mautic.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "mautic.validateValues.database" .) -}}
{{- $messages := append $messages (include "mautic.validateValues.redis" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}


{{/* Validate values of Mautic - Database */}}
{{- define "mautic.validateValues.database" -}}
{{- if and (not .Values.mariadb.enabled) (or (empty .Values.externalDatabase.host) (empty .Values.externalDatabase.port) (empty .Values.externalDatabase.database)) -}}
mautic: mariadb
   You disable the MariaDB installation but you did not provide the required parameters
   to use an external database. To use an external database, please ensure you provide
   (at least) the following values:

       externalDatabase.host=DB_SERVER_HOST
       externalDatabase.database=DB_NAME
       externalDatabase.port=DB_SERVER_PORT
{{- end -}}
{{- end -}}

{{/* Validate values of Mautic - Redis */}}
{{- define "mautic.validateValues.redis" -}}
{{- if and .Values.cache.enabled (not .Values.redis.enabled) (or (empty .Values.externalRedis.host) (empty .Values.externalRedis.port)) -}}
mautic: redis
   You enabled scaling with queue mechanism but you did not enable the Redis
   installation nor you did provided the required parameters to use an external redis server.
   Please enable the Redis installation (--set redis.enabled=true) or
   provide the external redis server values:

       externalRedis.host=REDIS_SERVER_HOST
       externalRedis.port=REDIS_SERVER_PORT
{{- end -}}
{{- end -}}
