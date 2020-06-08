{{/* vim: set filetype=mustache: */}}

{{/*
Copy Chipster configuration key-value pairs
*/}}
{{- define "chipster.listDeploymentConfigs" -}}
{{- range $configKey, $value := .configs }}
{{ $configKey }}: {{ $value }}
{{- end }}
{{- end -}}

{{/*
Check if TLS is configured and return a https or http string accordingly
*/}}
{{- define "chipster.getHttpProtocol" -}}
{{- if $.Values.tls.env -}}
https
{{- else -}}
http
{{- end -}}
{{- end -}}

{{/*
Check if TLS is configured and return a wss or ws string accordingly
*/}}
{{- define "chipster.getWebSocketProtocol" -}}
{{- if $.Values.tls.env -}}
wss
{{- else -}}
ws
{{- end -}}
{{- end -}}