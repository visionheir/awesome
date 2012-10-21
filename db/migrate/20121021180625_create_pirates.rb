class CreatePirates < ActiveRecord::Migration
  def change
    create_table :pirates do |t|
      t.string :name

      t.timestamps
    end
  end
end
