class MarketplaceOrder
  attr_reader :details
  attr_reader :campaign

  def type
    @details[:type]
  end

  def id
    @details[:id]
  end

  # The display date of the order, distinct from the billing_start_date
  def start_date
    @details[:start_date]
  end

  def description
    @details[:description]
  end

  def balance
    @details[:balance]
  end

  def account_name
    @details[:account_name]
  end

  def num
    @details[:num]
  end

  def internal_num
    @details[:internal_num]
  end

  def business_category
    @details[:business_category]
  end

  def campaign_start_date
    @campaign[:start_date]
  end
  
  def campaign_end_date
    if @campaign && @campaign[:end_date]
      return Date.parse(@campaign[:end_date])
    end

    if @campaign && @campaign[:start_date] && @campaign[:num_months]
      return Date.parse(@campaign[:start_date]) >> @campaign[:num_months]
    end
  end

  def campaign_length
    @campaign[:num_months]
  end

  def campaign_name
    @campaign[:name]
  end

  def cognito_entry
    @order.Cognito_Entry__c
  end

  def cognito_form
    @order.Cognito_Form_Name__c
  end

  def format_currency(amount)
    ActionController::Base.helpers.number_to_currency(amount || 0.00)
  end

  def revenue_str
    self.format_currency(@details[:revenue])
  end

  def retail_debits_str
    self.format_currency(self.balance.debits.retail)
  end

  def wholesale_debits_str
    self.format_currency(self.balance.debits.wholesale)
  end

  def retail_credits_str
    self.format_currency(self.balance.credits.retail * -1)
  end

  def wholesale_credits_str
    self.format_currency(self.balance.credits.wholesale * -1)
  end

  def initialize(order, orderId)
    @order = order
    @campaign = nil
    @details = {
        id: orderId,
        num: order.OrderNumber,
        type: order.Type,
        status: order.Status,
        description: order.Description__c,
        interval: order.Order_Interval__c, # one time, month, quarter, year
        payment_type: order.Payment_Type__c,
        partner_id: order.Account.Partner_Account__c,
        account_name: order.Account.Name,
        balance: nil,
        should_bill: nil,
        start_date: nil,
        billing_start_date: nil,
        end_date: nil,
        revenue: order.Order_Revenue__c || 0.00,
        internal_num: order.Partner_Internal_Order__c,
        business_category: order.Account.Business_Category__c,
    }

    if @details[:payment_type] === 'Credit Card'
      @details[:description] += ' (CC Refund)'
    end

    init_campaign(order)
    init_dates(order)
    init_balance(order)
  end

  # determine whether to bill the order in this invoice using the invoice date range
  def bill_order?(start_date, end_date)
    if @details[:should_bill] === nil
      @details[:should_bill] = true

      #
      # Find reasons to reject the order.
      # @todo move some of this filter logic into sql
      #

      # require start date, must be in range
      if @details[:billing_start_date] && @details[:billing_start_date] <= end_date
        # check order ending date
        if @details[:end_date]
          # only when here is no campaign number of months
          unless @campaign && @campaign[:num_months] && @campaign[:num_months] > 0
            # the order should have ended before start_date
            unless @details[:end_date] >= start_date# && @details[:end_date] <= end_date
              return disable_billing('when present, order end date must be after invoice start date')
            end
          end
        end

        # check interval
        if @details[:interval]
          interval_checks = []

          # Quarterly and semi-annual assume the invoice is on the first of the moth
          # and the invoice range is exactly one month (see InvoiceController)
          case @details[:interval]
            # when 'Monthly' # ... this code does nothing because that's the default (order start date is before invoice range end)
            # when 'Yearly'
            #   interval_checks << (@details[:billing_start_date].month === start_date.month)
            # when 'Quarterly'
            #   interval_checks << (get_invoice_month_diff(start_date) % 3 === 0) # because 3 months per quarter year
            # when 'Semi-annual'
            #   interval_checks << (get_invoice_month_diff(start_date) % 6 === 0)
            when 'One Time'
              # one-time orders must be in this period
              interval_checks << (@details[:billing_start_date] >= start_date && @details[:billing_start_date] <= end_date)
          end

          # all validations should be positive
          unless interval_checks.select{|ic| ic === false}.empty?
            return disable_billing('invalid interval')
          end
        end

        # campaign-specific validation
        if @campaign
          # check campaign length
          if @campaign[:num_months]
            # if this field is present, it must be positive
            unless @campaign[:num_months] > 0
              return disable_billing('when present, campaign num_months must be positive')
            end
            c_end_date = @details[:billing_start_date] >> (@campaign[:num_months] - 1)
            # don't bill if term has ended
            if c_end_date < start_date
              return disable_billing('campaign num_months billed has been exceeded.')
            end
          end
        end
      else
        return disable_billing('order start date is required and must be before the end of the invoicing period')
      end
    end

    return @details[:should_bill]
  end

  # def get_invoice_month_diff(invoice_start_date)
  #   invoice_month = invoice_start_date.month
  #   invoice_year = invoice_start_date.year
  #   order_month = @details[:billing_start_date].month
  #   order_year = @details[:billing_start_date].year

  #   # total months between invoice date and transaction date
  #   if invoice_year === order_year && (invoice_month >= order_month)
  #     invoice_month - order_month
  #   elsif (invoice_year > order_year)
  #     # the # months remaining in year and the # months in the year difference
  #     (order_month % 12) + (12 * (invoice_year - order_year - 1))
  #   else
  #     -1 ## don't bill
  #   end
  # end

  def get_row_balance
    if @details[:payment_type] === 'Credit Card'
      self.balance.credits.retail * -1.00
    else
      self.balance.debits.wholesale
    end
  end

  # todo - move to different class
  def get_row(account_name, start_date)
    if @details[:payment_type] === 'Credit Card'
      [
        self.internal_num,
        account_name,
        self.start_date,
        @details[:description],
        self.format_currency(@order.Retail_Monthly_Amount__c || 0.00),
        self.format_currency(@order.Wholesale_monthly_Amount__c || 0.00),
        self.format_currency(self.balance.credits.retail),
      ]
    else
      # column group 2
      if ['Digital Ads', 'OTT Ads', 'Waze Ads', 'Programmatic Audio', 'TikTok Ads', 'Digital Out of Home'].include?(self.type)
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:description],
          self.retail_debits_str,
          self.format_currency(@campaign[:cpm_wholesale] || 0.00),
          self.wholesale_debits_str,
        ]
      elsif ['Email'].include?(self.type)
          [
            self.internal_num,
            account_name,
            self.start_date,
            @details[:description],
            self.retail_debits_str,
            @campaign[:cpm_wholesale] || 0.00,
            self.wholesale_debits_str,
          ]
      # column group 3
      elsif 'Facebook Ads' === self.type
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:description],
          self.retail_debits_str,
          ActionController::Base.helpers.number_with_precision(@campaign[:cpm_wholesale] || @campaign[:management_fee] || 0, precision: 2),
          self.wholesale_debits_str,
        ]
      # 5
      elsif 'Smart Boundary/Pixel' === self.type
        [
          self.internal_num,
          @details[:description],
          self.start_date,
          self.retail_debits_str,
        ]
      # 6
      elsif 'EPiC Guarantee' === self.type
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:end_date] ? @details[:end_date].to_date.to_s : '',
          @details[:description],
          self.retail_debits_str,
          self.wholesale_debits_str,
        ]
      # 7
      elsif ['Intent'].include?(self.type)
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:description],
          self.retail_debits_str,
          self.wholesale_debits_str,
        ]
      # 8
      elsif 'Barter Fee' === self.type
        [
          self.internal_num,
          account_name,
          @details[:description],
          @details[:interval],
          self.wholesale_debits_str,
        ]
      # 10
      elsif ['TrueView Ads', 'Google / Bing Ads'].include?(self.type)
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:description],
          self.retail_debits_str,
          ActionController::Base.helpers.number_to_percentage(@campaign[:management_fee] || 0, precision: 2),
          self.wholesale_debits_str,
        ]
      else
        [
          self.internal_num,
          account_name,
          self.start_date,
          @details[:description],
          self.retail_debits_str,
          self.wholesale_debits_str,
        ]
      end
    end
  end

  private

  # set dates in the order
  # @see bill_order?
  def init_dates(order)
    if order.Billing_Start_Month__c
      @details[:billing_start_date] = Date.parse(order.Billing_Start_Month__c)
    else 
      if order.Order_Activated_Date__c
        @details[:billing_start_date] = Date.parse(order.Order_Activated_Date__c) || nil
      end

      # dates from campaign override the above
      if order.Order_Campaign_Start_Date__c
        @details[:billing_start_date] = Date.parse(order.Order_Campaign_Start_Date__c)
      end
    end

    if order.Order_Activated_Date__c
      @details[:start_date] = Date.parse(order.Order_Activated_Date__c) || nil
    end

    # dates from campaign override the above
    if order.Order_Campaign_Start_Date__c
      @details[:start_date] = Date.parse(order.Order_Campaign_Start_Date__c)
    end

    if order.Campaign_End_Date__c
      @details[:end_date] = Date.parse(order.Campaign_End_Date__c)
    end
  end

  def init_campaign(order)
    @campaign = {
        type: order.Campaign_Type__c,
        num_months: nil,
        ordered_total: order.Total_Impressions_Ordered__c,
        ordered_monthly: order.MONTHLY_Impressions_Ordered__c,
        cpm_wholesale: order.Wholesale_CPM__c,
        management_fee: order.Monthly_Management_Fee__c,
        start_date: order.Order_Campaign_Start_Date__c,
        name: order.Campaign_Name__c
    }

    if (order.Campaign_Length_Months__c)
      @campaign[:num_months] = order.Campaign_Length_Months__c.to_i
    elsif (order.Campaign_Length_Months_digital_ads__c)
      @campaign[:num_months] = order.Campaign_Length_Months_digital_ads__c.to_i
    end
  end

  def init_balance(order)
    # set invoicing amounts
    @details[:balance] = AccountBalance.new

    wh = order.Wholesale_monthly_Amount__c || 0.00
    re = order.Retail_Monthly_Amount__c || 0.00

    if @details[:payment_type] === 'Credit Card'
      # refund the difference
      @details[:balance].credit(0.00, (re - wh))
    else
      @details[:balance].debit(wh, re)
    end

    # retail amounts (used in CSV)
    @details[:retail_price] = re
  end

  def disable_billing(reason = 'None')
    @details[:should_bill] = false

    @details[:should_bill]
  end
end
