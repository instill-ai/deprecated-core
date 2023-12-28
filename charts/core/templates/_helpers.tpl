{{/*
Expand the name of the chart.
*/}}
{{- define "core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "core.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "core.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "core.labels" -}}
app.kubernetes.io/name: {{ include "core.name" . }}
helm.sh/chart: {{ include "core.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | replace "+" "_" }}
app.kubernetes.io/part-of: {{ .Chart.Name }}
{{- end -}}

{{/*
MatchLabels
*/}}
{{- define "core.matchLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "core.name" . }}
{{- end -}}

{{- define "core.autoGenCert" -}}
  {{- if and .Values.expose.tls.enabled (eq .Values.expose.tls.certSource "auto") -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "core.autoGenCertForIngress" -}}
  {{- if and (eq (include "core.autoGenCert" .) "true") (eq .Values.expose.type "ingress") -}}
    {{- printf "true" -}}
  {{- else -}}
    {{- printf "false" -}}
  {{- end -}}
{{- end -}}

{{- define "core.database.host" -}}
  {{- if .Values.database.enabled -}}
    {{- template "core.database" . -}}
  {{- else -}}
    {{- .Values.database.external.host -}}
  {{- end -}}
{{- end -}}

{{- define "core.database.port" -}}
  {{- if .Values.database.enabled -}}
    {{- printf "%s" "5432" -}}
  {{- else -}}
    {{- .Values.database.external.port -}}
  {{- end -}}
{{- end -}}

{{- define "core.database.username" -}}
  {{- if .Values.database.enabled -}}
    {{- printf "%s" "postgres" -}}
  {{- else -}}
    {{- .Values.database.external.username -}}
  {{- end -}}
{{- end -}}

{{- define "core.database.rawPassword" -}}
  {{- if .Values.database.enabled -}}
    {{- .Values.database.password -}}
  {{- else -}}
    {{- .Values.database.external.password -}}
  {{- end -}}
{{- end -}}

{{- define "core.database.encryptedPassword" -}}
  {{- include "core.database.rawPassword" . | b64enc | quote -}}
{{- end -}}

/*host:port*/
{{- define "core.redis.addr" -}}
  {{- with .Values.redis -}}
    {{- ternary (printf "%s:6379" (include "core.redis" $ )) .external.addr .enabled -}}
  {{- end -}}
{{- end -}}

{{- define "core.apiGateway" -}}
  {{- printf "%s-api-gateway" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.mgmtBackend" -}}
  {{- printf "%s-mgmt-backend" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.openfga" -}}
  {{- printf "%s-openfga" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.console" -}}
  {{- printf "%s-console" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.database" -}}
  {{- printf "%s-database" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.redis" -}}
  {{- printf "%s-redis" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.temporal" -}}
  {{- printf "%s-temporal" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.etcd" -}}
  {{- printf "%s-etcd" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.temporal.admintools" -}}
  {{- printf "%s-temporal-admintools" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.temporal.ui" -}}
  {{- printf "%s-temporal-ui" (include "core.fullname" .) -}}
{{- end -}}

{{- define "kube-prometheus-stack.alertmanager.crname" -}}
  {{- printf "alertmanager" -}}
{{- end -}}

{{- define "kube-prometheus-stack.prometheus.crname" -}}
  {{- printf "prometheus" -}}
{{- end -}}

{{/* api-gateway project */}}
{{- define "core.apiGateway.project" -}}
  {{- printf "core" -}}
{{- end -}}

{{/* api-gateway service and container port */}}
{{- define "core.apiGateway.httpPort" -}}
  {{- printf "8080" -}}
{{- end -}}

{{/* api-gateway service and container stats port */}}
{{- define "core.apiGateway.statsPort" -}}
  {{- printf "8070" -}}
{{- end -}}

{{/* api-gateway service and container metrics port */}}
{{- define "core.apiGateway.metricsPort" -}}
  {{- printf "8071" -}}
{{- end -}}

{{/* mgmt-backend service and container public port */}}
{{- define "core.mgmtBackend.publicPort" -}}
  {{- printf "8084" -}}
{{- end -}}

{{/* mgmt-backend service and container private port */}}
{{- define "core.mgmtBackend.privatePort" -}}
  {{- printf "3084" -}}
{{- end -}}

{{/* console service and container port */}}
{{- define "core.console.port" -}}
  {{- printf "3000" -}}
{{- end -}}

{{/* temporal container frontend gRPC port */}}
{{- define "core.temporal.frontend.grpcPort" -}}
  {{- printf "7233" -}}
{{- end -}}

{{/* temporal container frontend membership port */}}
{{- define "core.temporal.frontend.membershipPort" -}}
  {{- printf "6933" -}}
{{- end -}}

{{/* temporal container history gRPC port */}}
{{- define "core.temporal.history.grpcPort" -}}
  {{- printf "7234" -}}
{{- end -}}

{{/* temporal container history membership port */}}
{{- define "core.temporal.history.membershipPort" -}}
  {{- printf "6934" -}}
{{- end -}}

{{/* temporal container matching gRPC port */}}
{{- define "core.temporal.matching.grpcPort" -}}
  {{- printf "7235" -}}
{{- end -}}

{{/* temporal container matching membership port */}}
{{- define "core.temporal.matching.membershipPort" -}}
  {{- printf "6935" -}}
{{- end -}}

{{/* temporal container worker gRPC port */}}
{{- define "core.temporal.worker.grpcPort" -}}
  {{- printf "7239" -}}
{{- end -}}

{{/* temporal container worker membership port */}}
{{- define "core.temporal.worker.membershipPort" -}}
  {{- printf "6939" -}}
{{- end -}}

{{/* temporal web container port */}}
{{- define "core.temporal.ui.port" -}}
  {{- printf "8080" -}}
{{- end -}}

{{/* etcd port */}}
{{- define "core.etcd.clientPort" -}}
  {{- printf "2379" -}}
{{- end -}}

{{- define "core.etcd.peerPort" -}}
  {{- printf "2380" -}}
{{- end -}}

{{- define "core.influxdb" -}}
  {{- printf "%s-influxdb2" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.influxdb.port" -}}
  {{- printf "8086" -}}
{{- end -}}

{{- define "core.jaeger" -}}
  {{- printf "%s-jaeger-collector" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.jaeger.port" -}}
  {{- printf "14268" -}}
{{- end -}}

{{- define "core.otel" -}}
  {{- printf "%s-opentelemetry-collector" (include "core.fullname" .) -}}
{{- end -}}

{{- define "core.otel.port" -}}
  {{- printf "8095" -}}
{{- end -}}

{{- define "core.internalTLS.apiGateway.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.apiGateway.secretName -}}
  {{- else -}}
    {{- printf "%s-api-gateway-internal-tls" (include "core.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "core.internalTLS.mgmtBackend.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.mgmtBackend.secretName -}}
  {{- else -}}
    {{- printf "%s-mgmt-internal-tls" (include "core.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "core.internalTLS.console.secretName" -}}
  {{- if eq .Values.internalTLS.certSource "secret" -}}
    {{- .Values.internalTLS.console.secretName -}}
  {{- else -}}
    {{- printf "%s-console-internal-tls" (include "core.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{/* Allow KubeVersion to be overridden. */}}
{{- define "core.ingress.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version .Values.expose.ingress.kubeVersionOverride -}}
{{- end -}}

{{- define "vdp.pipelineBackend" -}}
  {{- print "vdp-pipeline-backend" -}}
{{- end -}}

{{/* pipeline service and container public port */}}
{{- define "vdp.pipelineBackend.publicPort" -}}
  {{- print "8081" -}}
{{- end -}}

{{- define "model.modelBackend" -}}
  {{- printf "model-model-backend" -}}
{{- end -}}

{{/* model-backend service and container public port */}}
{{- define "model.modelBackend.publicPort" -}}
  {{- printf "8083" -}}
{{- end -}}
