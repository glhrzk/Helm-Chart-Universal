# Universal App Helm Chart - Quick Start Guide

Get started with the universal-app Helm chart in minutes!

## Quick Installation Examples

### 1. Deploy a Simple HTTP Service

```bash
# Install with default values (nginx example)
helm install my-web ./helm-chart

# With custom image
helm install my-api ./helm-chart \
  --set image.repository=my-api \
  --set image.tag=1.0.0 \
  --set service.targetPort=3000
```

### 2. Deploy a Node.js Application

```bash
helm install nodejs-app ./helm-chart \
  --set mode=http \
  --set image.repository=my-nodejs-app \
  --set image.tag=2.0.0 \
  --set service.targetPort=3000 \
  --set command[0]=node \
  --set args[0]=server.js \
  --set env[0].name=NODE_ENV \
  --set env[0].value=production
```

### 3. Deploy a Python Worker

```bash
helm install python-worker ./helm-chart \
  --set mode=worker \
  --set image.repository=my-python-worker \
  --set image.tag=1.5.0 \
  --set replicaCount=3 \
  --set command[0]=python \
  --set args[0]=-u \
  --set args[1]=worker.py
```

### 4. Deploy a CronJob (Daily at 2 AM)

```bash
helm install daily-backup ./helm-chart \
  --set mode=cron \
  --set image.repository=my-backup-tool \
  --set cronjob.schedule="0 2 * * *" \
  --set command[0]=/app/backup.sh
```

### 5. Deploy a One-Off Migration Job

```bash
helm install db-migration ./helm-chart \
  --set mode=job \
  --set image.repository=my-app-migrations \
  --set image.tag=1.0.0 \
  --set job.restartPolicy=Never \
  --set command[0]=npm \
  --set args[0]=run \
  --set args[1]=migrate:up
```

## Using Example Values Files

### Development Environment

```bash
helm install my-app ./helm-chart -f examples/values-dev.yaml
```

### Production Environment

```bash
helm install my-app ./helm-chart -f examples/values-prod.yaml
```

### Node.js HTTP Service

```bash
helm install nodejs-api ./helm-chart -f examples/values-nodejs-http.yaml
```

### Python Worker

```bash
helm install python-worker ./helm-chart -f examples/values-python-worker.yaml
```

### Go CronJob

```bash
helm install go-cronjob ./helm-chart -f examples/values-go-cronjob.yaml
```

### Database Migration

```bash
helm install migration ./helm-chart -f examples/values-migration-job.yaml
```

## Common Operations

### Check Installation Status

```bash
helm status my-app
helm list
```

### View Deployed Resources

```bash
kubectl get all -l app.kubernetes.io/instance=my-app
```

### View Logs

```bash
# For http/worker
kubectl logs -l app.kubernetes.io/instance=my-app -f

# For cronjob
kubectl logs -l app.kubernetes.io/instance=my-app --tail=100

# For job
kubectl logs job/my-app -f
```

### Upgrade Deployment

```bash
# Change image tag
helm upgrade my-app ./helm-chart --set image.tag=2.0.0

# Change replica count
helm upgrade my-app ./helm-chart --set replicaCount=5

# With new values file
helm upgrade my-app ./helm-chart -f values-prod.yaml
```

### Rollback

```bash
# Rollback to previous version
helm rollback my-app

# Rollback to specific revision
helm rollback my-app 2
```

### Uninstall

```bash
helm uninstall my-app
```

## Testing Before Installation

### Dry Run

```bash
helm install my-app ./helm-chart --dry-run --debug
```

### Template Rendering

```bash
# Render all templates
helm template my-app ./helm-chart

# Render with custom values
helm template my-app ./helm-chart -f values-prod.yaml

# Render specific values
helm template my-app ./helm-chart \
  --set mode=worker \
  --set image.tag=latest
```

### Lint Chart

```bash
helm lint ./helm-chart
```

### Run Unit Tests

```bash
# Install helm-unittest plugin
helm plugin install https://github.com/helm-unittest/helm-unittest.git

# Run tests
helm unittest ./helm-chart
```

## Common Configuration Patterns

### Add Environment Variables

```bash
helm install my-app ./helm-chart \
  --set env[0].name=DATABASE_URL \
  --set env[0].value=postgres://db:5432 \
  --set env[1].name=LOG_LEVEL \
  --set env[1].value=info
```

### Enable Autoscaling

```bash
helm install my-app ./helm-chart \
  --set mode=http \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set autoscaling.targetCPUUtilizationPercentage=70
```

### Enable Ingress

```bash
helm install my-app ./helm-chart \
  --set mode=http \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=api.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

### Add Health Probes

```bash
helm install my-app ./helm-chart \
  --set mode=http \
  --set livenessProbe.enabled=true \
  --set livenessProbe.httpGet.path=/health \
  --set readinessProbe.enabled=true \
  --set readinessProbe.httpGet.path=/ready
```

### Set Resources

```bash
helm install my-app ./helm-chart \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=512Mi
```

### Use Secrets

Create a values file with secrets:

```yaml
# my-secrets.yaml
secret:
  enabled: true
  stringData:
    DB_PASSWORD: mysecretpassword
    API_KEY: myapikey

envFrom:
  - secretRef:
      name: RELEASE-NAME-universal-app
```

Install:
```bash
helm install my-app ./helm-chart -f my-secrets.yaml
```

## Troubleshooting

### Check rendered manifests

```bash
helm get manifest my-app
```

### Check values used

```bash
helm get values my-app
```

### Debug installation

```bash
helm install my-app ./helm-chart --debug --dry-run
```

### View events

```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Describe resources

```bash
kubectl describe deployment my-app
kubectl describe pod -l app.kubernetes.io/instance=my-app
```

## Next Steps

1. **Customize values**: Copy `values.yaml` and modify for your needs
2. **Review examples**: Check the `examples/` directory for pre-configured scenarios
3. **Read full documentation**: See `README.md` for complete documentation
4. **Run tests**: Execute `helm unittest ./helm-chart` to verify functionality
5. **Set up CI/CD**: Integrate Helm deployments into your pipeline

## Support

For detailed documentation, see the [README.md](../README.md) file.

For test documentation, see the [tests/README.md](tests/README.md) file.
