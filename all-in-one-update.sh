echo "[boot] /
systemd=true >> /etc/wsl.conf

apt update
apt upgrade -y
apt install -y sudo net-tools mc nano nmon curl wget telnet strace unzip wrk gnupg2 ncdu tar apache2-utils postgresql-client ca-certificates  lsb-release  debian-archive-keyring

timedatectl set-timezone Europe/Moscow
export PATH="/usr/local/bin:$PATH"
swapoff -a
#=======================================================================================================================
nano /etc/apt/preferences.d/99nginx

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx.key -out /etc/ssl/certs/nginx.crt -subj "/C=US/ST=New Sweden/L=Stockholm/O=.../OU=.../CN=.../emailAddress=default"

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
apt update
apt install -y nginx
service nginx stop

nano /etc/nginx/conf.d/default.new

nano /etc/nginx/conf.d/status.conf

nano /etc/nginx/nginx.conf

mv "/etc/nginx/conf.d/default.conf" "/etc/nginx/conf.d/default.conf.orig" 
mv "/etc/nginx/conf.d/default.new" "/etc/nginx/conf.d/default.conf" 
service nginx restart

#=======================================================================================================================

apt -y install pgbouncer
sudo sed -i '/;* = host=testserver/a * = host=localhost port=5432/' /etc/pgbouncer/pgbouncer.ini
sudo sed -i 's/^;max_client_conn = 100/max_client_conn = 1000/' /etc/pgbouncer/pgbouncer.ini
sudo sed -i 's/^listen_addr = localhost/listen_addr = */' /etc/pgbouncer/pgbouncer.ini
echo "\"bingouser\" \"bingouser\"" >> /etc/pgbouncer/userlist.txt
service pgbouncer restart
#=======================================================================================================================

  # postgres install
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt -y update && apt install postgresql-16 -y

  # prepare postgres
sudo sh -c 'echo "host all all 10.0.0.0/24 md5" >> /etc/postgresql/16/main/pg_hba.conf'
sudo sh -c 'echo "host all all 10.0.1.0/24 md5" >> /etc/postgresql/16/main/pg_hba.conf'
sudo sh -c 'echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/16/main/pg_hba.conf' # удалить TODO
echo "listen_addresses = '*'" >> /etc/postgresql/16/main/postgresql.conf
sudo sed -i 's/^max_connections = 100/max_connections = 5000/' /etc/postgresql/16/main/postgresql.conf
sudo sed -i 's/^shared_buffers = 128MB/shared_buffers = 512MB/' /etc/postgresql/16/main/postgresql.conf
sudo service postgresql restart
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
sudo -u postgres psql -c "create user bingouser;"
sudo -u postgres psql -c "ALTER USER bingouser WITH PASSWORD 'bingouser';"
sudo -u postgres psql -c "CREATE DATABASE bingodatabase OWNER bingouser;"
#=======================================================================================================================

  #prepare malware app
sudo mkdir -p /opt/bingo/
sudo mkdir -p /opt/bongo/logs/3b5f1461ab/
sudo touch /opt/bongo/logs/3b5f1461ab/main.log
sudo curl https://storage.yandexcloud.net/final-homework/bingo -o /opt/bin
sudo chmod +x /opt/bin
  # adding new user and own to bingo path
sudo useradd -m -s /bin/bash bingouser
echo bingouser:bingouser | chpasswd

nano /opt/bingo/config.yaml

chown -R bingouser /opt
  # run this hard software for hello woprld
sudo -H -u bingouser bash -c '/opt/bin'
  # prepare db localy
sudo -H -u bingouser bash -c '/opt/bin prepare_db'

nano /etc/systemd/system/bingo.service

systemctl daemon-reload
systemctl enable bingo.service
systemctl restart bingo.service
systemctl status bingo.service
#=======================================================================================================================

  #create indexes for db
  #GET /api/movie/{id} 
sudo -u bingouser psql -d bingodatabase -c "create index idx_movies_id on movies(id);"
  #GET /api/customer/{id} 
sudo -u bingouser psql -d bingodatabase -c "create index idx_cus_id on customers(id);"
  #GET /api/session/{id} 
sudo -u bingouser psql -d bingodatabase -c "create index grsagnf on sessions(id);"
sudo -u bingouser psql -d bingodatabase -c "create index grsagnfdd on sessions(id desc);"
sudo -u bingouser psql -d bingodatabase -c "create index idxvbdhdj on movies(year asc, name asc);"
sudo -u bingouser psql -d bingodatabase -c "create index idxvbdhddj on sessions(customer_id);"
sudo -u bingouser psql -d bingodatabase -c "create index idxvbdhdfdj on sessions(movie_id);"
  #GET /api/movie85  - 
sudo -u bingouser psql -d bingodatabase -c "create index idx_year_name_id on movies(year desc, name asc, id desc);"
sudo -u bingouser psql -d bingodatabase -c "create index idx_year_name_idd on movies(year);"
  #GET /api/customer313
sudo -u bingouser psql -d bingodatabase -c "create index idx_all on customers (surname asc, name asc, birthday desc, id desc);"
  #GET /api/session 1700
sudo -u bingouser psql -d bingodatabase -c "create index idxwtf on movies (year desc, name asc);"
sudo -u bingouser psql -d bingodatabase -c "create index hbfrjkbjj on sessions(customer_id);"
sudo -u bingouser psql -d bingodatabase -c "create index hbfrjfkbjj on sessions(movie_id);"
sudo -u bingouser psql -d bingodatabase -c "create index hbfrjkggbjj on sessions(id desc);"
  #POST /api/session 19
  #DELETE /api/session/{id} 

#=======================================================================================================================
cd
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
tar zxvf prometheus-2.48.0.linux-amd64.tar.gz
cd prometheus-2.48.0.linux-amd64
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
mkdir -p /data
cp prometheus promtool /usr/local/bin/
cp -r console_libraries consoles /etc/prometheus
useradd --no-create-home --shell /bin/false prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /data
chown -R prometheus:prometheus /usr/local/bin/{prometheus,promtool}
nano /etc/systemd/system/prometheus.service

nano /etc/prometheus/prometheus.yml

systemctl daemon-reload
systemctl enable prometheus.service
systemctl restart prometheus.service
systemctl status prometheus.service
#=======================================================================================================================
cd
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar zxvf node_exporter-1.7.0.linux-amd64.tar.gz
cd node_exporter-1.7.0.linux-amd64
mkdir /opt/node-exporter/
cp node_exporter /opt/node-exporter/
chown -R prometheus:prometheus /opt/node-exporter/
nano /etc/systemd/system/node-exporter.service

systemctl daemon-reload
systemctl enable node-exporter.service
systemctl restart node-exporter.service
systemctl status node-exporter.service

#=======================================================================================================================
cd
apt install -y build-essential ruby-dev
gem install fluentd --no-doc
gem install fluent-plugin-prometheus
mkdir /etc/fluent/
nano /etc/fluent/fluent.conf

chown -R prometheus:prometheus /etc/fluent/
nano /etc/systemd/system/fluentd.service

systemctl daemon-reload
systemctl enable fluentd
systemctl restart fluentd
systemctl status fluentd
#=======================================================================================================================
cd
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar -zxf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
mkdir /opt/nginx-exporter/
cp nginx-prometheus-exporter /opt/nginx-exporter/
chown -R prometheus:prometheus /opt/nginx-exporter/
nano /etc/systemd/system/nginx-exporter.service
systemctl daemon-reload
systemctl enable nginx-exporter
systemctl restart nginx-exporter
systemctl status nginx-exporter
#=======================================================================================================================
cd
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_10.2.2_amd64.deb
sudo dpkg -i grafana_10.2.2_amd64.deb
nano /etc/grafana/provisioning/datasources/datasource.yml

nano /etc/grafana/provisioning/dashboards/trafic-latency.json

nano /etc/grafana/provisioning/dashboards/monitoring.json

nano /etc/grafana/provisioning/dashboards/dashboard.yml

systemctl daemon-reload
systemctl enable grafana-server
systemctl restart grafana-server
systemctl status grafana-server
#=======================================================================================================================
cd
rm -rf nginx-prometheus-exporter*
rm -rf prometheus-2.48.0.linux-amd64*
rm -rf grafana_10.2.2*

#=======================================================================================================================





























