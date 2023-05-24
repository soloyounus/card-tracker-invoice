class CreateCommissionsReport < ActiveRecord::Migration[5.2]
  def up
    create_table :daily_commissions_report do |t|
      t.string :invoice_date
      t.string :owner_full_name
      t.string :msm1_full_name
      t.decimal :monthly_order_revenue
      t.string :partner_account_account_name
      t.string :marketplace_name
      t.string :account_name
      t.string :order_number
      t.string :order_type
      t.string :description
      t.decimal :wholesale_monthly_ammount
      t.decimal :retail_monthly_ammount
      t.string :order_campaign_start_date
      t.string :internal_order_n
      t.string :order_business_category
    end
  end

  def down
    drop_table :daily_commissions_report do |t|

    end
  end
end
