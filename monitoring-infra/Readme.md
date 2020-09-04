# How to run

### 1. Install dependencies
```sh
sudo curl -sSL https://get.docker.com/ | sh
sudo apt update && apt install git jq docker-compose

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
More details on the variables [here](https://github.com/easy2stake/elrond/blob/master/README.md)
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

Remove the infrastructure using:
```sh
cd $HOME/elrond/monitoring-infra
ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose down
```

Access your grafana dashboard using the default credentials (admin/admin) here:
http://your-ip-address:13000
