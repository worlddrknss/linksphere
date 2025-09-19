{{- define "linksphere-backend.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "linksphere-backend.fullname" -}}
{{ .Release.Name }}
{{- end }}
