#!/usr/bin/ruby
require 'json'
require "httparty"

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

def extract_info(heartbeats_array,statistics_hash, network)
	heartbeats_array.each do |heartbeat|
			metricLabels = "displayName=\"#{heartbeat['nodeDisplayName']}\",network=\"#{network}\",nodeType=\"#{heartbeat['peerType']}\",shardID=\"#{setMetaLabel(heartbeat['receivedShardID'])}\",validatorPubkey=\"#{heartbeat['publicKey']}\",identity=\"#{heartbeat['identity']}\",isActive=\"#{heartbeat['isActive']}\",version=\"#{heartbeat['versionNumber']}\""
      puts "elrond_node_r_is_active{#{metricLabels}} #{true_false(heartbeat['isActive'])}"
			puts "elrond_node_r_total_uptime_sec{#{metricLabels}} #{heartbeat['totalUpTimeSec']}"
			puts "elrond_node_r_total_downtime_sec{#{metricLabels}} #{heartbeat['totalDownTimeSec']}"
			puts "elrond_node_r_received_shard_id{#{metricLabels}} #{heartbeat['receivedShardID']}"
			puts "elrond_node_r_computed_shard_id{#{metricLabels}} #{heartbeat['computedShardID']}"
      puts "elrond_node_r_nonce{#{metricLabels}} #{heartbeat['nonce']}"
			if heartbeat['peerType'] != "observer"
			 	extract_statistics(statistics_hash,"#{heartbeat['publicKey']}", metricLabels)
		  end
	end
end

def extract_obs_status(status_hash,network)
    metricLabels="displayName=\"#{status_hash['erd_node_display_name']}\",nodeType=\"#{status_hash['erd_node_type']}\",network=\"#{network}\",shardID=\"#{status_hash['erd_shard_id']}\",validatorPubkey=\"#{status_hash['erd_p ublic_key_block_sign']}\",syncStatus=\"#{status_hash['erd_is_syncing']}\""
    puts "elrond_obs_sync_status{#{metricLabels}} #{status_hash['erd_is_syncing']}"
    puts "elrond_obs_epochNumber{#{metricLabels}} #{status_hash['erd_epoch_number']}"
end


# The function will read data from API and write response to filename passed as the second argument
def  get_heartbeatstatus(api_url)
  url="#{api_url}/node/heartbeatstatus"
  body = HTTParty.get(url).body
  validate_api_response(body)
  return body
  #`/usr/bin/curl --compressed -s #{api_url}/node/heartbeatstatus > #{fname}`
end

# The function will read data from API and write response to filename passed as the second argument
def  get_statistics(api_url)
  url="#{api_url}/validator/statistics"
  body = HTTParty.get(url).body
  validate_api_response(body)
  return body
  #`/usr/bin/curl --compressed -s #{api_url}/validator/statistics > #{fname}`
end

def read_observer_status(api_url, fname)
  `/usr/bin/curl --compressed -s #{api_url}/node/status > #{fname}`
end

def validate_api_response(json_data)
  if ! valid_json?(json_data)
  	puts "JSON file is not valid"
    puts json_data
  	exit
  end
end

# Read the Observer stats only if the API allows it. If the variable is empty it will not generate those metrics
def get_metrics(api_url, network, obstats_fname="")

  #heartbeatstatus = JSON.parse(get_heartbeatstatus(api_url))
  #statistics = JSON.parse(get_statistics(api_url))

  heartbeats_array = JSON.parse(get_heartbeatstatus(api_url))['data']['heartbeats']
  statistics_hash = JSON.parse(get_statistics(api_url))['data']['statistics']

  extract_info(heartbeats_array, statistics_hash, network)

  unless obstats_fname.to_s.strip.empty?
    read_observer_status(api_url, obstats_fname)
    status_file = File.read(obstats_fname)
    validate_api_response(status_file)
    status = JSON.parse(status_file)
    status_hash = status['data']['metrics']
    extract_obs_status(status_hash, network)
  end
end

api_url = "https://api.elrond.com"
network = "mainnet"
get_metrics(api_url, network)

#api_url = "https://testnet-api.elrond.com"
#network = "testnet"
#get_metrics(api_url, network)
