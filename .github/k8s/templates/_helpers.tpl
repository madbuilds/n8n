{{- define "deployment.labels" -}}
app.kubernetes.io/name: {{ .Values.deployment.name }}
app.kubernetes.io/instance: {{ .Values.deployment.name }}-{{ .Values.deployment.environment }}
app.kubernetes.io/environment: {{ .Values.deployment.environment }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Release.Revision }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "deployment.selector" -}}
app.kubernetes.io/name: {{ .Values.deployment.name }}
app.kubernetes.io/instance: {{ .Values.deployment.name }}-{{ .Values.deployment.environment }}
{{- end -}}

{{- define "deployment.url" -}}
{{- if .Values.ingress.enabled -}}
https://{{ required "deployment.host is required for ingress" .Values.deployment.host }}/
{{- else -}}
http://localhost/
{{- end -}}
{{- end -}}

{{- define "deployment.environmentMaps" -}}
{{- $defaults := default dict .defaults -}}
{{- $result := dict -}}
{{- range $field := list "environments" "secrets" -}}
{{- $values := deepCopy (default dict (index $defaults $field)) -}}
{{- range $key, $value := index $.service $field -}}
{{- $_ := set $values $key $value -}}
{{- end -}}
{{- $_ := set $result $field $values -}}
{{- end -}}
{{- $result | toYaml -}}
{{- end -}}

{{- define "deployment.validate" -}}
{{- $_ := required "Define at least one container in services" .Values.services -}}
{{- range $name, $service := .Values.services -}}
{{- $maps := include "deployment.environmentMaps" (dict "defaults" $.Values.defaults "service" $service) | fromYaml -}}
{{- range $key, $_ := $maps.secrets -}}
{{- if hasKey $maps.environments $key -}}
{{- fail (printf "services.%s: %s must be in secrets or environments, not both (including defaults)" $name $key) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if and .Values.ingress.enabled (eq .Values.deployment.host "localhost") -}}
{{- fail "set deployment.host to your DNS hostname before enabling ingress" -}}
{{- end -}}
{{- if .Values.ingress.enabled -}}
{{- $_ :=  required "ingress.tlsSecretName is required" .Values.ingress.tlsSecretName -}}
{{- if lt (int .Values.deployment.proxyHops) 1 -}}
{{- fail "set deployment.proxyHops to the number of trusted proxies when enabling ingress" -}}
{{- end -}}
{{- end -}}
{{- if and (eq .Values.deployment.environment "PRODUCTION") (not .Values.ingress.enabled) -}}
{{- fail "PRODUCTION requires HTTPS ingress in this chart" -}}
{{- end -}}
{{- end -}}