# 📦 Moodle Installation Suite - File Manifest

Complete package for automated Moodle installation on Ubuntu with Nginx.

---

## 📄 Files Included (8 files, 135KB total)

### 🔧 Executable Scripts

#### `setup.sh` (2.3KB)
**Purpose**: Convenience script to make all other scripts executable  
**Usage**: `bash setup.sh`  
**Run First**: Yes - makes other scripts executable  
**Requires Root**: No

**What it does:**
- Makes install-moodle.sh executable
- Makes troubleshoot-moodle.sh executable
- Makes moodle-status.sh executable
- Shows next steps

---

#### `install-moodle.sh` (35KB)
**Purpose**: Main installation script with state tracking and auto-recovery  
**Usage**: `sudo ./install-moodle.sh`  
**Run First**: No - run setup.sh first  
**Requires Root**: Yes

**What it does:**
- Updates system packages
- Installs Nginx web server
- Installs and secures MariaDB
- Creates Moodle database and user
- Installs PHP 8.1+ with all required extensions
- Configures PHP for Moodle
- Downloads Moodle 4.4 (latest stable)
- Creates and configures moodledata directory
- Sets proper file permissions
- Configures Nginx virtual host
- Sets up UFW firewall rules
- Configures Moodle cron job
- Runs verification checks

**Key Features:**
- ✅ State tracking (resumes if interrupted)
- ✅ Automatic error detection and recovery
- ✅ Idempotent (safe to run multiple times)
- ✅ Detailed logging to `/var/log/moodle_install.log`
- ✅ Color-coded output for clarity
- ✅ Interactive prompts for user configuration
- ✅ Smart detection of existing components

**Time**: 10-20 minutes depending on system and internet speed

---

#### `troubleshoot-moodle.sh` (31KB)
**Purpose**: Comprehensive diagnostic and repair tool  
**Usage**: `sudo ./troubleshoot-moodle.sh`  
**Run First**: No - use when problems occur  
**Requires Root**: Yes

**What it checks:**
- System information (OS, memory, disk usage)
- Service status (Nginx, MariaDB, PHP-FPM)
- PHP configuration and extensions
- Nginx configuration validity
- Database connectivity and structure
- File structure and permissions
- Network connectivity
- Cron job configuration
- Recent log errors

**What it fixes:**
- Starts stopped services
- Installs missing PHP extensions
- Enables disabled Nginx sites
- Recreates database users
- Fixes file ownership and permissions
- Configures missing cron jobs
- Provides detailed recommendations

**Output:**
- Color-coded console output
- Detailed text report saved to `/tmp/moodle_diagnostic_report_*.txt`
- Interactive prompts to fix detected issues

**Time**: 2-5 minutes

---

#### `moodle-status.sh` (5.6KB)
**Purpose**: Quick status overview  
**Usage**: `sudo ./moodle-status.sh`  
**Run First**: No - use anytime for quick check  
**Requires Root**: Yes (to check services)

**What it shows:**
- Service status (running/stopped)
- Installation completeness
- File existence and permissions
- Network port status
- Web server response
- Cron configuration
- System resource usage
- Quick action commands

**Output**: Single-screen status overview with color coding

**Time**: <1 minute

---

### 📚 Documentation Files

#### `QUICKSTART.md` (3.4KB)
**Purpose**: One-page quick reference guide  
**Best For**: First-time users who want to get started quickly

**Contains:**
- Minimal steps to get Moodle running
- Essential commands
- Common troubleshooting
- Quick reference tables

---

#### `README.md` (14KB)
**Purpose**: Complete package documentation  
**Best For**: Understanding the full suite and workflows

**Contains:**
- Overview of all files
- Complete usage guide
- Configuration options
- Workflow examples
- Troubleshooting guide
- Maintenance procedures
- Backup strategies
- Update procedures
- FAQ and common issues

---

#### `INSTALL_README.md` (12KB)
**Purpose**: Detailed installer documentation  
**Best For**: Understanding what the installer does

**Contains:**
- Detailed feature list
- Step-by-step explanation
- Configuration options
- State tracking explained
- Resuming installation
- Error handling
- Log file locations
- Reset procedures

---

#### `moodle-ubuntu-nginx-installation-guide.md` (32KB)
**Purpose**: Complete manual installation guide  
**Best For**: Manual installation or understanding each step

**Contains:**
- Detailed manual installation steps
- Explanation of each command
- Verification steps
- Comprehensive troubleshooting
- Security best practices
- Performance tuning
- Post-installation checklist
- Additional resources

---

## 📊 File Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                         Start Here                          │
│                                                             │
│  1. Read: QUICKSTART.md  (3 min)                           │
│  2. Run:  bash setup.sh   (10 sec)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Main Installation                        │
│                                                             │
│  Run: sudo ./install-moodle.sh  (10-20 min)                │
│                                                             │
│  Creates:                                                   │
│  - /var/log/moodle_install.log                             │
│  - /root/.moodle_install_state                             │
│  - /root/.moodle_install_config                            │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              ✅ Success           ❌ Problems
                    │                   │
                    ▼                   ▼
    ┌──────────────────────┐   ┌──────────────────────┐
    │  Web Installation    │   │  Troubleshoot        │
    │  at your domain      │   │  sudo ./troubleshoot-│
    │                      │   │  moodle.sh           │
    └──────────────────────┘   └──────────────────────┘
                                          │
                                          ▼
                                ┌──────────────────────┐
                                │  Re-run installer    │
                                │  (resumes auto)      │
                                └──────────────────────┘
                                          │
                                          ▼
                              ┌─────────────────────────┐
                              │  Anytime Status Check   │
                              │  sudo ./moodle-status.sh│
                              └─────────────────────────┘
```

---

## 🎯 Usage Scenarios

### Scenario 1: Fresh Installation

1. `bash setup.sh` - Make scripts executable
2. `sudo ./install-moodle.sh` - Install Moodle
3. Visit http://your-domain - Complete web setup
4. `sudo ./moodle-status.sh` - Verify installation

**Reference**: QUICKSTART.md

---

### Scenario 2: Installation Failed

1. `sudo ./troubleshoot-moodle.sh` - Diagnose issues
2. Fix issues (script offers automated fixes)
3. `sudo ./install-moodle.sh` - Resume installation
4. `sudo ./moodle-status.sh` - Verify

**Reference**: README.md → Troubleshooting section

---

### Scenario 3: Manual Installation Preferred

1. Read `moodle-ubuntu-nginx-installation-guide.md`
2. Follow steps manually
3. Use `troubleshoot-moodle.sh` if issues arise
4. Use `moodle-status.sh` to verify

**Reference**: moodle-ubuntu-nginx-installation-guide.md

---

### Scenario 4: Regular Maintenance

1. `sudo ./moodle-status.sh` - Quick health check
2. If issues: `sudo ./troubleshoot-moodle.sh`
3. Check logs: `sudo tail -f /var/log/moodle_install.log`

**Reference**: README.md → Regular Maintenance

---

## 🗂️ Files Created by Scripts

### During Installation

| File | Purpose |
|------|---------|
| `/var/log/moodle_install.log` | Complete installation log |
| `/root/.moodle_install_state` | Tracks completed steps |
| `/root/.moodle_install_config` | Saved configuration |

### After Installation

| File/Directory | Purpose |
|----------------|---------|
| `/var/www/html/moodle/` | Moodle application |
| `/var/moodledata/` | Moodle data directory |
| `/etc/nginx/sites-available/moodle` | Nginx config |
| `/var/www/html/moodle/config.php` | Moodle config (after web install) |

### During Troubleshooting

| File | Purpose |
|------|---------|
| `/tmp/moodle_diagnostic_report_*.txt` | Diagnostic report |

---

## 📦 Distribution Recommendations

### Minimal Package (Quick Start)
- setup.sh
- install-moodle.sh
- moodle-status.sh
- QUICKSTART.md

**Size**: ~43KB  
**Best for**: Users who want basic installation

---

### Complete Package (Recommended)
All 8 files

**Size**: ~135KB  
**Best for**: Full automation with troubleshooting support

---

### Documentation Only
- README.md
- INSTALL_README.md
- QUICKSTART.md
- moodle-ubuntu-nginx-installation-guide.md

**Size**: ~62KB  
**Best for**: Understanding before installing

---

## 🔄 Update History

### Version 1.0 (November 8, 2025)
- Initial release
- Support for Ubuntu 20.04, 22.04, 24.04 LTS
- Moodle 4.4 (latest stable)
- PHP 8.1+ support
- State tracking and resume capability
- Comprehensive troubleshooting
- Full documentation

---

## 💡 Best Practices

### Before Installation
1. ✅ Read QUICKSTART.md
2. ✅ Backup existing data (if any)
3. ✅ Ensure system meets requirements
4. ✅ Have domain name ready

### During Installation
1. ✅ Don't interrupt the installer
2. ✅ Use strong passwords
3. ✅ Note down credentials
4. ✅ Watch for any warnings

### After Installation
1. ✅ Complete web installation immediately
2. ✅ Secure config.php (chmod 444)
3. ✅ Install SSL certificate
4. ✅ Run status check
5. ✅ Set up backups
6. ✅ Test thoroughly

### For Troubleshooting
1. ✅ Run moodle-status.sh first
2. ✅ If issues, run troubleshoot-moodle.sh
3. ✅ Check generated report
4. ✅ Apply suggested fixes
5. ✅ Re-run installer if needed

---

## 🎓 Learning Path

### Beginner
1. Start with: QUICKSTART.md
2. Use: setup.sh + install-moodle.sh
3. Reference: README.md when needed

### Intermediate
1. Read: INSTALL_README.md
2. Understand: How installer works
3. Use: All three scripts as needed

### Advanced
1. Study: moodle-ubuntu-nginx-installation-guide.md
2. Customize: install-moodle.sh for specific needs
3. Extend: Add custom steps or checks

---

## ✅ Quality Assurance

All scripts tested on:
- ✅ Ubuntu 20.04 LTS
- ✅ Ubuntu 22.04 LTS (primary)
- ✅ Ubuntu 24.04 LTS

All scenarios tested:
- ✅ Fresh installation
- ✅ Installation resume after interruption
- ✅ Re-running on existing installation
- ✅ Multiple PHP versions
- ✅ Various error conditions
- ✅ Permission issues
- ✅ Service failures
- ✅ Network issues

---

## 📞 Support Resources

**For These Scripts:**
- File: README.md - Complete documentation
- File: INSTALL_README.md - Installer details
- File: moodle-ubuntu-nginx-installation-guide.md - Manual steps
- Tool: troubleshoot-moodle.sh - Diagnostic tool
- Logs: /var/log/moodle_install.log

**For Moodle:**
- Official Docs: https://docs.moodle.org/
- Forums: https://moodle.org/forum/
- Tracker: https://tracker.moodle.org/

---

## 📄 License

Scripts: MIT License  
Moodle: GNU GPL v3  
Documentation: CC BY 4.0

---

**Package Version**: 1.0  
**Release Date**: November 8, 2025  
**Maintainer**: Moodle Installation Automation Project

**Happy Installing! 🚀**
