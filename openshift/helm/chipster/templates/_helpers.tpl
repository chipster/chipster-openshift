{{/*
Copy Chipster configuration key-value pairs
*/}}
# insert values as yaml text block without the last new line
# backup encryption key requires a text block
# and simple strings shouldn't have a new line character in the end (at least aws sdk didn't tolerate it in the S3 url)
{{- define "chipster.listDeploymentConfigs" -}}
{{- range $configKey, $value := .configs }}
{{- if and (kindIs "string" $value) (contains "\n" $value)}}
{{ $configKey }}: |-
{{ $value | indent 2 }}
{{- else }}
{{ $configKey }}: {{ $value }}
{{- end }}
{{- end }}
{{- end -}}
