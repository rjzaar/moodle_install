#!/bin/bash

################################################################################
# Moodle Installation Troubleshooter
#
# This script diagnoses and fixes common issues with Moodle installations
# on Ubuntu with Nginx, MariaDB, and PHP
#
# Usage: sudo ./troubleshoot-moodle.sh
#
# Author: Troubleshooting Companion Script
# Version: 1.0
################################################################################

set +e  # Don't exit on errors (we're troubleshooting!)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
MOODLE_DIR="/var/www/html/moodle"
MOODLE_DATA="/var/moodledata"
CONFIG_FILE="/root/.moodle_install_config"
REPORT_FILE="/tmp/moodle_diagnostic_report_$(date +%Y%m%d_%H%M%S).txt"

# Initialize report
init_report() {
    cat > "$REPORT_FILE" <<EOF
═══════════════════════════════════════════════════════════════════════════
                    MOODLE DIAGNOSTIC REPORT
                    Generated: $(date)
═══════════════════════════════════════════════════════════════════════════

EOF
}

# Print and log message
log_report() {
    echo "$1" | tee -a "$REPORT_FILE"
}

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}${BOLD}$@${NC}"
}

print_success() { print_msg "$GREEN" "✓ $1"; }
print_error() { print_msg "$RED" "✗ $1"; }
print_warning() { print_msg "$YELLOW" "⚠ $1"; }
print_info() { print_msg "$BLUE" "ℹ $1"; }
print_header() { print_msg "$CYAN" "━━━ $1 ━━━"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Detect PHP version
detect_php_version() {
    if command -v php >/dev/null 2>&1; then
        PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    else
        PHP_VERSION="not installed"
    fi
}

################################################################################
# Diagnostic Functions
################################################################################

check_system_info() {
    print_header "System Information"
    log_report ""
    log_report "System Information"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    log_report "OS: $(lsb_release -d | cut -f2)"
    log_report "Kernel: $(uname -r)"
    log_report "Hostname: $(hostname)"
    log_report "Uptime: $(uptime -p)"
    
    local total_mem=$(free -h | awk '/^Mem:/ {print $2}')
    local used_mem=$(free -h | awk '/^Mem:/ {print $3}')
    log_report "Memory: $used_mem / $total_mem"
    
    local disk_usage=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')
    log_report "Disk Usage: $disk_usage"
    
    echo ""
}

check_services() {
    print_header "Service Status"
    log_report ""
    log_report "Service Status"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check Nginx
    if systemctl is-active --quiet nginx; then
        print_success "Nginx: Running"
        log_report "✓ Nginx: Running"
    else
        print_error "Nginx: NOT RUNNING"
        log_report "✗ Nginx: NOT RUNNING"
        issues=$((issues + 1))
        
        print_info "  Attempting to start Nginx..."
        if systemctl start nginx 2>/dev/null; then
            print_success "  Nginx started successfully"
        else
            print_error "  Failed to start Nginx"
            print_info "  Check logs: sudo journalctl -xeu nginx"
        fi
    fi
    
    # Check MariaDB/MySQL
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_success "MariaDB: Running"
        log_report "✓ MariaDB: Running"
    else
        print_error "MariaDB: NOT RUNNING"
        log_report "✗ MariaDB: NOT RUNNING"
        issues=$((issues + 1))
        
        print_info "  Attempting to start MariaDB..."
        if systemctl start mariadb 2>/dev/null; then
            print_success "  MariaDB started successfully"
        else
            print_error "  Failed to start MariaDB"
            print_info "  Check logs: sudo journalctl -xeu mariadb"
        fi
    fi
    
    # Check PHP-FPM
    detect_php_version
    if [ "$PHP_VERSION" != "not installed" ]; then
        if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
            print_success "PHP-FPM $PHP_VERSION: Running"
            log_report "✓ PHP-FPM $PHP_VERSION: Running"
        else
            print_error "PHP-FPM $PHP_VERSION: NOT RUNNING"
            log_report "✗ PHP-FPM $PHP_VERSION: NOT RUNNING"
            issues=$((issues + 1))
            
            print_info "  Attempting to start PHP-FPM..."
            if systemctl start php${PHP_VERSION}-fpm 2>/dev/null; then
                print_success "  PHP-FPM started successfully"
            else
                print_error "  Failed to start PHP-FPM"
                print_info "  Check logs: sudo journalctl -xeu php${PHP_VERSION}-fpm"
            fi
        fi
    else
        print_error "PHP: NOT INSTALLED"
        log_report "✗ PHP: NOT INSTALLED"
        issues=$((issues + 1))
    fi
    
    echo ""
    return $issues
}

check_php_configuration() {
    print_header "PHP Configuration"
    log_report ""
    log_report "PHP Configuration"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    detect_php_version
    
    if [ "$PHP_VERSION" = "not installed" ]; then
        print_error "PHP is not installed"
        log_report "✗ PHP is not installed"
        return 1
    fi
    
    print_info "PHP Version: $PHP_VERSION"
    log_report "PHP Version: $PHP_VERSION"
    
    # Check PHP settings
    local issues=0
    
    local max_exec=$(php -r "echo ini_get('max_execution_time');")
    if [ "$max_exec" -ge 300 ]; then
        print_success "max_execution_time: $max_exec (OK)"
        log_report "✓ max_execution_time: $max_exec"
    else
        print_warning "max_execution_time: $max_exec (Should be 300+)"
        log_report "⚠ max_execution_time: $max_exec (Should be 300+)"
        issues=$((issues + 1))
    fi
    
    local mem_limit=$(php -r "echo ini_get('memory_limit');")
    log_report "memory_limit: $mem_limit"
    if [[ "$mem_limit" =~ ^[0-9]+M$ ]] && [ "${mem_limit%M}" -ge 256 ]; then
        print_success "memory_limit: $mem_limit (OK)"
    elif [ "$mem_limit" = "-1" ]; then
        print_warning "memory_limit: unlimited (Consider setting to 256M)"
        log_report "⚠ memory_limit: unlimited"
    else
        print_warning "memory_limit: $mem_limit (Should be 256M+)"
        log_report "⚠ memory_limit: $mem_limit (Should be 256M+)"
        issues=$((issues + 1))
    fi
    
    local upload_max=$(php -r "echo ini_get('upload_max_filesize');")
    log_report "upload_max_filesize: $upload_max"
    if [[ "$upload_max" =~ ^[0-9]+M$ ]] && [ "${upload_max%M}" -ge 512 ]; then
        print_success "upload_max_filesize: $upload_max (OK)"
    else
        print_warning "upload_max_filesize: $upload_max (Should be 512M+)"
        log_report "⚠ upload_max_filesize: $upload_max (Should be 512M+)"
        issues=$((issues + 1))
    fi
    
    # Check required extensions
    print_info "Checking PHP extensions..."
    local required_exts="curl gd intl mbstring mysqli soap xml xmlrpc zip"
    local missing_exts=""
    
    for ext in $required_exts; do
        if php -m | grep -qi "^${ext}$"; then
            print_success "  $ext: Installed"
            log_report "✓ Extension $ext: Installed"
        else
            print_error "  $ext: MISSING"
            log_report "✗ Extension $ext: MISSING"
            missing_exts="$missing_exts $ext"
            issues=$((issues + 1))
        fi
    done
    
    if [ -n "$missing_exts" ]; then
        print_warning "Missing extensions:$missing_exts"
        read -p "Attempt to install missing extensions? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for ext in $missing_exts; do
                print_info "Installing php${PHP_VERSION}-${ext}..."
                apt install php${PHP_VERSION}-${ext} -y
            done
            systemctl restart php${PHP_VERSION}-fpm
            print_success "Extensions installed. PHP-FPM restarted."
        fi
    fi
    
    echo ""
    return $issues
}

check_nginx_configuration() {
    print_header "Nginx Configuration"
    log_report ""
    log_report "Nginx Configuration"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check if Nginx is installed
    if ! command -v nginx >/dev/null 2>&1; then
        print_error "Nginx is not installed"
        log_report "✗ Nginx is not installed"
        return 1
    fi
    
    print_info "Nginx Version: $(nginx -v 2>&1 | cut -d'/' -f2)"
    log_report "Nginx Version: $(nginx -v 2>&1 | cut -d'/' -f2)"
    
    # Check Moodle site configuration
    if [ -f "/etc/nginx/sites-available/moodle" ]; then
        print_success "Moodle site config exists"
        log_report "✓ Moodle site config exists"
        
        if [ -L "/etc/nginx/sites-enabled/moodle" ]; then
            print_success "Moodle site is enabled"
            log_report "✓ Moodle site is enabled"
        else
            print_error "Moodle site is NOT enabled"
            log_report "✗ Moodle site is NOT enabled"
            issues=$((issues + 1))
            
            read -p "Enable Moodle site? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/moodle
                print_success "Moodle site enabled"
            fi
        fi
    else
        print_error "Moodle site configuration not found"
        log_report "✗ Moodle site configuration not found"
        issues=$((issues + 1))
    fi
    
    # Test Nginx configuration
    print_info "Testing Nginx configuration..."
    if nginx -t 2>&1 | grep -q "successful"; then
        print_success "Nginx configuration is valid"
        log_report "✓ Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        log_report "✗ Nginx configuration has errors"
        nginx -t 2>&1 | tee -a "$REPORT_FILE"
        issues=$((issues + 1))
    fi
    
    # Check PHP-FPM socket
    detect_php_version
    local socket_path="/var/run/php/php${PHP_VERSION}-fpm.sock"
    if [ -S "$socket_path" ]; then
        print_success "PHP-FPM socket exists: $socket_path"
        log_report "✓ PHP-FPM socket exists: $socket_path"
    else
        print_error "PHP-FPM socket NOT found: $socket_path"
        log_report "✗ PHP-FPM socket NOT found: $socket_path"
        
        # Look for alternative socket
        local alt_socket=$(find /var/run/php/ -name "php*-fpm.sock" 2>/dev/null | head -n1)
        if [ -n "$alt_socket" ]; then
            print_warning "Found alternative socket: $alt_socket"
            log_report "⚠ Alternative socket: $alt_socket"
            print_info "You may need to update Nginx config to use this socket"
        fi
        issues=$((issues + 1))
    fi
    
    echo ""
    return $issues
}

check_database() {
    print_header "Database Configuration"
    log_report ""
    log_report "Database Configuration"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check if MariaDB is installed
    if ! command -v mysql >/dev/null 2>&1; then
        print_error "MariaDB/MySQL is not installed"
        log_report "✗ MariaDB/MySQL is not installed"
        return 1
    fi
    
    print_info "MySQL Version: $(mysql --version | cut -d' ' -f6)"
    log_report "MySQL Version: $(mysql --version | cut -d' ' -f6)"
    
    # Load config
    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
        print_warning "Database credentials not found in config"
        log_report "⚠ Database credentials not found in config"
        read -p "Enter database name [moodle]: " DB_NAME
        DB_NAME=${DB_NAME:-moodle}
        read -p "Enter database user [moodleuser]: " DB_USER
        DB_USER=${DB_USER:-moodleuser}
        read -sp "Enter database password: " DB_PASSWORD
        echo
    fi
    
    # Test root connection
    print_info "Testing root database connection..."
    if mysql -u root -p"${DB_PASSWORD}" -e "SELECT 1;" 2>/dev/null; then
        print_success "Root connection: OK"
        log_report "✓ Root connection: OK"
    else
        print_warning "Root connection with provided password failed"
        log_report "⚠ Root connection failed"
    fi
    
    # Test database existence
    print_info "Checking if database exists..."
    if mysql -u root -p"${DB_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
        print_success "Database '${DB_NAME}' exists"
        log_report "✓ Database '${DB_NAME}' exists"
        
        # Count tables
        local table_count=$(mysql -u root -p"${DB_PASSWORD}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null | tail -n1)
        print_info "  Tables in database: $table_count"
        log_report "  Tables: $table_count"
        
        if [ "$table_count" -eq 0 ]; then
            print_warning "  Database is empty (Moodle not installed yet)"
            log_report "⚠ Database is empty"
        fi
    else
        print_error "Database '${DB_NAME}' does NOT exist"
        log_report "✗ Database '${DB_NAME}' does NOT exist"
        issues=$((issues + 1))
        
        read -p "Create database? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mysql -u root -p"${DB_PASSWORD}" -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            print_success "Database created"
        fi
    fi
    
    # Test user connection
    print_info "Testing user database connection..."
    if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
        print_success "User '${DB_USER}' can connect and access database"
        log_report "✓ User '${DB_USER}' connection: OK"
    else
        print_error "User '${DB_USER}' cannot connect or access database"
        log_report "✗ User '${DB_USER}' connection: FAILED"
        issues=$((issues + 1))
        
        read -p "Recreate database user with correct privileges? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mysql -u root -p"${DB_PASSWORD}" <<EOF
DROP USER IF EXISTS '${DB_USER}'@'localhost';
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
            if [ $? -eq 0 ]; then
                print_success "User recreated with correct privileges"
            else
                print_error "Failed to recreate user"
            fi
        fi
    fi
    
    echo ""
    return $issues
}

check_file_structure() {
    print_header "File Structure & Permissions"
    log_report ""
    log_report "File Structure & Permissions"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check Moodle directory
    if [ -d "$MOODLE_DIR" ]; then
        print_success "Moodle directory exists: $MOODLE_DIR"
        log_report "✓ Moodle directory exists: $MOODLE_DIR"
        
        if [ -f "$MOODLE_DIR/version.php" ]; then
            print_success "Moodle appears complete (version.php found)"
            log_report "✓ Moodle files appear complete"
            
            local version=$(grep '$release' "$MOODLE_DIR/version.php" | head -n1 | sed "s/.*'\(.*\)'.*/\1/" 2>/dev/null)
            if [ -n "$version" ]; then
                print_info "  Moodle Version: $version"
                log_report "  Version: $version"
            fi
        else
            print_error "Moodle installation appears incomplete"
            log_report "✗ Moodle installation incomplete"
            issues=$((issues + 1))
        fi
        
        # Check ownership
        local owner=$(stat -c '%U:%G' "$MOODLE_DIR")
        if [ "$owner" = "www-data:www-data" ]; then
            print_success "Ownership: $owner (Correct)"
            log_report "✓ Ownership: $owner"
        else
            print_warning "Ownership: $owner (Should be www-data:www-data)"
            log_report "⚠ Ownership: $owner (Should be www-data:www-data)"
            issues=$((issues + 1))
            
            read -p "Fix ownership? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                chown -R www-data:www-data "$MOODLE_DIR"
                print_success "Ownership fixed"
            fi
        fi
        
        # Check permissions
        local perms=$(stat -c '%a' "$MOODLE_DIR")
        print_info "Permissions: $perms"
        log_report "Permissions: $perms"
        
    else
        print_error "Moodle directory NOT found: $MOODLE_DIR"
        log_report "✗ Moodle directory NOT found: $MOODLE_DIR"
        issues=$((issues + 1))
    fi
    
    # Check data directory
    if [ -d "$MOODLE_DATA" ]; then
        print_success "Data directory exists: $MOODLE_DATA"
        log_report "✓ Data directory exists: $MOODLE_DATA"
        
        local owner=$(stat -c '%U:%G' "$MOODLE_DATA")
        if [ "$owner" = "www-data:www-data" ]; then
            print_success "Ownership: $owner (Correct)"
            log_report "✓ Data dir ownership: $owner"
        else
            print_warning "Ownership: $owner (Should be www-data:www-data)"
            log_report "⚠ Data dir ownership: $owner"
            issues=$((issues + 1))
            
            read -p "Fix data directory ownership? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                chown -R www-data:www-data "$MOODLE_DATA"
                print_success "Ownership fixed"
            fi
        fi
        
        # Test write permissions
        if sudo -u www-data touch "$MOODLE_DATA/test.txt" 2>/dev/null; then
            rm -f "$MOODLE_DATA/test.txt"
            print_success "Write permissions: OK"
            log_report "✓ Write permissions: OK"
        else
            print_error "www-data cannot write to data directory"
            log_report "✗ Write permissions: FAILED"
            issues=$((issues + 1))
            
            read -p "Fix permissions? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                chmod -R 755 "$MOODLE_DATA"
                chown -R www-data:www-data "$MOODLE_DATA"
                print_success "Permissions fixed"
            fi
        fi
        
    else
        print_error "Data directory NOT found: $MOODLE_DATA"
        log_report "✗ Data directory NOT found: $MOODLE_DATA"
        issues=$((issues + 1))
        
        read -p "Create data directory? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$MOODLE_DATA"
            chown -R www-data:www-data "$MOODLE_DATA"
            chmod -R 755 "$MOODLE_DATA"
            print_success "Data directory created"
        fi
    fi
    
    # Check config.php
    if [ -f "$MOODLE_DIR/config.php" ]; then
        print_success "config.php exists"
        log_report "✓ config.php exists"
        
        local perms=$(stat -c '%a' "$MOODLE_DIR/config.php")
        if [ "$perms" = "444" ]; then
            print_success "config.php permissions: $perms (Read-only, secure)"
            log_report "✓ config.php: Read-only"
        else
            print_warning "config.php permissions: $perms (Should be 444 for security)"
            log_report "⚠ config.php permissions: $perms"
        fi
    else
        print_info "config.php not found (will be created during web install)"
        log_report "ℹ config.php not found (not installed yet)"
    fi
    
    echo ""
    return $issues
}

check_network_connectivity() {
    print_header "Network & Connectivity"
    log_report ""
    log_report "Network & Connectivity"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check if port 80 is listening
    if netstat -tuln 2>/dev/null | grep -q ":80 " || ss -tuln 2>/dev/null | grep -q ":80 "; then
        print_success "Port 80 (HTTP) is listening"
        log_report "✓ Port 80: Listening"
    else
        print_error "Port 80 (HTTP) is NOT listening"
        log_report "✗ Port 80: NOT listening"
        issues=$((issues + 1))
    fi
    
    # Check if port 443 is listening (optional)
    if netstat -tuln 2>/dev/null | grep -q ":443 " || ss -tuln 2>/dev/null | grep -q ":443 "; then
        print_success "Port 443 (HTTPS) is listening"
        log_report "✓ Port 443: Listening"
    else
        print_info "Port 443 (HTTPS) is not listening (SSL not configured yet)"
        log_report "ℹ Port 443: Not listening"
    fi
    
    # Check firewall status
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            print_success "UFW Firewall: Active"
            log_report "✓ UFW: Active"
            
            if ufw status | grep -q "Nginx"; then
                print_success "  Nginx rules: Configured"
                log_report "✓ Nginx firewall rules: OK"
            else
                print_warning "  Nginx rules: Not found"
                log_report "⚠ Nginx firewall rules: Missing"
                issues=$((issues + 1))
            fi
        else
            print_info "UFW Firewall: Inactive"
            log_report "ℹ UFW: Inactive"
        fi
    fi
    
    # Test local web server
    print_info "Testing local web server response..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
        print_success "Local web server responds correctly"
        log_report "✓ Local web server: Responding"
    else
        print_error "Local web server not responding correctly"
        log_report "✗ Local web server: Not responding"
        issues=$((issues + 1))
    fi
    
    echo ""
    return $issues
}

check_cron() {
    print_header "Cron Configuration"
    log_report ""
    log_report "Cron Configuration"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    local issues=0
    
    # Check if cron entry exists
    if crontab -u www-data -l 2>/dev/null | grep -q "admin/cli/cron.php"; then
        print_success "Moodle cron job is configured"
        log_report "✓ Moodle cron: Configured"
        
        print_info "Cron entry:"
        crontab -u www-data -l 2>/dev/null | grep "cron.php" | while read line; do
            print_info "  $line"
            log_report "  $line"
        done
    else
        print_error "Moodle cron job is NOT configured"
        log_report "✗ Moodle cron: NOT configured"
        issues=$((issues + 1))
        
        read -p "Configure Moodle cron? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            (crontab -u www-data -l 2>/dev/null; echo "* * * * * /usr/bin/php ${MOODLE_DIR}/admin/cli/cron.php >/dev/null") | crontab -u www-data -
            print_success "Cron configured"
        fi
    fi
    
    # Check recent cron activity
    print_info "Checking recent cron activity..."
    local recent_cron=$(grep CRON /var/log/syslog 2>/dev/null | grep www-data | tail -n 3)
    if [ -n "$recent_cron" ]; then
        print_success "Recent cron activity detected"
        log_report "✓ Recent cron activity found"
    else
        print_warning "No recent cron activity found"
        log_report "⚠ No recent cron activity"
    fi
    
    echo ""
    return $issues
}

check_logs_for_errors() {
    print_header "Recent Log Errors"
    log_report ""
    log_report "Recent Log Errors"
    log_report "─────────────────────────────────────────────────────────────────────"
    
    # Nginx errors
    if [ -f "/var/log/nginx/error.log" ]; then
        local nginx_errors=$(tail -n 50 /var/log/nginx/error.log 2>/dev/null | grep -i "error" | tail -n 5)
        if [ -n "$nginx_errors" ]; then
            print_warning "Recent Nginx errors found:"
            log_report "Recent Nginx errors:"
            echo "$nginx_errors" | while read line; do
                print_info "  $line"
                log_report "  $line"
            done
        else
            print_success "No recent Nginx errors"
            log_report "✓ No recent Nginx errors"
        fi
    fi
    
    # PHP errors
    detect_php_version
    if [ -f "/var/log/php${PHP_VERSION}-fpm.log" ]; then
        local php_errors=$(tail -n 50 /var/log/php${PHP_VERSION}-fpm.log 2>/dev/null | grep -i "error" | tail -n 5)
        if [ -n "$php_errors" ]; then
            print_warning "Recent PHP errors found:"
            log_report "Recent PHP errors:"
            echo "$php_errors" | while read line; do
                print_info "  $line"
                log_report "  $line"
            done
        else
            print_success "No recent PHP errors"
            log_report "✓ No recent PHP errors"
        fi
    fi
    
    echo ""
}

generate_summary() {
    print_header "Diagnostic Summary"
    log_report ""
    log_report "═══════════════════════════════════════════════════════════════════════════"
    log_report "SUMMARY"
    log_report "═══════════════════════════════════════════════════════════════════════════"
    
    local total_issues=$1
    
    if [ $total_issues -eq 0 ]; then
        print_success "No critical issues detected!"
        log_report "✓ No critical issues detected"
        log_report ""
        log_report "Your Moodle installation appears to be properly configured."
    else
        print_warning "Found $total_issues potential issue(s)"
        log_report "⚠ Found $total_issues potential issue(s)"
        log_report ""
        log_report "Review the details above and follow suggested fixes."
    fi
    
    log_report ""
    log_report "Full report saved to: $REPORT_FILE"
    
    echo ""
    print_info "Full diagnostic report saved to:"
    print_info "  $REPORT_FILE"
    echo ""
}

################################################################################
# Main Function
################################################################################

main() {
    clear
    print_msg "$MAGENTA" "╔════════════════════════════════════════════════════════════════════════════╗"
    print_msg "$MAGENTA" "║                                                                            ║"
    print_msg "$MAGENTA" "║                  MOODLE INSTALLATION TROUBLESHOOTER                        ║"
    print_msg "$MAGENTA" "║                                                                            ║"
    print_msg "$MAGENTA" "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    init_report
    
    print_info "Running comprehensive diagnostics..."
    print_info "This may take a minute..."
    echo ""
    sleep 1
    
    local total_issues=0
    
    check_system_info
    
    check_services
    total_issues=$((total_issues + $?))
    
    check_php_configuration
    total_issues=$((total_issues + $?))
    
    check_nginx_configuration
    total_issues=$((total_issues + $?))
    
    check_database
    total_issues=$((total_issues + $?))
    
    check_file_structure
    total_issues=$((total_issues + $?))
    
    check_network_connectivity
    total_issues=$((total_issues + $?))
    
    check_cron
    total_issues=$((total_issues + $?))
    
    check_logs_for_errors
    
    generate_summary $total_issues
    
    # Offer to view report
    read -p "View full report now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "$REPORT_FILE"
    fi
    
    print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_msg "$GREEN" "Diagnostics complete!"
    print_msg "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Run main function
main "$@"
