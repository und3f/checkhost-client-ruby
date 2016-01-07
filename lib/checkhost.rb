#!/usr/bin/env ruby
require 'checkhost/client'

module CheckHost
    def self.new(*args)
        CheckHost::Client.new(*args)
    end
end
