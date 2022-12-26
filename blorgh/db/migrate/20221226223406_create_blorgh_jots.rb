class CreateBlorghJots < ActiveRecord::Migration[7.0]
  def change
    create_table :blorgh_jots do |t|
      t.jsonb :data

      t.timestamps
    end
  end
end
