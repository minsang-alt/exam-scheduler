class CreateExamSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :exam_schedules do |t|
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :max_capacity, null: false, default: 50000
      t.integer :current_reservations, null: false, default: 0
      t.boolean :is_available, null: false, default: true

      t.timestamps
    end

    add_index :exam_schedules, :start_time
    add_index :exam_schedules, :end_time
  end
end 