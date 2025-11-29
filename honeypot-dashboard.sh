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
NC='\033[0m' # No Color
BOLD='\033[1m'

# Box drawing characters
TL='╔'
TR='╗'
BL='╚'
BR='╝'
H='═'
V='║'
VR='╠'
VL='╣'
HU='╩'
HD='╦'
CROSS='╬'

# Function to print a line
print_line() {
    local width=$1
    local char=$2
    printf "${char}%.0s" $(seq 1 $width)
}

# Function to print centered text in a box
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

# Function to print section header
print_section() {
    local text="$1"
    echo ""
    echo -e "${YELLOW}${BOLD}▶ ${text}${NC}"
    echo -e "${YELLOW}$(print_line 80 '─')${NC}"
}

# Function to print stat box
print_stat() {
    local label="$1"
    local value="$2"
    local color="$3"
    printf "  ${WHITE}%-30s${NC} ${color}${BOLD}%s${NC}\n" "$label:" "$value"
}

# Clear screen
clear

# Get log data
LOG_DATA=$(sudo journalctl -u sshesame --no-pager 2>/dev/null)

# Calculate statistics
TOTAL_ATTEMPTS=$(echo "$LOG_DATA" | grep -c "authentication for user")
SUCCESSFUL_LOGINS=$(echo "$LOG_DATA" | grep -c "accepted")
UNIQUE_IPS=$(echo "$LOG_DATA" | grep -oP '\[\K[0-9.]+' | sort -u | wc -l)
UNIQUE_USERNAMES=$(echo "$LOG_DATA" | grep "authentication for user" | awk '{print $9}' | tr -d '"' | sort -u | wc -l)
UNIQUE_PASSWORDS=$(echo "$LOG_DATA" | grep "with password" | grep -oP 'password "\K[^"]+' | sort -u | wc -l)
COMMANDS_RUN=$(echo "$LOG_DATA" | grep -c "command.*requested")
TOTAL_CONNECTIONS=$(echo "$LOG_DATA" | grep -c "connection with client")

# Get service status
if systemctl is-active --quiet sshesame; then
    STATUS="${GREEN}●${NC} ${BOLD}ACTIVE${NC}"
    UPTIME=$(systemctl show sshesame --property=ActiveEnterTimestamp --value)
else
    STATUS="${RED}●${NC} ${BOLD}INACTIVE${NC}"
    UPTIME="N/A"
fi

# Print dashboard header
print_header "SSH HONEYPOT DASHBOARD"

# Service Status
print_section "SERVICE STATUS"
echo -e "  Status: $STATUS"
if [ "$UPTIME" != "N/A" ]; then
    echo -e "  ${WHITE}Running since:${NC} $UPTIME"
fi

# Overview Statistics
print_section "OVERVIEW STATISTICS"
print_stat "Total Login Attempts" "$TOTAL_ATTEMPTS" "$CYAN"
print_stat "Successful Fake Logins" "$SUCCESSFUL_LOGINS" "$GREEN"
print_stat "Total Connections" "$TOTAL_CONNECTIONS" "$MAGENTA"
print_stat "Commands Attempted" "$COMMANDS_RUN" "$YELLOW"
print_stat "Unique Attacker IPs" "$UNIQUE_IPS" "$RED"
print_stat "Unique Usernames Tried" "$UNIQUE_USERNAMES" "$BLUE"
print_stat "Unique Passwords Tried" "$UNIQUE_PASSWORDS" "$BLUE"

# Top Attacker IPs
print_section "TOP 10 ATTACKER IPs"
if [ $UNIQUE_IPS -gt 0 ]; then
    echo "$LOG_DATA" | grep -oP '\[\K[0-9.]+' | sort | uniq -c | sort -rn | head -10 | while read count ip; do
        printf "  ${RED}%-15s${NC} ${WHITE}%s attempts${NC}\n" "$ip" "$count"
    done
else
    echo -e "  ${WHITE}No attacks detected yet${NC}"
fi

# Top Usernames
print_section "TOP 10 USERNAMES TRIED"
if [ $UNIQUE_USERNAMES -gt 0 ]; then
    echo "$LOG_DATA" | grep "authentication for user" | awk '{print $9}' | tr -d '"' | sort | uniq -c | sort -rn | head -10 | while read count username; do
        printf "  ${BLUE}%-20s${NC} ${WHITE}%s attempts${NC}\n" "$username" "$count"
    done
else
    echo -e "  ${WHITE}No usernames tried yet${NC}"
fi

# Top Passwords
print_section "TOP 10 PASSWORDS TRIED"
if [ $UNIQUE_PASSWORDS -gt 0 ]; then
    echo "$LOG_DATA" | grep "with password" | grep -oP 'password "\K[^"]+' | sort | uniq -c | sort -rn | head -10 | while read count password; do
        # Truncate long passwords
        if [ ${#password} -gt 30 ]; then
            password="${password:0:27}..."
        fi
        printf "  ${MAGENTA}%-30s${NC} ${WHITE}%s attempts${NC}\n" "$password" "$count"
    done
else
    echo -e "  ${WHITE}No passwords tried yet${NC}"
fi

# Top Commands
print_section "TOP 10 COMMANDS ATTEMPTED"
if [ $COMMANDS_RUN -gt 0 ]; then
    echo "$LOG_DATA" | grep "command" | grep -oP 'command "\K[^"]+' | sort | uniq -c | sort -rn | head -10 | while read count cmd; do
        # Truncate long commands
        if [ ${#cmd} -gt 50 ]; then
            cmd="${cmd:0:47}..."
        fi
        printf "  ${YELLOW}%-50s${NC} ${WHITE}%s times${NC}\n" "$cmd" "$count"
    done
else
    echo -e "  ${WHITE}No commands attempted yet${NC}"
fi

# Recent Activity
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

# Footer
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
