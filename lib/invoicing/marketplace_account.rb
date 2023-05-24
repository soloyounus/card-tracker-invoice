class MarketplaceAccount
  attr_reader :id
  attr_reader :name
  attr_reader :orders
  attr_reader :balance
  attr_reader :sorted_orders

  def initialize(account)
    @id = account.Id
    @name = account.Name
    @orders = {}
    @sorted_orders = nil
  end

  # add an MarketplaceOrder, only if new
  def add_order(marketplaceOrder)
    orderId = marketplaceOrder.id

    unless @orders[orderId]
      @orders[orderId] = marketplaceOrder
    end
  end

  def sort_orders(invoice_start_date)
    @sorted_orders = @orders.keys.sort_by{|k|
      @orders[k].start_date
    }
  end
end
