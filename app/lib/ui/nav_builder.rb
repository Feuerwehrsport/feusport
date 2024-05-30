# frozen_string_literal: true

Ui::NavBuilder = Struct.new(:options, :view, :block) do
  attr_reader :items

  delegate :each, :empty?, :map, :filter, :detect, to: :items

  def initialize(*args)
    super
    @items = []
    view.capture_haml(self, &block) if block
  end

  def link_to(label, url, options = {})
    options[:active] = view.try(:resource_class) == label unless options.key?(:active)
    @items << Ui::NavBuilderItem.new(to_string(label), url, options)
  end

  def dropdown(label, options = {}, &block)
    return unless block

    dropdown = Ui::NavBuilder.new(options, view, block)
    @items << Ui::NavBuilderItem.new(to_string(label), nil, { type: :dropdown, dropdown: })
  end

  private

  def to_string(something)
    return something.model_name.human(count: :many) if something.is_a?(Class) && something.respond_to?(:model_name)

    something
  end
end

Ui::NavBuilderItem = Struct.new(:label, :url, :options) do
  def active
    options[:active]
  end

  def data
    options[:data]
  end

  def variant
    options[:variant]
  end

  def btn_classes(fallback_variant, additional_classes = [])
    ["btn btn-#{variant || fallback_variant}", additional_classes.presence].compact.join(' ')
  end

  def start_icon_class
    "far fa-#{options[:start_icon].to_s.dasherize}" if options[:start_icon].present?
  end

  def end_icon_class
    "far fa-#{options[:end_icon].to_s.dasherize}" if options[:end_icon].present?
  end

  def dropdown?
    options[:type] == :dropdown
  end

  def dropdown
    options[:dropdown]
  end
end
