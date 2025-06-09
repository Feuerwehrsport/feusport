# frozen_string_literal: true

def competition_nested(path = nil)
  ["/#{competition.year}/#{competition.slug}", path].compact.join('/')
end
