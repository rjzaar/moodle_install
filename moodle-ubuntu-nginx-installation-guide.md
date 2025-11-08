# 🚀 Complete Moodle Installation Guide
## Ubuntu + Nginx + MariaDB + PHP

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
  - [Step 1: Update System Packages](#step-1-update-system-packages)
  - [Step 2: Install Nginx](#step-2-install-nginx)
  - [Step 3: Install MariaDB](#step-3-install-mariadb)
  - [Step 4: Create Database](#step-4-create-moodle-database-and-user)
  - [Step 5: Install PHP](#step-5-install-php-and-required-extensions)
  - [Step 6: Configure PHP](#step-6-configure-php-for-moodle)
  - [Step 7: Download Moodle](#step-7-download-moodle)
  - [Step 8: Create Data Directory](#step-8-create-moodle-data-directory)
  - [Step 9: Set Permissions](#step-9-set-permissions)
  - [Step 10: Configure Nginx](#step-10-configure-nginx-for-moodle)
  - [Step 11: Web Installation](#step-11-complete-web-installation)
  - [Step 12: Post-Installation Security](#step-12-post-installation-security)
  - [Step 13: SSL Certificate](#step-13-install-ssl-certificate)
- [Troubleshooting](#common-issues-and-troubleshooting)
- [Important Notes](#key-things-to-be-aware-of)

---

## 📦 Prerequisites

Before starting, ensure you have:

- ✅ Ubuntu 20.04/22.04/24.04 LTS server
- ✅ Root or sudo access
- ✅ Domain name pointed to your server (optional but recommended)
- ✅ Minimum 2GB RAM, 4GB+ recommended
- ✅ At least 20GB free disk space

---

## 🛠️ Installation Steps

### Step 1: Update System Packages

Update your system to ensure all packages are current:

```bash
sudo apt update && sudo apt upgrade -y
```

**What this does:**
- Updates the package repository cache
- Upgrades all installed packages to their latest versions
- Ensures security patches are applied

**✓ Verification:**

```bash
apt list --upgradable
```

**Expected output:** `All packages are up to date.` or `0 packages can be upgraded`

---

### Step 2: Install Nginx

Install the Nginx web server:

```bash
sudo apt install nginx -y
```

**What this does:**
- Installs Nginx, a high-performance web server
- Automatically starts the service
- Creates necessary configuration directories

**✓ Verification:**

```bash
# Check service status
sudo systemctl status nginx

# Check version
nginx -v

# Test HTTP response
curl -I localhost
```

**Expected results:**
- Status should show `active (running)` in green
- Version should display (e.g., `nginx/1.24.0`)
- Curl should return `HTTP/1.1 200 OK`

**Enable on boot:**

```bash
sudo systemctl enable nginx
```

**⚠️ Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Port 80 already in use | `sudo lsof -i :80` to identify conflicting service |
| Service fails to start | `sudo journalctl -xeu nginx` to check logs |
| Firewall blocking | `sudo ufw allow 'Nginx Full'` if using UFW |

---

### Step 3: Install MariaDB

Install the database server:

```bash
sudo apt install mariadb-server mariadb-client -y
```

**What this does:**
- Installs MariaDB (MySQL fork)
- Starts the database service
- Prepares for database creation

**✓ Verification:**

```bash
sudo systemctl status mariadb
mysql --version
```

**Secure the installation:**

```bash
sudo mysql_secure_installation
```

**Configuration prompts:**

| Prompt | Recommended Answer | Reason |
|--------|-------------------|--------|
| Enter current password | Press Enter (no password yet) | First time setup |
| Switch to unix_socket authentication? | N | Keep standard auth |
| Set root password? | Y | Security essential |
| Remove anonymous users? | Y | Prevent unauthorized access |
| Disallow root login remotely? | Y | Enhance security |
| Remove test database? | Y | Clean installation |
| Reload privilege tables? | Y | Apply changes |

**✓ Final verification:**

```bash
sudo mysql -u root -p
```

**Expected:** MySQL prompt `MariaDB [(none)]>`

Type `EXIT;` to leave the prompt.

---

### Step 4: Create Moodle Database and User

Create dedicated database and user for Moodle:

```bash
sudo mysql -u root -p
```

**Run these SQL commands:**

```sql
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**What this does:**
- Creates `moodle` database with UTF-8 support (emoji, international characters)
- Creates `moodleuser` with secure password
- Grants necessary permissions only to Moodle database
- Applies privilege changes

**✓ Verification:**

```bash
mysql -u moodleuser -p -e "SHOW DATABASES;"
```

**Expected output:** List including `moodle` database

**🔐 Important:** Save these credentials securely - you'll need them during web installation:
- Database: `moodle`
- Username: `moodleuser`
- Password: `your_strong_password`

---

### Step 5: Install PHP and Required Extensions

Install PHP and all Moodle dependencies:

```bash
sudo apt install php-fpm php-mysql php-xml php-mbstring php-curl \
php-zip php-gd php-intl php-soap php-xmlrpc php-ldap -y
```

**What each extension does:**

| Extension | Purpose |
|-----------|---------|
| `php-fpm` | FastCGI Process Manager for Nginx |
| `php-mysql` | Database connectivity |
| `php-xml` | XML parsing for content |
| `php-mbstring` | Multibyte string handling |
| `php-curl` | External HTTP requests |
| `php-zip` | Archive handling |
| `php-gd` | Image manipulation |
| `php-intl` | Internationalization |
| `php-soap` | Web services |
| `php-xmlrpc` | Remote procedure calls |
| `php-ldap` | Directory services (optional) |

**✓ Verification:**

```bash
# Check PHP version
php -v

# Verify all required extensions
php -m | grep -E 'curl|gd|intl|mbstring|mysql|soap|xml|xmlrpc|zip'

# Check PHP-FPM service
sudo systemctl status php*-fpm
```

**Expected results:**
- PHP version 7.4 or higher (8.1+ recommended)
- All extensions listed
- PHP-FPM service `active (running)`

**⚠️ Troubleshooting:**

```bash
# Find installed PHP version
ls /etc/php/

# Install missing extension (replace X.X with your version)
sudo apt install php8.1-<extension-name>
```

---

### Step 6: Configure PHP for Moodle

Optimize PHP settings for Moodle's requirements:

```bash
sudo nano /etc/php/8.1/fpm/php.ini
```

> **Note:** Replace `8.1` with your PHP version

**Find and modify these values:**

```ini
max_execution_time = 300        # From 30 - allows longer scripts
max_input_time = 300            # From 60 - allows larger uploads
memory_limit = 256M             # From 128M - more memory for operations
post_max_size = 512M            # From 8M - large file uploads
upload_max_filesize = 512M      # From 2M - large file uploads
```

**What each setting does:**

| Setting | Purpose | Why Increase |
|---------|---------|--------------|
| `max_execution_time` | Maximum script runtime (seconds) | Moodle tasks can take time |
| `max_input_time` | Maximum input parsing time | Large file uploads |
| `memory_limit` | Maximum memory per script | Complex operations |
| `post_max_size` | Maximum POST data size | File uploads via forms |
| `upload_max_filesize` | Maximum file upload size | Course materials, videos |

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

**Restart PHP-FPM:**

```bash
sudo systemctl restart php8.1-fpm
```

**✓ Verification:**

```bash
php -i | grep -E 'max_execution_time|memory_limit|upload_max_filesize'
```

**Expected:** Your new values displayed

---

### Step 7: Download Moodle

Download and extract Moodle:

**Option A: Direct Download (Stable Release)**

```bash
cd /tmp
wget https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz
tar -zxvf moodle-latest-404.tgz
sudo mv moodle /var/www/html/
```

**Option B: Git Clone (Easier Updates)**

```bash
cd /var/www/html
sudo git clone -b MOODLE_404_STABLE git://git.moodle.org/moodle.git
```

**What this does:**
- Downloads Moodle 4.4 (latest stable)
- Extracts to temporary location
- Moves to web server directory

**Which method to choose:**

| Method | Pros | Cons |
|--------|------|------|
| Direct Download | Simple, complete package | Manual updates |
| Git Clone | Easy updates via git pull | Requires git knowledge |

**✓ Verification:**

```bash
ls -la /var/www/html/moodle/
```

**Expected:** Directory containing `index.php`, `config-dist.php`, and many other files/folders

**Check Moodle version:**

```bash
grep '$release' /var/www/html/moodle/version.php
```

---

### Step 8: Create Moodle Data Directory

Create secure directory for Moodle data storage:

```bash
sudo mkdir /var/moodledata
sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 755 /var/moodledata
```

**What this does:**
- Creates directory for uploaded files, cache, sessions, temp files
- Sets `www-data` (Nginx user) as owner
- Sets appropriate permissions (755 = rwxr-xr-x)

**🔒 Critical Security Note:**
- This directory **MUST** be outside the web root (`/var/www/html`)
- It should **NOT** be accessible directly via web browser
- Moodle will handle file serving securely

**✓ Verification:**

```bash
ls -ld /var/moodledata
```

**Expected output:**
```
drwxr-xr-x 2 www-data www-data 4096 Nov 08 10:30 /var/moodledata
```

**Test write permissions:**

```bash
sudo -u www-data touch /var/moodledata/test.txt
ls -l /var/moodledata/test.txt
sudo rm /var/moodledata/test.txt
```

---

### Step 9: Set Permissions

Configure ownership and permissions for Moodle files:

```bash
sudo chown -R www-data:www-data /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle
```

**What this does:**
- Sets Nginx user (`www-data`) as owner of all Moodle files
- Allows Moodle to create `config.php` during installation
- Permits reading of PHP files by web server

**Permission breakdown:**

| Number | Permission | Meaning |
|--------|------------|---------|
| 7 | rwx | Owner (www-data) can read, write, execute |
| 5 | r-x | Group can read and execute |
| 5 | r-x | Others can read and execute |

**✓ Verification:**

```bash
ls -la /var/www/html/ | grep moodle
stat -c '%a %n' /var/www/html/moodle
```

**Expected:** 
- Owner: `www-data`
- Group: `www-data`
- Permissions: `755`

---

### Step 10: Configure Nginx for Moodle

Create Nginx server configuration:

```bash
sudo nano /etc/nginx/sites-available/moodle
```

**Add this complete configuration:**

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    root /var/www/html/moodle;
    index index.php index.html index.htm;

    # Increased upload size for large files
    client_max_body_size 512M;
    
    # Main location block
    location / {
        try_files $uri $uri/ =404;
    }
    
    # PHP processing
    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS off;
        
        # Increased buffers for large requests
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    
    # Protect dataroot directory
    location /dataroot/ {
        internal;
        alias /var/moodledata/;
    }
    
    # Deny access to hidden files
    location ~ /\.ht {
        deny all;
    }
}
```

**Configuration explanation:**

| Directive | Purpose |
|-----------|---------|
| `listen 80` | Listen on HTTP port |
| `server_name` | Your domain(s) |
| `root` | Moodle installation path |
| `client_max_body_size` | Maximum upload size (matches PHP settings) |
| `try_files` | Try to serve files directly, else 404 |
| `fastcgi_pass` | PHP-FPM socket location |
| `location /dataroot/` | Internal file serving (security) |
| `location ~ /\.ht` | Block access to .htaccess files |

**🔧 Important:** Replace `your-domain.com` with your actual domain, and adjust PHP version in socket path if needed.

**Enable the site:**

```bash
# Create symbolic link to enable site
sudo ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo unlink /etc/nginx/sites-enabled/default
```

**Test configuration:**

```bash
sudo nginx -t
```

**Expected output:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Reload Nginx:**

```bash
sudo systemctl reload nginx
```

**✓ Verification:**

```bash
# Check if site is enabled
ls -l /etc/nginx/sites-enabled/

# Test HTTP response
curl -I http://your-domain.com

# Check Nginx logs for errors
sudo tail -f /var/log/nginx/error.log
```

**⚠️ Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Config test fails | Check syntax, brackets, semicolons |
| 502 Bad Gateway | Verify PHP-FPM socket: `ls /var/run/php/` |
| 404 errors | Check `root` path matches installation |
| Permission denied | Verify www-data owns files |

---

### Step 11: Complete Web Installation

Navigate to your domain in a web browser:

```
http://your-domain.com
```

The Moodle installation wizard will guide you through these steps:

#### 11.1 Choose Language

- Select your preferred language
- Click **Next**

#### 11.2 Confirm Paths

Verify these paths are correct:

| Field | Value |
|-------|-------|
| Web address | `http://your-domain.com` |
| Moodle directory | `/var/www/html/moodle` |
| Data directory | `/var/moodledata` |

Click **Next**

#### 11.3 Choose Database Driver

- Select: **MariaDB (native/mariadb)**
- Click **Next**

#### 11.4 Database Settings

Enter credentials from Step 4:

| Field | Value |
|-------|-------|
| Database host | `localhost` |
| Database name | `moodle` |
| Database user | `moodleuser` |
| Database password | `your_strong_password` |
| Tables prefix | `mdl_` (default, don't change) |
| Database port | Leave empty |
| Unix socket | Leave empty |

Click **Next**

#### 11.5 Copyright Notice

- Read the GNU GPL license
- Click **Continue**

#### 11.6 Server Checks

Moodle checks if all requirements are met:

**✅ All checks should pass:**
- PHP version
- PHP extensions
- Directory permissions
- Database connection

**❌ If any checks fail:**

| Failed Check | Solution |
|--------------|----------|
| PHP extension missing | `sudo apt install php8.1-<extension>` then restart PHP-FPM |
| Can't write to config.php | Check permissions: `ls -la /var/www/html/moodle/` |
| Can't write to dataroot | Check permissions: `ls -la /var/moodledata/` |
| Database connection failed | Verify credentials and MySQL service |

Click **Continue** when all checks pass

#### 11.7 Installation

The installer will:
- Create database tables (approximately 5-10 minutes)
- Set up default site configuration
- Install core plugins

**⏳ Progress indicators:**
- Green checkmarks = completed
- Spinner = in progress
- Red X = error (check logs)

**Do NOT:**
- Close the browser
- Refresh the page
- Navigate away

#### 11.8 Create Admin Account

Set up the primary administrator:

| Field | Recommendation |
|-------|---------------|
| Username | `admin` (or your preference) |
| Password | Strong password (12+ chars, mixed case, numbers, symbols) |
| First name | Your first name |
| Surname | Your last name |
| Email | Valid email address (important for notifications) |
| City/Town | Your city |
| Country | Your country |

Click **Update profile**

#### 11.9 Front Page Settings

Configure basic site settings:

| Field | Purpose |
|-------|---------|
| Full site name | Displayed name of your Moodle site |
| Short site name | Abbreviated name (for navigation) |
| Front page summary | Description shown on home page |

Click **Save changes**

**🎉 Installation Complete!**

You should now see the Moodle dashboard.

**✓ Verification checklist:**

```bash
# Check config.php was created
ls -l /var/www/html/moodle/config.php

# Check database tables were created
mysql -u moodleuser -p -e "USE moodle; SHOW TABLES;" | wc -l
# Should show 400+ tables

# Check dataroot has files
ls -la /var/moodledata/
# Should show multiple directories (cache, filedir, lang, etc.)
```

**⚠️ Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Blank page | Check PHP error logs: `sudo tail -f /var/log/php8.1-fpm.log` |
| Timeout during installation | Increase PHP `max_execution_time` to 600 |
| Database connection error | Verify credentials in database settings |
| Permission errors | Ensure www-data owns both moodle and moodledata directories |
| Can't access site after install | Check Nginx is running: `sudo systemctl status nginx` |

---

### Step 12: Post-Installation Security

Secure your Moodle installation:

#### 12.1 Protect config.php

Make configuration file read-only:

```bash
sudo chmod 444 /var/www/html/moodle/config.php
```

**What this does:**
- Prevents modification through web interface
- Protects database credentials
- Makes file read-only (r--r--r--)

**✓ Verification:**

```bash
ls -l /var/www/html/moodle/config.php
```

**Expected:** `-r--r--r--` permissions

#### 12.2 Configure Cron Job

Moodle requires scheduled tasks for:
- Sending emails
- Backup operations
- Cleanup tasks
- Plugin maintenance

**Set up cron:**

```bash
sudo crontab -u www-data -e
```

**Add this line:**

```cron
* * * * * /usr/bin/php /var/www/html/moodle/admin/cli/cron.php >/dev/null
```

**What this does:**
- Runs Moodle cron every minute
- Executes as www-data user (required)
- Suppresses output (logs to Moodle)

**Save and exit:** `Ctrl+X`, `Y`, `Enter`

**✓ Verification:**

```bash
# List cron jobs
sudo crontab -u www-data -l

# Test manual run
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/cron.php

# Check cron is running (wait 2-3 minutes)
grep CRON /var/log/syslog | tail -5
```

**Expected:** No errors, scheduled tasks should execute

**Check in Moodle:**
1. Site administration → Server → Scheduled tasks
2. Verify tasks are running regularly

#### 12.3 Configure Firewall

Set up UFW firewall:

```bash
# Allow SSH (IMPORTANT: Do this first!)
sudo ufw allow OpenSSH

# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

**Expected output:**

```
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
Nginx Full                 ALLOW       Anywhere
```

#### 12.4 Additional Security Settings

**In Moodle Admin Interface:**

1. **Site administration → Security → Site security settings**
   - Enable Force login: Yes (users must log in)
   - Password policy: Strong (enforce complex passwords)

2. **Site administration → Security → HTTP security**
   - Cookie secure: Yes (after SSL setup)
   - Use HTTPS: Yes (after SSL setup)

3. **Site administration → Server → Update notifications**
   - Enable to receive security updates

---

### Step 13: Install SSL Certificate

Secure your site with HTTPS (free certificate):

#### 13.1 Install Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
```

**What this does:**
- Installs Let's Encrypt Certbot client
- Installs Nginx plugin for automatic configuration

#### 13.2 Obtain Certificate

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

**Follow the prompts:**

| Prompt | Recommended Action |
|--------|-------------------|
| Enter email | Provide valid email for renewal notices |
| Agree to Terms | Yes |
| Share email with EFF | Your choice (No is fine) |
| Redirect HTTP to HTTPS | Yes (option 2) |

**What this does:**
- Obtains SSL certificate from Let's Encrypt
- Automatically configures Nginx for HTTPS
- Sets up automatic HTTP to HTTPS redirect
- Configures automatic renewal

**✓ Verification:**

```bash
# Test certificate
sudo certbot certificates

# Visit your site
curl -I https://your-domain.com

# Test SSL configuration
openssl s_client -connect your-domain.com:443 -brief
```

**Expected:**
- Certificate valid
- HTTPS works with padlock in browser
- HTTP redirects to HTTPS

#### 13.3 Update Moodle Configuration

Update Moodle to use HTTPS:

```bash
sudo chmod 644 /var/www/html/moodle/config.php
sudo nano /var/www/html/moodle/config.php
```

**Find and change:**

```php
$CFG->wwwroot   = 'https://your-domain.com';
```

**Save and make read-only again:**

```bash
sudo chmod 444 /var/www/html/moodle/config.php
```

#### 13.4 Test Auto-Renewal

Let's Encrypt certificates expire every 90 days:

```bash
# Test renewal process (doesn't actually renew)
sudo certbot renew --dry-run
```

**Expected:** Success message with no errors

**Check auto-renewal timer:**

```bash
sudo systemctl status certbot.timer
```

**Expected:** `active (waiting)`

---

## 🔧 Common Issues and Troubleshooting

### Issue 1: White Screen / Blank Page

**Symptoms:** Site displays blank white page

**Diagnosis:**

```bash
# Enable debugging temporarily
sudo chmod 644 /var/www/html/moodle/config.php
sudo nano /var/www/html/moodle/config.php
```

**Add before** `require_once`:

```php
$CFG->debug = 32767;
$CFG->debugdisplay = true;
```

**Check logs:**

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/php8.1-fpm.log
```

**Common causes:**

| Error Message | Solution |
|--------------|----------|
| PHP Fatal error: memory limit | Increase `memory_limit` in php.ini |
| Permission denied | Check file ownership: `sudo chown -R www-data:www-data` |
| Failed to connect to database | Verify database credentials in config.php |

**Remember to disable debugging after fixing:**

```php
$CFG->debug = 0;
$CFG->debugdisplay = false;
```

---

### Issue 2: Database Connection Failed

**Symptoms:** Can't connect to database error

**Diagnosis:**

```bash
# Test database connection
mysql -u moodleuser -p moodle -e "SELECT 1;"

# Check database exists
mysql -u root -p -e "SHOW DATABASES;"

# Check user permissions
mysql -u root -p -e "SHOW GRANTS FOR 'moodleuser'@'localhost';"
```

**Solutions:**

```bash
# Recreate database user
sudo mysql -u root -p
```

```sql
DROP USER 'moodleuser'@'localhost';
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY 'your_strong_password';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Verify config.php has correct credentials:**

```bash
sudo grep -A5 "dbhost" /var/www/html/moodle/config.php
```

---

### Issue 3: File Upload Fails

**Symptoms:** Error when uploading files

**Diagnosis:**

```bash
# Check PHP settings
php -i | grep -E 'upload_max_filesize|post_max_size|max_execution_time'

# Check Nginx settings
sudo grep -r "client_max_body_size" /etc/nginx/

# Check dataroot permissions
ls -la /var/moodledata/
```

**Solutions:**

1. **Increase PHP limits:**

```bash
sudo nano /etc/php/8.1/fpm/php.ini
```

Ensure:
```ini
upload_max_filesize = 512M
post_max_size = 512M
max_execution_time = 300
```

2. **Increase Nginx limit:**

```bash
sudo nano /etc/nginx/sites-available/moodle
```

Ensure:
```nginx
client_max_body_size 512M;
```

3. **Fix permissions:**

```bash
sudo chown -R www-data:www-data /var/moodledata
sudo chmod -R 755 /var/moodledata
```

4. **Restart services:**

```bash
sudo systemctl restart php8.1-fpm
sudo systemctl reload nginx
```

---

### Issue 4: 502 Bad Gateway

**Symptoms:** Nginx returns 502 error

**Diagnosis:**

```bash
# Check PHP-FPM status
sudo systemctl status php8.1-fpm

# Check socket exists
ls -l /var/run/php/

# Check Nginx error log
sudo tail -50 /var/log/nginx/error.log
```

**Common causes and solutions:**

| Cause | Solution |
|-------|----------|
| PHP-FPM not running | `sudo systemctl start php8.1-fpm` |
| Wrong socket path in Nginx | Update `fastcgi_pass` to correct socket |
| PHP-FPM overloaded | Increase `pm.max_children` in pool config |
| Permissions on socket | Check socket permissions |

**Check PHP-FPM pool configuration:**

```bash
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```

Adjust if needed:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

---

### Issue 5: Cron Not Running

**Symptoms:** Scheduled tasks not executing

**Diagnosis:**

```bash
# Check cron is installed
sudo crontab -u www-data -l

# Check cron logs
sudo grep CRON /var/log/syslog | tail -20

# Test manual run
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/cron.php
```

**Solutions:**

1. **Verify cron entry:**

```bash
sudo crontab -u www-data -e
```

Should contain:
```cron
* * * * * /usr/bin/php /var/www/html/moodle/admin/cli/cron.php >/dev/null
```

2. **Check PHP path:**

```bash
which php  # Verify PHP location
```

3. **Check in Moodle:**
   - Site administration → Server → Scheduled tasks
   - Look for last run times

4. **Manual test with output:**

```bash
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/cron.php
```

Look for errors in output.

---

### Issue 6: Slow Performance

**Symptoms:** Pages load slowly

**Diagnosis:**

```bash
# Check server resources
htop  # or: top

# Check database
mysql -u root -p -e "SHOW PROCESSLIST;"

# Check PHP-FPM status
sudo systemctl status php8.1-fpm
```

**Performance optimizations:**

1. **Enable OPcache:**

```bash
sudo nano /etc/php/8.1/fpm/php.ini
```

Add/uncomment:
```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
```

2. **Enable Moodle caching:**
   - Site administration → Plugins → Caching
   - Enable Application cache
   - Enable Session cache

3. **Optimize database:**

```bash
# Run mysqltuner
sudo apt install mysqltuner
sudo mysqltuner
```

Follow recommendations.

4. **Increase PHP-FPM workers:**

```bash
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```

Increase based on your RAM:
```ini
pm.max_children = 100
```

5. **Restart services:**

```bash
sudo systemctl restart php8.1-fpm
sudo systemctl restart mariadb
```

---

### Issue 7: Email Not Sending

**Symptoms:** Moodle can't send emails

**Solution:**

Configure SMTP in Moodle:

1. Site administration → Server → Email → Outgoing mail configuration
2. Set SMTP settings:
   - SMTP hosts: `smtp.gmail.com:587` (example)
   - SMTP security: TLS
   - SMTP username: your email
   - SMTP password: app password

**Test email:**

Site administration → Server → Email → Test outgoing mail configuration

---

## ⚠️ Key Things to Be Aware Of

### 🔒 Security

| Item | Importance | Action |
|------|-----------|--------|
| **HTTPS** | Critical | Always use SSL in production |
| **config.php** | Critical | Keep read-only (chmod 444) |
| **Database passwords** | Critical | Use strong, unique passwords |
| **File permissions** | High | Never use 777 permissions |
| **Updates** | High | Check weekly for security updates |
| **Backups** | Critical | Automate database + moodledata backups |

### 📁 Directory Structure

**Must understand:**

```
/var/www/html/moodle/     # Application files (web accessible)
/var/moodledata/           # Data files (NOT web accessible)
```

**Never:**
- Store moodledata inside web root
- Allow direct web access to moodledata
- Set 777 permissions anywhere

### 💾 Backups

**What to backup:**

1. **Database:**
```bash
mysqldump -u moodleuser -p moodle > moodle_backup_$(date +%Y%m%d).sql
```

2. **Moodledata:**
```bash
sudo tar -czf moodledata_backup_$(date +%Y%m%d).tar.gz /var/moodledata/
```

3. **Moodle code** (especially if you have custom plugins):
```bash
sudo tar -czf moodle_backup_$(date +%Y%m%d).tar.gz /var/www/html/moodle/
```

**Automate with cron:**

```bash
sudo crontab -e
```

Add:
```cron
0 2 * * * /path/to/backup-script.sh
```

### 🔄 Updates

**Before updating:**

1. ✅ Backup everything
2. ✅ Check PHP compatibility
3. ✅ Put site in maintenance mode
4. ✅ Test on staging first (if possible)

**Update methods:**

| Method | Pros | Cons |
|--------|------|------|
| Git | Easy, quick | Requires git install |
| Manual | Complete control | More steps |
| Admin GUI | User-friendly | Can timeout |

**Via Git:**

```bash
cd /var/www/html/moodle
sudo -u www-data git pull
sudo -u www-data /usr/bin/php admin/cli/upgrade.php
```

### 📊 Resource Requirements

**Minimum specifications:**

| Users | RAM | CPU | Disk |
|-------|-----|-----|------|
| 1-50 | 2GB | 2 cores | 20GB |
| 50-200 | 4GB | 4 cores | 50GB |
| 200-1000 | 8GB | 6 cores | 100GB |
| 1000+ | 16GB+ | 8+ cores | 200GB+ |

**Monitor resources:**

```bash
# CPU and memory
htop

# Disk space
df -h

# Database size
du -sh /var/lib/mysql/moodle

# Moodledata size
du -sh /var/moodledata
```

### 🌐 Multi-Site Considerations

If running multiple sites on one server:

- Use separate databases per site
- Use separate moodledata directories
- Use separate Nginx server blocks
- Consider separate PHP-FPM pools

### 📝 Logging

**Important log locations:**

```bash
# Nginx access log
/var/log/nginx/access.log

# Nginx error log
/var/log/nginx/error.log

# PHP-FPM log
/var/log/php8.1-fpm.log

# Moodle logs
Site administration → Reports → Logs

# System logs
/var/log/syslog
```

**Monitor logs:**

```bash
# Real-time monitoring
sudo tail -f /var/log/nginx/error.log

# Search for errors
sudo grep -i error /var/log/nginx/error.log
```

### 🔧 Maintenance Mode

**Enable maintenance mode:**

```bash
# Via command line
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/maintenance.php --enable

# Via admin interface
Site administration → Server → Maintenance mode
```

**Use when:**
- Performing updates
- Making major configuration changes
- Running database maintenance
- Troubleshooting issues

**Disable:**

```bash
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/maintenance.php --disable
```

### 🌍 Timezone Configuration

**Set server timezone:**

```bash
sudo timedatectl set-timezone America/New_York
```

**Set Moodle timezone:**

Site administration → Location → Location settings → Default timezone

**⚠️ Important:** These should match!

---

## 🎯 Post-Installation Checklist

After installation, verify:

- [ ] Site loads over HTTPS
- [ ] Can log in with admin account
- [ ] Cron is running (check scheduled tasks)
- [ ] Email is configured and working
- [ ] SSL certificate is valid
- [ ] Firewall is enabled
- [ ] Backups are automated
- [ ] Timezone is correct
- [ ] config.php is read-only
- [ ] moodledata is not web-accessible
- [ ] All PHP extensions are installed
- [ ] Performance is acceptable
- [ ] Logs show no errors
- [ ] Test course creation works
- [ ] Test file upload works
- [ ] Mobile app connectivity (if needed)

---

## 📚 Additional Resources

**Official Documentation:**
- Moodle Docs: https://docs.moodle.org/
- Installation Guide: https://docs.moodle.org/en/Installing_Moodle
- Upgrading: https://docs.moodle.org/en/Upgrading

**Community:**
- Moodle Forums: https://moodle.org/forum/
- Moodle Tracker (Bug Reports): https://tracker.moodle.org/

**Performance:**
- Moodle Performance: https://docs.moodle.org/en/Performance
- PHP Performance: https://www.php.net/manual/en/opcache.configuration.php

**Security:**
- Moodle Security: https://docs.moodle.org/en/Security
- Let's Encrypt: https://letsencrypt.org/

---

## 🎓 Congratulations!

Your Moodle installation is now complete and secure! 

**Next steps:**

1. Configure your first course
2. Set up user authentication (LDAP, OAuth, etc.)
3. Customize theme and appearance
4. Install additional plugins as needed
5. Configure site policies
6. Set up grade scales and report cards

**Remember:**
- Keep everything updated
- Monitor server resources
- Back up regularly
- Test major changes on staging first

---

**Document Version:** 1.0  
**Last Updated:** November 8, 2025  
**Tested On:** Ubuntu 22.04 LTS, Moodle 4.4, Nginx 1.24, PHP 8.1, MariaDB 10.6
