# frozen_string_literal: true

class EmailHtmlRenderer < Redcarpet::Render::HTML
  def block_quote(quote)
    %(<blockquote style="margin: 0; padding-left: 30px;">#{quote}</blockquote>)
  end

  def paragraph(quote)
    %(<p style="margin: 0; margin-bottom: 15px; line-height: 1.5; color: #414141;">#{quote.gsub(/(?:\n\r?|\r\n?)/,
                                                                                                '<br>')}</p>)
  end

  def list_item(text, _list_type)
    text = text.gsub(/(?:\n\r?|\r\n?)/, '<br>').gsub('<br>\s*\z', '')
    %(<li style="margin: 0; margin-bottom: 5px; line-height: 1.5; color: #414141;">#{text}</li>)
  end

  def link(link, title, content)
    if content.is_a?(String) && content.starts_with?('[') && content.ends_with?(']')
      content = content[1...-1]
      style = 'background-color: #c84b47; font-size: 16px; text-decoration: none; padding: 8px 10px; ' \
              'color: #ffffff; display: inline-block; miso-padding-alt: 0;'
      <<-BUTTON_CODE.squish
      <table border="0" cellpadding="0" cellspacing="0" align="center">
        <tbody>
          <tr>
            <td align="center" style="padding: 10px 0;">
              <a href="#{link}" class="btn-link" style="#{style}" bgcolor="#c84b47">
                  <!--[if mso]>
                  <i style="letter-spacing: 23px; mso-font-width: -100%; mso-text-raise: 27pt;">&nbsp;</i>
                  <![endif]-->
                  <span style="mso-text-raise: 14pt;">#{content}</span>
                  <!--[if mso]>
                  <i style="letter-spacing: 23px; mso-font-width: -100%;">&nbsp;</i>
                  <![endif]-->
              </a>
            </td>
          </tr>
        </tbody>
      </table>
      BUTTON_CODE
    else
      %(<a href="#{link}" title="#{title}">#{content}</a>)
    end
  end
end

class EmailMarkdown
  RENDERER = Redcarpet::Markdown.new(EmailHtmlRenderer.new(hard_wrap: true), no_intra_emphasis: true)

  def self.renderer
    RENDERER
  end

  def self.render(text)
    renderer.render(text).html_safe
  end
end

class MarkdownTemplateHandler
  def erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def call(template, a)
    compiled_source = erb.call(template, a)
    "EmailMarkdown.renderer.render(begin;#{compiled_source};end.to_s).html_safe"
  end
end

ActionView::Template.register_template_handler(:md, MarkdownTemplateHandler.new)
