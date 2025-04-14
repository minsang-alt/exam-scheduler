class CreateReservations < ActiveRecord::Migration[7.1]
  def change
    create_table :reservations do |t|
      t.references :exam_schedule, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :number_of_people, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :reservations, :status
  end
end 