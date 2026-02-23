# Helm Chart Patterns

## When to load
Load when templating Kubernetes manifests, managing releases, or creating reusable charts.

## Chart Structure

```
my-app/
├── Chart.yaml           # Chart metadata + dependencies
├── values.yaml          # Default configuration values
├── values.staging.yaml  # Environment override
├── values.prod.yaml     # Environment override
├── templates/
│   ├── _helpers.tpl     # Template helpers (labels, names)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── NOTES.txt        # Post-install message
└── charts/              # Dependency charts
```

## Chart.yaml

```yaml
apiVersion: v2
name: my-app
description: My application Helm chart
type: application
version: 1.0.0        # Chart version
appVersion: "1.2.0"   # Application version
dependencies:
  - name: postgresql
    version: "13.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

## values.yaml

```yaml
replicaCount: 3

image:
  repository: registry.example.com/my-app
  tag: ""  # Overridden by CI/CD
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  host: app.example.com
  tls: true

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilization: 70

env:
  LOG_LEVEL: info
  NODE_ENV: production

secrets:
  # Injected from External Secrets Operator
  externalSecretName: my-app-secrets
```

## Template with Helpers

```yaml
# templates/_helpers.tpl
{{- define "my-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "my-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.name" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          ports:
            - containerPort: 3000
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          env:
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
```

## Helm Commands

```bash
# Install / upgrade
helm upgrade --install my-app ./my-app \
  --namespace production \
  --values values.prod.yaml \
  --set image.tag=v1.2.0 \
  --wait --timeout 5m

# Dry run (see rendered manifests)
helm template my-app ./my-app --values values.prod.yaml

# Rollback
helm rollback my-app 1 --namespace production

# List releases
helm list -A

# Show release history
helm history my-app -n production
```

## Environment Overrides

```yaml
# values.staging.yaml
replicaCount: 1
ingress:
  host: staging.app.example.com
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
autoscaling:
  enabled: false

# values.prod.yaml
replicaCount: 3
ingress:
  host: app.example.com
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

## Anti-patterns
- Hardcoded values in templates → defeats purpose of Helm, use values.yaml
- Secrets in values.yaml → use External Secrets or helm-secrets plugin
- No `helm template` before deploy → catch YAML errors before they hit cluster
- Mega-charts (one chart for entire platform) → split into chart per service
- Not using `--wait` → deploy command succeeds before pods are ready

## Quick reference
```
Chart structure: Chart.yaml + values.yaml + templates/ + charts/
Helpers: _helpers.tpl for reusable labels and names
Values: defaults in values.yaml, override with -f values.prod.yaml
Deploy: helm upgrade --install --wait --set image.tag=X
Rollback: helm rollback <release> <revision>
Dry run: helm template to render manifests locally
Deps: Chart.yaml dependencies, helm dependency update
Environments: separate values files per environment
Secrets: never in values.yaml — use External Secrets Operator
```
