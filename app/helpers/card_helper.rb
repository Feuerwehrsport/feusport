# frozen_string_literal: true

module CardHelper
  def card(headline = nil, options = {}, &block)
    card = Ui::CardBuilder.new(headline, options, self, block)
    render('card', card:)
  end
end
