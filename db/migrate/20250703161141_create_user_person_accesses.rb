# frozen_string_literal: true

class CreateUserPersonAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :user_person_accesses, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.references :person, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end

    add_index :user_person_accesses, %i[user_id person_id competition_id], unique: true

    Person.where.not(applicant_id: nil).find_each do |person|
      UserPersonAccess.create!(person:, user_id: person.applicant_id, competition_id: person.competition_id)
    end

    remove_column :people, :applicant_id
  end
end
