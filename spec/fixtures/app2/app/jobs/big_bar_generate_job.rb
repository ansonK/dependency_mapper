class BigBarGenerateJob < ApplicationJob
  def perform
    BusinessEvent.publish(:foo, :big_bar, payload: { lots: 'of', stuff: 'here' })
  end
end
