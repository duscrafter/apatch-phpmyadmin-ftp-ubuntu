#!/bin/bash

# Update packages
sudo apt-get update

# Install Apache
sudo apt-get install apache2 -y

# Install PHP
sudo apt-get install php libapache2-mod-php php-mysql -y

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections
sudo apt-get install mysql-server -y

# Install Expect
sudo apt-get -y install expect

# Build expect script
tee ~/secure_our_mysql.sh << EOF
spawn $(which mysql_secure_installation)

expect "Enter current password for root (enter for none):"
send "root\r"
expect "Change the root password?"
send "n\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "y\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
EOF

# Run expect script.
# This runs the "mysql_secure_installation" script which removes insecure defaults.
sudo expect ~/secure_our_mysql.sh

# Install phpMyAdmin
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | sudo debconf-set-selections
echo 'phpmyadmin phpmyadmin/app-password-confirm password root' | sudo debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password root' | sudo debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/app-pass password root' | sudo debconf-set-selections
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | sudo debconf-set-selections
sudo apt-get install phpmyadmin -y

# Set up SFTP
sudo apt-get install vsftpd -y
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.orig
echo "anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
pasv_enable=Yes
pasv_min_port=10000
pasv_max_port=10100
allow_writeable_chroot=YES" | sudo tee /etc/vsftpd.conf
sudo service vsftpd restart
