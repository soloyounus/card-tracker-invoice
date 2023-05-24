class AddCommissionsReportCognitoColumns < ActiveRecord::Migration[5.2]
  def change
    table = 'daily_commissions_report'

    add_column(table, 'cognito_entry', :string)
    add_column(table, 'cognito_form', :string)
  end
end
