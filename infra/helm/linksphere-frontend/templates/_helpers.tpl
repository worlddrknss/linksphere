{{- define "linksphere-frontend.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "linksphere-frontend.fullname" -}}
{{ .Release.Name }}
{{- end }}
