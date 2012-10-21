class CreateAliens < ActiveRecord::Migration
  def change
    create_table :aliens do |t|
      t.string :name

      t.timestamps
    end
  end
end
