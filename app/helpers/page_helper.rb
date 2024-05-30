# frozen_string_literal: true

module PageHelper
  def page_title(page_title, class: nil)
    @page_title = page_title
    tag.h1(page_title, class:)
  end

  def page(options = {}, &block)
    page = Ui::PageBuilder.new(options, self, block)
    page_title(page.head_title)
    content_for(:page_header, render('page_header', page:))
    content_for(:page_tabs, render('page_tabs', page:)) if page.tabs.present?
  end
end
