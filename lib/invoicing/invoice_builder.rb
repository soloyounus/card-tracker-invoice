require "csv"

# Builds Prawn PDF objects for a single marketplace
class InvoiceBuilder
  # required fields are represented by nil
  DEFAULTS = {
    invoice_date: nil,
    start_date: nil,
    end_date: nil,
    billee: [],
    payment_required: false,
    credit_issued: false,
    payment_amount: nil,
    credit_amount: nil,
    invoice_number: nil,
    summary: nil,
    pages: nil,
    mp_name: nil,
    mp_partner_name: nil,
    mp_msm1_name: nil,
    mp_owner_name: nil,
    commissions_only: false,
  }

  HORIZONTAL_MARGIN = 5
  FOOTER_HEIGHT = 40
  HEADER_HEIGHT = 120
  STUB_POS_Y = 250
  LOGO_SIZE = 23

  def initialize(options = {})
    # init options
    dk = DEFAULTS.keys
    @opt = {}
    @page_inner_height = nil

    DEFAULTS.each { |a, b| set_opt(a, b) }
    options.each { |a, b| set_opt(a, b) }

    DEFAULTS.keys.each do |x|
      if DEFAULTS[x] === nil && (!@opt.key?(x) || @opt[x] === nil)
        raise ArgumentError.new("InvoiceBuilder requires option: #{x}")
      end
    end
  end

  def build_pdf
    pdf = Prawn::Document.new({
      page_size: "LETTER",
    })

    page_height = pdf.bounds.height
    @page_inner_height = page_height - HEADER_HEIGHT - FOOTER_HEIGHT
    first_page_start_y = page_height - HEADER_HEIGHT

    # billee address
    ba_offset = 80
    ba_height = build_billee_address(pdf, page_height - ba_offset)
    ba_overlap = (ba_height + ba_offset) - HEADER_HEIGHT
    if ba_overlap > 0
      first_page_start_y -= ba_overlap
    end

    # first page = summary
    build_page(pdf, @opt[:summary], first_page_start_y, STUB_POS_Y)

    if @opt[:payment_required]
      build_payment_stub(pdf)
    else
      build_credit_stub(pdf)
    end

    # sub invoices
    @opt[:pages].each_index { |p|
      pdf.start_new_page
      build_page(pdf, @opt[:pages][p])
    }

    #headers and footers come last so they can be repeated on each page
    #and page numbered
    build_headers pdf
    build_footers pdf

    pdf
  end

  # returns a csv string
  def build_csv(sep = ",")
    # build the rows: Array[Array[String]]
    # commissions report shows individual orders
    # standard report shows orders aggregated by type
    if (@opt[:commissions_only])
      rows = get_commissions_report_rows
    else
      rows = get_all_partners_report_rows
    end

    CSV.generate(:col_sep => sep) do |csv|
      rows
        .sort_by { |x| [x[2], x[1]] }
        .each do |row|
          csv << row
        end
    end
  end

  def build_tsv
    build_csv("\t")
  end

  def get_commissions_report_rows
    rows = []

    @opt[:pages].each_index { |p|
      page = @opt[:pages][p]

      page[:tables].each_index { |t|
        table = page[:tables][t]

        if table[:orders]
          table[:orders].each { |order|
            rows << [
              @opt[:end_date],
              @opt[:mp_owner_name],
              @opt[:mp_msm1_name],
              order[:revenue],
              @opt[:mp_partner_name],
              @opt[:mp_name],
              order[:account],
              order[:num],
              order[:type],
              order[:desc],
              order[:total_wh],
              order[:total_rt],
              order[:campaign_start_date],
              order[:campaign_end_date],
              order[:campaign_length],
              order[:campaign_name],
              order[:internal_num],
              order[:business_category],
              order[:cognito_entry],
              order[:cognito_form],
            ]
          }
        end
      }
    }

    rows
  end

  def get_all_partners_report_rows
    rows = []
    p = @opt[:summary]

    p[:tables].each { |t|
      tr = t[:rows]
      retail = t[:row_total_retail]

      tr.each_index { |r_i|
        r = tr[r_i]
        unless r[0].eql?("Grand Total")
          rows << [
            @opt[:end_date],
            @opt[:mp_partner_name],
            @opt[:mp_name],
            r[1],
            retail[r_i],
            r[0],
          ]
        end
      }
    }

    rows
  end

  def self.get_csv_header(commissions_only, sep = ",")
    if (commissions_only)
      headers = [
        "Invoice Date",
        "Owner: Full Name",
        "MSM1: Full Name",
        "Monthly Order Revenue",
        "Partner Account: Account Name",
        "Marketplace Name",
        "Account Name",
        "Order Number",
        "Order Type",
        "Description",
        "Wholesale Monthly Ammount",
        "Retail Monthly Ammount",
        "Order Campaign Start Date",
        "Order Campaign End Date",
        "Order Campaign Length (months)",
        "Order Campaign Name",
        "Internal Order #",
        "Order Business Category",
        "Cognito Entry",
        "Cognito Form"
      ]
    else
      headers = [
        "Invoice Date",
        "Partner",
        "Marketplace",
        "Amount",
        "Retail",
        "Order Type",
      ]
    end

    CSV.generate(:col_sep => sep) do |csv|
      csv << headers
    end
  end

  def self.get_summary(mp_name)
    {
      title: "Order Type Summary: #{mp_name}",
      tables: [
        {
          headers: ["Order Type", "Net Total"],
          total_row: true,
          rows: [],
          row_total_retail: [],
          width_pct: 50,
        },
      ],
    }
  end

  private

  def build_page(pdf, data, pos_y = 600, offset_height = FOOTER_HEIGHT)
    #header
    pdf.text_box data[:title], at: [0, pos_y], align: :center, size: 14, style: :bold

    #tables
    #put this in a bounding box so it can flow to the next page if needed
    #without clobbering the header
    title_height = 25
    content_y = pos_y - title_height
    box_height = content_y - offset_height
    pdf.bounding_box(
      [HORIZONTAL_MARGIN / 2, content_y],
      height: box_height,
      width: pdf.bounds.width - (HORIZONTAL_MARGIN),
    ) do
      # pdf.stroke_color 'ff0000'
      # pdf.stroke_bounds

      # build tables
      unless data[:tables].empty?
        data[:tables].each { |t|
          # pdf.text_box('x.to_s')
          # x = x + 1
          build_table(pdf, t)
        }
      end

      if data[:page_total]
        # show total
        pdf.text("Total #{data[:page_total]}")
      end
    end
  end

  def set_opt(name, value)
    @opt[name] = value
  end

  # build the billee address and return the height
  def build_billee_address(pdf, pos_y = 600)
    height = 0

    unless @opt[:billee].empty?
      @opt[:billee].each { |line|
        pdf.text_box(line, at: [HORIZONTAL_MARGIN, pos_y], size: 12)
        pos_y -= 15
      }
      height = (@opt[:billee].size * 15) + 20
    end

    height
  end

  def build_payment_stub(pdf)
    start_y = STUB_POS_Y
    pdf.text_box "Please cut along this line and return the bottom section with your payment. The top section is for your records.", at: [0, start_y], size: 10, align: :left
    pdf.dash(5, :space => 2, :phase => 2)
    pdf.stroke_horizontal_line 0, pdf.bounds.width, :at => start_y - 13
    #undo dash setting
    pdf.dash(1, :space => 0, :phase => 0)

    start_y -= 18
    pdf.bounding_box(
      [0, start_y],
      height: start_y - FOOTER_HEIGHT,
      width: pdf.bounds.width,
    ) do
      build_logo pdf
      build_biller_address pdf
      build_dates_and_number pdf, pdf.bounds.height
      build_billee_address pdf, pdf.bounds.height - 70
      build_remit_to pdf
      build_payment_due pdf
    end
  end

  def build_credit_stub(pdf)
    start_y = STUB_POS_Y

    pdf.bounding_box(
      [0, start_y],
      height: start_y - FOOTER_HEIGHT,
      width: pdf.bounds.width,
    ) do
      build_logo pdf
      build_biller_address pdf
      build_dates_and_number pdf, pdf.bounds.height
      build_billee_address pdf, pdf.bounds.height - 70
      line_height = 15
      start_y = remit_start_y line_height
      pdf.text_box "THIS IS NOT A BILL", at: [0, start_y], size: 14, style: :bold
      build_payment_due pdf, "Payment Due to Partner:", 320
    end
  end

  def build_logo(pdf)
    #uncomment to remove Radiate Media logo
    #return unless @company_name == DEFAULTS[:company_name]

    pdf.image "./images/solesolutionlogo.png", width: LOGO_SIZE, at: [0, pdf.bounds.height]
  end

  def build_biller_address(pdf)
    pdf.text_box COMPANY[:name], at: [LOGO_SIZE + 5, pdf.bounds.height - 2]
    pdf.text_box COMPANY[:payment_address][0], at: [LOGO_SIZE + 5, pdf.bounds.height - 14], size: 10
    pdf.text_box COMPANY[:payment_address][1], at: [LOGO_SIZE + 5, pdf.bounds.height - 25], size: 10
    pdf.text_box COMPANY[:payment_address][2], at: [LOGO_SIZE + 5, pdf.bounds.height - 36], size: 10
  end

  def build_dates_and_number(pdf, start_y = 680)
    date_width = 180
    date_height = 15
    date_y_position = start_y
    date_size = 12

    if @opt[:end_date]
      pdf.text_box "#{@opt[:payment_required] ? "INVOICE DATE" : "STATEMENT DATE"}:", at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :left
      pdf.text_box @opt[:end_date].to_s, at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :right
      date_y_position -= date_height
    end
    if @opt[:start_date]
      pdf.text_box "PERIOD START:", at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :left
      pdf.text_box @opt[:start_date].to_s, at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :right
      date_y_position -= date_height
    end
    if @opt[:end_date]
      pdf.text_box "PERIOD END:", at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :left
      pdf.text_box @opt[:end_date].to_s, at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :right
      date_y_position -= date_height
    end
    if @opt[:invoice_number]
      pdf.text_box "#{@opt[:payment_required] ? "INVOICE NUMBER" : "STATEMENT NUMBER"}:", at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :left
      pdf.text_box @opt[:invoice_number].to_s, at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :right
      date_y_position -= date_height
    end
    if @opt[:payment_required]
      pdf.text_box "PAYABLE ON RECEIPT", at: [pdf.bounds.width - date_width, date_y_position], size: date_size, align: :left
      date_y_position -= date_height
    end
  end

  def build_remit_to(pdf)
    line_height = 15
    start_y = remit_start_y line_height
    pdf.text_box "Remit Payment To:", at: [0, start_y], size: 14, style: :bold
    current_y = start_y - line_height
    pdf.text_box COMPANY[:name], at: [0, current_y], size: 14
    current_y -= line_height
    COMPANY[:payment_address].each do |address_line|
      pdf.text_box address_line, at: [0, current_y], size: 14
      current_y -= line_height
    end
  end

  def build_payment_due(pdf, label = "Payment Due:", text_width = 220)
    line_height = 15
    font_size = 18
    start_y = remit_start_y line_height

    pdf.text_box(label, {
      at: [pdf.bounds.width - text_width, start_y],
      width: text_width,
      size: font_size,
      align: :left,
    })

    pdf.text_box(@opt[:payment_amount].to_s, {
      at: [pdf.bounds.width - text_width, start_y],
      width: text_width,
      size: font_size,
      align: :right,
    })
  end

  def build_headers(pdf)
    pdf.repeat(:all) do
      build_logo pdf
      build_biller_address pdf
      build_dates_and_number pdf, pdf.bounds.height - 40
    end

    build_page_numbers pdf

    pdf
  end

  def build_page_numbers(pdf)
    pdf.number_pages("(Page <page> of <total>)", {
      at: [pdf.bounds.right - 150, 705],
      width: 150,
      align: :right,
      size: 10,
      style: :bold,
    })

    pdf
  end

  def build_footers(pdf)
    pdf.repeat(:all) do
      pdf.text_box "For questions regarding this statement, contact #{COMPANY[:name]} Accounting: #{COMPANY[:email]}", at: [0, 12], align: :center, size: 9, overflow: :expand
    end
  end

  LINE_HEIGHT = 15

  def remit_start_y(line_height = LINE_HEIGHT)
    line_height * (COMPANY[:payment_address].length + 2)
  end

  # build table an return the bottom y position
  def build_table(pdf, data, pos_y = 0)
    if data[:title]
      pdf.text(data[:title], { align: :left, size: 12 })
      pdf.move_down LINE_HEIGHT * 0.25
    end

    if data[:headers]
      header_row = data[:headers].map { |h|
        pdf.make_cell(
          content: h,
          align: :left,
          size: 10,
          background_color: "cccccc",
        )
      }
    end

    if data[:rows]
      num_rows = data[:rows].count
      data_rows = []

      data[:rows].each_with_index { |r, r_i|
        data_rows << r.map { |field|
          f = field.to_s
          # letters or date Y-m-d
          cell_align = if f.match(/[a-zA-Z]/) || f.match(/\d{4}-\d{2}-\d{2}/)
              :left
            else
              :right
            end

          pdf.make_cell(
            content: field.to_s,
            align: cell_align,
            size: 9,
            font_style: (data[:total_row] && (r_i + 1) === num_rows) ? :bold : :normal,
          )
        }
      }

      if header_row
        data_rows.unshift(header_row)
      end

      # make table
      table_options = {
        position: :center,
        header: !!header_row,
        row_colors: ["FFFFFF", "ebebeb"],
      }

      table_options[:width] = (pdf.bounds.width * (data[:width_pct] / 100.00)) if data[:width_pct]
      table_options[:column_widths] = data[:column_widths] if data[:column_widths]

      # if table_options[:column_widths]

      #   if table_options[:column_widths].size == data_rows.first.size
      #     table_options.except(:width)
      #   end
      # end

      pdf.table(data_rows, table_options)

      if data[:footer_text]
        pdf.text "\n"
        pdf.text data[:footer_text]
        pdf.move_down LINE_HEIGHT
      end

      pdf.move_down LINE_HEIGHT * 2
    end
  end
end
