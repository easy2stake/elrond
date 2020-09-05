# How to run

### 1. Install dependencies
```sh
sudo apt update && apt install git jq curl -y
sudo curl -sSL https://get.docker.com/ | sh
sudo apt install docker-compose -y

#Optionally: Create a new user and enter it\'s home directory
sudo useradd -m -s /bin/bash monitor
sudo usermod -aG docker monitor
sudo su - monitor
```

### 2. Clone the repository and customize the configuration files
```sh
git clone https://github.com/easy2stake/elrond
cd elrond/
nano elrond-exporter.sh #use your preferred file editor here

#Edit the the following lines of elrond-exporter.sh according to your needs:
LOCAL_METRICS=0 #Enable local metrics
LOCAL_NODES=(URL1 URL2 URL3)  #Insert your validator node RPC URLs inside the parenthesis separated by space
REMOTE_METRICS=1
OBSERVER_URL="https://api.elrond.com"
IDENTITY="YOUR-GITHUB-IDENTITY-HERE" # Edit this with your own identity
```
More details on the variables [here](https://github.com/easy2stake/elrond/blob/master/README.md).
**Do not run REMOTE_METRICS=1 on the same machine as your validator.** Remote metrics tend to be CPU intensive if your identity hides more than 5-10 nodes.

```sh
#Change the elrond-exporter.sh permissions:
chmod 700 elrond-exporter.sh

#Create the metrics folder:
mkdir -p $HOME/.elrond-exporter

#Add the following line on your crontab:
crontab -e
* * * * * $HOME/elrond/elrond-exporter.sh > $HOME/.elrond-exporter/metrics.prom
```

### 3. Running Docker Compose
Create the infrastructure using:
```sh
cd $HOME/elrond/monitoring-infra
ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose up -d
```
**Attention:** Your grafana and prometheus instances will be accessible from the internet. We recommend to use a STRONG password.

Remove the infrastructure using:
```sh
cd $HOME/elrond/monitoring-infra
docker-compose down
```

Access your dashboards here:
- Grafana: http://your-ip-address:13000
- Prometheus: http://your-ip-address:19090

Grafana default credentials are admin/admin. It will ask for a password change when you first login.

### 4. More customisation

#### Adding remote endpoints:
By default, prometheus only scrapes the local nodeexporter instance. In order to scrape metrics from remote sources the prometheus.yml configuration file must be edited. Let's say we want to collect metrics from "http://my-remote-metrics1:9100" and "http://my-remote-metrics2:9100":
```sh
cd $HOME/elrond/monitoring-infra/prometheus
nano prometheus.yaml

#The default configuration looks like this:
scrape_configs:
  - job_name: 'nodeexporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['nodeexporter:9100']

#The updated configuration will look like this:
scrape_configs:
  - job_name: 'nodeexporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['nodeexporter:9100', 'my-remote-metrics1:9100', 'my-remote-metrics2:9100']

#Restart the container or redeploy the infrastructure for the configuration changes to take effect.
docker restart prometheus
```

#### Alerting:
We prefer telegram bots to send alerts to but the possibilities are endless.
There are plenty of guides out there about alerts on Grafana. We can link external references here if requested.

#### Credits:
This is a simplified customized docker-compose solution. For those with experience is easy to add more complexity. Credits for the original docker-compose setup: [here] (https://github.com/stefanprodan/dockprom)

#### Contact:
**Reach us on telegram:** https://t.me/easy2stake
