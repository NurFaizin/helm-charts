{{/*
Expand the name of the chart.
*/}}
{{- define "n8n.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "n8n.fullname" -}}
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
n8n base url
*/}}
{{- define "n8n.baseurl" -}}
{{- if and .Values.ingress.enabled .Values.ingress.hostname }}
{{- .Values.ingress.hostname }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "n8n.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "n8n.labels" -}}
helm.sh/chart: {{ include "n8n.chart" . }}
{{ include "n8n.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "n8n.selectorLabels" -}}
app.kubernetes.io/name: {{ include "n8n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod environments
*/}}
{{- define "n8n.deploymentPodEnvironments" -}}
{{- range $key, $value := .Values.extraEnv }}
- name: {{ $key }}
  value: {{ $value | quote}}
{{ end }}
- name: "N8N_PORT" #! we better set the port once again as ENV Var, see: https://community.n8n.io/t/default-config-is-not-set-or-the-port-to-be-more-precise/3158/3?u=vad1mo
  value: {{ get .Values.config "port" | default "5678" | quote }}
{{- if (include "n8n.baseurl" .) }}
- name: "N8N_EDITOR_BASE_URL"
  value: {{ include "n8n.baseurl" . | quote }}
- name: "WEBHOOK_URL"
  value: {{ include "n8n.baseurl" . | quote }}
- name: "WEBHOOK_TUNNEL_URL"
  value: {{ include "n8n.baseurl" . | quote }}
{{- end }}
- name: EXECUTIONS_TIMEOUT
  value: {{ .Values.executions.timeout | quote }}
- name: EXECUTIONS_TIMEOUT_MAX
  value: {{ .Values.executions.timeoutMax | quote }}
- name: EXECUTIONS_DATA_SAVE_ON_ERROR
  value: {{ .Values.executions.saveDataOnError | quote }}
- name: EXECUTIONS_DATA_SAVE_ON_SUCCESS
  value: {{ .Values.executions.saveDataOnSuccess | quote }}
- name: EXECUTIONS_DATA_SAVE_ON_PROGRESS
  value: {{ .Values.executions.saveExecutionProgress | quote }}
- name: EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS
  value: {{ .Values.executions.saveDataManualExecutions | quote }}
- name: EXECUTIONS_DATA_PRUNE
  value: {{ .Values.executions.pruneData | quote }}
- name: EXECUTIONS_DATA_MAX_AGE
  value: {{ .Values.executions.pruneDataMaxAge | quote }}
- name: EXECUTIONS_DATA_PRUNE_TIMEOUT
  value: {{ .Values.executions.pruneDataTimeout | quote }}
- name: EXECUTIONS_DATA_PRUNE_MAX_COUNT
  value: {{ .Values.executions.pruneDataMaxCount | quote }}
- name: N8N_EMAIL_MODE
  value: smtp
- name: N8N_SMTP_HOST
  value: {{ .Values.smtp.host | quote }}
- name: N8N_SMTP_PORT
  value: {{ .Values.smtp.port | quote }}
- name: N8N_SMTP_SSL
  value: {{ .Values.smtp.ssl | quote }}
- name: N8N_SMTP_USER
  value: {{ .Values.smtp.user | quote }}
- name: N8N_SMTP_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "n8n.fullname" . }}-smtp
      key: pass
- name: N8N_SMTP_SENDER
  value: {{ .Values.smtp.sender | quote }}
- name: DB_TYPE
  value: mariadb
- name: DB_MYSQLDB_HOST
  value: {{ include "n8n.databaseHost" . | quote }}
- name: DB_MYSQLDB_PORT
  value: {{ include "n8n.databasePort" . | quote }}
- name: DB_MYSQLDB_DATABASE
  value: {{ include "n8n.databaseName" . | quote }}
- name: DB_MYSQLDB_USER
  value: {{ include "n8n.databaseUser" . | quote }}
- name: DB_MYSQLDB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "n8n.databaseSecretName" . }}
      key: mariadb-password
- name: "N8N_ENCRYPTION_KEY"
  valueFrom:
    secretKeyRef:
      key:  N8N_ENCRYPTION_KEY
      name: {{ include "n8n.fullname" . }}
{{- if or .Values.config .Values.secret }}
- name: "N8N_CONFIG_FILES"
  value: {{ include "n8n.configFiles" . | quote }}
{{ end }}
{{- if .Values.scaling.enabled }}
- name: "EXECUTIONS_MODE"
  value: "queue"
- name: "QUEUE_BULL_REDIS_HOST"
  value: {{ ternary (include "n8n.redis.fullname" .) .Values.externalRedis.host .Values.redis.enabled | quote }}
- name: "QUEUE_BULL_REDIS_PORT"
  value: {{ ternary "6379" .Values.externalRedis.port .Values.redis.enabled | quote }}
- name: "QUEUE_BULL_REDIS_PASSWORD"
  valueFrom:
    secretKeyRef:
      name: {{ include "n8n.redis.secretName" . }}
      key: redis-password
- name: "QUEUE_HEALTH_CHECK_ACTIVE"
  value: {{ .Values.scaling.healthcheck | quote }}
{{ end }}
{{- if .Values.scaling.webhook.enabled }}
- name: "N8N_DISABLE_PRODUCTION_MAIN_PROCESS"
  value: "true"
{{ end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "n8n.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "n8n.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Create a list of config files for n8n */}}
{{- define "n8n.configFiles" -}}
    {{- $conf_val := "" }}
    {{- $sec_val  := "" }}
    {{- $separator  := "" }}
    {{- if .Values.config }}
        {{- $conf_val = "/n8n-config/config.json" }}
    {{- end }}
    {{- if .Values.secret }}
        {{- $sec_val = "/n8n-secret/secret.json" }}
    {{- end }}
    {{- if and .Values.config .Values.secret }}
        {{- $separator  = "," }}
    {{- end }}
    {{- print $conf_val $separator $sec_val }}
{{- end }}


{{/* PVC existing, emptyDir, Dynamic */}}
{{- define "n8n.pvc" -}}
{{- if or (not .Values.persistence.enabled) -}}
          emptyDir: {}
{{- else if and .Values.persistence.enabled .Values.persistence.existingClaim -}}
          persistentVolumeClaim:
            claimName: {{ .Values.persistence.existingClaim }}
{{- else if and .Values.persistence.enabled (not .Values.persistence.existingClaim) -}}
          persistentVolumeClaim:
            claimName: {{ include "n8n.fullname" . }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "n8n.mariadb.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "mariadb" "chartValues" .Values.mariadb "context" $) -}}
{{- end -}}

{{/*
Return the MariaDB Hostname
*/}}
{{- define "n8n.databaseHost" -}}
{{- if .Values.mariadb.enabled }}
    {{- if eq .Values.mariadb.architecture "replication" }}
        {{- printf "%s-primary" (include "n8n.mariadb.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s" (include "n8n.mariadb.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Port
*/}}
{{- define "n8n.databasePort" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "3306" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Database Name
*/}}
{{- define "n8n.databaseName" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.database -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB User
*/}}
{{- define "n8n.databaseUser" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.username -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Secret Name
*/}}
{{- define "n8n.databaseSecretName" -}}
{{- if .Values.mariadb.enabled }}
    {{- if .Values.mariadb.auth.existingSecret -}}
        {{- printf "%s" .Values.mariadb.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "n8n.mariadb.fullname" .) -}}
    {{- end -}}
{{- else if .Values.externalDatabase.existingSecret -}}
    {{- include "common.tplvalues.render" (dict "value" .Values.externalDatabase.existingSecret "context" $) -}}
{{- else -}}
    {{ printf "%s-%s" (include "n8n.fullname" .) "externaldatabase" }}
{{- end -}}
{{- end -}}


{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "n8n.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis-master" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Get the Redis credentials secret.
*/}}
{{- define "n8n.redis.secretName" -}}
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
        {{ printf "%s-%s" (include "n8n.fullname" .) "externalredis" }}
    {{- end -}}
{{- end -}}
{{- end -}}
