class CreateAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :admins do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :encrypted_password, null: false

      t.timestamps
    end

    add_index :admins, :email, unique: true
  end
end 