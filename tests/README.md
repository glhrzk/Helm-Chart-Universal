# Helm Chart Unit Tests

This directory contains comprehensive unit tests for the app Helm chart using the `helm-unittest` plugin.

## Prerequisites

Install the helm-unittest plugin:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

## Running Tests

### Run All Tests

```bash
# From the parent directory
helm unittest ./helm-chart

# Or with verbose output
helm unittest ./helm-chart -3
```

### Run Specific Test Suites

```bash
# Test only deployment
helm unittest ./helm-chart -f tests/deployment_test.yaml

# Test only service
helm unittest ./helm-chart -f tests/service_test.yaml

# Test cronjob
helm unittest ./helm-chart -f tests/cronjob_test.yaml

# Test job
helm unittest ./helm-chart -f tests/job_test.yaml
```

### Run with Strict Mode

```bash
helm unittest ./helm-chart --strict
```

### Generate Test Results

```bash
# Output as JUnit XML
helm unittest ./helm-chart -o junit -f test-results.xml

# Output with color
helm unittest ./helm-chart --color
```

## Test Coverage

### 1. deployment_test.yaml
Tests for the Deployment resource:
- ✅ Deployment creation in http and worker modes
- ✅ No deployment in cron/job modes
- ✅ Replica count configuration
- ✅ Autoscaling replica override
- ✅ Image configuration
- ✅ Command and args override
- ✅ Port configuration for http mode
- ✅ Environment variables and envFrom
- ✅ Resource limits and requests
- ✅ Liveness, readiness, and startup probes
- ✅ Volumes and volume mounts
- ✅ Init containers and sidecars
- ✅ Node selector, tolerations, affinity
- ✅ Security contexts
- ✅ Labels and annotations

### 2. service_test.yaml
Tests for the Service resource:
- ✅ Service creation only in http mode
- ✅ Service not created in worker/cron/job modes
- ✅ Service type (ClusterIP, NodePort, LoadBalancer)
- ✅ Port configuration
- ✅ NodePort configuration
- ✅ Service annotations
- ✅ Selector labels

### 3. cronjob_test.yaml
Tests for the CronJob resource:
- ✅ CronJob creation only in cron mode
- ✅ Schedule configuration
- ✅ Concurrency policy
- ✅ Job history limits
- ✅ Backoff and deadline settings
- ✅ Restart policy
- ✅ Image, command, and args
- ✅ Environment variables
- ✅ Resources
- ✅ Volumes and volume mounts

### 4. job_test.yaml
Tests for the Job resource:
- ✅ Job creation only in job mode
- ✅ Backoff limit and deadline
- ✅ TTL after finished
- ✅ Completions and parallelism
- ✅ Restart policy
- ✅ Image, command, and args
- ✅ Environment variables
- ✅ Resources
- ✅ Init containers
- ✅ Volumes and volume mounts

### 5. configmap_secret_test.yaml
Tests for ConfigMap and Secret resources:
- ✅ ConfigMap creation when enabled
- ✅ Custom ConfigMap name
- ✅ ConfigMap data
- ✅ Secret creation when enabled
- ✅ Custom Secret name
- ✅ Secret data and stringData
- ✅ Labels for both resources

### 6. ingress_hpa_test.yaml
Tests for Ingress and HPA resources:
- ✅ Ingress creation when enabled
- ✅ Ingress class name
- ✅ Ingress annotations
- ✅ TLS configuration
- ✅ HPA creation for http/worker modes
- ✅ No HPA for cron/job modes
- ✅ CPU and memory targets
- ✅ Min/max replicas

### 7. rbac_test.yaml
Tests for RBAC resources:
- ✅ ServiceAccount creation
- ✅ Custom ServiceAccount name
- ✅ ServiceAccount annotations
- ✅ Role creation when RBAC enabled
- ✅ Role rules
- ✅ RoleBinding creation
- ✅ RoleBinding references

### 8. values_override_test.yaml
Tests for values overrides:
- ✅ Image override with --set
- ✅ Replica count override
- ✅ Mode switching
- ✅ Service port override
- ✅ CronJob schedule override
- ✅ Job parallelism override
- ✅ Multiple environment variables
- ✅ Resource overrides
- ✅ Probe configuration
- ✅ Name overrides

## Test Examples

### Test a specific mode

```bash
# Test HTTP mode
helm unittest ./helm-chart \
  --set mode=http \
  --set image.repository=my-app \
  --set image.tag=v1.0.0

# Test Worker mode
helm unittest ./helm-chart \
  --set mode=worker

# Test CronJob mode
helm unittest ./helm-chart \
  --set mode=cron

# Test Job mode
helm unittest ./helm-chart \
  --set mode=job
```

### Debug Failed Tests

```bash
# Run with verbose output to see details
helm unittest ./helm-chart -3 -f tests/deployment_test.yaml

# Show full output for debugging
helm unittest ./helm-chart -3 --with-subchart=false
```

## Writing New Tests

To add new tests, create a new file in the `tests/` directory following this structure:

```yaml
suite: test description
templates:
  - template-name.yaml
tests:
  - it: should do something
    set:
      key: value
    asserts:
      - isKind:
          of: ResourceKind
      - equal:
          path: metadata.name
          value: expected-value
```

### Available Assertions

- `isKind`: Check resource kind
- `equal`: Check exact value
- `notEqual`: Check value is not equal
- `contains`: Check array contains item
- `isNull`: Check value is null
- `isNotNull`: Check value is not null
- `isEmpty`: Check value is empty
- `isNotEmpty`: Check value is not empty
- `hasDocuments`: Check number of documents
- `matchRegex`: Check value matches regex
- `lengthEqual`: Check array/string length

## Continuous Integration

Add to your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Install helm-unittest
  run: helm plugin install https://github.com/helm-unittest/helm-unittest.git

- name: Run Helm tests
  run: helm unittest ./helm-chart --strict --color
```

## Best Practices

1. **Test all modes**: Ensure tests cover http, worker, cron, and job modes
2. **Test conditionals**: Verify resources are created/not created based on conditions
3. **Test overrides**: Verify --set overrides work correctly
4. **Test defaults**: Verify default values are applied correctly
5. **Test labels**: Ensure all resources have proper labels
6. **Test edge cases**: Test with minimal and maximal configurations

## Troubleshooting

### Plugin not found
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

### Test fails with "template not found"
Check that the template name in the test matches the actual file name.

### Test fails with "path not found"
Verify the YAML path exists in the rendered template using:
```bash
helm template test ./helm-chart --debug
```

## Documentation

For more information on helm-unittest:
- GitHub: https://github.com/helm-unittest/helm-unittest
- Documentation: https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md
