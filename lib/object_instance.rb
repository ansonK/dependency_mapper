class ObjectInstance
  attr_reader :repository, :class_name, :child_objects, :events_published, :triggered_by_events
  attr_accessor :filepath

  def initialize(repository:, class_name:, module_names: [])
    @repository = repository
    @class_name = class_name
    @module_names = module_names
    @filepath = filepath
    @child_objects = []
    @events_published = []
    @triggered_by_events = []
  end

  alias name class_name

  def full_name
    repository.name.to_s + ' ' + [@module_names,class_name].flatten.join('::')
  end

  def content
    File.read(filepath)
  end

  def add_child_object(object)
    return if @child_objects.include?(object)

    @child_objects << object
  end

  def add_business_event_triggers(business_event)
    @triggered_by_events << business_event
  end

  def add_published_event(business_event)
    @events_published << business_event
  end

  def <=>(other_job)
    full_name <=> other_job.full_name
  end

  def to_s
    "<Object:#{object_id} repository: #{repository.name} class_name: #{class_name} module_names: #{@module_names}>"
  end
  alias inspect to_s
end
