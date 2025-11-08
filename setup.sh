#!/bin/bash

################################################################################
# Setup Script - Makes all Moodle installation scripts executable
#
# Usage: bash setup.sh
################################################################################

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Moodle Installation Suite - Setup Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}Setting up scripts in: $SCRIPT_DIR${NC}"
echo ""

# Make scripts executable
scripts=(
    "install-moodle.sh"
    "troubleshoot-moodle.sh"
    "moodle-status.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}✓${NC} Made executable: $script"
    else
        echo -e "${YELLOW}⚠${NC} Not found: $script"
    fi
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "You can now run:"
echo ""
echo "  ${BLUE}sudo ./install-moodle.sh${NC}       - Install Moodle"
echo "  ${BLUE}sudo ./troubleshoot-moodle.sh${NC}  - Diagnose issues"
echo "  ${BLUE}sudo ./moodle-status.sh${NC}        - Check status"
echo ""
echo "For detailed documentation, see:"
echo "  - README.md (start here)"
echo "  - INSTALL_README.md (installer details)"
echo "  - moodle-ubuntu-nginx-installation-guide.md (manual guide)"
echo ""
