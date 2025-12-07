# Universal App Helm Chart - Installation & Verification Guide

This guide will help you install, test, and verify the Helm chart.

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.0+
- kubectl configured to access your cluster

## Step 1: Verify Chart Structure

```bash
# Navigate to the chart directory
cd /Users/galih.rizkiansyah/Developments/dompay/helm-chart

# List chart contents
ls -la

# Expected structure:
# ├── Chart.yaml              # Chart metadata
# ├── values.yaml             # Default values
# ├── README.md               # Full documentation
# ├── QUICKSTART.md           # Quick start guide
# ├── .helmignore             # Files to ignore
# ├── templates/              # Kubernetes manifests
# │   ├── _helpers.tpl       # Template helpers
# │   ├── NOTES.txt          # Post-install notes
# │   ├── deployment.yaml    # Deployment (http/worker)
# │   ├── service.yaml       # Service (http only)
# │   ├── cronjob.yaml       # CronJob (cron mode)
# │   ├── job.yaml           # Job (job mode)
# │   ├── ingress.yaml       # Ingress
# │   ├── configmap.yaml     # ConfigMap
# │   ├── secret.yaml        # Secret
# │   ├── serviceaccount.yaml # ServiceAccount
# │   ├── role.yaml          # RBAC Role
# │   ├── rolebinding.yaml   # RBAC RoleBinding
# │   ├── hpa.yaml           # HorizontalPodAutoscaler
# │   └── poddisruptionbudget.yaml
# ├── examples/              # Example values files
# │   ├── values-dev.yaml
# │   ├── values-prod.yaml
# │   ├── values-nodejs-http.yaml
# │   ├── values-python-worker.yaml
# │   ├── values-go-cronjob.yaml
# │   └── values-migration-job.yaml
# └── tests/                 # Unit tests
#     ├── README.md
#     ├── deployment_test.yaml
#     ├── service_test.yaml
#     ├── cronjob_test.yaml
#     ├── job_test.yaml
#     ├── configmap_secret_test.yaml
#     ├── ingress_hpa_test.yaml
#     ├── rbac_test.yaml
#     └── values_override_test.yaml
```

## Step 2: Validate the Chart

```bash
# Lint the chart
helm lint .

# Expected output:
# ==> Linting .
# [INFO] Chart.yaml: icon is recommended
# 1 chart(s) linted, 0 chart(s) failed
```

## Step 3: Install helm-unittest Plugin

```bash
# Install the plugin
helm plugin install https://github.com/helm-unittest/helm-unittest.git

# Verify installation
helm plugin list
```

## Step 4: Run Unit Tests

```bash
# Run all tests
helm unittest .

# You should see output like:
# ### Chart [ universal-app ] .
# 
#  PASS  test deployment  tests/deployment_test.yaml
#  PASS  test service     tests/service_test.yaml
#  PASS  test cronjob     tests/cronjob_test.yaml
#  PASS  test job         tests/job_test.yaml
#  PASS  test configmap and secret  tests/configmap_secret_test.yaml
#  PASS  test ingress and hpa      tests/ingress_hpa_test.yaml
#  PASS  test rbac resources       tests/rbac_test.yaml
#  PASS  test values overrides     tests/values_override_test.yaml
# 
# Charts:      1 passed, 1 total
# Test Suites: 8 passed, 8 total
# Tests:       100+ passed, 100+ total
# Snapshot:    0 passed, 0 total
# Time:        XXXms
```

## Step 5: Test Template Rendering

### Test HTTP Mode (Default)

```bash
helm template test-http . --set mode=http

# Verify output contains:
# - Deployment
# - Service
# - ServiceAccount
```

### Test Worker Mode

```bash
helm template test-worker . --set mode=worker

# Verify output contains:
# - Deployment
# - ServiceAccount
# - NO Service
```

### Test Cron Mode

```bash
helm template test-cron . --set mode=cron

# Verify output contains:
# - CronJob
# - ServiceAccount
# - NO Deployment
# - NO Service
```

### Test Job Mode

```bash
helm template test-job . --set mode=job

# Verify output contains:
# - Job
# - ServiceAccount
# - NO Deployment
# - NO Service
```

## Step 6: Dry Run Installation

```bash
# Test HTTP mode installation
helm install test-app . --dry-run --debug --set mode=http

# Test with example values
helm install test-app . --dry-run --debug -f examples/values-dev.yaml
```

## Step 7: Install to Kubernetes

### Option A: Install with Default Values (HTTP Mode)

```bash
# Create a test namespace
kubectl create namespace helm-test

# Install the chart
helm install test-app . --namespace helm-test

# Check the installation
helm status test-app -n helm-test
kubectl get all -n helm-test
```

### Option B: Install HTTP Service

```bash
helm install my-api . \
  --namespace helm-test \
  --set mode=http \
  --set image.repository=nginx \
  --set image.tag=alpine \
  --set service.targetPort=80
```

### Option C: Install Worker

```bash
helm install my-worker . \
  --namespace helm-test \
  --set mode=worker \
  --set image.repository=busybox \
  --set image.tag=latest \
  --set command[0]=sh \
  --set args[0]=-c \
  --set args[1]="while true; do echo working...; sleep 10; done"
```

### Option D: Install CronJob

```bash
helm install my-cronjob . \
  --namespace helm-test \
  --set mode=cron \
  --set image.repository=busybox \
  --set cronjob.schedule="*/1 * * * *" \
  --set command[0]=sh \
  --set args[0]=-c \
  --set args[1]="echo 'CronJob executed at' \$(date)"
```

### Option E: Install Job

```bash
helm install my-job . \
  --namespace helm-test \
  --set mode=job \
  --set image.repository=busybox \
  --set command[0]=echo \
  --set args[0]="Job completed successfully"
```

## Step 8: Verify Installation

### Check Helm Release

```bash
helm list -n helm-test
helm status test-app -n helm-test
helm get values test-app -n helm-test
```

### Check Kubernetes Resources

```bash
# For HTTP mode
kubectl get deployment,service,pod -n helm-test -l app.kubernetes.io/instance=test-app

# For Worker mode
kubectl get deployment,pod -n helm-test -l app.kubernetes.io/instance=test-app

# For CronJob mode
kubectl get cronjob,pod -n helm-test -l app.kubernetes.io/instance=test-app

# For Job mode
kubectl get job,pod -n helm-test -l app.kubernetes.io/instance=test-app
```

### Check Logs

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n helm-test -l app.kubernetes.io/instance=test-app -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs -n helm-test $POD_NAME

# Follow logs
kubectl logs -n helm-test $POD_NAME -f
```

## Step 9: Test Different Configurations

### Test with ConfigMap

```bash
helm install test-config . \
  --namespace helm-test \
  --set mode=http \
  --set configMap.enabled=true \
  --set configMap.data.app\\.properties="key=value"

# Verify ConfigMap
kubectl get configmap -n helm-test
kubectl describe configmap test-config-universal-app -n helm-test
```

### Test with Secret

```bash
helm install test-secret . \
  --namespace helm-test \
  --set mode=http \
  --set secret.enabled=true \
  --set secret.stringData.username=admin \
  --set secret.stringData.password=secret123

# Verify Secret
kubectl get secret -n helm-test
kubectl describe secret test-secret-universal-app -n helm-test
```

### Test with Autoscaling

```bash
helm install test-hpa . \
  --namespace helm-test \
  --set mode=http \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=5

# Verify HPA
kubectl get hpa -n helm-test
kubectl describe hpa test-hpa-universal-app -n helm-test
```

### Test with RBAC

```bash
helm install test-rbac . \
  --namespace helm-test \
  --set mode=http \
  --set rbac.create=true \
  --set 'rbac.rules[0].apiGroups[0]=""' \
  --set 'rbac.rules[0].resources[0]=pods' \
  --set 'rbac.rules[0].verbs[0]=get' \
  --set 'rbac.rules[0].verbs[1]=list'

# Verify RBAC
kubectl get role,rolebinding,serviceaccount -n helm-test
```

## Step 10: Test Upgrades

```bash
# Change image tag
helm upgrade test-app . \
  --namespace helm-test \
  --set image.tag=1.21-alpine

# Verify upgrade
helm history test-app -n helm-test
kubectl rollout status deployment/test-app-universal-app -n helm-test
```

## Step 11: Test Rollback

```bash
# Rollback to previous version
helm rollback test-app -n helm-test

# Verify rollback
helm history test-app -n helm-test
```

## Step 12: Cleanup

```bash
# Uninstall all releases
helm uninstall test-app -n helm-test
helm uninstall my-api -n helm-test
helm uninstall my-worker -n helm-test
helm uninstall my-cronjob -n helm-test
helm uninstall my-job -n helm-test
helm uninstall test-config -n helm-test
helm uninstall test-secret -n helm-test
helm uninstall test-hpa -n helm-test
helm uninstall test-rbac -n helm-test

# Delete namespace
kubectl delete namespace helm-test
```

## Step 13: Package the Chart (Optional)

```bash
# Package the chart
helm package .

# Expected output:
# Successfully packaged chart and saved it to: /path/to/universal-app-1.0.0.tgz

# Verify package
helm show chart universal-app-1.0.0.tgz
helm show values universal-app-1.0.0.tgz
```

## Verification Checklist

- [ ] Chart structure is correct
- [ ] Helm lint passes without errors
- [ ] All unit tests pass (100+ tests)
- [ ] HTTP mode renders correctly
- [ ] Worker mode renders correctly
- [ ] Cron mode renders correctly
- [ ] Job mode renders correctly
- [ ] Service only appears in HTTP mode
- [ ] Can install to Kubernetes successfully
- [ ] Can upgrade release
- [ ] Can rollback release
- [ ] ConfigMap works when enabled
- [ ] Secret works when enabled
- [ ] Autoscaling works when enabled
- [ ] RBAC resources created when enabled
- [ ] Post-install NOTES display correctly

## Common Issues & Solutions

### Issue: helm-unittest not found
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

### Issue: Template rendering fails
```bash
# Check syntax
helm lint .

# Debug specific values
helm template test . --debug --set mode=http
```

### Issue: Installation fails
```bash
# Check cluster connectivity
kubectl cluster-info

# Check namespace
kubectl get namespace

# View detailed error
helm install test . --namespace helm-test --debug
```

### Issue: Resources not created
```bash
# Check mode setting
helm get values release-name -n namespace

# Verify template conditions
helm template test . --set mode=cron --debug
```

## Next Steps

1. **Customize for your needs**: Modify `values.yaml` or create custom values files
2. **Deploy to production**: Use `examples/values-prod.yaml` as a template
3. **Set up CI/CD**: Integrate tests and deployments into your pipeline
4. **Monitor deployments**: Set up monitoring and alerting for your applications

## Documentation

- Full documentation: [README.md](README.md)
- Quick start: [QUICKSTART.md](QUICKSTART.md)
- Test documentation: [tests/README.md](tests/README.md)

## Support

For issues or questions, contact the DevOps team or refer to the documentation.
