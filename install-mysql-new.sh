#!/bin/bash

# Exit script if any command fails
set -e

# Update and upgrade the system
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install MySQL server
echo "Installing MySQL Server..."
sudo apt install mysql-server -y

# Start MySQL service (if not already started)
echo "Starting MySQL service..."
sudo systemctl start mysql

# Enable MySQL service to start on boot
echo "Enabling MySQL to start on boot..."
sudo systemctl enable mysql

# MySQL Configuration: Add 'mysql_native_password' and other configurations
echo "Configuring MySQL server settings..."
sudo bash -c 'cat <<EOF >> /etc/mysql/mysql.conf.d/mysqld.cnf

[mysqld]
# * Basic Settings
mysql_native_password=ON
user            = mysql
bind-address    = 0.0.0.0
skip-name-resolve

EOF'

# Restart MySQL service to apply the changes
echo "Restarting MySQL service to apply configuration changes..."
sudo systemctl restart mysql

# Secure MySQL installation and set root password
echo "Securing MySQL installation and setting root password..."
sudo mysql_secure_installation <<EOF

y
root
root
y
y
y
y
EOF

# Logging in to MySQL and changing the root password
echo "Changing MySQL root password using mysql_native_password..."
sudo mysql -u root -proot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
FLUSH PRIVILEGES;
EOF

# Verify MySQL installation
echo "Verifying MySQL installation..."
mysql --version

# Check MySQL service status
echo "Checking MySQL service status..."
sudo systemctl status mysql

echo "MySQL installation complete with root password set to 'root'."
echo "MySQL configuration is complete with mysql_native_password enabled."

