#! /usr/bin/env ruby

require "fnordmetric"

FNM_HTTP_PORT  = (ENV["FNM_HTTP_PORT"] || 8080).to_i
FNM_UDP_PORT   = (ENV["FNM_UDP_PORT"]  || 2424).to_i
REDIS_URL      = ENV["REDIS_URL"]      || "redis://localhost:10002"
METRICS_PREFIX = ENV["METRICS_PREFIX"] || "redis-metrics"

FnordMetric.namespace :redis do

  hide_overview
  hide_active_users

  timeseries_gauge :clients, {
    group:      "Clients",
    key_nouns:  ["Client", "Clients"],
    calculate:  :average,
    resolution: 1.minute,
    series:     [:connected_clients, :blocked_clients]
  }

  timeseries_gauge :cpu_master, {
    group:      "CPU",
    title:      "Master",
    key_nouns:  ["%", "%"],
    calculate:  :average,
    resolution: 1.minute,
    series:     [:used_cpu_sys, :used_cpu_user]
  }

  timeseries_gauge :cpu_children, {
    group:      "CPU",
    title:      "Children",
    key_nouns:  ["%", "%"],
    calculate:  :average,
    resolution: 1.minute,
    series:     [:used_cpu_sys_children, :used_cpu_user_children]
  }

  timeseries_gauge :memory, {
    group:      "Memory",
    title:      "Usage",
    key_nouns:  ["byte", "bytes"],
    calculate:  :average,
    resolution: 1.minute,
    series:     [:used_memory, :used_memory_peak, :used_memory_rss]
  }

  timeseries_gauge :memory_fragmentation, {
    group:      "Memory",
    title:      "Fragmentation",
    key_nouns:  ["%", "%"],
    calculate:  :average,
    resolution: 1.minute,
    series:     [:mem_fragmentation_ratio]
  }

  event :redis do
    [:connected_clients, :blocked_clients].each do |metric|
      incr :clients, metric, data[metric]
    end

    [:used_cpu_sys, :used_cpu_user].each do |metric|
      incr :cpu_master, metric, data[metric].to_f
    end

    [:used_cpu_sys_children, :used_cpu_user_children].each do |metric|
      incr :cpu_children, metric, data[metric].to_f
    end

    [:used_memory, :used_memory_peak, :used_memory_rss].each do |metric|
      incr :memory, metric, data[metric].to_i
    end

    incr :memory_fragmentation, :mem_fragmentation_ratio, data[:mem_fragmentation_ratio].to_f
  end

end

FnordMetric.options = {
  redis_url:    REDIS_URL,
  redis_prefix: METRICS_PREFIX
}

FnordMetric::Web.new(:port => FNM_HTTP_PORT)
FnordMetric::Acceptor.new(:protocol => :udp, :port => FNM_UDP_PORT)
FnordMetric::Worker.new
FnordMetric.run
