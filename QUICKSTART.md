# 🚀 Moodle Installation - Quick Start Guide

## One-Command Installation

```bash
# 1. Make scripts executable
bash setup.sh

# 2. Run installer
sudo ./install-moodle.sh

# 3. Complete web installation at http://your-domain
```

That's it! The script handles everything automatically.

---

## 📋 What You Need

- ✅ Ubuntu 20.04/22.04/24.04 LTS
- ✅ Root/sudo access
- ✅ 2GB+ RAM
- ✅ Internet connection

---

## 🔑 During Installation

You'll be asked for:

1. **Domain name** (e.g., moodle.example.com or localhost)
2. **Database password** (choose a strong password)

Everything else is automatic!

---

## 📊 Installation Steps

The script automatically:

1. ✅ Updates Ubuntu packages
2. ✅ Installs Nginx
3. ✅ Installs MariaDB
4. ✅ Creates Moodle database
5. ✅ Installs PHP 8.1+
6. ✅ Downloads Moodle 4.4
7. ✅ Configures everything
8. ✅ Sets up firewall
9. ✅ Enables cron jobs

**Time:** 10-20 minutes

---

## 🌐 After Script Completes

1. Visit: `http://your-domain`
2. Follow Moodle's web installer
3. Use these database credentials:
   - Host: `localhost`
   - Database: `moodle`
   - User: `moodleuser`
   - Password: [what you entered]
   - Prefix: `mdl_`

---

## 🔒 Secure Your Installation

```bash
# Make config read-only
sudo chmod 444 /var/www/html/moodle/config.php

# Install SSL certificate (recommended)
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

---

## 🛠️ If Something Goes Wrong

```bash
# Run diagnostics
sudo ./troubleshoot-moodle.sh

# Check status
sudo ./moodle-status.sh

# Re-run installer (it resumes automatically)
sudo ./install-moodle.sh

# View logs
sudo tail -f /var/log/moodle_install.log
```

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `install-moodle.sh` | Main installer |
| `troubleshoot-moodle.sh` | Fix problems |
| `moodle-status.sh` | Quick check |
| `README.md` | Full documentation |

---

## 🆘 Common Issues

### White Screen
```bash
sudo ./troubleshoot-moodle.sh
```

### Can't Connect to Database
```bash
# Test connection
mysql -u moodleuser -p moodle -e "SELECT 1;"
```

### Service Not Running
```bash
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php8.1-fpm
```

### Permission Error
```bash
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chown -R www-data:www-data /var/moodledata
```

---

## ✅ Post-Installation Checklist

- [ ] Site loads at your domain
- [ ] Admin login works
- [ ] SSL certificate installed
- [ ] Cron is running
- [ ] Email configured
- [ ] Backups scheduled

---

## 📚 Need More Help?

- **Full docs**: See `README.md`
- **Detailed guide**: See `INSTALL_README.md`
- **Manual steps**: See `moodle-ubuntu-nginx-installation-guide.md`
- **Moodle docs**: https://docs.moodle.org/

---

## 🎯 Key Features

- ✅ **Automatic**: No manual configuration needed
- ✅ **Resumable**: Continues if interrupted
- ✅ **Safe**: Can run multiple times
- ✅ **Smart**: Auto-detects and fixes issues
- ✅ **Logged**: Everything recorded

---

## 📍 Default Paths

| Item | Location |
|------|----------|
| Moodle files | `/var/www/html/moodle` |
| Data directory | `/var/moodledata` |
| Install log | `/var/log/moodle_install.log` |
| Nginx config | `/etc/nginx/sites-available/moodle` |

---

**Ready to install? Run: `bash setup.sh` then `sudo ./install-moodle.sh`**

**Questions? Check README.md for complete documentation.**
