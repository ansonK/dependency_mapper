class Job
  attr_reader :repository, :class_name, :child_jobs, :parent_jobs, :content, :events_published, :triggered_by_events

  def initialize(repository:, class_name:, module_names: [], content: '')
    @repository = repository
    @class_name = class_name
    @module_names = module_names
    @content = content
    @child_jobs = []
    @parent_jobs = []
    @events_published = []
    @triggered_by_events = []
  end

  alias name class_name

  def full_name
    repository.name.to_s + ' ' + [@module_names,class_name].flatten.join('::')
  end

  def set_content(content)
    @content = content
  end

  def add_child_job(job)
    return if @child_jobs.include?(job)

    @child_jobs << job
    job.add_parent_job(self)
  end

  def add_business_event_triggers(business_event)
    return unless type == :job

    @triggered_by_events << business_event
  end

  def add_published_event(business_event)
    @events_published << business_event
  end

  def <=>(other_job)
    full_name <=> other_job.full_name
  end

  def to_s
    "<Job:#{object_id} repository: #{repository.name} class_name: #{class_name} module_names: #{@module_names}>"
  end
  alias inspect to_s

  protected

  def add_parent_job(job)
    @parent_jobs << job
  end
end
