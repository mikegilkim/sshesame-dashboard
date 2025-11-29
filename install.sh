#!/bin/bash

# SSHESAME Dashboard One-liner Installer
# https://github.com/mikegilkim/sshesame-dashboard

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         SSH Honeypot Dashboard Installer v1.0                  ║"
echo "║         Installing beautiful dashboard for sshesame            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if sshesame service exists
echo -e "${BLUE}[1/5]${NC} Checking for sshesame service..."
if ! systemctl list-unit-files | grep -q sshesame.service; then
    echo -e "${YELLOW}⚠ Warning: sshesame service not found${NC}"
    echo -e "${YELLOW}   The dashboard will install, but you need sshesame to see data${NC}"
    echo -e "${YELLOW}   Visit: https://github.com/jaksi/sshesame${NC}"
else
    echo -e "${GREEN}✓ sshesame service found${NC}"
fi

# Download the dashboard script
echo -e "${BLUE}[2/5]${NC} Downloading honeypot dashboard..."
SCRIPT_URL="https://raw.githubusercontent.com/YOUR_USERNAME/sshesame-dashboard/main/honeypot-dashboard.sh"

# For testing, use the embedded script
cat > /usr/local/bin/honeypot-dashboard << 'DASHBOARD_SCRIPT'
#!/bin/bash

# SSH Honeypot Dashboard
# Beautiful display of sshesame honeypot statistics

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Box drawing characters
TL='╔'
TR='╗'
BL='╚'
BR='╝'
H='═'
V='║'

print_line() {
    local width=$1
    local char=$2
    printf "${char}%.0s" $(seq 1 $width)
}

print_header() {
    local text="$1"
    local width=80
    local text_len=${#text}
    local padding=$(( (width - text_len - 2) / 2 ))
    
    echo -e "${CYAN}${TL}$(print_line $((width-2)) $H)${TR}${NC}"
    printf "${CYAN}${V}${NC}"
    printf "%*s" $padding
    echo -ne "${WHITE}${BOLD}${text}${NC}"
    printf "%*s" $((width - text_len - padding - 2))
    echo -e "${CYAN}${V}${NC}"
    echo -e "${CYAN}${BL}$(print_line $((width-2)) $H)${BR}${NC}"
}

print_section() {
    local text="$1"
    echo ""
    echo -e "${YELLOW}${BOLD}▶ ${text}${NC}"
    echo -e "${YELLOW}$(print_line 80 '─')${NC}"
}

print_stat() {
    local label="$1"
    local value="$2"
    local color="$3"
    printf "  ${WHITE}%-30s${NC} ${color}${BOLD}%s${NC}\n" "$label:" "$value"
}

clear

LOG_DATA=$(sudo journalctl -u sshesame --no-pager 2>/dev/null)

TOTAL_ATTEMPTS=$(echo "$LOG_DATA" | grep -c "authentication for user")
SUCCESSFUL_LOGINS=$(echo "$LOG_DATA" | grep -c "accepted")
UNIQUE_IPS=$(echo "$LOG_DATA" | grep -oP '\[\K[0-9.]+' | sort -u | wc -l)
UNIQUE_USERNAMES=$(echo "$LOG_DATA" | grep "authentication for user" | awk '{print $9}' | tr -d '"' | sort -u | wc -l)
UNIQUE_PASSWORDS=$(echo "$LOG_DATA" | grep "with password" | grep -oP 'password "\K[^"]+' | sort -u | wc -l)
COMMANDS_RUN=$(echo "$LOG_DATA" | grep -c "command.*requested")
TOTAL_CONNECTIONS=$(echo "$LOG_DATA" | grep -c "connection with client")

if systemctl is-active --quiet sshesame; then
    STATUS="${GREEN}●${NC} ${BOLD}ACTIVE${NC}"
    UPTIME=$(systemctl show sshesame --property=ActiveEnterTimestamp --value)
else
    STATUS="${RED}●${NC} ${BOLD}INACTIVE${NC}"
    UPTIME="N/A"
fi

print_header "SSH HONEYPOT DASHBOARD"

print_section "SERVICE STATUS"
echo -e "  Status: $STATUS"
if [ "$UPTIME" != "N/A" ]; then
    echo -e "  ${WHITE}Running since:${NC} $UPTIME"
fi

print_section "OVERVIEW STATISTICS"
print_stat "Total Login Attempts" "$TOTAL_ATTEMPTS" "$CYAN"
print_stat "Successful Fake Logins" "$SUCCESSFUL_LOGINS" "$GREEN"
print_stat "Total Connections" "$TOTAL_CONNECTIONS" "$MAGENTA"
print_stat "Commands Attempted" "$COMMANDS_RUN" "$YELLOW"
print_stat "Unique Attacker IPs" "$UNIQUE_IPS" "$RED"
print_stat "Unique Usernames Tried" "$UNIQUE_USERNAMES" "$BLUE"
print_stat "Unique Passwords Tried" "$UNIQUE_PASSWORDS" "$BLUE"

print_section "TOP 10 ATTACKER IPs"
if [ $UNIQUE_IPS -gt 0 ]; then
    echo "$LOG_DATA" | grep -oP '\[\K[0-9.]+' | sort | uniq -c | sort -rn | head -10 | while read count ip; do
        printf "  ${RED}%-15s${NC} ${WHITE}%s attempts${NC}\n" "$ip" "$count"
    done
else
    echo -e "  ${WHITE}No attacks detected yet${NC}"
fi

print_section "TOP 10 USERNAMES TRIED"
if [ $UNIQUE_USERNAMES -gt 0 ]; then
    echo "$LOG_DATA" | grep "authentication for user" | awk '{print $9}' | tr -d '"' | sort | uniq -c | sort -rn | head -10 | while read count username; do
        printf "  ${BLUE}%-20s${NC} ${WHITE}%s attempts${NC}\n" "$username" "$count"
    done
else
    echo -e "  ${WHITE}No usernames tried yet${NC}"
fi

print_section "TOP 10 PASSWORDS TRIED"
if [ $UNIQUE_PASSWORDS -gt 0 ]; then
    echo "$LOG_DATA" | grep "with password" | grep -oP 'password "\K[^"]+' | sort | uniq -c | sort -rn | head -10 | while read count password; do
        if [ ${#password} -gt 30 ]; then
            password="${password:0:27}..."
        fi
        printf "  ${MAGENTA}%-30s${NC} ${WHITE}%s attempts${NC}\n" "$password" "$count"
    done
else
    echo -e "  ${WHITE}No passwords tried yet${NC}"
fi

print_section "TOP 10 COMMANDS ATTEMPTED"
if [ $COMMANDS_RUN -gt 0 ]; then
    echo "$LOG_DATA" | grep "command" | grep -oP 'command "\K[^"]+' | sort | uniq -c | sort -rn | head -10 | while read count cmd; do
        if [ ${#cmd} -gt 50 ]; then
            cmd="${cmd:0:47}..."
        fi
        printf "  ${YELLOW}%-50s${NC} ${WHITE}%s times${NC}\n" "$cmd" "$count"
    done
else
    echo -e "  ${WHITE}No commands attempted yet${NC}"
fi

print_section "LAST 5 ATTACKS"
if [ $TOTAL_ATTEMPTS -gt 0 ]; then
    echo "$LOG_DATA" | grep "authentication for user" | tail -5 | while read line; do
        TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3}')
        IP=$(echo "$line" | grep -oP '\[\K[0-9.]+')
        USERNAME=$(echo "$line" | awk '{print $9}' | tr -d '"')
        echo -e "  ${WHITE}$TIMESTAMP${NC} ${RED}$IP${NC} tried username: ${BLUE}$USERNAME${NC}"
    done
else
    echo -e "  ${WHITE}No attacks detected yet${NC}"
fi

echo ""
echo -e "${CYAN}$(print_line 80 '═')${NC}"
echo -e "${WHITE}  Press Ctrl+C to exit  |  Run: ${CYAN}sudo journalctl -u sshesame -f${WHITE} for live logs${NC}"
echo -e "${CYAN}$(print_line 80 '═')${NC}"
echo ""
echo -e "${CYAN}                        ╔══════════════════════════════╗${NC}"
echo -e "${CYAN}                        ║${NC} ${BOLD}${MAGENTA}★${NC} ${BOLD}${WHITE}Created by${NC} ${BOLD}${CYAN}mikegilkim${NC} ${BOLD}${MAGENTA}★${NC} ${CYAN}║${NC}"
echo -e "${CYAN}                        ║${NC}   ${BLUE}facebook.com/mikegilkim${NC}   ${CYAN}║${NC}"
echo -e "${CYAN}                        ╚══════════════════════════════╝${NC}"
echo ""
DASHBOARD_SCRIPT

echo -e "${GREEN}✓ Dashboard script downloaded${NC}"

# Make script executable
echo -e "${BLUE}[3/5]${NC} Making script executable..."
chmod +x /usr/local/bin/honeypot-dashboard
echo -e "${GREEN}✓ Script is now executable${NC}"

# Add alias to bash profiles
echo -e "${BLUE}[4/5]${NC} Adding 'honeypot' alias..."

# Function to add alias to a file if it doesn't exist
add_alias() {
    local file=$1
    if [ -f "$file" ]; then
        if ! grep -q "alias honeypot=" "$file"; then
            echo "" >> "$file"
            echo "# SSH Honeypot Dashboard alias" >> "$file"
            echo "alias honeypot='sudo /usr/local/bin/honeypot-dashboard'" >> "$file"
            echo -e "${GREEN}  ✓ Added alias to $file${NC}"
        else
            echo -e "${YELLOW}  ⚠ Alias already exists in $file${NC}"
        fi
    fi
}

# Add to root's bashrc
add_alias "/root/.bashrc"

# Add to all user bash profiles
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        add_alias "$user_home/.bashrc"
        # Change ownership to user
        if grep -q "alias honeypot=" "$user_home/.bashrc" 2>/dev/null; then
            chown $username:$username "$user_home/.bashrc" 2>/dev/null || true
        fi
    fi
done

# Add to global bash profile
if [ -f /etc/bash.bashrc ]; then
    add_alias "/etc/bash.bashrc"
fi

# Test the dashboard
echo -e "${BLUE}[5/5]${NC} Testing installation..."
if [ -x /usr/local/bin/honeypot-dashboard ]; then
    echo -e "${GREEN}✓ Dashboard installed successfully!${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

# Final message
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                 Installation Complete! 🎉                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${WHITE}To use the dashboard, run:${NC}"
echo -e "  ${CYAN}${BOLD}honeypot${NC}"
echo ""
echo -e "${WHITE}Or directly:${NC}"
echo -e "  ${CYAN}sudo /usr/local/bin/honeypot-dashboard${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to reload your shell:${NC}"
echo -e "  ${CYAN}source ~/.bashrc${NC}"
echo ""
echo -e "${WHITE}For live attack monitoring:${NC}"
echo -e "  ${CYAN}sudo journalctl -u sshesame -f${NC}"
echo ""
echo -e "${GREEN}Happy honeypot monitoring! 🍯${NC}"
echo ""
