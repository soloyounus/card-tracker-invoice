class InvoicerJob < ApplicationJob
  include ActiveJobStatus::Hooks
  queue_as :default

  after_enqueue do |job|
    ActionCable.server.broadcast('invoicer:generate', {
      action: :enqueue,
      jobId: job.job_id,
      args: job.arguments[0],
    })

    ActionCable.server.broadcast('invoicer:generate', {
      action: :status,
      jobId: job.job_id,
      status: ActiveJobStatus.fetch(job.job_id).status,
    })
  end

  before_perform do |job|
    ActionCable.server.broadcast('invoicer:generate', {
      action: :status,
      jobId: job.job_id,
      status: ActiveJobStatus.fetch(job.job_id).status,
    })
  end

  rescue_from(RuntimeError) do |exception|
    ActionCable.server.broadcast('invoicer:generate', {
      action: :status,
      jobId: self.job_id,
      status: :fail,
      message: exception.message,
    })
   end

  # see invoices_controller#create
  # aid: partner id
  # aname: partner name
  # num: invoice number
  # start: report "start date" (invoice month and year)
  # end: report "end date" (only used for commissions report)
  def perform(args)
    start_date = Date.parse(args[:start]).at_beginning_of_month
    invoice_num = args[:num].to_i

    # initialize the correct reporter...
    if args[:aid]
      # individual partner invoice
      reporter = Salesforce::Reports.partnerInvoice(args[:aid], invoice_num, start_date)
    else
      # commissions or all-partners report...

      if args[:end]
        # multi-month report
        end_date = Date.parse(args[:end]).at_beginning_of_month
        reporter = BulkReport.new(self.job_id, invoice_num, start_date, end_date, args[:commissions_only])
      else
        # single report
        reporter = Salesforce::Reports.allPartners(invoice_num, start_date, args[:commissions_only])
      end
    end

    # generate report and output file
    output_file = reporter.create_zip(self.job_id)

    if output_file
      # associate the job_id with a filename
      report = Report.new

      report.job_id = self.job_id
      report.job_args = args.to_json

      report.file.attach(io: File.open(output_file), filename: output_file.split('/').last)
      report.save()

      # @todo OK to remove zipped file?

      ActionCable.server.broadcast('invoicer:generate', {
        action: :status,
        jobId: self.job_id,
        status: :complete,
        # url: report.
      })
    else
      if report.method_defined?(:orders) && report.orders.empty?
        ActionCable.server.broadcast('invoicer:generate', {
          action: :status,
          jobId: self.job_id,
          status: :empty,
        })
      else
        # unknown error
        ActionCable.server.broadcast('invoicer:generate', {
          action: :status,
          jobId: self.job_id,
          status: :fail,
        })
      end
    end
  end
end
