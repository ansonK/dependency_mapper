require 'active_support/all'
require 'pry'
require './lib/repository'
require './lib/job'
require './lib/rails_app_processor'
require './lib/graph_drawer'

REPOSITORIES = {
  research_site: '../research_site',
  quotes_site: '../quotes_site',
  dealers_site: '../dealers_site',
  performance_stats_service: '../performance_stats_service',
  admin_site: '../flatmin'}.freeze

@repositories = REPOSITORIES.map { |name, location| Repository.new(name: name, location: location) }

@repositories.each { |repo| RailsAppProcessor.new(repository: repo).process }

GraphDrawer.new(repositories: @repositories).draw(filename: 'carwow')

