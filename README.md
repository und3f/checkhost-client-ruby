# checkhost-ruby
checkhost-ruby is a Ruby gem to check-host.net API, supporting all the checks so far published (ping, http, tcp, dns and udp). The official API reference can be found [here](http://check-host.net/about/api).

## Compatibility
Only standard library is required.
Tested on:
* 1.9.1-p431
* 1.9.3-p194
* 1.9.3-p551
* 2.0.0-p643
* 2.1.5-p273
* 2.2.1-p85

## Attributes
##### nodes

Array containing the nodes codes used for the check.
## Methods
##### new(*<host&gt;*, {*[:type]*, *[:max_nodes]*})

Initializes a new instance to check *<host&gt;*. Note this doesn't actually begin any check.

*<type&gt;*: one of the supported check protocols (default: http)

*<max_nodes&gt;*: max number of nodes to run the check with (default: 3)

##### run()

Sends the API request.

##### check()

Returns an hash containing the current check results, with nodes codes as keys.

##### node_info(*<code&gt;*)

Returns an array containing country code, country name and location of the node.

*<code&gt;*: node code (see *nodes* attribute)
## Example
```
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
```
```
Check nodes: Italy(Milano) United Kingdom(London) Netherlands(Amsterdam) 

Italy: Found (in 16ms)
United Kingdom: Found (in 4ms)
Netherlands: Found (in 14ms)
```
## License
checkhost-ruby is licensed under the MIT license. For a copy of the license refer to the LICENSE file.