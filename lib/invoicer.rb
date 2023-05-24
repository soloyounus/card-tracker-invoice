require 'date'
require 'fileutils'

# Represents the invoices for a partner, organized by marketplace, order type, and account.
# Invoice billed on invoice_date for transactions from previous month (@start_date to @end_date)
# Can call method create_zip upon init to generate a zip of pdf invoices
class Invoicer
  attr_accessor :filename
  attr_accessor :orders

  def initialize(partner, invoice_date, invoice_number, formats, commissions_only = false)
    @invoice_number = invoice_number.to_i
    @commissions_only = commissions_only === true

    if partner === false && formats[:pdf] === true then
      raise ArgumentError.new("PDF Export requires a specific account. Cannot generate PDF for all accounts.");
    end

    # hash of partner id => name (Accounts)
    @partner_names = {
      __unknown: 'Unknown',
    }

    if partner.instance_of?(String) then
      # setup for single partner
      @partner = Salesforce::Accounts.get(partner)
      @partner_slug = @partner.Name.gsub(/\W/, '-').downcase
      @partner_account_id = @partner.Id[0..-4]
      @partner_billing_info = [
          @partner.Name,
      ]
      @partner_names[@partner_account_id.to_sym] = @partner.Name
    elsif partner === false then
      # setup for all partners
      @partner_slug = 'all-partners'
      @partner_account_id = nil
      @partner_billing_info = [
          'All Billable Accounts',
      ]
      Salesforce::Accounts.all.map { |a|
        unless @partner_names.key?(a.Id.to_sym)
          @partner_names[a.Id.to_sym] = a.Name
        end
      }
    else
      # arg type not supported
      raise ArgumentError.new("Invoicer:initialize - argument 'partner' type is not supported. Must be either String or false")
    end

    # the invoicing period to lookup transactions
    @start_date = invoice_date.at_beginning_of_month
    # end of invoicing period to lookup transactions
    @end_date = @start_date.at_end_of_month
    # the date that the invoice is "sent". typically 1 mo after start_date.
    @invoice_date = @start_date.next_month


    # string format, used to name marketplace-specific files
    @filename_tmpl = "#{@partner_slug}_%s_#{@start_date.year.to_s}-#{@start_date.month.to_s}"

    # a non marketplace-specific name for files
    @filename_short = "#{@partner_slug}_#{@start_date.year.to_s}-#{@start_date.month.to_s}"

    # zip file name - set when ready for download
    @zip_filename = nil

    # export formats
    @export_to = formats

    # marketplace id hash
    # see add_to_marketplace
    @marketplaces = {}

    # order id hash
    # see add_to_marketplace
    @orders = {}

    @orderTypes = OrderType.includes(:orderGroup)

    # query for data
    init_orders
  end

  # Generate object representations of invoices and write a zip
  # Return the filename - ready for download
  def create_zip(namespace)
    unless @orders.empty? && @marketplaces.empty?
      # sort marketplaces for accurate invoice number sequence in the resulting files
      mps = @marketplaces.keys.select{|a| @marketplaces[a].num_orders > 0}.sort{|a, b|
        @marketplaces[a].name <=> @marketplaces[b].name
      }

      # Build object representations for each requested format, for each marketplace
      # Include the filename prefix for each marketplace
      invoice_objects = mps.each_with_index.map{|m, mi|
        # builder instance
        i = InvoiceBuilder.new(invoice_builder_opts(m, mi))

        # formats
        p = if @export_to[:pdf] === true then i.build_pdf else nil end
        c = if @export_to[:csv] === true then i.build_csv else nil end
        t = if @export_to[:tsv] === true then i.build_tsv else nil end

        # filename title template arguments
        tmpl_vars = [ @marketplaces[m].slug ]

        # [pdf[], csv[], tsv[], string[]]
        [p, c, t, tmpl_vars]
      }

      # write a zip file
      zipper = InvoiceZipper.new("#{@partner_slug}-#{namespace}", @filename_tmpl, @filename_short, @commissions_only)
      zipper.build_zip(invoice_objects);
      @zip_filename = zipper.get_zip_filename

      return @zip_filename
    else
      return nil
    end
  end

  private

  # query for invoice orders and create marketplaces
  def init_orders
    results = Salesforce::Orders.query(nil, @partner_account_id, @start_date)

    if results.size > 0 then
      add_to_marketplace(results)

      # paginate using date of last the result and max row limit
      more_pages = (results.size === 2000)
      while (more_pages)
        # query again, using date of last result
        last_row_date = results.drop(1999).first.Order.CreatedDate
        results = Salesforce::Orders.query(last_row_date, @partner_account_id, @start_date)
        more_pages = (results.size === 2000)

        if results.size > 0 then
          add_to_marketplace(results)
        end
      end
    end

    # final sort
    @marketplaces.each{|k, v| v.sort_orders(@start_date)}

    @marketplaces

    puts "length() of  @marketplaces : #{ @marketplaces.length()}\n\n"
  end

  # return an array of invoice options for each market place
  # @todo - optimize this function...remove duplicate data for csv and pdf
  def invoice_builder_opts(mp_id, invoice_num_offset = 0)
    mp = @marketplaces[mp_id]
    mp_net = mp.balance.debits.wholesale - mp.balance.credits.retail
    mp_partner_id = :__unknown
    payment_required = ((mp.balance.debits.retail > 0.00 || mp.balance.debits.wholesale > 0.00) && mp_net > 0.00)
    credit_issued = ((mp.balance.credits.retail > 0) && mp_net < 0.00)
    credit_amount = mp.balance.credits.retail

    summary = InvoiceBuilder::get_summary(mp.name)

    pages = mp.sorted_order_types.map{|order_type|
      # order type
      ot = mp.orders_by_type[order_type]
      ot_bal = mp.balance_by_order_type[order_type]
      ot_total_retail = 0.00

      ot_net_total = ot_bal.debits.wholesale -  ot_bal.credits.retail

      # begin a new page
      page = mp.new_invoice_page(@start_date, @end_date, order_type)

      # add order type net total to summary
      summary[:tables][0][:rows] << [order_type, ActionController::Base.helpers.number_to_currency(ot_net_total)]

      ot[:__sorted_keys].each{|a_id|
        # account
        acct = ot[a_id]

        acct.sorted_orders.each{|o_id|
          # order
          order = acct.orders[o_id]

          # set partner account id for this marketplace (assumes marketplace belongs to partner account)
          # used in CSV
          if mp_partner_id === :__unknown && order.details[:partner_id]
            mp_partner_id = order.details[:partner_id].to_sym
          end

          # add row data
          if order.details[:payment_type] === 'Credit Card'
            # refund
            tableIndex = 1
            total_wh = order.wholesale_credits_str
            total_rt = order.retail_credits_str
          else
            # charge
            tableIndex = 0
            total_wh = order.wholesale_debits_str
            total_rt = order.retail_debits_str
          end

          page[:tables][tableIndex][:rows] << order.get_row(acct.name, @start_date)
          page[:tables][tableIndex][:row_balances] << order.get_row_balance

          # add structured data
          page[:tables][tableIndex][:orders] << {
            num: order.num,
            desc: order.description,
            total_wh: order.wholesale_debits_str,
            total_rt: order.retail_debits_str,
            account: order.account_name,
            revenue: order.revenue_str,
            internal_num: order.internal_num,
            business_category: order.business_category,
            campaign_start_date: order.campaign_start_date,
            campaign_end_date: order.campaign_end_date,
            campaign_length: order.campaign_length,
            campaign_name: order.campaign_name,
            type: order_type,
            cognito_entry: order.cognito_entry,
            cognito_form: order.cognito_form,
          }

          # add up order retail amounts for CSV export
          ot_total_retail += order.details[:retail_price]
        }

      }

      summary[:tables][0][:row_total_retail] << ot_total_retail

      # debits & credits total rows
      unless page[:tables][0][:rows].empty?
        page[:tables][0][:rows] << mp.order_type_total_debit_row(order_type)
      end
      unless page[:tables][1][:rows].empty?
        page[:tables][1][:rows] << mp.order_type_total_credit_row(order_type)
      end

      # sub totals on each page (sub-invoice)
      page[:total] = ot_net_total

      # remove unused credit section
      page[:tables] = page[:tables].select{|t| !t[:rows].empty?}

      #
      # return the order type page
      #
      page
    }

    # summary totals
    if summary[:tables][0][:rows].empty?
      summary[:tables].pop
    else
      # add summary net total total
      summary[:tables][0][:rows] << ['Grand Total', ActionController::Base.helpers.number_to_currency(mp_net)]
    end

    # finish by returning data
    {
      invoice_date: @invoice_date,
      start_date: @start_date,
      end_date: @end_date,
      billee: @partner_billing_info,
      payment_required: payment_required,
      credit_issued: credit_issued,
      payment_amount: ActionController::Base.helpers.number_to_currency(mp_net),
      credit_amount: ActionController::Base.helpers.number_to_currency(credit_amount),
      invoice_number: @invoice_number + invoice_num_offset,
      summary: summary,
      pages: pages,
      mp_name: mp.name,
      mp_partner_name: @partner_names[mp_partner_id] || @partner_names[:__unknown],
      mp_msm1_name: mp.msm1_name,
      mp_owner_name: mp.owner_name,
      commissions_only: @commissions_only,
    }
  end

  # add an order item to the marketplace
  def add_to_marketplace(orderItems, start_date = @start_date, end_date = @end_date)
    #
    # Build or get marketplace for each item. Builds @var m
    #
    orderItems.each {|x|
      # only process order once
      next if @orders[x.OrderId]
      @orders[x.OrderId] = true

      # sanitize order type
      x.Order.Type = getOrderGroupName(x.Order.Type);

      next if x.Order.Type == nil

      # instantiate order model
      order = MarketplaceOrder.new(x.Order, x.OrderId)

      # skip billing this one?
      next if !order.bill_order?(start_date, end_date)

      mp_name = x.Order.Account.Marketplace_Name__r.try(:Name)
      mp_id = x.Order.Account.Marketplace_Name__r.try(:Id)

      unless mp_name
        # puts("account #{x.Order.Account.Name} has no associated marketplace!")
        mp_name = 'Unknown'
        mp_id = '-1'
      end

      unless @marketplaces[mp_id]
        mp_msm = mp_id == '-1' ? 'Unknown' : x.Order.Account.Marketplace_Name__r.MSM1__r.try(:Name)
        mp_owner = mp_id == '-1' ? 'Unknown' :  x.Order.Account.Marketplace_Name__r.Owner.try(:Name)

        unless mp_msm
          mp_msm = 'Unknown'
        end

        unless mp_name
          mp_name = 'Unknown'
        end

        @marketplaces[mp_id] = Marketplace.new(mp_name, mp_id, mp_msm, mp_owner)
      end

      # update the marketplace
      @marketplaces[mp_id].add_order(x.Order.Account, x.Order.Type, order)
    }

    @marketplaces
  end

  # used to group orders into sub invoices
  def getOrderGroupName(type) 
    orderType = @orderTypes.find {|t| t.apiValue == type }

    if !orderType
      # puts ("unknown order type #{type}")
      return nil
    end

    return orderType.orderGroup.label
  end
end
