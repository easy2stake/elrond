#!/usr/bin/ruby
require 'json'

def valid_json?(json)
    JSON.parse(json)
    true
rescue
    false
end

def extract_statistics(statistics_hash,publickey, metricLabels)
	statistics_hash.each do |key, value|
		if key == publickey
			puts "elrond_node_r_rating_modifier{#{metricLabels}} #{value['ratingModifier']}"
			puts "elrond_node_r_shard_id{#{metricLabels}} #{value['shardId']}"
			puts "elrond_node_r_epoch_rating{#{metricLabels}} #{value['tempRating']}"
			puts "elrond_node_r_epoch_leader_success{#{metricLabels}} #{value['numLeaderSuccess']}"
			puts "elrond_node_r_epoch_leader_failure{#{metricLabels}} #{value['numLeaderFailure']}"
			puts "elrond_node_r_epoch_validator_success{#{metricLabels}} #{value['numValidatorSuccess']}"
			puts "elrond_node_r_epoch_validator_failure{#{metricLabels}} #{value['numValidatorFailure']}"
			puts "elrond_node_r_epoch_validator_ignored_signatures{#{metricLabels}} #{value['numValidatorIgnoredSignatures']}"
			puts "elrond_node_r_total_rating{#{metricLabels}} #{value['rating']}"
			puts "elrond_node_r_total_leader_success{#{metricLabels}} #{value['totalNumLeaderSuccess']}"
			puts "elrond_node_r_total_leader_failure{#{metricLabels}} #{value['totalNumLeaderFailure']}"
			puts "elrond_node_r_total_validator_success{#{metricLabels}} #{value['totalNumValidatorSuccess']}"
			puts "elrond_node_r_total_validator_failure{#{metricLabels}} #{value['totalNumValidatorFailure']}"
			puts "elrond_node_r_total_validator_ignored_signatures{#{metricLabels}} #{value['totalNumValidatorIgnoredSignatures']}"
		end
	end
end


def true_false(condition)
	if condition
		return 0
	else
		return 1
	end
end

def setMetaLabel(shardid)
	if shardid == 4294967295
		return "meta"
	else
		return shardid
	end
end

def extract_info(heartbeats_array,statistics_hash,identity)
	heartbeats_array.each do |heartbeat|
		# if heartbeat['identity'] == identity
			metricLabels = "displayName=\"#{heartbeat['nodeDisplayName']}\",nodeType=\"#{heartbeat['peerType']}\",shardID=\"#{setMetaLabel(heartbeat['receivedShardID'])}\",validatorPubkey=\"#{heartbeat['publicKey']}\",identity=\"#{heartbeat['identity']}\",version=\"#{heartbeat['versionNumber']}\""
			puts "elrond_node_r_is_active{#{metricLabels}} #{true_false(heartbeat['isActive'])}"
			puts "elrond_node_r_total_uptime_sec{#{metricLabels}} #{heartbeat['totalUpTimeSec']}"
			puts "elrond_node_r_total_downtime_sec{#{metricLabels}} #{heartbeat['totalDownTimeSec']}"
			puts "elrond_node_r_received_shard_id{#{metricLabels}} #{heartbeat['receivedShardID']}"
			puts "elrond_node_r_computed_shard_id{#{metricLabels}} #{heartbeat['computedShardID']}"
			if heartbeat['peerType'] != "observer"
			 	extract_statistics(statistics_hash,"#{heartbeat['publicKey']}", metricLabels)
		    end
	    # end
	end
end


`/usr/bin/curl --compressed -s https://api.elrond.com/node/heartbeatstatus > heartbeatstatus.json`
`/usr/bin/curl --compressed -s https://api.elrond.com/validator/statistics > statistics.json`

heartbeatstatus_file = File.read("heartbeatstatus.json")
statistics_file = File.read("statistics.json")

if ! valid_json?(heartbeatstatus_file)
	puts "JSON file is not valid"
	exit
end

if ! valid_json?(statistics_file)
	puts "JSON file is not valid"
	exit
end

heartbeatstatus = JSON.parse(heartbeatstatus_file)
statistics = JSON.parse(statistics_file)

heartbeats_array = heartbeatstatus['data']['heartbeats']
statistics_hash = statistics['data']['statistics']

extract_info(heartbeats_array, statistics_hash,"elrondcom")
