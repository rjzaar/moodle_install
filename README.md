# 🚀 Moodle Installation Automation Suite

Complete automation suite for installing and managing Moodle on Ubuntu with Nginx, MariaDB, and PHP.

## 📦 What's Included

This package contains everything you need for a successful Moodle deployment:

| File | Description |
|------|-------------|
| `install-moodle.sh` | **Main installer script** with state tracking and auto-recovery |
| `troubleshoot-moodle.sh` | **Diagnostic tool** to identify and fix issues |
| `moodle-status.sh` | **Quick status checker** for installation overview |
| `INSTALL_README.md` | Detailed documentation for the installer |
| `moodle-ubuntu-nginx-installation-guide.md` | Complete manual installation guide |

## ⚡ Quick Start

### 1. Download All Files

```bash
# Create directory
mkdir ~/moodle-installer
cd ~/moodle-installer

# Copy all files to this directory
```

### 2. Make Scripts Executable

```bash
chmod +x install-moodle.sh troubleshoot-moodle.sh moodle-status.sh
```

### 3. Run the Installer

```bash
sudo ./install-moodle.sh
```

### 4. Follow the Prompts

The script will ask for:
- Your domain name
- Database password

Then it will automatically:
- ✅ Install all required packages
- ✅ Configure services
- ✅ Download Moodle
- ✅ Set up database
- ✅ Configure Nginx
- ✅ Set permissions
- ✅ Enable firewall
- ✅ Setup cron jobs

### 5. Complete Web Installation

After the script completes, visit your domain in a browser to finish the Moodle setup.

## 🛠️ Usage Guide

### Main Installation Script

```bash
sudo ./install-moodle.sh
```

**Features:**
- ✅ **State Tracking**: Automatically resumes if interrupted
- ✅ **Error Recovery**: Detects and fixes common issues
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Detailed Logging**: All actions logged to `/var/log/moodle_install.log`
- ✅ **Smart Detection**: Auto-detects PHP version and configuration

**What it does:**
1. Updates system packages
2. Installs Nginx web server
3. Installs and secures MariaDB
4. Creates Moodle database and user
5. Installs PHP and all required extensions
6. Configures PHP for Moodle
7. Downloads Moodle 4.4 (latest stable)
8. Creates moodledata directory
9. Sets correct permissions
10. Configures Nginx virtual host
11. Sets up firewall rules
12. Configures cron jobs
13. Runs verification checks

### Troubleshooting Script

```bash
sudo ./troubleshoot-moodle.sh
```

**Features:**
- 🔍 Comprehensive diagnostics
- 🛠️ Interactive fixes
- 📊 Detailed report generation
- ⚡ Quick problem identification

**What it checks:**
- Service status (Nginx, MariaDB, PHP-FPM)
- PHP configuration and extensions
- Nginx configuration validity
- Database connectivity
- File structure and permissions
- Network connectivity
- Cron configuration
- Recent log errors

**Output:**
- Color-coded console output
- Detailed text report saved to `/tmp/moodle_diagnostic_report_*.txt`
- Interactive fix prompts for detected issues

### Quick Status Script

```bash
sudo ./moodle-status.sh
```

**Features:**
- ⚡ Fast overview
- 📊 Key metrics
- 🎯 At-a-glance status

**Shows:**
- Service status
- Installation completeness
- Network status
- System resources
- Next steps

## 📋 Complete Workflow

### First-Time Installation

```bash
# 1. Run installer
sudo ./install-moodle.sh

# 2. Complete web installation at http://your-domain

# 3. Secure config.php
sudo chmod 444 /var/www/html/moodle/config.php

# 4. Install SSL (recommended)
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com

# 5. Check status
sudo ./moodle-status.sh
```

### If Installation Fails

```bash
# 1. Run diagnostics
sudo ./troubleshoot-moodle.sh

# 2. Fix identified issues (script will offer to fix automatically)

# 3. Re-run installer (it will resume from where it stopped)
sudo ./install-moodle.sh

# 4. Check status
sudo ./moodle-status.sh
```

### Regular Maintenance

```bash
# Quick health check
sudo ./moodle-status.sh

# Full diagnostics
sudo ./troubleshoot-moodle.sh

# View logs
sudo tail -f /var/log/moodle_install.log
sudo tail -f /var/log/nginx/error.log
```

## 🔧 Configuration

### Default Settings

The scripts use these default values (can be changed):

```bash
MOODLE_DIR="/var/www/html/moodle"
MOODLE_DATA="/var/moodledata"
DB_NAME="moodle"
DB_USER="moodleuser"
```

### Customizing Installation

Edit `install-moodle.sh` before running to change:

```bash
# Line ~40
MOODLE_DIR="/var/www/html/moodle"      # Change install path
MOODLE_DATA="/var/moodledata"          # Change data path
DB_NAME="moodle"                        # Change database name
DB_USER="moodleuser"                    # Change database user
```

### Environment Variables

Set variables to skip prompts:

```bash
export DOMAIN="moodle.example.com"
export DB_PASSWORD="your_secure_password"
sudo -E ./install-moodle.sh
```

## 📍 Important Paths

After installation, know these locations:

| Path | Purpose |
|------|---------|
| `/var/www/html/moodle` | Moodle application files |
| `/var/moodledata` | Moodle data (uploads, cache, sessions) |
| `/etc/nginx/sites-available/moodle` | Nginx configuration |
| `/etc/php/X.X/fpm/php.ini` | PHP configuration |
| `/var/log/moodle_install.log` | Installation log |
| `/root/.moodle_install_state` | State tracking file |
| `/root/.moodle_install_config` | Saved configuration |

## 🔒 Security Checklist

After installation, ensure:

- [ ] config.php is read-only: `sudo chmod 444 /var/www/html/moodle/config.php`
- [ ] SSL certificate installed: `sudo certbot --nginx -d your-domain.com`
- [ ] Firewall enabled: `sudo ufw status`
- [ ] Strong database password set
- [ ] Regular backups configured
- [ ] Moodledata NOT web-accessible
- [ ] Site admin password is strong
- [ ] Email configuration tested

## 🐛 Common Issues & Solutions

### Installation Hangs or Fails

```bash
# Check the log
sudo tail -50 /var/log/moodle_install.log

# Run troubleshooter
sudo ./troubleshoot-moodle.sh

# Re-run installer (it will resume)
sudo ./install-moodle.sh
```

### Services Not Running

```bash
# Check status
sudo systemctl status nginx mariadb php*-fpm

# Restart services
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php8.1-fpm
```

### White Screen / 502 Error

```bash
# Run diagnostics
sudo ./troubleshoot-moodle.sh

# Check PHP logs
sudo tail -f /var/log/php8.1-fpm.log

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Permission Errors

```bash
# Fix Moodle permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

# Fix data directory
sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 755 /var/moodledata
```

### Database Connection Failed

```bash
# Test connection
mysql -u moodleuser -p moodle -e "SELECT 1;"

# If fails, recreate user
sudo mysql -u root -p
```
```sql
DROP USER IF EXISTS 'moodleuser'@'localhost';
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Reset & Start Fresh

```bash
# Remove state tracking
sudo rm -f /root/.moodle_install_state
sudo rm -f /root/.moodle_install_config

# Remove Moodle files (careful!)
sudo rm -rf /var/www/html/moodle
sudo rm -rf /var/moodledata

# Drop database (careful!)
sudo mysql -u root -p -e "DROP DATABASE IF EXISTS moodle;"

# Re-run installer
sudo ./install-moodle.sh
```

## 📊 Log Files

### View Installation Log

```bash
# View entire log
sudo cat /var/log/moodle_install.log

# View last 50 lines
sudo tail -50 /var/log/moodle_install.log

# Follow in real-time
sudo tail -f /var/log/moodle_install.log
```

### View Service Logs

```bash
# Nginx error log
sudo tail -f /var/log/nginx/error.log

# PHP-FPM log
sudo tail -f /var/log/php8.1-fpm.log

# MariaDB log
sudo journalctl -xeu mariadb

# System log
sudo journalctl -xe
```

## 🔄 Updating Moodle

After initial installation:

### Via Git (if installed with Git)
```bash
cd /var/www/html/moodle
sudo -u www-data git pull
sudo -u www-data php admin/cli/upgrade.php --non-interactive
```

### Via Admin Interface
1. Site administration → Notifications
2. Follow upgrade prompts

### Manual Update
```bash
# 1. Backup everything
sudo tar -czf moodle-backup-$(date +%Y%m%d).tar.gz /var/www/html/moodle
sudo mysqldump -u moodleuser -p moodle > moodle-db-backup-$(date +%Y%m%d).sql

# 2. Download new version
cd /tmp
wget https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz

# 3. Extract and replace (keep config.php)
tar -zxf moodle-latest-404.tgz
sudo cp /var/www/html/moodle/config.php /tmp/
sudo rm -rf /var/www/html/moodle
sudo mv moodle /var/www/html/
sudo mv /tmp/config.php /var/www/html/moodle/

# 4. Set permissions
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle
sudo chmod 444 /var/www/html/moodle/config.php

# 5. Run upgrade
sudo -u www-data php /var/www/html/moodle/admin/cli/upgrade.php
```

## 💾 Backup Strategy

### Automated Backup Script

Create `/root/backup-moodle.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/moodle"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u moodleuser -p'password' moodle | gzip > $BACKUP_DIR/moodle-db-$DATE.sql.gz

# Backup moodledata
tar -czf $BACKUP_DIR/moodledata-$DATE.tar.gz /var/moodledata/

# Backup Moodle code (if you have custom plugins)
tar -czf $BACKUP_DIR/moodle-code-$DATE.tar.gz /var/www/html/moodle/

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable and add to crontab:
```bash
chmod +x /root/backup-moodle.sh
sudo crontab -e
# Add: 0 2 * * * /root/backup-moodle.sh >> /var/log/moodle-backup.log 2>&1
```

## 🎯 Post-Installation Checklist

After installation, verify:

- [ ] Site loads at http://your-domain
- [ ] Can log in with admin account
- [ ] Cron is running (Site admin → Server → Scheduled tasks)
- [ ] Email works (Site admin → Server → Test outgoing mail)
- [ ] SSL certificate installed and working (https://)
- [ ] config.php is read-only (444 permissions)
- [ ] Firewall is enabled
- [ ] Backups are automated
- [ ] Test course creation works
- [ ] Test file upload works
- [ ] Mobile app connectivity (if needed)
- [ ] All required plugins installed
- [ ] Timezone set correctly
- [ ] Performance is acceptable

## 🆘 Getting Help

### Check Documentation

1. **Installation README**: `INSTALL_README.md` - Detailed installer docs
2. **Manual Guide**: `moodle-ubuntu-nginx-installation-guide.md` - Complete manual steps
3. **Official Moodle Docs**: https://docs.moodle.org/

### Run Diagnostics

```bash
# Quick overview
sudo ./moodle-status.sh

# Full diagnostics with report
sudo ./troubleshoot-moodle.sh
```

### Check Logs

```bash
# Installation log
sudo tail -50 /var/log/moodle_install.log

# Service logs
sudo journalctl -xeu nginx
sudo journalctl -xeu mariadb
sudo journalctl -xeu php8.1-fpm
```

### Community Resources

- **Moodle Forums**: https://moodle.org/forum/
- **Moodle Docs**: https://docs.moodle.org/
- **Moodle Tracker**: https://tracker.moodle.org/

## 📚 Additional Resources

- **Installation Guide**: https://docs.moodle.org/en/Installing_Moodle
- **System Requirements**: https://docs.moodle.org/en/System_requirements
- **Security Best Practices**: https://docs.moodle.org/en/Security
- **Performance Tuning**: https://docs.moodle.org/en/Performance
- **Nginx Configuration**: https://docs.moodle.org/en/Nginx
- **PHP Configuration**: https://docs.moodle.org/en/PHP

## 🔍 Script Features Comparison

| Feature | installer | troubleshooter | status |
|---------|-----------|----------------|--------|
| Installs Moodle | ✅ | ❌ | ❌ |
| State tracking | ✅ | ❌ | ❌ |
| Error recovery | ✅ | ✅ | ❌ |
| Diagnostics | Basic | Comprehensive | Quick |
| Interactive fixes | Some | Yes | No |
| Report generation | Log file | Text report | Screen only |
| Runtime | 10-20 min | 2-5 min | <1 min |

## ⚙️ System Requirements

### Minimum Specifications

- **OS**: Ubuntu 20.04, 22.04, or 24.04 LTS
- **RAM**: 2GB (4GB+ recommended)
- **CPU**: 2 cores (4+ recommended)
- **Disk**: 20GB free space
- **Network**: Internet connection

### Recommended for Production

- **OS**: Ubuntu 22.04 LTS
- **RAM**: 8GB+
- **CPU**: 4+ cores
- **Disk**: 100GB+ SSD
- **Network**: High-speed connection
- **Backup**: Automated daily backups

## 📄 License

These installation scripts are provided as-is under the MIT License.  
Moodle itself is licensed under GNU GPL v3.

## ⚠️ Disclaimer

These scripts are provided for convenience and educational purposes. Always:

- ✅ Test on a staging server first
- ✅ Backup before running on production
- ✅ Review script code before execution
- ✅ Understand what each step does
- ✅ Keep security best practices in mind
- ✅ Monitor your installation after deployment

## 📞 Support

For issues with these scripts:
1. Run `./troubleshoot-moodle.sh` for diagnostics
2. Check `/var/log/moodle_install.log` for details
3. Consult the detailed README files included

For Moodle-specific issues:
- Visit https://moodle.org/forum/
- Check https://docs.moodle.org/

---

**Package Version**: 1.0  
**Last Updated**: November 8, 2025  
**Tested On**: Ubuntu 22.04 LTS with Moodle 4.4

**Happy Moodling! 🎓**
