class BasicJob < ApplicationJob
  def perform
    # do stuff
    BusinessEvent.publish(:foo, :small_bar, payload: { more: 'stuff', to: 'send' })
  end
end
