class AddCommissionsReportCampaignColumns < ActiveRecord::Migration[5.2]
  def change
    table = 'daily_commissions_report'

    add_column(table, 'order_campaign_end_date', :string)
    add_column(table, 'order_campaign_length_months', :integer)
  end
end
