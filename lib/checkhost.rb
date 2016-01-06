#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'json'

class CheckHost
    attr_reader :nodes
    
    def initialize(host, options = {:type => 'http', :max_nodes => 3})
        supported_types = %w(ping http tcp dns udp)
        raise(ArgumentError, "unsupported check type (valid values: #{supported_types.join(' ')})") unless supported_types.include?(options[:type])
        raise(ArgumentError, "maximum number of nodes has to be integer") unless options[:max_nodes].is_a? Integer
        
        @host    = host
        @options = options
        @nodes   = []
    end
    
    def run
        res         = parse(query(:newcheck, {:host => @host, :type => @options[:type], :max_nodes => @options[:max_nodes]}))
        @id         = res['request_id']
        @nodes_info = res['nodes']
        @nodes_info.each do |key, value|
            @nodes.push(key);
        end

        res
    end
    
    def node_info(code) # cc, country, location
        if @nodes_info.has_key?(code) then
            return {:cc       => @nodes_info[code][0],
                    :country  => @nodes_info[code][1],
                    :location => @nodes_info[code][2]}
        end
    end

    def check
        res_data = {}
        res = parse(query(:results, {:request_id => @id}))
        res.each do |node, value|
            if !value.nil? then value.flatten!(1) end
            if !value.nil? && !value[0].nil? then # 'cause some return [nil] and can't flatten more
                node_data = {}
                case @options[:type]
                when 'ping' # avg_ok, avg_timeout, avg_malformed, ok_count, timeout_count, malformed_count, ip
                    node_data[:ok_count] = 0
                    node_data[:timeout_count] = 0
                    node_data[:malformed_count] = 0
                    node_data[:avg_ok]        = 0
                    node_data[:avg_timeout]   = 0
                    node_data[:avg_malformed] = 0
                    node_data[:total_count]   = value.count

                    value.each do |info|
                        node_data[:ip] = info[2] if(info[2])
                        case info[0]
                        when 'OK'
                            node_data[:avg_ok]          += info[1]
                            node_data[:ok_count]        += 1
                        when 'TIMEOUT'
                            node_data[:avg_timeout]     += info[1]
                            node_data[:timeout_count]   += 1
                        when 'MALFORMED'
                            node_data[:avg_malformed]   += info[1]
                            node_data[:malformed_count] += 1
                        end
                    end
                    
                    if(node_data[:ok_count] > 0) then
                        node_data[:avg_ok] = (node_data[:avg_ok]*1000).to_i
                        node_data[:avg_ok] /= node_data[:ok_count]
                    end
                    if(node_data[:timeout_count] > 0) then
                        node_data[:avg_timeout] = (node_data[:avg_timeout]*1000).to_i
                        node_data[:avg_timeout] /= node_data[:timeout_count]
                    end
                    if(node_data[:malformed_count] > 0) then
                        node_data[:avg_malformed] = (node_data[:avg_malformed]*1000).to_i
                        node_data[:avg_malformed] /= node_data[:malformed_count]
                    end
                when 'http' # success, time, message, code, ip
                    node_data[:success] = value[0]
                    node_data[:time]    = (value[1]*1000).to_i
                    node_data[:message] = value[2]
                    node_data[:code]    = value[3].to_i
                    node_data[:ip]      = value[4]
                when 'tcp', 'udp' # error, time, ip
                    node_data[:error] = value[0]['error']
                    node_data[:time]  = (value[0]['time']*1000).to_i
                    node_data[:ip]    = value[0]['address']
                when 'dns' # a, aaaa, ttl
                    node_data[:a]    = value[0]['A']
                    node_data[:aaaa] = value[0]['AAAA']
                    node_data[:ttl]  = value[0]['TTL']
                end
                res_data[node] = node_data
            else res_data[node] = nil end
        end
        return res_data
    end    
    
    private
    def query(action, data) # action: newcheck, results; data(hash): newcheck:: type, host, max_nodes | results:: request_id
        headers = {'Accept' => 'application/json'}
        
        case action
        when :newcheck
            open("http://check-host.net/check-#{data[:type]}?host=#{data[:host]}&max_nodes=#{data[:max_nodes]}", headers) {|io| io.read}
        when :results
            open("http://check-host.net/check-result/#{data[:request_id]}", headers) {|io| io.read}
        end
    end
    
    def parse(json)
        res = JSON.parse(json)
        raise "check-host.net returned error: #{res['error']}" if res.has_key?('error')
        return res
    end
end
