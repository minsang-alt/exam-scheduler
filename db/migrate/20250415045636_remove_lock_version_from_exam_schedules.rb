class RemoveLockVersionFromExamSchedules < ActiveRecord::Migration[8.0]
  def change
    remove_column :exam_schedules, :lock_version, :integer
  end
end
