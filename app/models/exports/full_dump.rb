# frozen_string_literal: true

class Exports::FullDump
  attr_reader :competition, :user, :hint

  def initialize(competition, user, hint)
    @competition = competition
    @user = user
    @hint = hint
    competition.score_results.each do |result|
      add_file('Score::Result', [result], prefix: 'ergebnis')
    end

    return unless competition.score_competition_results.exists?

    add_file('Score::CompetitionResults', [competition, competition.score_competition_results])
  end

  def to_export_hash
    {
      files: files.map(&:to_export_hash),
      name: competition.name,
      date: competition.date.to_s,
      place: competition.place,
      user: user.name,
      user_email_address: user.email,
      hint:,
      url: competition.self_url,
    }
  end

  def to_export_data
    Base64.encode64(Zlib::Deflate.deflate(to_export_hash.to_json))
  end

  protected

  StoredFile = Struct.new(:name, :mimetype, :data) do
    def to_export_hash
      {
        name:,
        mimetype: mimetype.to_s,
        base64_data: Base64.encode64(data),
      }
    end
  end

  def add_file(klass_name, args, prefix: nil)
    %w[Pdf Json].each do |module_name|
      begin
        klass = "Exports::#{module_name}::#{klass_name}".constantize
      rescue NameError
        next
      end
      model = klass.perform(*args)
      name = model.filename
      name = "#{prefix}-#{name}" if prefix.present?
      files.push(StoredFile.new(name, Mime[module_name.downcase.to_sym], model.bytestream))
    end
  end

  def files
    @files ||= []
  end
end
