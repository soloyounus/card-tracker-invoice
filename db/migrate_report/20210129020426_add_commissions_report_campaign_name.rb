class AddCommissionsReportCampaignName < ActiveRecord::Migration[5.2]
  def change
    table = 'daily_commissions_report'

    add_column(table, 'order_campaign_name', :string)
  end
end
