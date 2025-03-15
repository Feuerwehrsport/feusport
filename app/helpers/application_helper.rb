# frozen_string_literal: true

module ApplicationHelper
  SOCIAL_SHARE_SITES = %i[twitter facebook email vkontakte telegram whatsapp_app whatsapp_web].freeze
  def qrcode(url)
    RQRCode::QRCode.new(url).as_png(size: 200, fill: ChunkyPNG::Color::TRANSPARENT).to_data_url
  end

  def competition_path(competition)
    competition_show_path(competition.year, competition.slug)
  end

  def documents_link_array(competition)
    competition.documents.map do |document|
      out = { title: document.title, url: rails_blob_url(document.file), preview: false }
      if document.file.representable?
        out[:preview] = document.file.representation(resize_to_limit: [100, 100]).processed.url
        out[:image] = document.file.representation(resize_to_limit: [1000, 1000]).processed.url
      end
      out
    end
  end

  def social_share_button_tag(_title = '', _opts = {})
    links = SOCIAL_SHARE_SITES.map do |name|
      link_title = t('social_share_button.share_to', name: t("social_share_button.#{name}"))
      link_to('', '#', rel: 'nofollow',
                       'data-site' => name,
                       :class => "ssb-icon ssb-#{name}",
                       :onclick => 'return SocialShareButton.share(this);',
                       :title => h(link_title))
    end
    tag.div(safe_join(links, ' '), class: 'social-share-button')
  end

  def discipline_image(discipline, options = {})
    options[:size] ||= '20x20'
    image_tag "disciplines/#{discipline}.svg", options
  end

  def short_edit_link(path, options = {})
    options[:title] ||= 'Bearbeiten'
    icon_link_btn('far fa-edit', path, options)
  end

  def short_destroy_link(path, options = {})
    options[:title] ||= 'Löschen'
    icon_link_btn('far fa-trash', path, options)
  end

  def icon_link_btn(icon_classes, path, options = {})
    btn_link_to(tag.i('', class: icon_classes), path, options)
  end

  def personal_best_badge(person, current_result = nil)
    return if person.nil?

    classes = %w[balloon best-badge]
    classes.push('personal-best') if person.new_personal_best?(current_result)
    tag.span('i', class: classes, data: { balloon_content: render('competitions/people/best_badge', person:) })
  end

  def team_badge(team, gender)
    return if team.nil?

    classes = %w[balloon team-badge]
    tag.span('i', class: classes, data: { balloon_content: render('competitions/teams/badge', team:, gender:) })
  end

  def home_competition_classes(competition)
    classes = %w[list-group-item list-group-item-action]
    classes.push('current-competition') if competition.date.in?(@current_dates)
    classes
  end
end
