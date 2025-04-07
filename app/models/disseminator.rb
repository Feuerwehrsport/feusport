# frozen_string_literal: true

# == Schema Information
#
# Table name: disseminators
#
#  id            :uuid             not null, primary key
#  email_address :string
#  lfv           :string
#  name          :string           not null
#  phone_number  :string
#  position      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Disseminator < ApplicationRecord
  schema_validations
end
