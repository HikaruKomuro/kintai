class AddSuperior2ToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :superior2, :string
  end
end
