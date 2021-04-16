{{/* vim: set filetype=mustache: */}}

{{/*
Copy Chipster configuration key-value pairs
*/}}
{{- define "chipster.listDeploymentConfigs" -}}
# insert values as yaml text block without the last new line
# backup encryption key requires a text block
# and simple strings shouldn't have a new line character in the end (at least aws sdk didn't tolerate it in the S3 url)
{{- range $configKey, $value := .configs }}
{{ $configKey }}: |-
{{ $value | indent 2 }}
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