#!/bin/bash

################################################################################
# Moodle Installation Script for Ubuntu + Nginx + MariaDB + PHP
# 
# Features:
# - Step-by-step installation with clear messaging
# - State tracking to resume from where it left off
# - Automatic error detection and fixing
# - Idempotent (safe to run multiple times)
# - Detailed logging
#
# Usage: sudo ./install-moodle.sh
#
# Author: Installation Automation Script
# Version: 1.0
################################################################################

set -e  # Exit on error (we'll handle errors explicitly)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
STATE_FILE="/root/.moodle_install_state"
LOG_FILE="/var/log/moodle_install.log"
MOODLE_DIR="/var/www/html/moodle"
MOODLE_DATA="/var/moodledata"
DB_NAME="moodle"
DB_USER="moodleuser"

# Default values (will be prompted if not set)
DOMAIN=""
DB_PASSWORD=""
PHP_VERSION=""

################################################################################
# Helper Functions
################################################################################

# Print colored message
print_message() {
    local color=$1
    shift
    echo -e "${color}${BOLD}$@${NC}"
}

# Print step header
print_step() {
    echo ""
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$MAGENTA" "STEP: $1"
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Print success message
print_success() {
    print_message "$GREEN" "✓ $1"
}

# Print error message
print_error() {
    print_message "$RED" "✗ ERROR: $1"
}

# Print warning message
print_warning() {
    print_message "$YELLOW" "⚠ WARNING: $1"
}

# Print info message
print_info() {
    print_message "$BLUE" "ℹ $1"
}

# Log message to file
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if step is already completed
is_step_completed() {
    local step=$1
    if [ -f "$STATE_FILE" ] && grep -q "^${step}$" "$STATE_FILE"; then
        return 0
    fi
    return 1
}

# Mark step as completed
mark_step_completed() {
    local step=$1
    echo "$step" >> "$STATE_FILE"
    log_message "Completed: $step"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect PHP version
detect_php_version() {
    if [ -z "$PHP_VERSION" ]; then
        if command -v php >/dev/null 2>&1; then
            PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
            print_info "Detected PHP version: $PHP_VERSION"
        else
            # Default to 8.1 if not installed yet
            PHP_VERSION="8.1"
            print_info "Will install PHP $PHP_VERSION"
        fi
    fi
}

# Prompt for configuration
prompt_configuration() {
    print_step "Configuration Setup"
    
    if [ -z "$DOMAIN" ]; then
        read -p "Enter your domain name (e.g., moodle.example.com): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            print_warning "No domain provided. Using localhost (you can change this later)"
            DOMAIN="localhost"
        fi
    fi
    
    if [ -z "$DB_PASSWORD" ]; then
        while true; do
            read -sp "Enter MySQL password for moodleuser: " DB_PASSWORD
            echo
            read -sp "Confirm MySQL password: " DB_PASSWORD_CONFIRM
            echo
            if [ "$DB_PASSWORD" = "$DB_PASSWORD_CONFIRM" ]; then
                break
            else
                print_error "Passwords do not match. Please try again."
            fi
        done
    fi
    
    print_info "Domain: $DOMAIN"
    print_info "Database: $DB_NAME"
    print_info "DB User: $DB_USER"
    print_info "Moodle Directory: $MOODLE_DIR"
    print_info "Data Directory: $MOODLE_DATA"
    
    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
}

################################################################################
# Installation Steps
################################################################################

# Step 1: Update system
step_update_system() {
    local step="update_system"
    print_step "1. Updating System Packages"
    
    if is_step_completed "$step"; then
        print_success "System already updated (skipping)"
        return 0
    fi
    
    print_info "Running apt update and upgrade..."
    if apt update >> "$LOG_FILE" 2>&1 && apt upgrade -y >> "$LOG_FILE" 2>&1; then
        print_success "System updated successfully"
        mark_step_completed "$step"
    else
        print_error "Failed to update system"
        print_info "Attempting to fix broken packages..."
        apt --fix-broken install -y >> "$LOG_FILE" 2>&1
        dpkg --configure -a >> "$LOG_FILE" 2>&1
        apt update >> "$LOG_FILE" 2>&1
        print_success "Fixed package issues, continuing..."
        mark_step_completed "$step"
    fi
}

# Step 2: Install Nginx
step_install_nginx() {
    local step="install_nginx"
    print_step "2. Installing Nginx"
    
    if is_step_completed "$step"; then
        print_success "Nginx already installed (skipping)"
        return 0
    fi
    
    if systemctl is-active --quiet nginx; then
        print_success "Nginx is already running"
        mark_step_completed "$step"
        return 0
    fi
    
    print_info "Installing Nginx web server..."
    if apt install nginx -y >> "$LOG_FILE" 2>&1; then
        systemctl enable nginx >> "$LOG_FILE" 2>&1
        systemctl start nginx >> "$LOG_FILE" 2>&1
        
        # Verify installation
        if systemctl is-active --quiet nginx; then
            print_success "Nginx installed and running"
            print_info "Version: $(nginx -v 2>&1 | cut -d'/' -f2)"
            mark_step_completed "$step"
        else
            print_error "Nginx installed but not running"
            print_info "Attempting to start Nginx..."
            systemctl start nginx
            sleep 2
            if systemctl is-active --quiet nginx; then
                print_success "Nginx started successfully"
                mark_step_completed "$step"
            else
                print_error "Could not start Nginx. Check logs: journalctl -xeu nginx"
                exit 1
            fi
        fi
    else
        print_error "Failed to install Nginx"
        exit 1
    fi
}

# Step 3: Install MariaDB
step_install_mariadb() {
    local step="install_mariadb"
    print_step "3. Installing MariaDB"
    
    if is_step_completed "$step"; then
        print_success "MariaDB already installed (skipping)"
        return 0
    fi
    
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_success "MariaDB/MySQL is already running"
        mark_step_completed "$step"
        return 0
    fi
    
    print_info "Installing MariaDB server..."
    if apt install mariadb-server mariadb-client -y >> "$LOG_FILE" 2>&1; then
        systemctl enable mariadb >> "$LOG_FILE" 2>&1
        systemctl start mariadb >> "$LOG_FILE" 2>&1
        
        # Verify installation
        if systemctl is-active --quiet mariadb; then
            print_success "MariaDB installed and running"
            print_info "Version: $(mysql --version | cut -d' ' -f6)"
            mark_step_completed "$step"
        else
            print_error "MariaDB installed but not running"
            print_info "Attempting to start MariaDB..."
            systemctl start mariadb
            sleep 2
            if systemctl is-active --quiet mariadb; then
                print_success "MariaDB started successfully"
                mark_step_completed "$step"
            else
                print_error "Could not start MariaDB. Check logs: journalctl -xeu mariadb"
                exit 1
            fi
        fi
    else
        print_error "Failed to install MariaDB"
        exit 1
    fi
}

# Step 4: Secure MariaDB
step_secure_mariadb() {
    local step="secure_mariadb"
    print_step "4. Securing MariaDB Installation"
    
    if is_step_completed "$step"; then
        print_success "MariaDB already secured (skipping)"
        return 0
    fi
    
    print_info "Running mysql_secure_installation automation..."
    
    # Set root password and secure installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';" 2>/dev/null || \
    mysql -u root -p"${DB_PASSWORD}" -e "SELECT 1;" 2>/dev/null || \
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('${DB_PASSWORD}') WHERE User='root';" 2>/dev/null
    
    mysql -u root -p"${DB_PASSWORD}" <<EOF >> "$LOG_FILE" 2>&1
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "MariaDB secured successfully"
        mark_step_completed "$step"
    else
        print_warning "Some security steps may have already been completed"
        mark_step_completed "$step"
    fi
}

# Step 5: Create Moodle Database
step_create_database() {
    local step="create_database"
    print_step "5. Creating Moodle Database and User"
    
    if is_step_completed "$step"; then
        print_success "Database already created (skipping)"
        return 0
    fi
    
    print_info "Creating database: $DB_NAME"
    print_info "Creating user: $DB_USER"
    
    # Check if database already exists
    if mysql -u root -p"${DB_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
        print_warning "Database ${DB_NAME} already exists"
    else
        mysql -u root -p"${DB_PASSWORD}" <<EOF >> "$LOG_FILE" 2>&1
CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF
        if [ $? -eq 0 ]; then
            print_success "Database created successfully"
        else
            print_error "Failed to create database"
            exit 1
        fi
    fi
    
    # Create user and grant privileges
    mysql -u root -p"${DB_PASSWORD}" <<EOF >> "$LOG_FILE" 2>&1
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Database user created and privileges granted"
        
        # Verify user can connect
        if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
            print_success "Database connection verified"
            mark_step_completed "$step"
        else
            print_error "Could not verify database connection"
            exit 1
        fi
    else
        print_error "Failed to create database user"
        exit 1
    fi
}

# Step 6: Install PHP
step_install_php() {
    local step="install_php"
    print_step "6. Installing PHP and Extensions"
    
    if is_step_completed "$step"; then
        print_success "PHP already installed (skipping)"
        return 0
    fi
    
    detect_php_version
    
    print_info "Installing PHP ${PHP_VERSION} and required extensions..."
    
    local php_packages="php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-xml \
php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-zip \
php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-soap \
php${PHP_VERSION}-xmlrpc php${PHP_VERSION}-ldap"
    
    if apt install $php_packages -y >> "$LOG_FILE" 2>&1; then
        print_success "PHP and extensions installed"
        
        # Verify PHP installation
        if command -v php >/dev/null 2>&1; then
            print_info "PHP Version: $(php -v | head -n1)"
            
            # Check extensions
            print_info "Verifying required extensions..."
            local required_exts="curl gd intl mbstring mysqli soap xml xmlrpc zip"
            local missing_exts=""
            
            for ext in $required_exts; do
                if php -m | grep -qi "^${ext}$"; then
                    print_success "Extension $ext: OK"
                else
                    print_warning "Extension $ext: MISSING"
                    missing_exts="$missing_exts $ext"
                fi
            done
            
            if [ -n "$missing_exts" ]; then
                print_warning "Some extensions are missing:$missing_exts"
                print_info "Attempting to install missing extensions..."
                for ext in $missing_exts; do
                    apt install php${PHP_VERSION}-${ext} -y >> "$LOG_FILE" 2>&1
                done
            fi
            
            # Start PHP-FPM
            systemctl enable php${PHP_VERSION}-fpm >> "$LOG_FILE" 2>&1
            systemctl start php${PHP_VERSION}-fpm >> "$LOG_FILE" 2>&1
            
            if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
                print_success "PHP-FPM is running"
                mark_step_completed "$step"
            else
                print_error "PHP-FPM failed to start"
                exit 1
            fi
        else
            print_error "PHP installation verification failed"
            exit 1
        fi
    else
        print_error "Failed to install PHP"
        exit 1
    fi
}

# Step 7: Configure PHP
step_configure_php() {
    local step="configure_php"
    print_step "7. Configuring PHP for Moodle"
    
    if is_step_completed "$step"; then
        print_success "PHP already configured (skipping)"
        return 0
    fi
    
    detect_php_version
    local php_ini="/etc/php/${PHP_VERSION}/fpm/php.ini"
    
    if [ ! -f "$php_ini" ]; then
        print_error "PHP configuration file not found: $php_ini"
        exit 1
    fi
    
    print_info "Backing up original php.ini..."
    cp "$php_ini" "${php_ini}.backup.$(date +%Y%m%d-%H%M%S)"
    
    print_info "Updating PHP settings..."
    
    # Update PHP settings
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$php_ini"
    sed -i 's/^max_input_time = .*/max_input_time = 300/' "$php_ini"
    sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$php_ini"
    sed -i 's/^post_max_size = .*/post_max_size = 512M/' "$php_ini"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' "$php_ini"
    
    # Verify changes
    print_info "Verifying PHP configuration..."
    local errors=0
    
    if grep -q "^max_execution_time = 300" "$php_ini"; then
        print_success "max_execution_time: 300"
    else
        print_error "Failed to set max_execution_time"
        errors=$((errors + 1))
    fi
    
    if grep -q "^memory_limit = 256M" "$php_ini"; then
        print_success "memory_limit: 256M"
    else
        print_error "Failed to set memory_limit"
        errors=$((errors + 1))
    fi
    
    if grep -q "^upload_max_filesize = 512M" "$php_ini"; then
        print_success "upload_max_filesize: 512M"
    else
        print_error "Failed to set upload_max_filesize"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "PHP configuration updated successfully"
        
        # Restart PHP-FPM
        print_info "Restarting PHP-FPM..."
        systemctl restart php${PHP_VERSION}-fpm
        
        if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
            print_success "PHP-FPM restarted successfully"
            mark_step_completed "$step"
        else
            print_error "PHP-FPM failed to restart"
            exit 1
        fi
    else
        print_error "Failed to configure PHP properly"
        exit 1
    fi
}

# Step 8: Download Moodle
step_download_moodle() {
    local step="download_moodle"
    print_step "8. Downloading Moodle"
    
    if is_step_completed "$step"; then
        print_success "Moodle already downloaded (skipping)"
        return 0
    fi
    
    if [ -d "$MOODLE_DIR" ] && [ -f "$MOODLE_DIR/version.php" ]; then
        print_success "Moodle directory already exists"
        mark_step_completed "$step"
        return 0
    fi
    
    print_info "Downloading Moodle 4.4 (latest stable)..."
    
    cd /tmp
    
    # Try wget first, then curl
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz 2>&1 | tee -a "$LOG_FILE"
    elif command -v curl >/dev/null 2>&1; then
        curl -# -L -o moodle-latest-404.tgz https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz 2>&1 | tee -a "$LOG_FILE"
    else
        print_error "Neither wget nor curl is available"
        print_info "Installing wget..."
        apt install wget -y >> "$LOG_FILE" 2>&1
        wget -q --show-progress https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz 2>&1 | tee -a "$LOG_FILE"
    fi
    
    if [ ! -f "moodle-latest-404.tgz" ]; then
        print_error "Failed to download Moodle"
        exit 1
    fi
    
    print_info "Extracting Moodle..."
    tar -zxf moodle-latest-404.tgz >> "$LOG_FILE" 2>&1
    
    if [ ! -d "moodle" ]; then
        print_error "Failed to extract Moodle"
        exit 1
    fi
    
    print_info "Moving Moodle to $MOODLE_DIR..."
    mkdir -p /var/www/html
    mv moodle "$MOODLE_DIR"
    
    if [ -f "$MOODLE_DIR/version.php" ]; then
        print_success "Moodle downloaded and extracted successfully"
        
        # Get Moodle version
        local moodle_version=$(grep '$release' "$MOODLE_DIR/version.php" | head -n1 | sed "s/.*'\(.*\)'.*/\1/")
        print_info "Moodle Version: $moodle_version"
        
        mark_step_completed "$step"
    else
        print_error "Moodle installation appears incomplete"
        exit 1
    fi
    
    # Cleanup
    cd /tmp
    rm -f moodle-latest-404.tgz
}

# Step 9: Create Data Directory
step_create_datadir() {
    local step="create_datadir"
    print_step "9. Creating Moodle Data Directory"
    
    if is_step_completed "$step"; then
        print_success "Data directory already created (skipping)"
        return 0
    fi
    
    if [ -d "$MOODLE_DATA" ]; then
        print_warning "Data directory already exists"
    else
        print_info "Creating $MOODLE_DATA..."
        mkdir -p "$MOODLE_DATA"
    fi
    
    print_info "Setting ownership and permissions..."
    chown -R www-data:www-data "$MOODLE_DATA"
    chmod -R 755 "$MOODLE_DATA"
    
    # Verify
    if [ -d "$MOODLE_DATA" ]; then
        local owner=$(stat -c '%U:%G' "$MOODLE_DATA")
        local perms=$(stat -c '%a' "$MOODLE_DATA")
        
        if [ "$owner" = "www-data:www-data" ] && [ "$perms" = "755" ]; then
            print_success "Data directory created successfully"
            print_info "Owner: $owner"
            print_info "Permissions: $perms"
            
            # Test write permission
            if sudo -u www-data touch "$MOODLE_DATA/test.txt" 2>/dev/null; then
                rm -f "$MOODLE_DATA/test.txt"
                print_success "Write permissions verified"
                mark_step_completed "$step"
            else
                print_error "www-data cannot write to data directory"
                exit 1
            fi
        else
            print_error "Incorrect ownership or permissions"
            print_info "Fixing ownership and permissions..."
            chown -R www-data:www-data "$MOODLE_DATA"
            chmod -R 755 "$MOODLE_DATA"
            mark_step_completed "$step"
        fi
    else
        print_error "Failed to create data directory"
        exit 1
    fi
}

# Step 10: Set Permissions
step_set_permissions() {
    local step="set_permissions"
    print_step "10. Setting Moodle File Permissions"
    
    if is_step_completed "$step"; then
        print_success "Permissions already set (skipping)"
        return 0
    fi
    
    if [ ! -d "$MOODLE_DIR" ]; then
        print_error "Moodle directory not found: $MOODLE_DIR"
        exit 1
    fi
    
    print_info "Setting ownership to www-data:www-data..."
    chown -R www-data:www-data "$MOODLE_DIR"
    
    print_info "Setting permissions to 755..."
    chmod -R 755 "$MOODLE_DIR"
    
    # Verify
    local owner=$(stat -c '%U:%G' "$MOODLE_DIR")
    local perms=$(stat -c '%a' "$MOODLE_DIR")
    
    if [ "$owner" = "www-data:www-data" ]; then
        print_success "Ownership set correctly: $owner"
    else
        print_warning "Ownership may not be correct: $owner"
    fi
    
    print_success "Permissions configured"
    mark_step_completed "$step"
}

# Step 11: Configure Nginx
step_configure_nginx() {
    local step="configure_nginx"
    print_step "11. Configuring Nginx for Moodle"
    
    if is_step_completed "$step"; then
        print_success "Nginx already configured (skipping)"
        return 0
    fi
    
    detect_php_version
    local nginx_config="/etc/nginx/sites-available/moodle"
    local php_sock="/var/run/php/php${PHP_VERSION}-fpm.sock"
    
    # Check if PHP socket exists
    if [ ! -S "$php_sock" ]; then
        print_warning "PHP-FPM socket not found: $php_sock"
        print_info "Looking for alternative socket..."
        php_sock=$(find /var/run/php/ -name "php*-fpm.sock" | head -n1)
        if [ -n "$php_sock" ]; then
            print_info "Using socket: $php_sock"
        else
            print_error "No PHP-FPM socket found"
            exit 1
        fi
    fi
    
    print_info "Creating Nginx configuration..."
    
    cat > "$nginx_config" <<EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    root ${MOODLE_DIR};
    index index.php index.html index.htm;

    client_max_body_size 512M;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ [^/]\.php(/|\$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${php_sock};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS off;
        
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    
    location /dataroot/ {
        internal;
        alias ${MOODLE_DATA}/;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    print_success "Nginx configuration created"
    
    # Enable site
    if [ ! -L "/etc/nginx/sites-enabled/moodle" ]; then
        print_info "Enabling Moodle site..."
        ln -s "$nginx_config" /etc/nginx/sites-enabled/moodle
    fi
    
    # Disable default site if exists
    if [ -L "/etc/nginx/sites-enabled/default" ]; then
        print_info "Disabling default site..."
        rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Test configuration
    print_info "Testing Nginx configuration..."
    if nginx -t >> "$LOG_FILE" 2>&1; then
        print_success "Nginx configuration is valid"
        
        # Reload Nginx
        print_info "Reloading Nginx..."
        systemctl reload nginx
        
        if systemctl is-active --quiet nginx; then
            print_success "Nginx reloaded successfully"
            mark_step_completed "$step"
        else
            print_error "Nginx failed to reload"
            print_info "Checking logs: "
            tail -n 20 /var/log/nginx/error.log
            exit 1
        fi
    else
        print_error "Nginx configuration test failed"
        nginx -t
        exit 1
    fi
}

# Step 12: Configure Firewall
step_configure_firewall() {
    local step="configure_firewall"
    print_step "12. Configuring Firewall"
    
    if is_step_completed "$step"; then
        print_success "Firewall already configured (skipping)"
        return 0
    fi
    
    if ! command -v ufw >/dev/null 2>&1; then
        print_info "Installing UFW..."
        apt install ufw -y >> "$LOG_FILE" 2>&1
    fi
    
    print_info "Configuring firewall rules..."
    
    # Allow SSH first (critical!)
    ufw allow OpenSSH >> "$LOG_FILE" 2>&1
    print_success "Allowed: OpenSSH"
    
    # Allow Nginx
    ufw allow 'Nginx Full' >> "$LOG_FILE" 2>&1
    print_success "Allowed: Nginx Full (HTTP & HTTPS)"
    
    # Enable UFW
    print_info "Enabling firewall..."
    echo "y" | ufw enable >> "$LOG_FILE" 2>&1
    
    # Verify
    if ufw status | grep -q "Status: active"; then
        print_success "Firewall enabled and configured"
        ufw status | grep -E "OpenSSH|Nginx" | while read line; do
            print_info "  $line"
        done
        mark_step_completed "$step"
    else
        print_warning "Firewall may not be active"
        mark_step_completed "$step"
    fi
}

# Step 13: Setup Cron
step_setup_cron() {
    local step="setup_cron"
    print_step "13. Setting Up Cron Job"
    
    if is_step_completed "$step"; then
        print_success "Cron already configured (skipping)"
        return 0
    fi
    
    print_info "Configuring Moodle cron job..."
    
    # Check if cron entry already exists
    if crontab -u www-data -l 2>/dev/null | grep -q "admin/cli/cron.php"; then
        print_success "Cron job already exists"
        mark_step_completed "$step"
        return 0
    fi
    
    # Add cron job
    (crontab -u www-data -l 2>/dev/null; echo "* * * * * /usr/bin/php ${MOODLE_DIR}/admin/cli/cron.php >/dev/null") | crontab -u www-data -
    
    # Verify
    if crontab -u www-data -l 2>/dev/null | grep -q "admin/cli/cron.php"; then
        print_success "Cron job configured successfully"
        print_info "Moodle cron will run every minute"
        mark_step_completed "$step"
    else
        print_error "Failed to configure cron job"
        exit 1
    fi
}

# Step 14: Final Checks
step_final_checks() {
    local step="final_checks"
    print_step "14. Running Final System Checks"
    
    if is_step_completed "$step"; then
        print_success "Final checks already completed (skipping)"
        return 0
    fi
    
    print_info "Verifying installation..."
    
    local errors=0
    
    # Check Nginx
    if systemctl is-active --quiet nginx; then
        print_success "Nginx: Running"
    else
        print_error "Nginx: Not running"
        errors=$((errors + 1))
    fi
    
    # Check MariaDB
    if systemctl is-active --quiet mariadb; then
        print_success "MariaDB: Running"
    else
        print_error "MariaDB: Not running"
        errors=$((errors + 1))
    fi
    
    # Check PHP-FPM
    detect_php_version
    if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
        print_success "PHP-FPM: Running"
    else
        print_error "PHP-FPM: Not running"
        errors=$((errors + 1))
    fi
    
    # Check Moodle directory
    if [ -d "$MOODLE_DIR" ] && [ -f "$MOODLE_DIR/version.php" ]; then
        print_success "Moodle directory: OK"
    else
        print_error "Moodle directory: Problem detected"
        errors=$((errors + 1))
    fi
    
    # Check data directory
    if [ -d "$MOODLE_DATA" ] && [ -w "$MOODLE_DATA" ]; then
        print_success "Data directory: OK"
    else
        print_error "Data directory: Problem detected"
        errors=$((errors + 1))
    fi
    
    # Check database connection
    if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
        print_success "Database connection: OK"
    else
        print_error "Database connection: Failed"
        errors=$((errors + 1))
    fi
    
    # Check Nginx configuration
    if nginx -t >> "$LOG_FILE" 2>&1; then
        print_success "Nginx configuration: Valid"
    else
        print_error "Nginx configuration: Invalid"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "All system checks passed!"
        mark_step_completed "$step"
    else
        print_error "Found $errors issue(s). Please review and fix."
        exit 1
    fi
}

################################################################################
# Main Installation Function
################################################################################

main() {
    clear
    print_message "$MAGENTA" "╔════════════════════════════════════════════════════════════════════════════╗"
    print_message "$MAGENTA" "║                                                                            ║"
    print_message "$MAGENTA" "║              MOODLE INSTALLATION SCRIPT FOR UBUNTU + NGINX                 ║"
    print_message "$MAGENTA" "║                                                                            ║"
    print_message "$MAGENTA" "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if running as root
    check_root
    
    # Initialize log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    log_message "===== Moodle Installation Started ====="
    
    # Check if resuming installation
    if [ -f "$STATE_FILE" ]; then
        print_warning "Found existing installation state. Resuming from where we left off..."
        print_info "State file: $STATE_FILE"
        echo ""
        sleep 2
    else
        print_info "Starting fresh installation..."
        touch "$STATE_FILE"
        echo ""
    fi
    
    # Prompt for configuration
    if ! is_step_completed "configuration"; then
        prompt_configuration
        mark_step_completed "configuration"
    else
        print_info "Using existing configuration"
        # Try to load config from previous run
        if [ -f "/root/.moodle_install_config" ]; then
            source /root/.moodle_install_config
        fi
    fi
    
    # Save configuration
    cat > /root/.moodle_install_config <<EOF
DOMAIN="$DOMAIN"
DB_PASSWORD="$DB_PASSWORD"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
MOODLE_DIR="$MOODLE_DIR"
MOODLE_DATA="$MOODLE_DATA"
EOF
    chmod 600 /root/.moodle_install_config
    
    echo ""
    print_message "$CYAN" "Starting installation process..."
    echo ""
    sleep 1
    
    # Run installation steps
    step_update_system
    step_install_nginx
    step_install_mariadb
    step_secure_mariadb
    step_create_database
    step_install_php
    step_configure_php
    step_download_moodle
    step_create_datadir
    step_set_permissions
    step_configure_nginx
    step_configure_firewall
    step_setup_cron
    step_final_checks
    
    # Print completion message
    echo ""
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$GREEN" "╔════════════════════════════════════════════════════════════════════════════╗"
    print_message "$GREEN" "║                                                                            ║"
    print_message "$GREEN" "║                    ✓ INSTALLATION COMPLETED SUCCESSFULLY!                  ║"
    print_message "$GREEN" "║                                                                            ║"
    print_message "$GREEN" "╚════════════════════════════════════════════════════════════════════════════╝"
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    print_message "$BOLD" "📋 INSTALLATION SUMMARY"
    echo ""
    print_info "Domain: http://${DOMAIN}"
    print_info "Moodle Directory: $MOODLE_DIR"
    print_info "Data Directory: $MOODLE_DATA"
    print_info "Database Name: $DB_NAME"
    print_info "Database User: $DB_USER"
    echo ""
    
    print_message "$BOLD" "🚀 NEXT STEPS"
    echo ""
    print_message "$YELLOW" "1. Complete web installation:"
    print_info "   Visit: http://${DOMAIN}"
    print_info "   Follow the Moodle installation wizard"
    echo ""
    print_message "$YELLOW" "2. Use these database credentials:"
    print_info "   Database host: localhost"
    print_info "   Database name: $DB_NAME"
    print_info "   Database user: $DB_USER"
    print_info "   Database password: [the password you entered]"
    print_info "   Tables prefix: mdl_"
    echo ""
    print_message "$YELLOW" "3. After web installation completes:"
    print_info "   - Secure config.php: chmod 444 ${MOODLE_DIR}/config.php"
    print_info "   - Consider installing SSL: apt install certbot python3-certbot-nginx"
    print_info "   - Then run: certbot --nginx -d ${DOMAIN}"
    echo ""
    
    print_message "$BOLD" "📝 IMPORTANT FILES"
    echo ""
    print_info "Log file: $LOG_FILE"
    print_info "State file: $STATE_FILE"
    print_info "Config backup: /root/.moodle_install_config"
    echo ""
    
    print_message "$BOLD" "🔍 TROUBLESHOOTING"
    echo ""
    print_info "If you encounter issues:"
    print_info "  - Check logs: tail -f $LOG_FILE"
    print_info "  - Check Nginx logs: tail -f /var/log/nginx/error.log"
    print_info "  - Check PHP logs: tail -f /var/log/php${PHP_VERSION}-fpm.log"
    print_info "  - Re-run this script: It will resume from where it left off"
    echo ""
    
    print_message "$GREEN" "Thank you for using the Moodle Installation Script!"
    print_message "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_message "===== Moodle Installation Completed Successfully ====="
}

# Run main function
main "$@"
