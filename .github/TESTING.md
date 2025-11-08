# GitHub Actions Testing Guide

This directory contains automated tests for the Moodle Installation Suite.

## Workflow Overview

The test suite runs automatically on:
- **Push to main or develop branches**
- **Pull requests to main or develop**
- **Manual trigger** via GitHub Actions UI

## Test Jobs

### 1. **test-installation** (Matrix Strategy)
Tests complete installation across multiple Ubuntu versions:
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS  
- Ubuntu 24.04 LTS

**What it tests:**
- ✅ System package updates
- ✅ Script execution permissions
- ✅ Complete installation process
- ✅ Service startup (Nginx, MariaDB, PHP-FPM)
- ✅ File structure and permissions
- ✅ Database connectivity
- ✅ PHP configuration
- ✅ Nginx configuration
- ✅ Web server response
- ✅ Moodle page loading
- ✅ Cron job configuration
- ✅ Firewall setup

**Duration:** ~15-30 minutes per Ubuntu version

### 2. **test-resume-capability**
Tests the installation resume feature:
- Runs partial installation
- Interrupts the process
- Verifies state file creation
- Resumes installation from checkpoint
- Confirms successful completion

**Duration:** ~10-15 minutes

### 3. **test-idempotency**
Tests that scripts can run multiple times safely:
- Runs complete installation
- Re-runs installation script
- Verifies no errors when steps already completed
- Confirms services remain operational

**Duration:** ~15-20 minutes

### 4. **test-scripts-only** (Fast)
Quick validation without full installation:
- Bash syntax checking
- ShellCheck static analysis
- Documentation presence verification

**Duration:** ~2-3 minutes

## Viewing Test Results

### On GitHub
1. Go to **Actions** tab in your repository
2. Click on the workflow run
3. Click on each job to see detailed output

### Badges
Add this badge to your README.md:

```markdown
![Test Status](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Test%20Moodle%20Installation/badge.svg)
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your values.

## Artifacts

Each test run generates diagnostic artifacts:
- Installation logs (`/var/log/moodle_install.log`)
- Troubleshoot reports (`/tmp/moodle_diagnostic_report_*.txt`)

**Retention:** 30 days

**Download:** Actions tab → Click workflow run → Artifacts section

## Manual Testing Triggers

### Trigger via GitHub UI
1. Go to **Actions** tab
2. Select **Test Moodle Installation** workflow
3. Click **Run workflow** button
4. Select branch
5. Click **Run workflow**

### Trigger via GitHub CLI
```bash
gh workflow run test-installation.yml
```

## Test Configuration

### Environment Variables
The tests use these default values:
- `DOMAIN`: localhost
- `DB_PASSWORD`: TestPassword123!
- Installation timeout: 30 minutes

### Modify Test Parameters
Edit `.github/workflows/test-installation.yml`:

```yaml
env:
  DOMAIN: your-test-domain.local
  DB_PASSWORD: YourCustomPassword
```

## Local Testing with Act

You can run GitHub Actions locally using [act](https://github.com/nektos/act):

### Install Act
```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Run Tests Locally
```bash
# Run all jobs
act

# Run specific job
act -j test-scripts-only

# Run with specific Ubuntu version
act -j test-installation --matrix ubuntu-version:22.04
```

## Troubleshooting Test Failures

### Service Not Starting
**Check logs in test output:**
```yaml
- name: Check service logs on failure
  if: failure()
  run: |
    sudo tail -50 /var/log/nginx/error.log
    sudo journalctl -u mariadb -n 50
```

### Installation Timeout
Increase timeout in workflow:
```yaml
timeout-minutes: 45  # Increase from 30
```

### Database Connection Failed
Check test output for:
- MariaDB service status
- Database credentials
- Network connectivity

### File Permission Issues
Verify ownership in test output:
```bash
stat -c '%U:%G' /var/www/html/moodle
stat -c '%U:%G' /var/moodledata
```

## Test Environment Specifications

Each test runner provides:
- **CPU:** 2 cores
- **RAM:** 7 GB
- **Disk:** 14 GB SSD
- **Network:** High-speed internet

This exceeds Moodle's minimum requirements:
- Minimum: 2GB RAM, 20GB disk
- Recommended: 4GB+ RAM, 50GB+ disk

## Adding New Tests

### Add Test Case
1. Create new job in workflow file:
```yaml
test-new-feature:
  name: Test New Feature
  runs-on: ubuntu-22.04
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Test new feature
      run: |
        # Your test commands
```

2. Add to existing job:
```yaml
- name: Test new feature
  run: |
    # Your test commands
```

## Best Practices

### For Contributors
- ✅ Run `bash -n script.sh` before committing
- ✅ Test locally when possible
- ✅ Check workflow syntax before push
- ✅ Review test output on failures
- ✅ Update tests when adding features

### For Maintainers
- ✅ Monitor test success rates
- ✅ Review artifact logs regularly
- ✅ Update Ubuntu versions as needed
- ✅ Adjust timeouts based on actual duration
- ✅ Add tests for new features

## Performance Metrics

Typical test durations:
- **Fast syntax check:** 2-3 minutes
- **Single Ubuntu install:** 15-30 minutes
- **Full matrix (3 versions):** 45-90 minutes
- **Resume test:** 10-15 minutes
- **Idempotency test:** 15-20 minutes

**Total workflow time:** ~60-120 minutes for all tests

## Security Considerations

### Test Credentials
- Default password: `TestPassword123!`
- Only used in ephemeral test runners
- Runners destroyed after each test
- No sensitive data persists

### Artifact Security
- Logs may contain system information
- No credentials in logs (passwords redacted)
- 30-day retention only
- Accessible only to repository collaborators

## CI/CD Integration

### Pre-commit Hook
Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running syntax checks..."
bash -n install-moodle.sh || exit 1
bash -n troubleshoot-moodle.sh || exit 1
bash -n moodle-status.sh || exit 1
echo "✓ Syntax checks passed"
```

### Automated Releases
Trigger on successful tests:
```yaml
release:
  needs: [test-installation, test-resume-capability, test-idempotency]
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - name: Create release
      # Release steps
```

## Monitoring & Alerts

### GitHub Notifications
Configure in repository settings:
- Settings → Notifications
- Enable workflow notifications
- Set email preferences

### Status Webhooks
Monitor test status via webhooks:
- Settings → Webhooks
- Add webhook URL
- Select workflow events

## Support

### Issues with Tests
1. Check workflow run logs
2. Download diagnostic artifacts
3. Review error messages
4. Open issue with:
   - Ubuntu version
   - Test job name
   - Error output
   - Relevant log files

### Contributing Test Improvements
1. Fork repository
2. Create feature branch
3. Add/modify tests
4. Submit pull request
5. Ensure all tests pass

---

**Last Updated:** November 8, 2025  
**Workflow Version:** 1.0  
**Minimum GitHub Actions Version:** N/A (uses standard actions)
