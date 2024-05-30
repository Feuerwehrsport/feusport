# frozen_string_literal: true

Ui::PageBuilder = Struct.new(:options, :view, :block) do
  attr_reader :body

  def initialize(*args)
    super
    @tabs = Ui::NavBuilder.new(options, view)
    view.capture_haml(self, &block)
  end

  def title(title = nil)
    @title = title if title
    @title
  end

  def sub_title(sub_title = nil)
    @sub_title = sub_title if sub_title
    @sub_title
  end

  def sub_title2(sub_title2 = nil)
    @sub_title2 = sub_title2 if sub_title2
    @sub_title2
  end

  def tabs(options = {}, &block)
    @tabs = Ui::NavBuilder.new(options, view, block) if block
    @tabs
  end

  def head_title
    parts = []
    parts << tabs.detect(&:active)&.label
    parts << title
    parts.compact_blank.join(' - ')
  end

  private

  def to_string(something)
    return something.model_name.human(count: :many) if something.is_a?(Class) && something.respond_to?(:model_name)

    something
  end
end
