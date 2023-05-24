class CreateOrderTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :order_types do |t|
      t.string :apiLabel
      t.string :apiValue
    end
  end
end
