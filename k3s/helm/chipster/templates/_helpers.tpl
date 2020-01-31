{{/* vim: set filetype=mustache: */}}

{{/*
Copy Chipster configuration key-value pairs
*/}}
{{- define "chipster.listDeploymentConfigs" -}}
{{- range $configKey, $value := .configs }}
{{ $configKey }}: {{ $value }}
{{- end }}
{{- end -}}
