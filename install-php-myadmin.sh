#!/usr/bin/env bash

set -e

# Function to log messages
log_message() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_message "===================================="
log_message "🧩 phpMyAdmin + DBeaver Setup"
log_message "===================================="

# -----------------------------
# CONFIGURATION
# -----------------------------
MYSQL_ROOT_PASSWORD="root"

# -----------------------------
# UPDATE SYSTEM
# -----------------------------
log_message "🔄 Updating system packages..."
sudo apt-get update -y && log_message "System packages updated"
sudo apt-get upgrade -y && log_message "System upgraded"

# -----------------------------
# INSTALL PHP + APACHE + PHPMyAdmin
# -----------------------------
if ! dpkg -s phpmyadmin &>/dev/null; then
    log_message "⬇️ Installing Apache, PHP, and phpMyAdmin..."
    sudo apt-get install -y apache2 php php-mbstring php-zip php-gd php-json php-curl php-mysql phpmyadmin
    log_message "Apache, PHP, and phpMyAdmin installed"

    log_message "⚙️ Configuring phpMyAdmin..."
    # Link phpMyAdmin to Apache manually if needed
    if [ ! -f /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
        sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
        log_message "phpMyAdmin configuration linked to Apache"
    fi

   sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.con

    # Restart Apache
    sudo systemctl restart apache2
    log_message "Apache restarted after phpMyAdmin configuration"
else
    log_message "✅ phpMyAdmin is already installed."
fi

# -----------------------------
# CONFIGURE PHPMyAdmin TO USE ROOT
# -----------------------------
log_message "🔧 Updating phpMyAdmin configuration for root login..."
PHP_CONF_FILE="/etc/phpmyadmin/config.inc.php"
if ! grep -q "\$cfg\['Servers'\]\[\$i\]\['AllowRoot'\] = true;" "$PHP_CONF_FILE"; then
    sudo sed -i "/Authentication type and info/a \$cfg['Servers'][\$i]['AllowRoot'] = true;" "$PHP_CONF_FILE"
    log_message "Root login enabled in phpMyAdmin configuration"
fi

# Ensure correct MySQL socket path
sudo sed -i "s#'socket'\] = ''#'socket'] = '/var/run/mysqld/mysqld.sock'#" "$PHP_CONF_FILE"
log_message "MySQL socket path updated in phpMyAdmin configuration"

sudo systemctl restart apache2
log_message "Apache restarted after configuration changes"

# -----------------------------
# INSTALL DBEAVER COMMUNITY EDITION
# -----------------------------
if ! command -v dbeaver &>/dev/null; then
    log_message "⬇️ Installing DBeaver CE..."
    wget -O /tmp/dbeaver-ce_latest_amd64.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
    log_message "DBeaver downloaded"
    sudo apt-get install -y ./tmp/dbeaver-ce_latest_amd64.deb || sudo dpkg -i /tmp/dbeaver-ce_latest_amd64.deb
    rm /tmp/dbeaver-ce_latest_amd64.deb
    log_message "DBeaver installed"
else
    log_message "✅ DBeaver is already installed."
fi

# -----------------------------
# SUMMARY
# -----------------------------
log_message "===================================="
log_message "✅ Installation complete!"
log_message "------------------------------------"
log_message "🌐 phpMyAdmin: http://localhost/phpmyadmin"
log_message "🧰 Username: root"
log_message "🔑 Password: ${MYSQL_ROOT_PASSWORD}"
log_message "------------------------------------"
log_message "🐬 DBeaver: Launch via app menu or 'dbeaver' command"
log_message "===================================="

