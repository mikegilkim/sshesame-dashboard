# 🍯 SSH Honeypot Dashboard for sshesame

A beautiful, colorful terminal dashboard to monitor your [sshesame](https://github.com/jaksi/sshesame) SSH honeypot attacks in real-time.

<img width="733" height="537" alt="image" src="https://github.com/user-attachments/assets/31b4855b-279b-49f6-8925-2ddb64d737ae" />

## ✨ Features

- 📊 **Beautiful Dashboard** - Color-coded statistics with elegant box design
- 🎯 **Overview Stats** - Total attacks, successful logins, commands run
- 🌍 **Top Attackers** - See which IPs are hitting your honeypot most
- 👤 **Username Analysis** - Most common usernames attackers try
- 🔑 **Password Analysis** - What passwords are being attempted
- 💻 **Command Tracking** - See what commands attackers try to run
- ⏱️ **Recent Activity** - Last 5 attacks with timestamps
- 🚀 **One-line Installation** - Quick and easy setup
- ⌨️ **Quick Alias** - Just type `honeypot` to view dashboard

## 📸 UI Sampling

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                         SSH HONEYPOT DASHBOARD                               ║
╚══════════════════════════════════════════════════════════════════════════════╝

▶ SERVICE STATUS
────────────────────────────────────────────────────────────────────────────────
  Status: ● ACTIVE
  Running since: Sun 2025-11-30 00:39:41 PST

▶ OVERVIEW STATISTICS
────────────────────────────────────────────────────────────────────────────────
  Total Login Attempts:          127
  Successful Fake Logins:        112
  Total Connections:             98
  Commands Attempted:            45
  Unique Attacker IPs:           23
  Unique Usernames Tried:        15
  Unique Passwords Tried:        87
```

## 🚀 Quick Installation

**One-line install command:**

```bash
curl -sSL https://raw.githubusercontent.com/mikegilkim/sshesame-dashboard/main/install.sh | sudo bash
```

That's it! The installer will:
- ✅ Download and install the dashboard
- ✅ Make it executable
- ✅ Add the `honeypot` alias to all users
- ✅ Test the installation

## 📋 Requirements

- Linux system (Ubuntu, Debian, CentOS, etc.)
- [sshesame](https://github.com/jaksi/sshesame) SSH honeypot installed and running
- systemd (for service management)
- Root or sudo access

## 🎯 Usage

After installation, simply run:

```bash
honeypot
```

Or directly:

```bash
sudo /usr/local/bin/honeypot-dashboard
```

### First time users

If the alias doesn't work immediately, reload your shell:

```bash
source ~/.bashrc
```

## 📦 Manual Installation

If you prefer manual installation:

1. Download the dashboard script:
```bash
sudo wget -O /usr/local/bin/honeypot-dashboard https://raw.githubusercontent.com/mikegilkim/sshesame-dashboard/main/honeypot-dashboard.sh
```

2. Make it executable:
```bash
sudo chmod +x /usr/local/bin/honeypot-dashboard
```

3. Add the alias to your `.bashrc`:
```bash
echo "alias honeypot='sudo /usr/local/bin/honeypot-dashboard'" >> ~/.bashrc
source ~/.bashrc
```

## 🔧 Setting up sshesame

If you haven't set up sshesame yet, here's a quick guide:

1. **Download sshesame:**
```bash
wget https://github.com/jaksi/sshesame/releases/download/v0.0.39/sshesame-linux-amd64 -O sshesame
chmod +x sshesame
sudo mv sshesame /usr/local/bin/
```

2. **Create systemd service:**
```bash
sudo nano /etc/systemd/system/sshesame.service
```

Add:
```ini
[Unit]
Description=sshesame SSH Honeypot
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/sshesame -data_dir /var/lib/sshesame -config /etc/sshesame/config.yaml
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

3. **Create config:**
```bash
sudo mkdir -p /etc/sshesame /var/lib/sshesame
sudo nano /etc/sshesame/config.yaml
```

Add:
```yaml
server:
  listen_address: "0.0.0.0:22"
```

4. **Start the service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable sshesame
sudo systemctl start sshesame
```

## 🛡️ Security Recommendations

- **Move your real SSH to a different port**
- **Configure fail2ban** to protect your real SSH port
- **Use strong authentication** on your real SSH (keys, not passwords)
- **Monitor the honeypot regularly** to see attack patterns
- **Don't expose sensitive services** on default ports

## 📊 Dashboard Sections

### Service Status
Shows if sshesame is running and uptime

### Overview Statistics
- Total login attempts
- Successful fake logins
- Commands attempted
- Unique attackers

### Top 10 Attacker IPs
Most aggressive IPs targeting your honeypot

### Top 10 Usernames
Most commonly tried usernames (root, admin, ubuntu, etc.)

### Top 10 Passwords
Most commonly tried passwords

### Top 10 Commands
Commands attackers try to execute

### Last 5 Attacks
Recent attack attempts with timestamps

## 🔍 Live Monitoring

To watch attacks in real-time:

```bash
sudo journalctl -u sshesame -f
```

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## 📝 License

MIT License - feel free to use and modify!

## ⭐ Star this repo!

If you find this useful, please star the repository!

## 🙏 Credits

- Built for [sshesame](https://github.com/jaksi/sshesame) by jaksi
- Dashboard created with ❤️ for the security community


**Happy honeypot monitoring!** 🍯✨
