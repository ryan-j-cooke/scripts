#!/usr/bin/env bash

set -e

echo "===================================="
echo "🧩 MySQL + phpMyAdmin + DBeaver Setup"
echo "===================================="

# -----------------------------
# CONFIGURATION
# -----------------------------
MYSQL_ROOT_PASSWORD="root"

# -----------------------------
# UPDATE SYSTEM
# -----------------------------
echo "🔄 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# -----------------------------
# INSTALL MYSQL SERVER
# -----------------------------
if ! command -v mysql &>/dev/null; then
    echo "⬇️ Installing MySQL server..."
    sudo apt-get install -y mysql-server
else
    echo "✅ MySQL is already installed."
fi

# -----------------------------
# START & ENABLE MYSQL
# -----------------------------
echo "🚀 Starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

# -----------------------------
# SECURE MYSQL INSTALLATION
# -----------------------------
echo "🔐 Securing MySQL installation..."
sudo mysql --user=root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
EOSQL

echo "✅ MySQL root password set to '${MYSQL_ROOT_PASSWORD}'"

# -----------------------------
# INSTALL PHP + APACHE + PHPMyAdmin
# -----------------------------
if ! dpkg -s phpmyadmin &>/dev/null; then
    echo "⬇️ Installing Apache, PHP, and phpMyAdmin..."
    sudo apt-get install -y apache2 php php-mbstring php-zip php-gd php-json php-curl php-mysql phpmyadmin

    echo "⚙️ Configuring phpMyAdmin..."

    # Link phpMyAdmin to Apache manually if needed
    if [ ! -f /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
        sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
    fi

    # Restart Apache
    sudo systemctl restart apache2
else
    echo "✅ phpMyAdmin is already installed."
fi

# -----------------------------
# CONFIGURE PHPMyAdmin TO USE ROOT
# -----------------------------
echo "🔧 Updating phpMyAdmin configuration for root login..."
PHP_CONF_FILE="/etc/phpmyadmin/config.inc.php"
if ! grep -q "\$cfg\['Servers'\]\[\$i\]\['AllowRoot'\] = true;" "$PHP_CONF_FILE"; then
    sudo sed -i "/Authentication type and info/a \$cfg['Servers'][\$i]['AllowRoot'] = true;" "$PHP_CONF_FILE"
fi

# Ensure correct MySQL socket path
sudo sed -i "s#'socket'\] = ''#'socket'] = '/var/run/mysqld/mysqld.sock'#" "$PHP_CONF_FILE"

sudo systemctl restart apache2

# -----------------------------
# INSTALL DBEAVER COMMUNITY EDITION
# -----------------------------
if ! command -v dbeaver &>/dev/null; then
    echo "⬇️ Installing DBeaver CE..."
    wget -O /tmp/dbeaver-ce_latest_amd64.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
    sudo apt-get install -y ./tmp/dbeaver-ce_latest_amd64.deb || sudo dpkg -i /tmp/dbeaver-ce_latest_amd64.deb
    rm /tmp/dbeaver-ce_latest_amd64.deb
else
    echo "✅ DBeaver is already installed."
fi

# -----------------------------
# SUMMARY
# -----------------------------
echo "===================================="
echo "✅ Installation complete!"
echo "------------------------------------"
echo "🌐 phpMyAdmin: http://localhost/phpmyadmin"
echo "🧰 Username: root"
echo "🔑 Password: ${MYSQL_ROOT_PASSWORD}"
echo "------------------------------------"
echo "🐬 DBeaver: Launch via app menu or 'dbeaver' command"
echo "===================================="
