require "spec"
require "redis"
require "../src/pennant"

Pennant.config do |c|
  c.adapter = Pennant::RedisAdapter.new(Redis::Client.new)
end
