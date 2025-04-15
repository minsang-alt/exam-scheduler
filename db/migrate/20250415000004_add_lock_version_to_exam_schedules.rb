class AddLockVersionToExamSchedules < ActiveRecord::Migration[7.1]
  def change
    add_column :exam_schedules, :lock_version, :integer, default: 0, null: false
  end
end
