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
    content_for(:page_tabs, render('page_tabs', page:))
  end

  def hcaptcha
    safe_join([
                tag.div(data: { controller: 'hcaptcha', sitekey: Recaptcha.configuration.site_key }),
                tag.script(async: true, defer: true,
                           src: 'https://hcaptcha.com/1/api.js?onload=hcaptchaOnLoad&render=explicit'),
              ])
  end
end
