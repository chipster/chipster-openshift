{{/*
Copy Chipster configuration key-value pairs
*/}}
# - insert multiline values as yaml text block without the last new line
#   backup encryption key requires a text block
#   and simple strings shouldn't have a new line character in the end (at least aws sdk didn't tolerate it in the S3 url)
# - insert arrays (i.e. "slice") as json array. Without this array ["a","b"] would be converted to invalid string [a b]
# - insert other values as string
{{- define "chipster.listDeploymentConfigs" -}}
{{- range $configKey, $value := .configs }}
{{- if and (kindIs "string" $value) (contains "\n" $value)}}
{{ $configKey }}: |-
{{ $value | indent 2 }}
{{- else if kindIs "slice" $value }}
{{ $configKey }}: {{ $value | toJson }} 
{{- else }}
{{ $configKey }}: {{ $value }}
{{- end }}
{{- end }}
{{- end -}}
