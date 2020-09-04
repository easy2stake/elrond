#!/bin/bash

# Dependencies: curl, jq
# Remote Metrics: Recommended to run at a 1second/node. Ex: Loop each 10 seconds if you scrape metrics for 10 nodes.
# This is for safety. Normally it should scrape 10 nodes in under 5 secs.


#LOCAL_METRICS=${E_LOCAL_METRICS:=0}
#LOCAL_NODES=$E_LOCAL_NODES
#REMOTE_METRICS=${E_REMOTE_METRICS:=1}
#IDENTITY=$E_IDENTITY
#OBSERVER_URL=${E_OBSERVER_URL:="https://api.elrond.com"}

LOCAL_METRICS=1 #Enable local metrics
LOCAL_NODES=(127.0.0.1:8080)  #Insert your own nodes inside the paranthesis
REMOTE_METRICS=1
OBSERVER_URL="https://api.elrond.com"
IDENTITY="easy2stake" # Edit this with your own identity

# LOCAL_NODES: Array containing the nodes you want to generate local metrics from.
if [[ -z "$LOCAL_NODES" ]]; then LOCAL_METRICS=0; fi
if [[ -z "$IDENTITY" ]]; then
  echo "Please set the IDENTITY variable."
  exit 1
fi

# Usage: setMetaLabel $shardId. It will echo "meta" or $shardId given te shardId
setMetaLabel (){
  if [[ $1 -eq 4294967295 ]]
  then
    echo "meta"
  else echo $1
  fi
}

if [[ $LOCAL_METRICS -eq 1 ]]
then
  # Defining the metrics used
  echo "# HELP elrond_node_type Elrond node type."
  echo "# TYPE elrond_node_type gauge"
  echo "# HELP elrond_node_sync_status 0=in sync 1=syncing."
  echo "# TYPE elrond_node_sync_status gauge"
  echo "# HELP elrond_node_chain_id The chain ID stripped by all characters but numbers."
  echo "# TYPE elrond_node_chain_id gauge"
  echo "# HELP elrond_node_epoch_number The epoch number."
  echo "# TYPE elrond_node_epoch_number counter"
  echo "# HELP elrond_node_shard_id The shard id. Meta shard is always 4294967295."
  echo "# TYPE elrond_node_shard_id gauge"
  echo "# HELP elrond_node_peers The number of peers the node is connected to."
  echo "# TYPE elrond_node_peers gauge"
  echo "# HELP elrond_node_validators The number of validators reported by the queried node."
  echo "# TYPE elrond_node_validators gauge"
  echo "# HELP elrond_node_nodes The total number of elrond nodes reported by the queried node."
  echo "# TYPE elrond_node_nodes gauge"
  echo "# HELP elrond_node_nonce ERD nonce"
  echo "# TYPE elrond_node_nonce counter"
  echo "# HELP elrond_node_shard_headers_in_pool ERD shard headers in pool"
  echo "# TYPE elrond_node_shard_headers_in_pool gauge"
  echo "# HELP elrond_node_shards_winthout_meta ERD number of shards without meta"
  echo "# TYPE elrond_node_shards_winthout_meta gauge"
  echo "# HELP elrond_node_live_validators The total number of live validators"
  echo "# TYPE elrond_node_live_validators gauge"
  echo "# HELP elrond_node_net_rx_bps Node incoming network traffic [bps]"
  echo "# TYPE elrond_node_net_rx_bps gauge"
  echo "# HELP elrond_node_net_rx_bps_peak Node incoming peak network traffic [bps]"
  echo "# TYPE elrond_node_net_rx_bps_peak gauge"
  echo "# HELP elrond_node_net_tx_bps Node outgoing network traffic [bps]"
  echo "# TYPE elrond_node_net_tx_bps gauge"
  echo "# HELP elrond_node_net_tx_bps_peak Node outgoing peak network traffic [bps]"
  echo "# TYPE elrond_node_net_tx_bps_peak gauge"

  # Local metrics
  for i in "${LOCAL_NODES[@]}"
  do
    status=$(curl -s $i/node/status)
    displayName=$(jq '.data.metrics.erd_node_display_name' -r <<< $status)
    nodeType=$(jq '.data.metrics.erd_node_type' -r <<< $status)
    syncStatus=$(jq '.data.metrics.erd_is_syncing' -r <<< $status)
    chainID=$(jq '.data.metrics.erd_chain_id' -r <<< $status)
    appVersion=$(jq '.data.metrics.erd_app_version' -r <<< $status)
    epochNumber=$(jq '.data.metrics.erd_epoch_number // 0' -r <<< $status)
    shardID=$(jq '.data.metrics.erd_shard_id // 0' -r <<< $status)
    validatorPubkey=$(jq '.data.metrics.erd_public_key_block_sign' -r <<< $status)
    peers=$(jq '.data.metrics.erd_num_connected_peers // 0' -r <<< $status)
    validators=$(jq '.data.metrics.erd_num_validators // 0' -r <<< $status)
    nodes=$(jq '.data.metrics.erd_connected_nodes // 0' -r <<< $status)
    nonce=$(jq '.data.metrics.erd_nonce // 0' -r <<< $status)
    shardHeadersInPool=$(jq '.data.metrics.erd_num_shard_headers_from_pool // 0' -r <<< $status)
    shards=$(jq '.data.metrics.erd_num_shards_without_meta' -r <<< $status)
    liveValidators=$(jq '.data.metrics.erd_live_validator_nodes // 0' -r <<< $status)
    netRxBps=$(jq '.data.metrics.erd_network_recv_bps // 0' -r <<< $status)
    netRxBpsPeak=$(jq '.data.metrics.erd_network_recv_bps_peak // 0' -r <<< $status)
    netTxBps=$(jq '.data.metrics.erd_network_sent_bps // 0' -r <<< $status)
    NetTxBpsPeak=$(jq '.data.metrics.erd_network_sent_bps_peak // 0' -r <<< $status)
    erdPeakTPS=$(jq '.data.metrics.erd_peak_tps // 0' -r <<< $status)
    erdNumShards=$(jq '.data.metrics.erd_num_shards_without_meta // 0' -r <<< $status)
    shardIDlabel=""

    # Set a friendly name for the Meta shard to be used as metricLabels
    shardIDlabel=$(setMetaLabel $shardID)

    # Set the final metricLabels variable
    metricLabels="displayName=\"$displayName\",nodeType=\"$nodeType\",shardID=\"$shardIDlabel\",validatorPubkey=\"$validatorPubkey\""
    metricsLabels_observer="displayName=\"$displayName\",nodeType=\"observer\",shardID=\"$shardIDlabel\",validatorPubkey=\"$validatorPubkey\""
    metricsLabels_validator="displayName=\"$displayName\",nodeType=\"validator\",shardID=\"$shardIDlabel\",validatorPubkey=\"$validatorPubkey\""

    # Make metrics Prometheus compliant
    p_chainID=$(echo $chainID | tr -d "." | tr -d "v")

    #Prometheus metrics
    case $nodeType in
     "validator")
        echo "elrond_node_type{$metricLabels} 1"
        echo "elrond_node_type{$metricsLabels_observer} 0"
        ;;
     "observer")
        echo "elrond_node_type{$metricLabels} 1"
        echo "elrond_node_type{$metricsLabels_validator} 0"
        ;;
    esac

    echo "elrond_node_sync_status{$metricLabels} $syncStatus"
    echo "elrond_node_chain_id{$metricLabels} $p_chainID"
    echo "elrond_node_epoch_number{$metricLabels} $epochNumber"
    echo "elrond_node_shard_id{$metricLabels} $shardID"
    echo "elrond_node_peers{$metricLabels} $peers"
    echo "elrond_node_validators{$metricLabels} $validators"
    echo "elrond_node_nodes{$metricLabels} $nodes"
    echo "elrond_node_nonce{$metricLabels} $nonce"
    echo "elrond_node_shard_headers_in_pool{$metricLabels} $shardHeadersInPool"
    echo "elrond_node_shards_winthout_meta{$metricLabels} $shards"
    echo "elrond_node_live_validators{$metricLabels} $liveValidators"
    echo "elrond_node_net_rx_bps{$metricLabels} $netRxBps"
    echo "elrond_node_net_rx_bps_peak{$metricLabels} $netRxBpsPeak"
    echo "elrond_node_net_tx_bps{$metricLabels} $netTxBps"
    echo "elrond_node_net_tx_bps_peak{$metricLabels} $NetTxBpsPeak"
    echo "elrond_node_num_shards_wo_meta{$metricLabels} $erdNumShards"
  done
fi

if [[ $REMOTE_METRICS -eq 1 ]]
then

  # Remote metrics - stats that are seen from a different node but itself
  # Collect all elrond data and store it inside buffers avoiding unecessary calls
  bufHB=$(curl -m 5 -s ${OBSERVER_URL}/node/heartbeatstatus)
  allBufStats=$(curl -m 5 -s ${OBSERVER_URL}/validator/statistics) #Should curl only once
  myNodesHB=$(jq ".data.heartbeats[] | select (.identity==\"$IDENTITY\")" -c <<< $bufHB)

  for i in $(echo "$myNodesHB")
  do
    r_displayName=$(jq '.nodeDisplayName' -r <<< $i)
    r_identity=$(jq '.identity' -r <<< $i)
    r_validatorPubkey=$(jq '.publicKey' -r <<< $i)

    r_isActive=$(jq '.isActive' -r <<< $i) # This echoes true or false. Must convert to 1/0
    grep -i true <<< $r_isActive 2>&1 > /dev/null
    if [[ $? -eq 0 ]]; then int_r_isActive=1
    else int_r_isActive=0
    fi

    r_totalUpTimeSec=$(jq '.totalUpTimeSec' -r <<< $i)
    r_totalDownTimeSec=$(jq '.totalDownTimeSec' -r <<< $i)
    # r_maxInactiveTime=$(jq '.maxInactiveTime' -r <<< $i) #The actual format is not prometheus friendly
    r_peerType=$(jq '.peerType' -r <<< $i) #Possible values are: "eligible", "observer", "waiting"
    r_receivedShardID=$(jq '.receivedShardID' -r <<< $i) #What the current observer node received from this peer
    r_computedShardID=$(jq '.computedShardID' -r <<< $i) #What the current observer node knows abut this peer
    # Hint: r_receivedShardID must EQUAL r_computedShardID when r_peerType=eligible. A specific metric can be added here reflecting this. (elrond_node_shardID)

    # Prepare the metricLabels
    shardIDlabel=$(setMetaLabel $r_receivedShardID)
    metricLabels="displayName=\"$r_displayName\",nodeType=\"$r_peerType\",shardID=\"$shardIDlabel\",validatorPubkey=\"$r_validatorPubkey\",identity=\"$r_identity\""

    # Exporting generic prometheus merics
    echo "elrond_node_r_is_active{$metricLabels} $int_r_isActive"
    echo "elrond_node_r_total_uptime_sec{$metricLabels} $r_totalUpTimeSec"
    echo "elrond_node_r_total_downtime_sec{$metricLabels} $r_totalDownTimeSec"
    #echo "elrond_node_r_max_inactive_time{$metricLabels} $r_maxInactiveTime" #Must be converted to seconds. The actual format is not prometheus friendly
    echo "elrond_node_r_received_shard_id{$metricLabels} $r_receivedShardID"
    echo "elrond_node_r_computed_shard_id{$metricLabels} $r_computedShardID"

    # Exporting validator prometheus merics. Do not calculate for observers.
    if [[ $r_peerType != "observer" ]]
    then
      # Using the discovered r_validatorPubkey collect the validator performance statistics
      bufStats=$(jq ".data.statistics.\"$r_validatorPubkey\"" <<< $allBufStats)

      r_ratingModifier=$(jq ".ratingModifier"  -r <<< $bufStats)
      r_shardId=$(jq ".shardId" -r <<< $bufStats)
      #r_validatorStatus=$(jq ".validatorStatus")  #Possible values are: "eligible", "waiting". Using r_peerType

      # Current epoch Stats
      r_tempRating=$(jq ".tempRating" -r <<< $bufStats)
      r_numLeaderSuccess=$(jq ".numLeaderSuccess" -r <<< $bufStats)  #Role:block proposer
      r_numLeaderFailure=$(jq ".numLeaderFailure" -r <<< $bufStats)  #Role:block proposer
      r_numValidatorSuccess=$(jq ".numValidatorSuccess" -r <<< $bufStats)  #Role:consensus participant
      r_numValidatorFailure=$(jq ".numValidatorFailure" -r <<< $bufStats)  #Role:consensus participant
      r_numValidatorIgnoredSignatures=$(jq ".numValidatorIgnoredSignatures" <<< $bufStats)

      # Stats since genesis time
      r_rating=$(jq ".rating" <<< $bufStats)
      r_totalNumLeaderSuccess=$(jq ".totalNumLeaderSuccess" -r <<< $bufStats)
      r_totalNumLeaderFailure=$(jq ".totalNumLeaderFailure" -r <<< $bufStats)
      r_totalNumValidatorSuccess=$(jq ".totalNumValidatorSuccess" -r <<< $bufStats)
      r_totalNumValidatorFailure=$(jq ".totalNumValidatorFailure" -r <<< $bufStats)
      r_totalNumValidatorIgnoredSignatures=$(jq ".totalNumValidatorIgnoredSignatures" -r <<< $bufStats)

      echo "elrond_node_r_rating_modifier{$metricLabels} $r_ratingModifier"
      echo "elrond_node_r_shard_id{$metricLabels} $r_shardId"
      # Current epoch Stats
      echo "elrond_node_r_epoch_rating{$metricLabels} $r_tempRating"
      echo "elrond_node_r_epoch_leader_success{$metricLabels} $r_numLeaderSuccess"
      echo "elrond_node_r_epoch_leader_failure{$metricLabels} $r_numLeaderFailure"
      echo "elrond_node_r_epoch_validator_success{$metricLabels} $r_numValidatorSuccess"
      echo "elrond_node_r_epoch_validator_failure{$metricLabels} $r_numValidatorFailure"
      echo "elrond_node_r_epoch_validator_ignored_signatures{$metricLabels} $r_numValidatorIgnoredSignatures"
      # Stats since genesis time
      echo "elrond_node_r_total_rating{$metricLabels} $r_rating"
      echo "elrond_node_r_total_leader_success{$metricLabels} $r_totalNumLeaderSuccess"
      echo "elrond_node_r_total_leader_failure{$metricLabels} $r_totalNumLeaderFailure"
      echo "elrond_node_r_total_validator_success{$metricLabels} $r_totalNumValidatorSuccess"
      echo "elrond_node_r_total_validator_failure{$metricLabels} $r_totalNumValidatorFailure"
      echo "elrond_node_r_total_validator_ignored_signatures{$metricLabels} $r_totalNumValidatorIgnoredSignatures"
    fi
  done
fi

#Other metrics to consider
  #erd_cpu_load_percent
  #erd_mem_load_percent
  #erd_mem_total
  #erd_num_metachain_nodes
  #erd_num_nodes_in_shard
  #erd_num_transactions_processed
  #erd_peak_tps
  #erd_current_block_size
  #erd_app_version
