#!/bin/bash

repo="The-DevOps-Journey-101"

echo "==============================================="
echo "Actualizando Ubuntu"
echo "==============================================="
sleep 2
apt update
echo "==============================================="
echo "Instalando MariaDB y Creando la DB"
echo "==============================================="
sleep 2

#Validamos si esta instalado MariaDB

if dpkg -l | grep -q mariadb; 
then
	echo "Ya esta instalado MariaDB"
else
	sudo apt install -y mariadb-server
	sudo systemctl start mariadb
	sudo systemctl enable mariadb
fi

#Configuramos la Base de Datos
mysql -e "
	  CREATE DATABASE ecomdb;
	  CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
	  GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
	  FLUSH PRIVILEGES;"

echo "==============================================="
echo "Agregando datos a la DB"
echo "==============================================="

cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

sleep 1

mysql < db-load-script.sql

echo "==============================================="
echo "Configurando Apache y PHP"
echo "==============================================="

if dpkg -l | grep -q apache2;
then
	echo "Apache se encuentra instalado"
else
	sudo apt install apache2 -y
	sudo systemctl start apache2
	sudo systemctl enable apache2
fi

if dpkg -l | grep -q php;
then
	echo "PHP esta instalado"
	php -v
else
	sudo apt install -y php libapache2-mod-php php-mysql php-mysqli
	sudo systemctl reload apache2
	php -v
fi

echo "==============================================="
echo "Deploy"
echo "==============================================="

if dpkg -l | grep -q git;
then
	echo "Git esta instalado"
else
	sudo apt install git -y
fi

if [ -d $repo ];
then
	echo "Existe el proyecto"
	cd /root/$repo
	git pull
	echo "Se actualiza el proyecto desde Git"
else
        git clone https://github.com/roxsross/$repo.git
        cp -r The-DevOps-Journey-101/CLASE-02/lamp-app-ecommerce/* /var/www/html/
        mv /var/www/html/index.html /var/www/html/index.html.bkp
        sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
fi

if [ -f /var/www/html/info.php ];
then
    echo "info.php existe"
else
	cat > /var/www/html/info.php <<-EOF
	<?php
		phpinfo();
	?>
	EOF
fi

echo "==============================================="
echo "Test"
echo "==============================================="
systemctl reload apache2
curl http://localhost

echo "==============================================="
echo "Notificación"
echo "==============================================="

# Configura el token de acceso de tu bot de Discord
DISCORD=""

# Cambia al directorio del repositorio
cd /root/$repo

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
	GRUPO="Grupo: Alberto Núñez"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION\n$GRUPO"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"

echo "Notificacion enviada a Discord"
