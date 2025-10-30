#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/tomcat-setup.log) 2>&1

# ========== VARIABLES ==========
TOMCAT_VERSION="9.0.111"
TOMCAT_USER="tomcat"
TOMCAT_PASSWORD="raham123"
INSTALL_DIR="/opt/tomcat"
TOMCAT_TGZ="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/${TOMCAT_TGZ}"

# ========== INSTALL JAVA ==========
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jre-headless wget tar

# ========== CREATE TOMCAT USER ==========
if ! id $TOMCAT_USER >/dev/null 2>&1; then
  sudo useradd -m -U -d ${INSTALL_DIR} -s /bin/false ${TOMCAT_USER}
fi

# ========== DOWNLOAD & INSTALL TOMCAT ==========
cd /tmp
wget -q ${TOMCAT_URL}
sudo mkdir -p ${INSTALL_DIR}
sudo tar -xzf ${TOMCAT_TGZ} -C ${INSTALL_DIR} --strip-components=1
rm -f ${TOMCAT_TGZ}

# ========== CONFIGURE TOMCAT USERS ==========
TOMCAT_USERS_FILE="${INSTALL_DIR}/conf/tomcat-users.xml"

sudo tee ${TOMCAT_USERS_FILE} > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users>
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="${TOMCAT_USER}" password="${TOMCAT_PASSWORD}" roles="manager-gui,manager-script"/>
</tomcat-users>
EOF

# ========== UNLOCK MANAGER & HOST-MANAGER WEBAPPS ==========
sudo sed -i '/Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' \
  ${INSTALL_DIR}/webapps/manager/META-INF/context.xml || true
sudo sed -i '/Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' \
  ${INSTALL_DIR}/webapps/host-manager/META-INF/context.xml || true

# ========== PERMISSIONS ==========
sudo chown -R ${TOMCAT_USER}:${TOMCAT_USER} ${INSTALL_DIR}

# ========== SYSTEMD SERVICE ==========
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=${TOMCAT_USER}
Group=${TOMCAT_USER}

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_PID=${INSTALL_DIR}/temp/tomcat.pid"
Environment="CATALINA_HOME=${INSTALL_DIR}"
Environment="CATALINA_BASE=${INSTALL_DIR}"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=${INSTALL_DIR}/bin/startup.sh
ExecStop=${INSTALL_DIR}/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ========== START TOMCAT ==========
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
sudo systemctl status tomcat --no-pager || true

echo "✅ Tomcat ${TOMCAT_VERSION} installation completed successfully."
