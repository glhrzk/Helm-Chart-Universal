#!/bin/bash

# Universal App Helm Chart - Verification Script
# This script verifies that the Helm chart is correctly configured

set -e

CHART_DIR="."
FAILED=0
PASSED=0

echo "========================================="
echo "Universal App Helm Chart Verification"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

function fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

function info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

echo "1. Checking chart structure..."
if [ -f "$CHART_DIR/Chart.yaml" ]; then
    pass "Chart.yaml exists"
else
    fail "Chart.yaml not found"
fi

if [ -f "$CHART_DIR/values.yaml" ]; then
    pass "values.yaml exists"
else
    fail "values.yaml not found"
fi

if [ -d "$CHART_DIR/templates" ]; then
    pass "templates/ directory exists"
else
    fail "templates/ directory not found"
fi

echo ""
echo "2. Checking required templates..."
TEMPLATES=(
    "_helpers.tpl"
    "deployment.yaml"
    "service.yaml"
    "cronjob.yaml"
    "job.yaml"
    "ingress.yaml"
    "configmap.yaml"
    "secret.yaml"
    "serviceaccount.yaml"
    "role.yaml"
    "rolebinding.yaml"
    "hpa.yaml"
    "NOTES.txt"
)

for template in "${TEMPLATES[@]}"; do
    if [ -f "$CHART_DIR/templates/$template" ]; then
        pass "templates/$template exists"
    else
        fail "templates/$template not found"
    fi
done

echo ""
echo "3. Checking example files..."
if [ -d "$CHART_DIR/examples" ]; then
    pass "examples/ directory exists"
    EXAMPLES=($(ls "$CHART_DIR/examples" 2>/dev/null || echo ""))
    if [ ${#EXAMPLES[@]} -gt 0 ]; then
        pass "Found ${#EXAMPLES[@]} example files"
    else
        fail "No example files found"
    fi
else
    fail "examples/ directory not found"
fi

echo ""
echo "4. Checking test files..."
if [ -d "$CHART_DIR/tests" ]; then
    pass "tests/ directory exists"
    TEST_FILES=($(ls "$CHART_DIR/tests"/*.yaml 2>/dev/null || echo ""))
    if [ ${#TEST_FILES[@]} -gt 0 ]; then
        pass "Found ${#TEST_FILES[@]} test files"
    else
        fail "No test files found"
    fi
else
    fail "tests/ directory not found"
fi

echo ""
echo "5. Running helm lint..."
if helm lint "$CHART_DIR" > /dev/null 2>&1; then
    pass "Helm lint passed"
else
    fail "Helm lint failed"
    info "Run 'helm lint $CHART_DIR' for details"
fi

echo ""
echo "6. Testing template rendering for each mode..."

# Test HTTP mode
if helm template test "$CHART_DIR" --set mode=http > /dev/null 2>&1; then
    KINDS=$(helm template test "$CHART_DIR" --set mode=http | grep "^kind:" | sort -u)
    if echo "$KINDS" | grep -q "Deployment" && echo "$KINDS" | grep -q "Service"; then
        pass "HTTP mode renders correctly (Deployment + Service)"
    else
        fail "HTTP mode rendering issue"
    fi
else
    fail "HTTP mode template rendering failed"
fi

# Test Worker mode
if helm template test "$CHART_DIR" --set mode=worker > /dev/null 2>&1; then
    KINDS=$(helm template test "$CHART_DIR" --set mode=worker | grep "^kind:" | sort -u)
    if echo "$KINDS" | grep -q "Deployment" && ! echo "$KINDS" | grep -q "Service.*http"; then
        pass "Worker mode renders correctly (Deployment, no Service)"
    else
        fail "Worker mode rendering issue"
    fi
else
    fail "Worker mode template rendering failed"
fi

# Test Cron mode
if helm template test "$CHART_DIR" --set mode=cron > /dev/null 2>&1; then
    KINDS=$(helm template test "$CHART_DIR" --set mode=cron | grep "^kind:" | sort -u)
    if echo "$KINDS" | grep -q "CronJob"; then
        pass "Cron mode renders correctly (CronJob)"
    else
        fail "Cron mode rendering issue"
    fi
else
    fail "Cron mode template rendering failed"
fi

# Test Job mode
if helm template test "$CHART_DIR" --set mode=job > /dev/null 2>&1; then
    KINDS=$(helm template test "$CHART_DIR" --set mode=job | grep "^kind:" | sort -u)
    if echo "$KINDS" | grep -q "^kind: Job$"; then
        pass "Job mode renders correctly (Job)"
    else
        fail "Job mode rendering issue"
    fi
else
    fail "Job mode template rendering failed"
fi

echo ""
echo "7. Checking documentation..."
DOCS=("README.md" "QUICKSTART.md" "INSTALL.md" "PROJECT_SUMMARY.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$CHART_DIR/$doc" ]; then
        pass "$doc exists"
    else
        fail "$doc not found"
    fi
done

echo ""
echo "8. Testing helm-unittest (if installed)..."
if command -v helm &> /dev/null && helm plugin list | grep -q unittest; then
    if helm unittest "$CHART_DIR" > /dev/null 2>&1; then
        pass "Helm unittest passed"
        info "Run 'helm unittest $CHART_DIR' to see detailed results"
    else
        fail "Helm unittest failed"
        info "Run 'helm unittest $CHART_DIR' to see errors"
    fi
else
    info "helm-unittest plugin not installed (optional)"
    info "Install with: helm plugin install https://github.com/helm-unittest/helm-unittest.git"
fi

echo ""
echo "========================================="
echo "Verification Complete"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    echo "Please fix the failed checks before using the chart."
    exit 1
else
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    echo -e "${GREEN}✓ All checks passed! Your Helm chart is ready to use.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the README.md for full documentation"
    echo "  2. Try the examples: helm install test $CHART_DIR -f examples/values-dev.yaml --dry-run"
    echo "  3. Run tests: helm unittest $CHART_DIR"
    echo "  4. Deploy: helm install myapp $CHART_DIR"
    exit 0
fi
