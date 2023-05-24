class CreateOrderGroupOrderTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :order_group_order_types do |t|
      t.references :orderGroup, foreign_key: false
      t.references :orderType, foreign_key: false
    end
  end
end
