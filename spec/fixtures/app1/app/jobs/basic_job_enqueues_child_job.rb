class BasicJobEnqueuesChildJob < ApplicationJob
  def perform
    # do stuff
    ChildJob.perform_later
  end
end
