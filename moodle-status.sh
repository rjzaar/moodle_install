#!/bin/bash

################################################################################
# Moodle Quick Status Checker
#
# Quick overview of Moodle installation status
# Usage: sudo ./moodle-status.sh
#
# Version: 1.0
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
MOODLE_DIR="/var/www/html/moodle"
MOODLE_DATA="/var/moodledata"

print_status() {
    local status=$1
    local message=$2
    case $status in
        "ok")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "error")
            echo -e "${RED}✗${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "info")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

print_header() {
    echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}"
}

# Detect PHP version
if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
else
    PHP_VERSION="not installed"
fi

clear
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          ${BOLD}MOODLE INSTALLATION STATUS${NC}${CYAN}                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Services Status
print_header "Services"
if systemctl is-active --quiet nginx; then
    print_status "ok" "Nginx: Running"
else
    print_status "error" "Nginx: Stopped"
fi

if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    print_status "ok" "MariaDB: Running"
else
    print_status "error" "MariaDB: Stopped"
fi

if [ "$PHP_VERSION" != "not installed" ]; then
    if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
        print_status "ok" "PHP-FPM ${PHP_VERSION}: Running"
    else
        print_status "error" "PHP-FPM ${PHP_VERSION}: Stopped"
    fi
else
    print_status "error" "PHP: Not installed"
fi

# Installation Status
print_header "Installation"
if [ -d "$MOODLE_DIR" ] && [ -f "$MOODLE_DIR/version.php" ]; then
    print_status "ok" "Moodle files: Present"
    version=$(grep '$release' "$MOODLE_DIR/version.php" 2>/dev/null | head -n1 | sed "s/.*'\(.*\)'.*/\1/")
    [ -n "$version" ] && print_status "info" "  Version: $version"
else
    print_status "error" "Moodle files: Missing or incomplete"
fi

if [ -d "$MOODLE_DATA" ]; then
    print_status "ok" "Data directory: Present"
    owner=$(stat -c '%U' "$MOODLE_DATA" 2>/dev/null)
    print_status "info" "  Owner: $owner"
else
    print_status "error" "Data directory: Missing"
fi

if [ -f "$MOODLE_DIR/config.php" ]; then
    print_status "ok" "config.php: Exists"
    perms=$(stat -c '%a' "$MOODLE_DIR/config.php" 2>/dev/null)
    if [ "$perms" = "444" ]; then
        print_status "ok" "  Permissions: Secure (444)"
    else
        print_status "warning" "  Permissions: $perms (should be 444)"
    fi
else
    print_status "info" "config.php: Not created (web install pending)"
fi

# Network
print_header "Network"
if netstat -tuln 2>/dev/null | grep -q ":80 " || ss -tuln 2>/dev/null | grep -q ":80 "; then
    print_status "ok" "Port 80 (HTTP): Listening"
else
    print_status "error" "Port 80 (HTTP): Not listening"
fi

if netstat -tuln 2>/dev/null | grep -q ":443 " || ss -tuln 2>/dev/null | grep -q ":443 "; then
    print_status "ok" "Port 443 (HTTPS): Listening"
else
    print_status "info" "Port 443 (HTTPS): Not configured"
fi

# Web Server Test
if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200\|301\|302"; then
    print_status "ok" "Web server: Responding"
else
    print_status "error" "Web server: Not responding"
fi

# Cron
print_header "Scheduled Tasks"
if crontab -u www-data -l 2>/dev/null | grep -q "admin/cli/cron.php"; then
    print_status "ok" "Moodle cron: Configured"
else
    print_status "warning" "Moodle cron: Not configured"
fi

# System Resources
print_header "System Resources"
mem_usage=$(free | awk '/Mem:/ {printf "%.0f%%", $3/$2 * 100}')
print_status "info" "Memory usage: $mem_usage"

disk_usage=$(df -h / | awk 'NR==2 {print $5}')
print_status "info" "Disk usage: $disk_usage"

load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
print_status "info" "Load average: $load_avg"

# Quick Actions
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Quick Actions:${NC}"
echo ""
echo "  View logs:           sudo tail -f /var/log/nginx/error.log"
echo "  Restart services:    sudo systemctl restart nginx php${PHP_VERSION}-fpm"
echo "  Run diagnostics:     sudo ./troubleshoot-moodle.sh"
echo "  Re-run installer:    sudo ./install-moodle.sh"
echo ""

# Check if web installation needed
if [ -d "$MOODLE_DIR" ] && [ ! -f "$MOODLE_DIR/config.php" ]; then
    echo -e "${YELLOW}${BOLD}⚠ Next Step:${NC} Complete web installation at: http://localhost"
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
