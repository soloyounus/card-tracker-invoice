class CreateOrderGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :order_groups do |t|
      t.string :label
      t.integer :column_group_id
    end
  end
end
