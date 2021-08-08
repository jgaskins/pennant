require "../src/web"
require "redis"

Pennant.config do |c|
  c.adapter = Pennant::RedisAdapter.new(Redis::Client.new)
end

http = HTTP::Server.new([
  HTTP::LogHandler.new,
  Pennant::Web.new(mount_at: "/feature_flags"),
])

port = ENV.fetch("PORT", "2345").to_i
puts "Listening on #{port}..."
http.listen port
