require "json"

module Pennant
  VERSION = "0.1.0"

  CONFIG = Configuration.new

  def self.config
    yield CONFIG
  end

  extend self

  def enable(feature : String)
    CONFIG.adapter.enable feature
  end

  def enable(feature : String, *, for actor : Actor)
    CONFIG.adapter.enable feature, for: actor
  end

  def enable(feature : String, *, percentage_of_time : Float64)
    CONFIG.adapter.enable feature, percentage_of_time: percentage_of_time
  end

  def disable(feature : String)
    CONFIG.adapter.disable feature
  end

  def disable(feature : String, for actor : Actor)
    CONFIG.adapter.disable feature, for: actor
  end

  def enabled?(feature : String)
    CONFIG.adapter.enabled? feature
  end

  def enabled?(feature : String, for actor : Actor) : Bool
    CONFIG.adapter.enabled? feature, for: actor
  end

  def features
    CONFIG.adapter.features
  end

  class Configuration
    property adapter : Adapter = MemoryAdapter.new
  end

  abstract class Adapter
    abstract def enable(feature : String) : Nil
    abstract def enable(feature : String, *, for actor : Actor) : Nil
    abstract def enable(feature : String, *, percentage_of_time : Float64) : Nil
    abstract def disable(feature : String) : Nil
    abstract def disable(feature : String, *, for actor : Actor) : Nil
    abstract def enabled?(feature : String) : Bool
    abstract def enabled?(feature : String, *, for actor : Actor) : Bool

    abstract def features : Enumerable(Feature)
  end

  module Feature
    getter name : String
  end

  struct ToggleFeature
    include Feature

    getter? enabled : Bool

    def initialize(@name, @enabled)
    end
  end

  struct PercentageOfTimeFeature
    include Feature

    getter percentage_of_time : Float64
    getter? enabled : Bool

    def initialize(@name, @percentage_of_time)
      @enabled = rand(@percentage_of_time)
    end
  end

  class MemoryAdapter < Adapter
    def initialize(@features : Hash(String, Bool) = {} of String => Bool)
    end

    def enable(feature : String) : Nil
      @features[feature] = true
    end

    def enable(feature : String, *, for actor : Actor) : Nil

    end

    def enable(feature : String, *, percentage_of_time : Float64) : Nil

    end

    def disable(feature : String) : Nil
    end

    def disable(feature : String, *, for actor : Actor) : Nil
    end

    def enabled?(feature : String) : Bool
      @features.has_key?(feature)
    end

    def enabled?(feature : String, *, for actor : Actor) : Bool
      @features.has_key?(key(feature, actor))
    end

    def features : Enumerable(Feature)
      [] of Feature
    end

    private def key(feature, actor) : String
      "#{feature}/#{actor.pennant_id}"
    end
  end

  class RedisAdapter < Adapter
    KEY = "pennant-features"

    def initialize(@redis : Redis::Client)
    end

    def enable(feature : String) : Nil
      @redis.hset KEY, feature, "true"
    end

    def enable(feature : String, *, for actor : Actor) : Nil
      @redis.hset KEY, key(feature, actor), "true"
    end

    def enable(feature : String, *, percentage_of_time : Float64) : Nil
      @redis.hset KEY, feature, PercentageOfTime.new(percentage_of_time).to_json
    end

    def disable(feature : String) : Nil
      @redis.hset KEY, feature, "false"
    end

    def disable(feature : String, *, for actor : Actor) : Nil
      @redis.hset KEY, key(feature, actor), "false"
    end

    def enabled?(feature : String) : Bool
      case value = @redis.hget(KEY, feature)
      when nil
        false
      when "true"
        true
      when String
        if value.includes? "percentage_of_time"
          rand < PercentageOfTime.from_json(value).percentage_of_time
        else
          false
        end
      else
        false
      end
    end
    record PercentageOfTime, percentage_of_time : Float64 do
      include JSON::Serializable
    end

    def enabled?(feature : String, *, for actor : Actor) : Bool
      case value = @redis.hget(KEY, key(feature, actor))
      when "false"
        false
      when nil
        enabled? feature
      when "true", ""
        true
      else
        raise InvalidSetting.new("Stored value is wrong: #{value.inspect}")
      end
    end

    def features : Enumerable(Feature)
      cursor = "0"
      values = [] of Feature
      started = false
      feature_names = Set(String).new

      @redis.hscan_each KEY do |key, value|
        if index = key.index("/actor:")
          key = key[0...index]
        end

        unless feature_names.includes? key
          values << ToggleFeature.new(key, enabled: value == "true")
          feature_names << key
        end
      end

      values
    end

    private def key(feature : String, actor : Actor) : String
      "#{feature}/actor:#{actor.pennant_id}"
    end

    class InvalidSetting < Exception
    end
  end

  module Actor
    abstract def pennant_id : String
  end
end

module Redis
  module Commands
    def hset(key : String, field : String, value : String)
      run({"hset", key, field, value})
    end

    def hexists(key : String, field : String)
      run({"hexists", key, field})
    end

    def hget(key : String, field : String)
      run({"hget", key, field})
    end

    def hdel(key : String, field : String)
      run({"hdel", key, field})
    end

    def hgetall(key : String)
      run({"hgetall", key})
    end

    def hscan(key : String, cursor : String = "0", *, match : String? = nil, count : String? = nil)
      command = {"hscan", key, cursor}
      command += {"match", match} if match
      command += {"count", count} if count

      run command
    end

    def hscan_each(key : String, *, match : String? = nil, count : String? = nil, & : String, String ->)
      cursor = "0"
      started = false

      until started && cursor == "0"
        started = true

        _cursor, array = hscan(key, cursor, match: match, count: count).as(Array)
        cursor = _cursor.as(String)
        array.as(Array).each_slice(2) do |(key, value)|
          yield key.as(String), value.as(String)
        end
      end
    end
  end
end
