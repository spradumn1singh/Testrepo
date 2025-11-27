#!/bin/bash

##Step1##Updating packagaes in linux
LAMP_LOG="lamplog.txt"
MYSQL_ADMIN_PASSWORD="12345"

echo " " > "$LAMP_LOG"
echo "----LAMP SETUP log started : $(date) " |tee $"LAMP_LOG"
echo "----FIRST STEP : updating system packages--------" | tee -a "$LAMP_LOG"
sudo apt update && sudo apt upgrade -y 2>&1 | tee -a "$LAMP_LOG"
echo "----FIRST STEP : completed----------" | tee -a "$LAMP_LOG"
## Package updated

##Step2##Installing apache and checking its status
echo "----SECOND STEP : Installing APACHE --------" | tee -a "$LAMP_LOG"
sudo apt install -y apache2 2>&1
echo "----enable apache---" | tee -a "$LAMP_LOG"
sudo systemctl enable --now apache2
sudo systemctl status apache2 --no-pager |head -3 |tee -a "$LAMP_LOG"
## status checked 

##Step3##Check and Open Port 80 for Apache ---                                                                                                            
echo "----THIRD STEP : Checking and configuring Firewall for Apache--------" | tee -a "$LAMP_LOG"
sudo ss -tunlp | grep apache2
if [$? -eq 0]; then
echo "SUCCESS: Apache is actively listening on port 80. No firewall changes needed." | tee -a "$LAMP_LOG"
else
    echo "NOTICE: Apache process found, but port 80 may be blocked by the firewall." | tee -a "$LAMP_LOG"
    echo "ACTION: Attempting to open port 80 (HTTP) using UFW." | tee -a "$LAMP_LOG"
	sudo ufw allow 80/tcp 2>&1
fi
echo "--- Script Finished ---" | tee -a "$LAMP_LOG"
## apache installed and 80 port enabled	


##STEP4 Installing MYSQL server 
echo "--- FORTH STEP : Installing MYSQL Server ---" | tee -a "$LAMP_LOG"
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
sudo systemctl status mysql --no-pager | head -3 |tee -a "$LAMP_LOG"
# Ensure correct root auth plugin
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpass123';"
sudo systemctl restart mysql
# Create admin user properly
MYSQL_ADMIN_PASSWORD="12345"
sudo mysql -u root -prootpass123 -e "DROP USER IF EXISTS 'admin'@'localhost';"
sudo mysql -u root -prootpass123 -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';"
sudo mysql -u root -prootpass123 -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -prootpass123 -e "FLUSH PRIVILEGES;"
echo " Mysql installed and Admin user created successfully!" | tee -a "$LAMP_LOG"

echo "Creating test PHP file..." | tee -a "$LAMP_LOG"
sudo bash -c "cat > /var/www/html/db-test.php <<EOF
<?php
\$servername = 'localhost';
\$username = 'admin';
\$password = '${MYSQL_ADMIN_PASSWORD}';

\$conn = new mysqli(\$servername, \$username, \$password);

if (\$conn->connect_error) {
    die('Connection failed: ' . \$conn->connect_error);
}
echo 'Connected successfully!';
?>
EOF"

sudo chown -R www-data:www-data /var/www/html/

### Final Status ###
echo "--------------------------------------------------" | tee -a "$LAMP_LOG"
echo "LAMP installation completed successfully!" | tee -a "$LAMP_LOG"
echo "Test PHP page URL: http://<your-server-ip>/db-test.php" | tee -a "$LAMP_LOG"
echo "--------------------------------------------------" | tee -a "$LAMP_LOG"
