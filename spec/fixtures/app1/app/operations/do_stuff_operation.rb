class DoStuffOperation
  def self.call
    BusinessEvent.publish(:foo, :noop, payload: { some: 'stuff' })
    BasicJob.perform_later
  end
end
