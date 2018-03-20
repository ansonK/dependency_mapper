require 'graphviz'

GRAPH_OPTIONS = {
  default: {},
  blue_square: { "shape" => "polygon", "sides" => "4", "color" => "lightblue", "style" => "filled" },
  green_circle: { "color" => "palegreen", "style" => "filled" }
}.freeze

class GraphDrawer
  def initialize(repositories: [])
    @repositories = repositories
  end

  def draw(filename: nil)
    @repositories.each do |repository|
      subgraph = repo_graph(repository)
      draw_repository(repository, subgraph: subgraph)
    end

    graph.output(png: "#{filename || repository.name}.png")
  end

  private

  def graph
    @graph ||= GraphViz::new( "G", "rankdir" => "LR" )
  end

  def repo_graph(repository)
    graph.add_graph(repository.name, "label" => repository.name)
  end

  def nodes
    @nodes ||= {}
  end

  def draw_repository(repository, subgraph:)
    repository.jobs.sort_by(&:full_name).reverse.each do |job|
      add_job_to_graph(job, subgraph: subgraph)
    end
  end

  def find_or_create_node(object, subgraph:, type: :default)
    nodes[object.full_name] || create_node(object, subgraph: subgraph, type: type)
  end

  def create_node(object, subgraph:, type: :default)
    nodes[object.full_name] = subgraph.add_nodes(object.full_name, GRAPH_OPTIONS.fetch(type.to_sym).dup)
  end

  def add_job_to_graph(job, subgraph:, parent_node: nil, parent_job: nil)
    job_node = find_or_create_node(job, subgraph: subgraph, type: :green_circle)

    subgraph.add_edges(parent_node, job_node) if parent_node

    job.child_jobs.each do |child_job|
      next if parent_job && parent_job == child_job

      add_job_to_graph(child_job, subgraph: subgraph, parent_node: job_node, parent_job: job)
    end

    job.events_published.each do |event|
      event_node = find_or_create_node(event, subgraph: subgraph, type: :blue_square)

      graph.add_edges(job_node, event_node)
    end

    job.triggered_by_events.each do |event|
      event_node = find_or_create_node(event, subgraph: subgraph, type: :blue_square)

      graph.add_edges(event_node, job_node)
    end
  end
end
