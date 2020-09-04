# Description
A bash script collecting data from elrond nodes and printing them out in a Prometheus metrics format.

It started as a simple metric exporter used during the battle-of-nodes and with each necessity we added more and more metrics. The slow execution time of bash results in low performance when exporting metrics for more than 10 nodes. It also depends on the host machine.

On a dual-core, HT enabled VM the performance for one run exporting 10 nodes metrics is:
max 6s, avg: 4s

Please keep in mind that this is only an exporter. A complete working setup requires:
- An existing Grafana installation
- An existing Prometheus installation
- Prometheus Node Exporter installed on the host running the elrond-exporter.sh script

# How to use it

## 1. Set the Environment Variables

The scripts collects two types of metrics:
- Local metrics: Metrics collected from your node RPC/node/status page.
- Remote metrics: Metrics collected using an OBSERVER_URL

```sh
The only environment variable that MUST be setup in order to run the script is E_IDENTITY:

export E_IDENTITY=easy2stake
```
However, by running the script only exporting E_IDENTITY it will only collect validator performance metrics but it will not collect metrics directly from your node http://RPC-URL/node/status.

In order to collect metrics directly from your nodes then edit the beginning section of the script like this:
```sh
Enable local metrics:
LOCAL_METRICS=1

Edit the example list below with your own nodes. The RPC port has to be reachable from the location of the script:
LOCAL_NODES=(127.0.0.1:8080 127.0.0.1:8081 x.y.z.t:8080)
```

Variables explained:
- LOCAL_METRICS: Enable (1) or disable (0) the local metrics collection. By default this is set to 0
- LOCAL_NODES: Array with each one of the node RPC that you want to collect local metrics from
- E_REMOTE_METRICS: Enable (1) or disable (0) the remote metrics collection. By default this is set to 1. DO NOT ENABLE this metrics if you are running the script on the same machine as your validator. It can impact validator performance.
- E_OBSERVER_URL: The observer to be used in order to collect the REMOTE_METRCS from. By default this is set to https://api.elrond.com
- E_IDENTITY: Your keybase identity. This is a mandatory variable.

## 2. Run the script

By simply running the script it will print the metrics on the terminal.
```sh
bash elrond-exporter.sh
```

Setup cronab and import the metrics to Prometheus using node_exporter collector.

Example node_exporter start with collector:
```sh
ExecStart=/usr/local/bin/node_exporter \
    --collector.cpu \
    --collector.diskstats \
    --collector.filesystem \
    --collector.loadavg \
    --collector.meminfo \
    --collector.systemd \
    --collector.tcpstat \
    --web.listen-address=:9100 \
    --web.telemetry-path="/metrics" \
    --collector.textfile.directory="/var/local/prometheus-metrics/"
```
Add a cron job to write metrics to collector directory configured in node_exporter:
```sh
* * * * * /absolute/path/to/elrond-exporter.sh > /var/local/prometheus-metrics/elrond-exporter.prom
```

# Future

A go / python version of this exporter would be ideal.
