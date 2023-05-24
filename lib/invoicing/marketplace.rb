INTERNAL_NUM_WIDTH = 45
ACCOUNT_NAME_WIDTH = 101

class Marketplace
  attr_reader :id
  attr_reader :name
  attr_reader :msm1_name
  attr_reader :owner_name
  attr_reader :slug
  attr_reader :orders_by_type
  attr_reader :sorted_order_types
  attr_reader :balance_by_order_type
  attr_reader :balance
  attr_reader :num_orders

  def initialize(name, id, msm1, owner)
    @id = id
    @name = name
    @msm1_name = msm1
    @owner_name = owner
    @slug = @name.gsub(/\W/, '-').downcase

    # nested hash of orders by: type > account > order > orderItem[]
    @orders_by_type = {}
    # an array of sorted keys of @order_by_type (to be set after orders have been added)
    @sorted_order_types = nil
    # a map of order id to AccountBalance
    @balance_by_order_type = {}
    # the number of orders added
    @num_orders = 0

    # invoicing amounts
    @balance = AccountBalance.new
  end

  # Add an order item to this marketplace. File it under the correct order type and account name.
  # Order model should be a MarketplaceOrder
  # @param [MarketplaceOrder] orderModel an initialized order
  def add_order(account, orderType, orderModel)
    accountId = account.Id

    # 1. order type
    @orders_by_type[orderType] ||= {
        __sorted_keys: nil,
    }

    @balance_by_order_type[orderType] ||= AccountBalance.new

    # 2. account id - get or create account
    @orders_by_type[orderType][accountId] ||= MarketplaceAccount.new(account)

    # 3. add order to account (only once)
    unless @orders_by_type[orderType][accountId].orders[orderModel.id]
      @orders_by_type[orderType][accountId].add_order(orderModel)

      update_balance(orderModel.balance, orderType)

      @num_orders += 1
    end
  end

  # sort order: order type, account name, order description, credit/debit
  # requires an invoice start date to sort orders
  def sort_orders(invoice_start_date)
    @sorted_order_types = @orders_by_type.keys.sort()

    @sorted_order_types.each {|ot|
      t = @orders_by_type[ot]

      # sort accounts by name
      t[:__sorted_keys] = t.keys.delete_if{|_| _ === :__sorted_keys}.sort_by{|_| t[_].name}

      t[:__sorted_keys].each{|a|
        t[a].sort_orders(invoice_start_date)
      }
    }
  end

  def order_column_headers(orderType)
    # todo - seed this into OrderGroup model
    if orderType === :credit
      [
        'Internal Num',
        'Account Name',
        'Billing Start Date',
        'Details',
        'Retail',
        'Wholesale',
        'Refund',
      ]
    else
      columns = OrderGroup
        .includes(:columns)
        .where(label: orderType)
        .limit(1)
        .first()
        .columns()
        .map{ |m| m.label }
    end
  end

  def order_column_widths(orderType)
    case orderType
      when 'Digital Ads', 'Intent', 'Email'
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 60, 135]
      when 'EPiC Guarantee'
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 60, 135]
      when 'Licensing Fees'
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 135]
      when 'Barter Fee'
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 150]
      when 'Smart Boundary/Pixel'
        [INTERNAL_NUM_WIDTH, 325, 75, 80]
      when :credit
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 60, 135]
      else
        [INTERNAL_NUM_WIDTH, ACCOUNT_NAME_WIDTH, 60, 135]
    end
  end

  # a map to begin building a new page
  # todo - move to different class
  # @todo - consolidate keys in tables: rows, row_balances, row_data
  def new_invoice_page(start_date, end_date, order_type)
    bal = @balance_by_order_type[order_type]

    {
      title: "#{order_type}: #{start_date.strftime('%B %-d')} - #{end_date.strftime('%-d, %Y')}",
      order_type: order_type,
      page_total: ActionController::Base.helpers.number_to_currency(bal.debits.wholesale - bal.credits.retail),
      tables: [
          {
              # debits
              headers: order_column_headers(order_type),
              column_widths: order_column_widths(order_type),
              rows: [],
              row_balances: [],
              total_row: true,
              # "orders" key contains structured data.
              orders: []
          },
          {
              #credits
              title: 'Paid Directly by Credit Card',
              headers: order_column_headers(:credit),
              column_widths: order_column_widths(:credit),
              rows: [],
              row_balances: [],
              total_row: true,
              orders: []
          },
      ],
    }
  end

  def order_type_total_debit_row(ot)
    b = @balance_by_order_type[ot]


    if ['Digital Ads', 'Programmatic Audio', 'TikTok Ads', 'Digital Out of Home'].include?(ot)
      ['Total Charges', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail), '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif ['Email', 'OTT Ads', 'Waze Ads'].include?(ot)
      ['Total Charges', '', '', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif 'Facebook Ads' === ot
      ['Total Charges', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail), '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif 'Smart Boundary/Pixel' === ot
      ['Total Charges', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail)]
    elsif ['EPiC Guarantee'].include?(ot)
      ['Total Charges', '', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail), ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif ['Intent'].include?(ot)
      ['Total Charges', '', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif 'Barter Fee' === ot
      ['Total Charges', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    elsif ['TrueView Ads', 'Google / Bing Ads'].include?(ot)
      ['Total Charges', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail), '', ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    else
      ['Total Charges', '', '', '', ActionController::Base.helpers.number_to_currency(b.debits.retail), ActionController::Base.helpers.number_to_currency(b.debits.wholesale)]
    end
  end

  def order_type_total_credit_row(ot)
    b = @balance_by_order_type[ot]
    ['Total Credits', '', '', '', '', '', ActionController::Base.helpers.number_to_currency(b.credits.retail - b.credits.wholesale)]
  end

  def update_balance(bal, orderType)
    # update marketplace
    @balance.credit(bal.credits.wholesale, bal.credits.retail)
    @balance.debit(bal.debits.wholesale, bal.debits.retail)

    # update order type
    @balance_by_order_type[orderType].add(bal)
  end
end
