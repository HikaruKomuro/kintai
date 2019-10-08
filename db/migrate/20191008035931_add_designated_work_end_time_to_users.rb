class AddDesignatedWorkEndTimeToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :designated_work_end_time, :time, default: Time.current.change(hour: 10, min: 0, sec: 0)
  end
end
