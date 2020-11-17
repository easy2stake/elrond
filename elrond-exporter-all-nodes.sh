#!/bin/bash

# Dependencies: curl, jq
# Remote Metrics: Recommended to run at a 1second/node. Ex: Loop each 10 seconds if you scrape metrics for 10 nodes.
# This is for safety. Normally it should scrape 10 nodes in under 5 secs.

# OBSERVER_URL="https://api-testnet.elrond.com"
# OBSERVER_URL="https://api.elrond.com"
# OBSERVER_URL="80.241.217.149:8080"
OBSERVER_URL="144.91.127.3:8081"

# Usage: setMetaLabel $shardId. It will echo "meta" or $shardId given te shardId
setMetaLabel (){
  if [[ $1 -eq 4294967295 ]]
  then
    echo "meta"
  else echo $1
  fi
}
### Observer data
status=$(curl -s ${OBSERVER_URL}/node/status)
read obs_displayName obs_nodeType obs_syncStatus obs_chainID obs_appVersion obs_epochNumber obs_shardID obs_validatorPubkey obs_peers obs_validators obs_nodes obs_nonce obs_shardHeadersInPool obs_shards obs_liveValidators obs_netRxBps obs_netRxBpsPeak obs_netTxBps obs_NetTxBpsPeak obs_erdPeakTPS obs_erdNumShards \
< <(echo $(jq '.data.metrics.erd_node_display_name, .data.metrics.erd_node_type, .data.metrics.erd_is_syncing, .data.metrics.erd_chain_id, .data.metrics.erd_app_version, .data.metrics.erd_epoch_number // 0, .data.metrics.erd_shard_id // 0, .data.metrics.erd_public_key_block_sign, .data.metrics.erd_num_connected_peers // 0, .data.metrics.erd_num_validators // 0, .data.metrics.erd_connected_nodes // 0, .data.metrics.erd_nonce // 0, .data.metrics.erd_num_shard_headers_from_pool // 0, .data.metrics.erd_num_shards_without_meta, .data.metrics.erd_live_validator_nodes // 0, .data.metrics.erd_network_recv_bps // 0, .data.metrics.erd_network_recv_bps_peak // 0, .data.metrics.erd_network_sent_bps // 0, .data.metrics.erd_network_sent_bps_peak // 0, .data.metrics.erd_peak_tps // 0, .data.metrics.erd_num_shards_without_meta // 0' -r <<< $status))

shardIDlabel=$(setMetaLabel $r_receivedShardID)
metricLabels="displayName=\"$obs_displayName\",nodeType=\"$obs_nodeType\",shardID=\"$obs_shardID\",validatorPubkey=\"$obs_validatorPubkey\",syncStatus=\"$obs_syncStatus\""
# Exporting observer prometheus merics
printf "%s\n" "elrond_obs_sync_status{$metricLabels} $obs_syncStatus" \
              "elrond_obs_epochNumber{$metricLabels} $obs_epochNumber"


# Remote metrics - stats that are seen from a different node but itself
# Collect all elrond data and store it inside buffers avoiding unecessary calls
bufHB=$(curl -m 5 -s ${OBSERVER_URL}/node/heartbeatstatus)
allBufStats=$(curl -m 5 -s ${OBSERVER_URL}/validator/statistics) #Should curl only once
####################### ALL NODES #######################
allNodesHB=$(jq ".data.heartbeats[]" -c <<< $bufHB)

for i in $(echo "$allNodesHB" | jq -r '. | @base64')
do
  i=$(base64 --decode <<< $i)
  #if [[ -z $(jq '.identity' -r <<< $i) || $(jq '.identity' -r <<< $i) == "null" ]]; then continue; fi
  #if [[ -z $(jq '.nodeDisplayName' -r <<< $i) || $(jq '.nodeDisplayName' -r <<< $i) == "null" ]]; then continue; fi

  #echo ""
  #echo $i
  #echo "=========================================================="

  read  r_validatorPubkey r_isActive r_totalUpTimeSec r_totalDownTimeSec r_peerType r_receivedShardID r_computedShardID r_nonce\
  < <(echo $(jq '.publicKey, .isActive, .totalUpTimeSec, .totalDownTimeSec, .peerType, .receivedShardID, .computedShardID, .nonce' -r <<< $i))

  read r_displayName < <(echo $(jq '.nodeDisplayName // "noName"' -r <<< $i))
  read r_identity < <(echo $(jq '.identity // "noID"' -r <<< $i))

  # r_maxInactiveTime=$(jq '.maxInactiveTime' -r <<< $i) #The actual format is not prometheus friendly
  # r_peerType #Possible values are: "eligible", "observer", "waiting"
  # r_receivedShardID #What the current observer node received from this peer
  # r_computedShardID #What the current observer node knows abut this peer
  # Hint: r_receivedShardID must EQUAL r_computedShardID when r_peerType=eligible. A specific metric can be added here reflecting this. (elrond_node_shardID)

  # Prepare the metricLabels
  shardIDlabel=$(setMetaLabel $r_receivedShardID)
  metricLabels="displayName=\"$r_displayName\",nodeType=\"$r_peerType\",shardID=\"$shardIDlabel\",validatorPubkey=\"$r_validatorPubkey\",identity=\"$r_identity\",isActive=\"$r_isActive\""

  # Exporting generic prometheus merics
  printf "%s\n" "elrond_node_r_total_uptime_sec{$metricLabels} $r_totalUpTimeSec" \
                "elrond_node_r_total_downtime_sec{$metricLabels} $r_totalDownTimeSec" \
                "elrond_node_r_received_shard_id{$metricLabels} $r_receivedShardID" \
                "elrond_node_r_computed_shard_id{$metricLabels} $r_computedShardID" \
                "elrond_node_r_nonce{$metricLabels} $r_nonce"

  #echo "elrond_node_r_max_inactive_time{$metricLabels} $r_maxInactiveTime" #Must be converted to seconds. The actual format is not prometheus friendly
  # Exporting validator prometheus merics. Do not calculate for observers.

  # if [[ $r_peerType != "observer" ]]
  # then
  #   # Using the discovered r_validatorPubkey collect the validator performance statistics
  #   bufStats=$(jq ".data.statistics.\"$r_validatorPubkey\"" <<< $allBufStats)
  #
  #   read r_ratingModifier r_shardId r_tempRating r_numLeaderSuccess r_numLeaderFailure r_numValidatorSuccess r_numValidatorFailure r_numValidatorIgnoredSignatures r_rating r_totalNumLeaderSuccess r_totalNumLeaderFailure r_totalNumValidatorSuccess r_totalNumValidatorFailure r_totalNumValidatorIgnoredSignatures \
  #   < <(echo $(jq '.ratingModifier, .shardId, .tempRating, .numLeaderSuccess, .numLeaderFailure, .numValidatorSuccess, .numValidatorFailure, .numValidatorIgnoredSignatures, .rating, .totalNumLeaderSuccess, .totalNumLeaderFailure, .totalNumValidatorSuccess, .totalNumValidatorFailure, .totalNumValidatorIgnoredSignatures' -r <<< $bufStats))
  #
  #   printf "%s\n" "elrond_node_r_rating_modifier{$metricLabels} $r_ratingModifier" \
  #           "elrond_node_r_shard_id{$metricLabels} $r_shardId" \
  #           "elrond_node_r_epoch_rating{$metricLabels} $r_tempRating" \
  #           "elrond_node_r_epoch_leader_success{$metricLabels} $r_numLeaderSuccess" \
  #           "elrond_node_r_epoch_leader_failure{$metricLabels} $r_numLeaderFailure" \
  #           "elrond_node_r_epoch_validator_success{$metricLabels} $r_numValidatorSuccess" \
  #           "elrond_node_r_epoch_validator_failure{$metricLabels} $r_numValidatorFailure" \
  #           "elrond_node_r_epoch_validator_ignored_signatures{$metricLabels} $r_numValidatorIgnoredSignatures" \
  #           "elrond_node_r_total_rating{$metricLabels} $r_rating" \
  #           "elrond_node_r_total_leader_success{$metricLabels} $r_totalNumLeaderSuccess" \
  #           "elrond_node_r_total_leader_failure{$metricLabels} $r_totalNumLeaderFailure" \
  #           "elrond_node_r_total_validator_success{$metricLabels} $r_totalNumValidatorSuccess" \
  #           "elrond_node_r_total_validator_failure{$metricLabels} $r_totalNumValidatorFailure" \
  #           "elrond_node_r_total_validator_ignored_signatures{$metricLabels} $r_totalNumValidatorIgnoredSignatures"
  # fi
done
