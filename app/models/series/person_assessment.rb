# frozen_string_literal: true

# == Schema Information
#
# Table name: series_assessments
#
#  id         :bigint           not null, primary key
#  discipline :string(2)        not null
#  gender     :integer          not null
#  name       :string           default(""), not null
#  type       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  round_id   :integer          not null
#
class Series::PersonAssessment < Series::Assessment
end
