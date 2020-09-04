Dependencies:
sudo curl -sSL https://get.docker.com/ | sh
sudo apt update && apt install git jq docker-compose

Optional: Create a new user
sudo useradd -m -s /bin/bash monitor
usermod -aG docker monitor
su - monitor


git clone https://github.com/easy2stake/elrond
cd elrond/
Edit the the following lines of elrond-exporter.sh:
```sh
LOCAL_METRICS=0 #Enable local metrics
LOCAL_NODES=(URL1 URL2 URL3)  #Insert your validator node RPC URLs inside the parenthesis separated by space
REMOTE_METRICS=1
OBSERVER_URL="https://api.elrond.com"
IDENTITY="YOUR-GITHUB-IDENTITY-HERE" # Edit this with your own identity
```
More details on the variables [here](https://github.com/easy2stake/elrond/blob/master/README.md)
Do not run REMOTE_METRICS=1 on the same machine as your validator. Remote metrics tend to be CPU intensive if your identity hides more than 5-10 nodes.

Change the elrond-exporter.sh permissions:
chmod 700 elrond-exporter.sh

Create the metrics folder:
mkdir -p $HOME/.elrond-exporter

Add the following line on your crontab:
```sh
* * * * * $HOME/elrond/elrond-exporter.sh > $HOME/.elrond-exporter/metrics.prom
```


# Docker Compose
Create the infrastructure:

```sh
cd $HOME/elrond/monitoring-infra
ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose up -d
```
Remove the infrastructure:
```sh
ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose down
```
