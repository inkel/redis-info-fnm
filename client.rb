#! /usr/bin/env ruby

require "redis"
require_relative "./metrics"

FNM_HOST  = ENV["FNM_HOST"]  || "localhost"
FNM_PORT  = (ENV["FNM_PORT"] || 2424).to_i
REDIS_URL = ENV["REDIS_URL"] || "redis://localhost:10001"
INTERVAL  = (ENV["INTERVAL"] || 1).to_i

REDIS_METRICS = %w{
  blocked_clients
  changes_since_last_save
  connected_clients
  connected_slaves
  evicted_keys
  expired_keys
  keyspace_hits
  keyspace_misses
  mem_fragmentation_ratio
  pubsub_channels
  pubsub_patterns
  total_commands_processed
  total_connections_received
  uptime_in_days
  uptime_in_seconds
  used_cpu_sys
  used_cpu_sys_children
  used_cpu_user
  used_cpu_user_children
  used_memory
  used_memory_peak
  used_memory_rss
}

redis = Redis.connect url: REDIS_URL

loop do
  info = redis.info

  data = {}

  REDIS_METRICS.each { |metric| data[metric] = info[metric] }

  data["dbs_in_use"] = info.keys.grep(/^db\d+$/)

  data["dbs_in_use"].each do |db|
    data[db] = {}
    info[db]
      .split(",")
      .map{ |d| d.split("=") }
      .each{ |key, value| data[db][key] = value }
  end

  Metrics.event(:redis, data)

  sleep INTERVAL
end
