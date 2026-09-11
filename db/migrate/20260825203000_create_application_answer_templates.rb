class CreateApplicationAnswerTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :application_answer_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :persona_id
      t.string :question_kind, null: false
      t.string :normalized_prompt, null: false
      t.string :prompt, null: false
      t.text :answer, null: false
      t.string :source, null: false, default: "manual"
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :application_answer_templates,
              %i[user_id persona_id normalized_prompt],
              name: "idx_answer_templates_lookup"
  end
end
