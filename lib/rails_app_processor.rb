require 'yaml'
require './lib/repository'
require './lib/job'
require './lib/object_instance'
require './lib/business_event'

class RailsAppProcessor
  def initialize(repository:)
    @repository = repository
  end

  def process
    discover_objects
    process_objects
    process_business_events
  end

  private

  attr_reader :repository

  def process_business_events
    hash = YAML.load(File.open repository.business_event_file.to_s)
    hash.each do |topic, events|
      events.each do |event, job_full_names|
        business_event = BusinessEvent.find_or_create(topic: topic, name: event)

        job_full_names.each do |job_full_name|
          job_module_names = job_full_name.split('::').reverse.drop(1).reverse
          job_class_name = job_full_name.split('::').last

          job = repository.find_or_create_object(class_name: job_class_name, module_names: job_module_names)

          business_event.add_job(job)
        end
      end
    end
  end

  def discover_objects
    repository.filepaths.each do |filepath|
      discover_object(filepath)
    end
  end

  def discover_object(filepath)
    content = File.read(filepath)

    module_names = content.scan(/module (\w+)/)
    class_name = content.scan(/class (\w+)/).first&.first

    puts "ERROR: Object at #{filepath} does not have a class defined" && return unless class_name

    obj = repository.find_or_create_object(class_name: class_name, module_names: module_names)
    obj.tap { |obj| obj.filepath = filepath }
  end

  def process_objects
    repository.objects.each do |obj|
      process_object(obj)
    end
  end

  def process_object(obj)
    content = obj.content

    child_job_classes = content.split("\n").map { |row| row.match(/([\w]+?)\.perform_later/)&.captures }.compact.flatten

    child_job_classes.each do |child_jobs_class_name|
      child_job = repository.find_object(class_name: child_jobs_class_name)
      obj.add_child_object(child_job) if child_job
    end

    events_published = content.split("\n").map { |row| row.match(/BusinessEvent\.publish\(\:([\w]+),\W\:([\w]+).*\)/)&.captures }.compact
    events_published.each do |topic_and_name|
      business_event = BusinessEvent.find_or_create(topic: topic_and_name.first, name: topic_and_name.last)
      obj.add_published_event(business_event)
    end
  end

  # def process_child_jobs(job)
  #   child_job_classes = job.content.split("\n").map { |r| r.match(/([\w]+?)\.perform_later/)&.captures }.compact.flatten

  #   child_job_classes.each do |child_jobs_class_name|
  #     child_job = repository.find_job_by_class_name(child_jobs_class_name)
  #     job.add_child_job(child_job) if child_job
  #   end

  #   events_published = job.content.split("\n").map { |row| row.match(/BusinessEvent\.publish\(\:([\w]+),\W\:([\w]+).*\)/)&.captures }.compact
  #   events_published.each do |topic_and_name|
  #     business_event = BusinessEvent.find_or_create(topic: topic_and_name.first, name: topic_and_name.last)
  #     job.add_published_event(business_event)
  #   end
  # end
end
