class CreateSecretVariables < ActiveRecord::Migration
  def change
    create_table :gnomes do |t|
      t.string :name
      t.string :value
      t.timestamps null: false
    end
  end
end
