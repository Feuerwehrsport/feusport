# frozen_string_literal: true

def competition_nested(path = nil)
  ["/#{competition.year}/#{competition.slug}", path].compact.join('/')
end

def expect_access_denied(redirect_to_url: '/users/sign_in')
  expect(response).to redirect_to(redirect_to_url)
  expect(flash[:alert]).to eq 'Bitte melde Dich an, um diese Funktion nutzen zu können.'
end
