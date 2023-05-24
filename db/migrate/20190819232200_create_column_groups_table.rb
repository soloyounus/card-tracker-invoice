class CreateColumnGroupsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :column_groups do |t|
      t.integer :groupId
      t.integer :sort
      t.string :label
      # t.string :apiName
    end
  end
end
