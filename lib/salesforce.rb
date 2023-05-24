require 'date'

module Salesforce
  def self.getClient
    client = Restforce.new()
  
    client
  end

  module Accounts
    def self.all
      client = Restforce.new(cache: Rails.cache)
      client.query("select Id, Name FROM Account where type='Partner' AND Partner_Account_Status__c='Active' ORDER BY Name ASC")
    end

    def self.get(id)
      client = Restforce.new(cache: Rails.cache)
      client.query("select Id, Name FROM Account where type='Partner' AND Partner_Account_Status__c='Active' AND Id='#{id}' ORDER BY Name ASC").first
    end
  end

  module Orders
    # on the 'OrderItem' table
    @@select_fields = [
      'Id',
      'OrderId',
      'Order.Account.Id',
      'Order.Account.Name',
      'Order.Account.Active_Date__c',
      'Quantity',
      'UnitPrice',
      'Order.CreatedDate',
      'Order.Payment_Type__c',
      'Order.Retail_Monthly_Amount__c',
      'Order.Wholesale_monthly_Amount__c',
      'Order.Monthly_Management_Fee__c',
      'Order.Type',
      'Order.Id',
      'Order.Status',
      'Order.EffectiveDate',
      'Order.Order_Activated_Date__c',
      'Order.Description__c',
      'Order.OrderNumber',
      'Order.Order_Campaign_Start_Date__c',
      'Order.Campaign_End_Date__c',
      'Order.Order_Interval__c',
      'Order.Campaign_Type__c',
      'Order.Campaign_Name__c',
      'Order.Total_Impressions_Ordered__c',
      'Order.MONTHLY_Impressions_Ordered__c',
      'Order.Wholesale_CPM__c',
      'Order.Account.Partner_Account__c',
      'Order.Account.Marketplace_Name__r.Name',
      'Order.Account.Marketplace_Name__r.Id',
      # revenue, MSM1, and Owner are used in commissions report
      'Order.Order_Revenue__c',
      'Order.Account.Marketplace_Name__r.MSM1__r.Name',
      'Order.Account.Marketplace_Name__r.Owner.Name',
      'Order.Campaign_Length_Months__c',
      'Order.Campaign_Length_Months_digital_ads__c',
      'Order.Billing_Start_Month__c',
      'Order.Partner_Internal_Order__c',
      'Order.Account.Business_Category__c',
      'Order.Cognito_Entry__c',
      'Order.Cognito_Form_Name__c',
    ]

    def self.query(created_at, account_id, invoicing_period_start_date)
      where = []
      
      # account
      where << "Order.Account.Account_Status__c = 'Active' OR Order.Account.Cancelled_Date__c >= #{invoicing_period_start_date.to_date.to_s}"

      if account_id then
        where << "Order.Account.Partner_Account_ID__c='#{account_id}'"
      end

      # order
      where += [
        ['Completed', 'Cancelled'].map{ |_| "Order.Status = '#{_}'" }.join(' OR '),
        "Order.Status = 'Completed' OR Order.Status = 'Cancelled'",
        "Order.Payment_Type__c='Invoice' OR Order.Payment_Type__c='Credit Card'",
      ]

      if created_at then
        where << "Order.CreatedDate < #{created_at}"
      end

      query_parts = [
        "SELECT #{@@select_fields.join(', ')}",
        'FROM OrderItem',
        "WHERE #{where.map{ |_| "(#{_})" }.join(' AND ')}",
        'ORDER BY Order.CreatedDate DESC',
        'LIMIT 2000',
      ]

      client = Restforce.new
      client.query(query_parts.join(' '))
    end
  end

  module Reports
    def self.allPartners(num, start_date, commissions_only = false, format_tsv = false)
      formats = { pdf: false }

      if format_tsv
        formats[:tsv] = true
      else
        formats[:csv] = true
      end

      Invoicer.new(false, start_date, num, formats, commissions_only)
    end

    def self.partnerInvoice(id, num, start_date)
      formats = { pdf: true, csv: false }

      Invoicer.new(id, start_date, num, formats)
    end
  end
end
