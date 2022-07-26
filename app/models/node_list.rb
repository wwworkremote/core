# frozen_string_literal: true

class NodeList # :nodoc:
  include Enumerable

  attr_reader :head, :tail

  def initialize(head, tail = nil)
    @head = head
    @tail = tail
  end

  def <<(item)
    self.class.new(item, self)
  end

  def inspect
    [head, tail].inspect
  end

  def each(&block)
    return to_enum(:each) unless block

    yield(head)

    tail&.each(&block)
  end
end
