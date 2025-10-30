#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/monitoring-setup.log) 2>&1

# Ensure basic utilities
sudo apt-get update -y
sudo apt-get install -y wget curl tar adduser libfontconfig1

# ========== PROMETHEUS ==========
PROM_VERSION="2.43.0"
cd /tmp

echo "Installing Prometheus v${PROM_VERSION}..."
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar -xf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROM_VERSION}.linux-amd64/prometheus prometheus-${PROM_VERSION}.linux-amd64/promtool /usr/local/bin/

sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo mv prometheus-${PROM_VERSION}.linux-amd64/consoles prometheus-${PROM_VERSION}.linux-amd64/console_libraries /etc/prometheus/
sudo rm -rf prometheus-${PROM_VERSION}.linux-amd64*

# Prometheus config
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100','worker-1:9100','worker-2:9100']
EOF

# Prometheus service user and permissions
if ! id prometheus >/dev/null 2>&1; then
  sudo useradd -rs /bin/false prometheus
fi
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Prometheus systemd unit
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus
sudo systemctl status prometheus --no-pager || true


# ========== GRAFANA ==========
GRAFANA_VERSION="9.4.7"
cd /tmp

echo "Installing Grafana v${GRAFANA_VERSION}..."
wget -q https://dl.grafana.com/enterprise/release/grafana-enterprise_${GRAFANA_VERSION}_amd64.deb
sudo dpkg -i grafana-enterprise_${GRAFANA_VERSION}_amd64.deb || sudo apt-get install -f -y

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server
sudo systemctl status grafana-server --no-pager || true


# ========== NODE EXPORTER ==========
NODE_EXPORTER_VERSION="1.5.0"
cd /tmp

echo "Installing Node Exporter v${NODE_EXPORTER_VERSION}..."
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

if ! id node_exporter >/dev/null 2>&1; then
  sudo useradd -rs /bin/false node_exporter
fi

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl restart node_exporter
sudo systemctl status node_exporter --no-pager || true

echo "✅ Prometheus + Grafana + Node Exporter setup completed successfully."
