#!/bin/bash

################################################################################
# GitHub Actions Workflow Validator
#
# Validates the GitHub Actions workflow file locally before pushing
# Usage: bash validate-workflow.sh
#
# Version: 1.0
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GitHub Actions Workflow Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

WORKFLOW_FILE=".github/workflows/test-installation.yml"
ERRORS=0

# Check if workflow file exists
print_info "Checking workflow file..."
if [ -f "$WORKFLOW_FILE" ]; then
    print_success "Workflow file exists: $WORKFLOW_FILE"
else
    print_error "Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

# Check YAML syntax with Python
print_info "Validating YAML syntax..."
if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
        print_success "YAML syntax is valid"
    else
        print_error "YAML syntax error detected"
        python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>&1
        ERRORS=$((ERRORS + 1))
    fi
else
    print_warning "Python3 not available - skipping YAML validation"
    print_info "Install with: sudo apt install python3-yaml"
fi

# Check if all referenced scripts exist
print_info "Checking referenced scripts..."
SCRIPTS=("install-moodle.sh" "troubleshoot-moodle.sh" "moodle-status.sh" "setup.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        print_success "Found: $script"
    else
        print_error "Missing: $script"
        ERRORS=$((ERRORS + 1))
    fi
done

# Validate bash syntax for all scripts
print_info "Validating bash syntax for all scripts..."
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            print_success "Syntax OK: $script"
        else
            print_error "Syntax error in: $script"
            bash -n "$script"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# Check if documentation files exist
print_info "Checking documentation files..."
DOCS=("README.md" "QUICKSTART.md" "INSTALL_README.md" "FILE_MANIFEST.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_success "Found: $doc"
    else
        print_warning "Missing: $doc (referenced in workflow)"
    fi
done

# Check workflow actions versions
print_info "Checking GitHub Actions versions..."
if grep -q "actions/checkout@v4" "$WORKFLOW_FILE"; then
    print_success "Using checkout@v4 (current)"
elif grep -q "actions/checkout@v3" "$WORKFLOW_FILE"; then
    print_warning "Using checkout@v3 (consider upgrading to v4)"
else
    print_error "checkout action version not found or outdated"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "actions/upload-artifact@v4" "$WORKFLOW_FILE"; then
    print_success "Using upload-artifact@v4 (current)"
elif grep -q "actions/upload-artifact@v3" "$WORKFLOW_FILE"; then
    print_warning "Using upload-artifact@v3 (consider upgrading to v4)"
fi

# Check for common workflow issues
print_info "Checking for common workflow issues..."

# Check timeout values
TIMEOUTS=$(grep -o "timeout-minutes: [0-9]*" "$WORKFLOW_FILE" | cut -d' ' -f2)
if [ -n "$TIMEOUTS" ]; then
    print_success "Timeouts configured: $(echo $TIMEOUTS | tr '\n' ', ')"
else
    print_warning "No timeout values found - jobs might run indefinitely"
fi

# Check environment variables
if grep -q "env:" "$WORKFLOW_FILE"; then
    print_success "Environment variables configured"
else
    print_warning "No environment variables defined"
fi

# Check matrix strategy
if grep -q "matrix:" "$WORKFLOW_FILE"; then
    print_success "Matrix strategy configured"
    UBUNTU_VERSIONS=$(grep -A3 "ubuntu-version:" "$WORKFLOW_FILE" | grep "'" | tr -d " '-[]")
    if [ -n "$UBUNTU_VERSIONS" ]; then
        print_info "Testing on Ubuntu versions: $(echo $UBUNTU_VERSIONS | tr '\n' ', ')"
    fi
else
    print_warning "No matrix strategy found"
fi

# Check for artifact retention
if grep -q "retention-days:" "$WORKFLOW_FILE"; then
    RETENTION=$(grep "retention-days:" "$WORKFLOW_FILE" | head -1 | awk '{print $2}')
    print_success "Artifact retention: $RETENTION days"
else
    print_warning "No artifact retention specified (default: 90 days)"
fi

# Suggest optional improvements
echo ""
print_info "Optional improvements:"
echo ""

# Check for caching
if ! grep -q "actions/cache" "$WORKFLOW_FILE"; then
    print_info "  • Consider adding caching for faster runs"
fi

# Check for concurrency limits
if ! grep -q "concurrency:" "$WORKFLOW_FILE"; then
    print_info "  • Consider adding concurrency limits to prevent duplicate runs"
fi

# Check for manual workflow dispatch
if grep -q "workflow_dispatch" "$WORKFLOW_FILE"; then
    print_success "Manual workflow trigger enabled"
else
    print_info "  • Consider adding workflow_dispatch for manual triggers"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    print_success "Validation complete - No errors found!"
    echo ""
    print_info "You can now safely commit and push your changes."
    echo ""
    print_info "To test locally with act:"
    echo "  act -j test-scripts-only"
    echo ""
    print_info "To push and trigger workflow:"
    echo "  git add .github/workflows/test-installation.yml"
    echo "  git commit -m 'Add GitHub Actions testing'"
    echo "  git push"
else
    print_error "Validation failed with $ERRORS error(s)"
    echo ""
    print_info "Please fix the errors above before pushing."
    exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
