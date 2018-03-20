class BusinessEvent
  @@events = []

  attr_reader :topic, :name, :jobs

  def initialize(topic:, name:)
    @topic = topic.to_sym
    @name = name.to_sym
    @jobs = []
  end

  def full_name
    "#{topic} #{name}"
  end

  def add_job(job)
    @jobs << job
    job.add_business_event_triggers(self)
  end

  def to_s
    "<BusinessEvent:#{object_id} topic: #{topic} name: #{name}>"
  end
  alias inspect to_s

  def self.add_event(event)
    @@events << event
  end

  def self.all
    @@events
  end

  def self.find(topic:, name:)
    @@events.find { |e| e.topic == topic.to_sym && e.name == name.to_sym }
  end

  def self.create(topic:, name:)
    new(topic: topic, name: name).tap { |be| @@events << be }
  end

  def self.find_or_create(topic:, name:)
    find(topic: topic, name: name) || create(topic: topic, name: name)
  end
end
