class InvoicesController < ApplicationController
  def new
    @partners = Salesforce::Accounts.all.map { |a|
      [a.Name, a.Id]
    }.unshift ['All Partners (orders)', -1], ['All Partners (commissions)', -2]
  end

  def create
    # extract inputs
    form = ReportFormRecord.new(params)

    unless form.valid?
      return render :status => :bad_request, :json => { error: form.errors.full_messages.to_sentence }.to_json
    end

    # report options
    partner_id = form.partner_id 
    commisions_only=false

    if partner_id.to_s === '-1' then
      partner_id = false
      partner_name = 'All Partners'
    elsif partner_id.to_s === '-2' then
      partner_id = false
      partner_name = 'All Partners'
      commisions_only=true
    else
      begin
        partner = Salesforce::Accounts.get(partner_id)
        partner_name = partner.Name
      rescue => e
        return render json: {error: "Partner does not exist", status: 400}.to_json
      end
    end

    #
    # Push job
    #
    InvoicerJob.perform_later({
      aid: partner_id,
      aname: partner_name,
      num: form.invoice_number,
      start: Date.new(form.start_date[:year].to_i, form.start_date[:month].to_i).to_s,
      end: if form.end_date then Date.new(form.end_date[:year].to_i, form.end_date[:month].to_i).to_s else nil end,
      commissions_only: commisions_only
    })
  end
end
