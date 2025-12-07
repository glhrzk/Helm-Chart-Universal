# Universal App Helm Chart

A flexible and reusable Helm chart for deploying applications in various modes: HTTP services, background workers, cron jobs, and one-off jobs. This chart supports multiple programming languages including Node.js, Python, Go, and more.

## Features

- **Multi-Mode Deployment**: Support for HTTP services, workers, cron jobs, and one-off jobs
- **Language Agnostic**: Works with any containerized application (Node.js, Python, Go, etc.)
- **Highly Configurable**: Comprehensive configuration options via `values.yaml`
- **Production Ready**: Includes support for autoscaling, probes, RBAC, security contexts, and more
- **Resource Management**: ConfigMaps, Secrets, volumes, and environment variables
- **Advanced Features**: Sidecars, init containers, pod disruption budgets

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

### Basic Installation

```bash
# Install with default values (HTTP mode)
helm install my-app ./helm-chart

# Install with custom values
helm install my-app ./helm-chart -f values-prod.yaml

# Install with inline overrides
helm install my-app ./helm-chart \
  --set mode=worker \
  --set image.repository=myapp \
  --set image.tag=v1.0.0
```

## Deployment Modes

### 1. HTTP Mode (Default)

Deploy a web service with a Service and optional Ingress.

```bash
helm install my-api ./helm-chart \
  --set mode=http \
  --set image.repository=my-api \
  --set image.tag=1.0.0 \
  --set service.port=80 \
  --set service.targetPort=8080
```

**Features:**
- Deployment with replicas
- Service (ClusterIP, NodePort, or LoadBalancer)
- Optional Ingress
- Health probes (liveness, readiness, startup)
- Autoscaling support

### 2. Worker Mode

Deploy a background worker application.

```bash
helm install my-worker ./helm-chart \
  --set mode=worker \
  --set image.repository=my-worker \
  --set image.tag=1.0.0 \
  --set replicaCount=3
```

**Features:**
- Deployment with replicas
- No Service created
- Autoscaling support
- Suitable for queue consumers, data processors, etc.

### 3. Cron Job Mode

Deploy a scheduled job.

```bash
helm install my-cronjob ./helm-chart \
  --set mode=cron \
  --set image.repository=my-batch-job \
  --set cronjob.schedule="0 2 * * *"
```

**Features:**
- CronJob resource
- Configurable schedule
- Job history limits
- Backoff and deadline settings

### 4. Job Mode

Deploy a one-off job.

```bash
helm install my-job ./helm-chart \
  --set mode=job \
  --set image.repository=my-migration \
  --set job.completions=1
```

**Features:**
- Job resource
- Parallelism and completions
- TTL after finished
- Suitable for migrations, data imports, etc.

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mode` | Deployment mode: `http`, `worker`, `cron`, `job` | `http` |
| `replicaCount` | Number of replicas (http/worker) | `1` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | Chart appVersion |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `command` | Override container command | `[]` |
| `args` | Override container args | `[]` |

### Service Configuration (HTTP Mode)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8080` |

### Resources

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Environment Variables

```yaml
# Simple environment variables
env:
  - name: NODE_ENV
    value: production
  - name: LOG_LEVEL
    value: info

# From ConfigMap or Secret
envFrom:
  - configMapRef:
      name: app-config
  - secretRef:
      name: app-secrets
```

### ConfigMap

```yaml
configMap:
  enabled: true
  data:
    config.yaml: |
      server:
        port: 8080
      database:
        host: postgres
```

### Secrets

```yaml
secret:
  enabled: true
  stringData:
    DB_PASSWORD: mypassword
    API_KEY: mysecretkey
```

### Volumes and Volume Mounts

```yaml
volumes:
  - name: config
    configMap:
      name: my-config
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc

volumeMounts:
  - name: config
    mountPath: /etc/config
  - name: data
    mountPath: /data
```

### Probes (HTTP Mode)

```yaml
livenessProbe:
  enabled: true
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Init Containers and Sidecars

```yaml
initContainers:
  - name: wait-for-db
    image: busybox:1.28
    command: ['sh', '-c', 'until nslookup postgres; do echo waiting; sleep 2; done']

sidecars:
  - name: log-forwarder
    image: fluentd:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log
```

### RBAC

```yaml
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["pods", "secrets"]
      verbs: ["get", "list"]
```

## Examples

### Node.js HTTP Application

```yaml
# values-nodejs-http.yaml
mode: http
replicaCount: 3

image:
  repository: my-nodejs-app
  tag: "2.0.0"
  pullPolicy: Always

command: ["node"]
args: ["server.js"]

service:
  enabled: true
  type: ClusterIP
  port: 80
  targetPort: 3000

env:
  - name: NODE_ENV
    value: production
  - name: PORT
    value: "3000"

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  enabled: true
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30

readinessProbe:
  enabled: true
  httpGet:
    path: /ready
    port: http

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Install:
```bash
helm install nodejs-app ./helm-chart -f examples/values-nodejs-http.yaml
```

### Python Worker

```yaml
# values-python-worker.yaml
mode: worker
replicaCount: 2

image:
  repository: my-python-worker
  tag: "1.5.0"

command: ["python"]
args: ["-u", "worker.py"]

env:
  - name: REDIS_HOST
    value: redis-service
  - name: WORKER_CONCURRENCY
    value: "4"

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

Install:
```bash
helm install python-worker ./helm-chart -f examples/values-python-worker.yaml
```

### Go Cron Job

```yaml
# values-go-cronjob.yaml
mode: cron

image:
  repository: my-go-batch
  tag: "1.0.0"

cronjob:
  schedule: "0 2 * * *"  # 2 AM daily
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 5
  restartPolicy: OnFailure

command: ["/app/batch-processor"]
args: ["--daily-report"]

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

Install:
```bash
helm install go-cronjob ./helm-chart -f examples/values-go-cronjob.yaml
```

### Database Migration Job

```yaml
# values-migration-job.yaml
mode: job

image:
  repository: my-app-migrations
  tag: "1.0.0"

job:
  restartPolicy: Never
  backoffLimit: 3
  completions: 1
  parallelism: 1
  ttlSecondsAfterFinished: 3600

command: ["npm"]
args: ["run", "migrate:up"]

envFrom:
  - secretRef:
      name: database-credentials
```

Install:
```bash
helm install migration ./helm-chart -f examples/values-migration-job.yaml
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade my-app ./helm-chart -f values-prod.yaml

# Upgrade with inline overrides
helm upgrade my-app ./helm-chart --set image.tag=v2.0.0

# Rollback if needed
helm rollback my-app
```

## Uninstalling

```bash
helm uninstall my-app
```

## Testing

This chart includes comprehensive unit tests using the `helm-unittest` plugin.

### Install helm-unittest

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

### Run Tests

```bash
# Run all tests
helm unittest ./helm-chart

# Run with verbose output
helm unittest ./helm-chart -3

# Run specific test files
helm unittest ./helm-chart -f tests/deployment_test.yaml
```

### Test Coverage

The test suite covers:
- Deployment creation for http and worker modes
- Service creation only for http mode
- CronJob creation for cron mode
- Job creation for job mode
- ConfigMap and Secret rendering
- RBAC resources
- HPA configuration
- Values overrides

## Directory Structure

```
helm-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/
│   ├── NOTES.txt            # Post-installation notes
│   ├── _helpers.tpl         # Template helpers
│   ├── deployment.yaml      # Deployment (http/worker)
│   ├── service.yaml         # Service (http only)
│   ├── cronjob.yaml         # CronJob (cron mode)
│   ├── job.yaml             # Job (job mode)
│   ├── ingress.yaml         # Ingress
│   ├── configmap.yaml       # ConfigMap
│   ├── secret.yaml          # Secret
│   ├── serviceaccount.yaml  # ServiceAccount
│   ├── role.yaml            # RBAC Role
│   ├── rolebinding.yaml     # RBAC RoleBinding
│   ├── hpa.yaml             # HorizontalPodAutoscaler
│   └── poddisruptionbudget.yaml
├── tests/                    # Helm unit tests
│   ├── deployment_test.yaml
│   ├── service_test.yaml
│   ├── cronjob_test.yaml
│   ├── job_test.yaml
│   └── configmap_test.yaml
└── examples/
    ├── values-dev.yaml
    ├── values-prod.yaml
    ├── values-nodejs-http.yaml
    ├── values-python-worker.yaml
    └── values-go-cronjob.yaml
```

## Best Practices

1. **Use specific image tags** instead of `latest` in production
2. **Set resource requests and limits** for better scheduling and stability
3. **Enable health probes** for HTTP applications
4. **Use secrets** for sensitive data, not ConfigMaps
5. **Enable autoscaling** for production HTTP and worker deployments
6. **Set pod disruption budgets** for high-availability applications
7. **Use separate values files** for different environments (dev, staging, prod)

## Troubleshooting

### Check deployment status
```bash
kubectl get all -l app.kubernetes.io/instance=my-app
```

### View logs
```bash
kubectl logs -l app.kubernetes.io/instance=my-app -f
```

### Debug helm release
```bash
helm get all my-app
helm get values my-app
```

### Test template rendering
```bash
helm template my-app ./helm-chart -f values.yaml
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License

## Support

For questions and support, please contact the DevOps team at devops@example.com
