require "./spec_helper"
require "uuid"

Redis::Client.new.del "pennant-features"

describe Pennant do
  it "enables a flag" do
    feature = UUID.random.to_s
    Pennant.enable feature

    Pennant.enabled?(feature).should eq true
  end

  it "disables a flag" do
    feature = UUID.random.to_s
    Pennant.enable feature
    Pennant.enabled?(feature).should eq true

    Pennant.disable feature
    Pennant.enabled?(feature).should eq false
  end

  it "enables a flag for a specific actor but not globally" do
    feature = UUID.random.to_s
    actor = TestActor.new(UUID.random.to_s)

    Pennant.enable feature, for: actor

    Pennant.enabled?(feature).should eq false
    Pennant.enabled?(feature, for: actor).should eq true
  end

  it "enables a flag for an actor if it is enabled globally" do
    feature = UUID.random.to_s
    actor = TestActor.new(UUID.random.to_s)

    Pennant.enable feature

    Pennant.enabled?(feature, for: actor).should eq true
  end

  it "disables a flag for a specific actor but not globally" do
    feature = UUID.random.to_s
    actor = TestActor.new(UUID.random.to_s)
    Pennant.enable feature

    Pennant.disable feature, for: actor

    Pennant.enabled?(feature).should eq true
    Pennant.enabled?(feature, for: actor).should eq false
  end

  it "enables a flag for a percentage of time" do
    feature = UUID.random.to_s

    Pennant.enable feature, percentage_of_time: 0.6 # 60% of the time

    true_count = 0
    1_000.times do
      true_count += 1 if Pennant.enabled?(feature)
    end

    # A 60% probability should be true close to 60% of the time. We allow ±10%
    # wiggle room. NOTE: This can cause false negatives if it's outside this
    # range. I have no idea how to make this predictable for testing purposes.
    true_count.should be_close 600, delta: 100
  end

  it "lists all features only once" do
    toggled_on = UUID.random.to_s
    toggled_off = UUID.random.to_s
    actor_specific = UUID.random.to_s
    percentage_of_time = UUID.random.to_s
    actor = TestActor.new(UUID.random.to_s)

    Pennant.enable toggled_on
    Pennant.disable toggled_off
    Pennant.enable toggled_on, for: actor
    Pennant.enable actor_specific, for: actor
    Pennant.enable percentage_of_time, percentage_of_time: 0.6

    features = Pennant.features.map(&.name).sort
    features.should contain toggled_on
    features.should contain toggled_off
    features.should contain actor_specific
    features.should contain percentage_of_time
    features.count(toggled_on).should eq 1
  end
end

class TestActor
  include Pennant::Actor

  getter pennant_id : String

  def initialize(@pennant_id)
  end
end
