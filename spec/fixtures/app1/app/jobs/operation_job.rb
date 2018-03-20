class OperationJob < ApplicationJob
  def perform
    DoStuffOperation.call
  end
end
