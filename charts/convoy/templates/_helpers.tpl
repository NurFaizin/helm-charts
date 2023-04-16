{{/*
Expand the name of the chart.
*/}}
{{- define "convoy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "convoy.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "convoy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "convoy.labels" -}}
helm.sh/chart: {{ include "convoy.chart" . }}
{{ include "convoy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "convoy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "convoy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "convoy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "convoy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "convoy.postgresql.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "postgresql" "chartValues" .Values.postgresql "context" $) -}}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "convoy.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis-master" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Define database host
*/}}
{{- define "convoy.database.host" -}}
{{- ternary (include "convoy.postgresql.fullname" .) .Values.externalDatabase.host .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Define database port
*/}}
{{- define "convoy.database.port" -}}
{{- ternary "5432" .Values.externalDatabase.port .Values.postgresql.enabled -}}
{{- end -}}

{{/*
Define database user 
*/}}
{{- define "convoy.database.user" -}}
{{- if .Values.postgresql.enabled }}
    {{- .Values.postgresql.auth.username -}}
{{- else -}}
    {{- .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
Define database password 
*/}}
{{- define "convoy.database.password" -}}
{{- if and .Values.postgresql.enabled (not (empty .Values.postgresql.auth.password)) }}
    {{- .Values.postgresql.auth.password -}}
{{- else if not (empty .Values.externalDatabase.password) -}}
    {{- .Values.externalDatabase.password -}}
{{- else -}}
    {{- fail "postgresql.auth.password or externalDatabase.password must be defined" }}
{{- end -}}
{{- end -}}

{{/*
Define database name
*/}}
{{- define "convoy.database.name" -}}
{{- if and .Values.postgresql.enabled }}
    {{- .Values.postgresql.auth.database -}}
{{- else -}}
    {{- .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Define database DSN
*/}}
{{- define "convoy.database.dsn" -}}
{{- printf "postgres://%s:%s@%s:%s/%s?sslmode=disable" (include "convoy.database.user" .) (include "convoy.database.password" .) (include "convoy.database.host" .) (include "convoy.database.port" .) (include "convoy.database.name" .) }}
{{- end }}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "airflow.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis-master" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Define redis host
*/}}
{{- define "convoy.redis.host" -}}
{{- ternary (include "convoy.redis.fullname" .) .Values.externalRedis.host .Values.redis.enabled -}}
{{- end -}}

{{/*
Define redis password 
*/}}
{{- define "convoy.redis.password" -}}
{{- if and .Values.redis.enabled (not (empty .Values.redis.auth.password)) }}
    {{- .Values.redis.auth.password -}}
{{- else if not (empty .Values.externalRedis.password) -}}
    {{- .Values.externalRedis.password -}}
{{- else -}}
    {{- fail "redis.auth.password or externalRedis.password must be defined" }}
{{- end -}}
{{- end -}}

{{/*
Define redis port
*/}}
{{- define "convoy.redis.port" -}}
{{- ternary "6379" .Values.externalRedis.port .Values.redis.enabled -}}
{{- end -}}

{{/*
Define redis DSN
*/}}
{{- define "convoy.redis.dsn" -}}
{{- printf "redis://:%s@%s:%s" (include "convoy.redis.password" .) (include "convoy.redis.host" .) (include "convoy.redis.port" .) }}
{{- end }}

{{/*
Pod environments
*/}}
{{- define "convoy.deploymentPodEnvironments" -}}
{{- range $key, $value := .Values.extraEnv }}
- name: {{ $key }}
  value: {{ $value | quote}}
{{- end }}
- name: CONVOY_ENV
  value: {{ .Values.convoy.env | quote }}
{{- if .Values.ingress.enabled }}
- name: CONVOY_HOST
  value: {{ .Values.ingress.hostname | quote }}
{{- end }}
- name: CONVOY_DB_TYPE
  value: postgres
- name: CONVOY_DB_DSN
  valueFrom:
    secretKeyRef:
      name: {{ include "convoy.fullname" . }}
      key: database-dsn
- name: CONVOY_QUEUE_PROVIDER
  value: redis
- name: CONVOY_CACHE_PROVIDER
  value: redis
- name: CONVOY_REDIS_DSN
  valueFrom:
    secretKeyRef:
      name: {{ include "convoy.fullname" . }}
      key: redis-dsn
- name: CONVOY_SMTP_PROVIDER
  value: {{ .Values.smtp.provider | quote }}
- name: CONVOY_SMTP_URL
  value: {{ .Values.smtp.url | quote }}
- name: CONVOY_SMTP_PORT
  value: {{ .Values.smtp.port | quote }}
- name: CONVOY_SMTP_USERNAME
  value: {{ .Values.smtp.username | quote }}
- name: CONVOY_SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "convoy.fullname" . }}
      key: smtp-password
- name: CONVOY_SMTP_FROM
  value: {{ .Values.smtp.port | quote }}
- name: CONVOY_SMTP_REPLY_TO
  value: {{ .Values.smtp.replyTo | quote }}
- name: CONVOY_NATIVE_REALM_ENABLED
  value: {{ .Values.auth.native | quote }}
- name: CONVOY_JWT_REALM_ENABLED
  value: {{ .Values.auth.jwt | quote }}
- name: CONVOY_SIGNUP_ENABLED
  value: {{ .Values.auth.signup | quote }}
{{- end }}


{{/*
Compile all warnings into a single message.
*/}}
{{- define "convoy.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "convoy.validateValues.database" .) -}}
{{- $messages := append $messages (include "convoy.validateValues.redis" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}


{{/* Validate values of convoy - Database */}}
{{- define "convoy.validateValues.database" -}}
{{- if and (not .Values.postgresql.enabled) (or (empty .Values.externalDatabase.host) (empty .Values.externalDatabase.port) (empty .Values.externalDatabase.database)) -}}
convoy: postgresql
   You disable the PostgreSQL installation but you did not provide the required parameters
   to use an external database. To use an external database, please ensure you provide
   (at least) the following values:

       externalDatabase.host=DB_SERVER_HOST
       externalDatabase.database=DB_NAME
       externalDatabase.port=DB_SERVER_PORT
{{- end -}}
{{- end -}}

{{/* Validate values of convoy - Redis */}}
{{- define "convoy.validateValues.redis" -}}
{{- if and (not .Values.redis.enabled) (or (empty .Values.externalRedis.host) (empty .Values.externalRedis.port)) -}}
convoy: redis
   You enabled scaling with queue mechanism but you did not enable the Redis
   installation nor you did provided the required parameters to use an external redis server.
   Please enable the Redis installation (--set redis.enabled=true) or
   provide the external redis server values:

       externalRedis.host=REDIS_SERVER_HOST
       externalRedis.port=REDIS_SERVER_PORT
{{- end -}}
{{- end -}}
