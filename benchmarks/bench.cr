require "benchmark"
require "../src/pennant"
require "redis"
require "uuid"

redis = Redis::Client.new
Pennant.config { |c| c.adapter = Pennant::RedisAdapter.new(redis) }
redis.hdel "pennant-features", "my-feature"

feature = "my-feature" 
actor = MyActor.new(UUID.random.to_s)

Benchmark.ips do |x|
  x.report "enable" { Pennant.enable feature }
  x.report "enable for actor" { Pennant.enable feature, for: actor }
  x.report "enabled? true" { Pennant.enabled? feature }
  x.report "enabled? false" { Pennant.enabled? "nope" }
  x.report "enabled? for actor, true" { Pennant.enabled? feature, for: actor }
  x.report "enabled? for actor, false" { Pennant.enabled? "nope", for: actor }
  x.report "enable percentage_of_time" { Pennant.enable feature, percentage_of_time: 0.1 }
  x.report "enabled? percentage_of_time" { Pennant.enabled? feature }
  x.report "disable" { Pennant.disable feature }
  x.report "disable for actor" { Pennant.disable "my-feature", for: actor }
end

struct MyActor
  include Pennant::Actor

  getter pennant_id : String

  def initialize(@pennant_id)
  end
end
