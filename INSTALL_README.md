# Moodle Installation Script - README

## Overview

This automated installation script will install and configure Moodle on Ubuntu with Nginx, MariaDB, and PHP. It includes intelligent features like state tracking, error recovery, and automatic fixing of common issues.

## ✨ Key Features

- **🔄 State Tracking**: Resume installation from where it left off if interrupted
- **🛠️ Error Recovery**: Automatically detects and fixes common installation issues
- **✅ Idempotent**: Safe to run multiple times without breaking existing setup
- **📝 Detailed Logging**: All actions logged to `/var/log/moodle_install.log`
- **🎨 Color-Coded Output**: Clear visual feedback on progress and status
- **🔍 Pre-flight Checks**: Verifies each step before proceeding
- **⚡ Smart Detection**: Automatically detects PHP version and configuration

## 📋 Prerequisites

- **Operating System**: Ubuntu 20.04, 22.04, or 24.04 LTS
- **Access**: Root or sudo privileges
- **RAM**: Minimum 2GB (4GB+ recommended)
- **Disk Space**: At least 20GB free
- **Network**: Internet connection for downloading packages

## 🚀 Quick Start

### 1. Download the Script

```bash
wget https://your-server.com/install-moodle.sh
# OR
curl -O https://your-server.com/install-moodle.sh
```

### 2. Make it Executable

```bash
chmod +x install-moodle.sh
```

### 3. Run as Root

```bash
sudo ./install-moodle.sh
```

### 4. Follow Prompts

The script will ask you for:
- **Domain name** (e.g., moodle.example.com or localhost)
- **Database password** (choose a strong password)

### 5. Complete Web Installation

After the script finishes, visit `http://your-domain` to complete the Moodle setup through the web interface.

## 📊 Installation Steps

The script performs these steps in order:

1. ✅ **Update System Packages** - Updates Ubuntu packages
2. ✅ **Install Nginx** - Web server installation
3. ✅ **Install MariaDB** - Database server installation
4. ✅ **Secure MariaDB** - Security configuration
5. ✅ **Create Database** - Moodle database and user setup
6. ✅ **Install PHP** - PHP and required extensions
7. ✅ **Configure PHP** - Optimize settings for Moodle
8. ✅ **Download Moodle** - Get latest Moodle 4.4
9. ✅ **Create Data Directory** - Setup moodledata folder
10. ✅ **Set Permissions** - Configure file ownership
11. ✅ **Configure Nginx** - Web server configuration
12. ✅ **Configure Firewall** - UFW firewall rules
13. ✅ **Setup Cron** - Scheduled tasks
14. ✅ **Final Checks** - Verify installation

## 🔄 Resuming Installation

If the installation is interrupted (power loss, connection drop, etc.), simply run the script again:

```bash
sudo ./install-moodle.sh
```

The script will:
- ✅ Detect which steps were already completed
- ✅ Skip completed steps
- ✅ Continue from where it stopped
- ✅ Show clear status messages

State is tracked in: `/root/.moodle_install_state`

## 🔧 Configuration Files

The script creates and uses these configuration files:

| File | Purpose |
|------|---------|
| `/root/.moodle_install_state` | Tracks completed steps |
| `/root/.moodle_install_config` | Stores installation configuration |
| `/var/log/moodle_install.log` | Detailed installation log |
| `/etc/nginx/sites-available/moodle` | Nginx configuration |
| `/etc/php/X.X/fpm/php.ini` | PHP configuration |

## 📍 Important Paths

After installation:

| Path | Description |
|------|-------------|
| `/var/www/html/moodle` | Moodle application files |
| `/var/moodledata` | Moodle data directory (NOT web accessible) |
| `/var/log/nginx/` | Nginx logs |
| `/var/log/php*-fpm.log` | PHP-FPM logs |

## 🌐 Database Credentials

You'll need these for the web installation:

- **Database host**: `localhost`
- **Database name**: `moodle`
- **Database user**: `moodleuser`
- **Database password**: [the password you entered]
- **Tables prefix**: `mdl_` (keep default)

## 🔒 Security Notes

### After Installation

1. **Secure config.php**:
   ```bash
   sudo chmod 444 /var/www/html/moodle/config.php
   ```

2. **Install SSL Certificate** (recommended):
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   sudo certbot --nginx -d your-domain.com
   ```

3. **Update Moodle config for HTTPS**:
   ```bash
   sudo chmod 644 /var/www/html/moodle/config.php
   sudo nano /var/www/html/moodle/config.php
   # Change: $CFG->wwwroot = 'https://your-domain.com';
   sudo chmod 444 /var/www/html/moodle/config.php
   ```

### Regular Maintenance

- Keep Ubuntu updated: `sudo apt update && sudo apt upgrade`
- Monitor logs: `sudo tail -f /var/log/moodle_install.log`
- Backup regularly (database + moodledata)

## 🐛 Troubleshooting

### Script Won't Run

**Problem**: Permission denied
```bash
# Solution:
chmod +x install-moodle.sh
sudo ./install-moodle.sh
```

**Problem**: Not running as root
```bash
# Solution: Use sudo
sudo ./install-moodle.sh
```

### Installation Fails at a Step

**Check the log file:**
```bash
sudo tail -50 /var/log/moodle_install.log
```

**Re-run the script:**
```bash
sudo ./install-moodle.sh
```
The script will automatically retry failed steps.

### Reset Installation

If you need to start completely fresh:

```bash
# Remove state file
sudo rm -f /root/.moodle_install_state
sudo rm -f /root/.moodle_install_config

# Re-run script
sudo ./install-moodle.sh
```

### Service Not Running

**Check service status:**
```bash
sudo systemctl status nginx
sudo systemctl status mariadb
sudo systemctl status php*-fpm
```

**Restart services:**
```bash
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php8.1-fpm  # Adjust version
```

### Database Connection Issues

**Test database connection:**
```bash
mysql -u moodleuser -p moodle -e "SELECT 1;"
```

**Reset database user:**
```bash
sudo mysql -u root -p
```
```sql
DROP USER 'moodleuser'@'localhost';
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### White Screen After Installation

**Enable debugging:**
```bash
sudo nano /var/www/html/moodle/config.php
```
Add before `require_once`:
```php
$CFG->debug = 32767;
$CFG->debugdisplay = true;
```

**Check PHP logs:**
```bash
sudo tail -f /var/log/php*-fpm.log
```

### Permission Issues

**Fix Moodle permissions:**
```bash
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 755 /var/moodledata
```

### 502 Bad Gateway

**Check PHP-FPM:**
```bash
sudo systemctl status php*-fpm
sudo systemctl restart php*-fpm
```

**Check PHP socket:**
```bash
ls -l /var/run/php/
```

**Update Nginx config if socket path is different:**
```bash
sudo nano /etc/nginx/sites-available/moodle
# Update fastcgi_pass line to correct socket path
sudo nginx -t
sudo systemctl reload nginx
```

## 📊 Viewing Logs

### Installation Log
```bash
# View entire log
sudo cat /var/log/moodle_install.log

# View last 50 lines
sudo tail -50 /var/log/moodle_install.log

# Follow log in real-time
sudo tail -f /var/log/moodle_install.log
```

### Nginx Logs
```bash
# Error log
sudo tail -f /var/log/nginx/error.log

# Access log
sudo tail -f /var/log/nginx/access.log
```

### PHP Logs
```bash
sudo tail -f /var/log/php8.1-fpm.log  # Adjust version
```

### System Logs
```bash
# General system log
sudo tail -f /var/log/syslog

# Service-specific logs
sudo journalctl -xeu nginx
sudo journalctl -xeu mariadb
sudo journalctl -xeu php8.1-fpm
```

## 🔄 Updating Moodle

After initial installation, you can update Moodle using:

### Option 1: Git (if installed via Git)
```bash
cd /var/www/html/moodle
sudo -u www-data git pull
sudo -u www-data php admin/cli/upgrade.php --non-interactive
```

### Option 2: Admin Interface
1. Site administration → Notifications
2. Follow upgrade prompts

### Option 3: Manual Update
1. Backup everything
2. Download new version
3. Replace files (keep config.php and moodledata)
4. Run upgrade: `sudo -u www-data php admin/cli/upgrade.php`

## 🗑️ Uninstalling

To completely remove Moodle:

```bash
# Stop services
sudo systemctl stop nginx
sudo systemctl stop php*-fpm

# Remove files
sudo rm -rf /var/www/html/moodle
sudo rm -rf /var/moodledata

# Remove database
sudo mysql -u root -p -e "DROP DATABASE moodle; DROP USER 'moodleuser'@'localhost';"

# Remove Nginx config
sudo rm -f /etc/nginx/sites-available/moodle
sudo rm -f /etc/nginx/sites-enabled/moodle
sudo systemctl reload nginx

# Remove state files
sudo rm -f /root/.moodle_install_state
sudo rm -f /root/.moodle_install_config
sudo rm -f /var/log/moodle_install.log
```

## 🆘 Getting Help

If you encounter issues not covered here:

1. **Check the installation log**: `/var/log/moodle_install.log`
2. **Check service logs**: Nginx, PHP-FPM, MariaDB logs
3. **Consult Moodle docs**: https://docs.moodle.org/
4. **Moodle forums**: https://moodle.org/forum/

## 📝 Advanced Usage

### Custom Installation Paths

Edit the script variables before running:
```bash
nano install-moodle.sh
```

Modify these lines:
```bash
MOODLE_DIR="/var/www/html/moodle"      # Change install path
MOODLE_DATA="/var/moodledata"          # Change data path
DB_NAME="moodle"                        # Change database name
DB_USER="moodleuser"                    # Change database user
```

### Non-Interactive Mode

Set environment variables to skip prompts:
```bash
export DOMAIN="moodle.example.com"
export DB_PASSWORD="your_secure_password"
sudo -E ./install-moodle.sh
```

### Dry Run / Verification Mode

Check what would be done without making changes:
```bash
# View state of each step
cat /root/.moodle_install_state

# Check if services are running
sudo systemctl status nginx mariadb php*-fpm
```

## 📈 Performance Tuning

After installation, consider these optimizations:

### 1. Enable OPcache
```bash
sudo nano /etc/php/8.1/fpm/php.ini
```
```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
```

### 2. Configure Moodle Caching
Site administration → Plugins → Caching → Configuration

### 3. Database Optimization
```bash
sudo apt install mysqltuner
sudo mysqltuner
```

### 4. Increase PHP-FPM Workers
```bash
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```
```ini
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
```

## 🎯 Post-Installation Checklist

After running the script and completing web installation:

- [ ] Can access Moodle at http://your-domain
- [ ] Admin login works
- [ ] Cron is running (check Site administration → Server → Scheduled tasks)
- [ ] Email configuration works (test email)
- [ ] SSL certificate installed and working
- [ ] config.php is read-only (chmod 444)
- [ ] Firewall is enabled
- [ ] Backups are configured
- [ ] Test course creation
- [ ] Test file upload
- [ ] Review security settings

## 📚 Additional Resources

- **Official Moodle Docs**: https://docs.moodle.org/
- **Installation Guide**: https://docs.moodle.org/en/Installing_Moodle
- **System Requirements**: https://docs.moodle.org/en/System_requirements
- **Security**: https://docs.moodle.org/en/Security
- **Performance**: https://docs.moodle.org/en/Performance

## 📄 License

This installation script is provided as-is under the MIT License. Moodle itself is licensed under GNU GPL v3.

## ⚠️ Disclaimer

This script is provided for educational and convenience purposes. Always:
- Test on a staging server first
- Backup before running on production
- Review the script code before execution
- Understand what each step does
- Keep security best practices in mind

---

**Script Version**: 1.0  
**Last Updated**: November 8, 2025  
**Tested On**: Ubuntu 22.04 LTS, Moodle 4.4
