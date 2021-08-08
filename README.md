# Pennant

Feature flags for your application, with pluggable backends.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pennant:
       github: jgaskins/pennant
   ```

2. Run `shards install`

## Usage

Load and configure Pennant:

```crystal
require "pennant"
require "redis"

redis = Redis::Client.new

Pennant.config do |c|
  c.adapter = Pennant::RedisAdapter.new(redis)
end
```

Now, anywhere in your application, you can simply call `Pennant.enabled?("my-feature")` to see if a particular feature flag is enabled.

To enable or disable a feature flag, you can simply call "Pennant.enable("my-feature")` or `Pennant.disable("my-feature")`, respectively. To run this in production, you can run the following command at a production Bash prompt (assuming your Pennant configuration exists in `./config/pennant.cr`):

```
crystal eval 'require "./config/pennant"; Pennant.enable "my-feature"'
```

For example, if your Crystal application is running on Heroku, you can prefix the command with `heroku run ...`. If it's running on Kubernetes, you could prefix it with `kubectl exec -it $POD -- ...`.

### Enabling for a given actor

Pennant allows enabling a feature for specific actors, such as specific users, groups. Any object in your application can be used for this purpose as long as it includes the `Pennant::Actor` mixin, which requires defining the `pennant_id` method:

```crystal
struct User
  include Pennant::Actor

  getter id : UUID

  def pennant_id : String
    "User:#{id}"
  end
end
```

The format of `pennant_id` is up to you, as long as it uniquely identifies that person, group, or concept and resolves to the same value for it every time. For database-backed objects, this is often a class (or table) name and a primary key.

Once you have this in place, you can check whether a feature is enabled by passing `for: actor` to the `enable`, `disable`, and `enabled?` method:

```crystal
if Pennant.enabled?("my-feature", for: current_user)
  # new hotness
else
  # old and busted
end
```

### Enabling for a percentage of requests

Sometimes you don't necessarily want to enable a feature for the same people, but instead for a percentage of your application's traffic. For this, you can pass `percentage_of_time: 0.1` to `enable`:

```crystal
Pennant.enable("my-feature", percentage_of_time: 0.05)
```

All calls to `Pennant.enabled?("my-feature")` will now return `true` 5% of the time. 

## Web UI

There is a web UI in progress to manage feature flags so that you don't need to enable/disable them via production shells. The intent is to be able to insert it into your `HTTP::Server` middleware:

```crystal
http = HTTP::Server.new([
  HTTP::LogHandler.new,
  Pennant::Web.new(mount_at: "/feature_flags"),
  # ...
])
```

With the Lucky framework, you'd insert this into [your `middleware` array](https://luckyframework.org/guides/http-and-routing/http-handlers#built-in-handlers).

## Contributing

1. Fork it (<https://github.com/jgaskins/pennant/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
