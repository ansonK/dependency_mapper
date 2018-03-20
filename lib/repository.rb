require 'pathname'
require './lib/job'

class Repository
  attr_reader :name, :location, :objects

  def initialize(name:, location:, business_event_file_path: 'config/business_events.yml')
    @name = name
    @location = location
    @objects = []
    @business_event_file_path = business_event_file_path
  end

  def jobs
    @objects.select { |obj| obj.filename =~ /app\/jobs/ }
  end

  def base_path
    Pathname.new(File.expand_path(File.join(__FILE__, '../../', location)))
  end

  def filepaths
    [
      Dir[base_path.join('app/controllers/**/*.rb').to_s],
      Dir[base_path.join('app/models/**/*.rb').to_s],
      Dir[base_path.join('app/jobs/**/*.rb').to_s],
      Dir[base_path.join('app/operations/**/*.rb').to_s]
    ].flatten
  end

  def business_event_file
    base_path.join(@business_event_file_path)
  end

  def add_object(object)
    @objects << object
  end

  def find_object(class_name:, module_names: [])
    if module_names.empty?
      @objects.find { |obj| obj.class_name == class_name }
    else
      @objects.find { |obj| obj.class_name == class_name && module_names == module_names }
    end
  end

  def find_or_create_object(class_name:, module_names: [])
    find_object(class_name: class_name, module_names: module_names) || ObjectInstance.new(repository: self, class_name: class_name, module_names: module_names).tap { |obj| add_object(obj) }
  end

  def to_s
    "<Repository:#{object_id} name: #{name} location: #{location}>"
  end
end
