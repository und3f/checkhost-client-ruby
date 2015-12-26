#!/usr/bin/env ruby
require 'checkhost'
res = {}

google = CheckHost.new('google.com', {:type => 'http', :max_nodes => 3})
google.run
res = google.check until !res.empty? && !res.has_value?(nil)

print 'Check nodes: '
google.nodes.each do |node|
    node = google.node_info(node)
    print "#{node[:country]}(#{node[:location]}) "
end
puts "\n\n"
res.each do |node, result|
    country = google.node_info(node)[:country]
    message = result[:message]
    time    = result[:time]
    
    puts "#{country}: #{message} (in #{time}ms)"
end