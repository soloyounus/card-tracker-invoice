require 'zip'

class BulkReport
  TMP_DIR = Rails.root.join('tmp', 'reports-bulk').to_s

  def initialize(job_id, invoice_number, start_date, end_date, commissions_only)
    unless start_date.instance_of?(Date)
      raise 'start_date must be instance of Date'
    end

    unless end_date.instance_of?(Date)
      raise 'end_date must be instance of Date'
    end

    num_months = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    @report_dates = (num_months + 1).times.each_with_object([]) do |count, array|
      array << start_date.beginning_of_month + count.months
    end

    if @report_dates.empty?
      raise "@report_dates must not be empty"
    end

    @job_id = job_id
    @invoice_number = invoice_number
    @start_date = start_date
    @end_date = end_date
    @storage_dir = File.join(TMP_DIR, @job_id)
    @file_name = "bulk_#{commissions_only ? 1 : 0}_#{start_date}_to_#{end_date}"
    @commissions_only = commissions_only
    @invoicer_format = { pdf: false, csv: true }

    prepare_storage
  end

  def create_zip(namespace)
    reports = []

    @report_dates.each do |date|
      invoicer = Invoicer.new(false, date, @invoice_number, @invoicer_format, @commissions_only)

      reports << invoicer.create_zip(namespace)
    end

    save_to_zip(combine_report_data(reports))
  end

  def combine_report_data(files)
    header = ''
    rows = []

    files.each do |path|
      if path
        Zip::File.open(path) do |archive|
          archive.each_with_index do |entry, index|
            if entry.name.include?('.csv')
              file_rows = archive.read(entry.name)
                .force_encoding('utf-8')
                .lines(chomp:true)

              if header.empty?
                header = file_rows.first
              end

              file_rows.slice(1, file_rows.size).each do |row|
                rows.push(row)
              end
            end
          end
        end
      end
    end

    [header].concat(rows)
  end

  def save_to_zip(csv_data)
    # make csv
    csv_file_name = "#{@file_name}.csv"
    csv_file_path = File.join(@storage_dir, csv_file_name)

    File.open(csv_file_path, 'w+') { |f|
      f << csv_data.join("\r\n")
    }

    # make zip
    zip_file_path = File.join(@storage_dir, "#{@file_name}.zip")

    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      zipfile.add(csv_file_name, csv_file_path)
    end

    return zip_file_path
  end

  def prepare_storage
    unless Dir.exist?(TMP_DIR)
      FileUtils.mkdir_p(TMP_DIR)
    end

    FileUtils.rm_rf(@storage_dir)
    FileUtils.mkdir_p(@storage_dir)
  end
end