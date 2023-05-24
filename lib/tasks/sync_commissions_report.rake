require 'zip'
require "#{Rails.root}/config/environment"

# Sync the current month's "commisisons report" to the reporting database
namespace :sync do
  task :commissions, [:num_months, :offset] do | t, args |
    num_months = args[:num_months].to_i
    offset = args[:offset].to_i || 0

    unless num_months.is_a?(Numeric) && num_months > 0
      raise "num_months must be a non-zero positive integer"
    end
    
    puts "syncing commissions report: starting"

    start_month = Date.today.beginning_of_month << offset
    report_range = (num_months.times.each_with_object([]) do |count, array|
      array << start_month - count.months
    end).reverse

    puts [
      "Report Date Range:", 
      report_range.first,
      'to',
      report_range.last.end_of_month,
    ].join(' ')

    report_range.each do |date|
      data_size = sync_report(date)
      puts "Synced report: #{date}. Data Size: #{data_size}"
    end

    puts 'syncing commissions report: done'
  end
end

def sync_report(date)
  zip_file = generate_report_zip(date)
  data = extract_tsv_data(zip_file)

  sync_data(data)

  data.size
end

def generate_report_zip(date)
  invoicer = Salesforce::Reports
    .allPartners(0, date.at_beginning_of_month, true, true)

  invoicer.create_zip('task')
end

def extract_tsv_data(path) 
  data = []

  Zip::File.open(path) do |zipfile|
    zipfile.each do |entry|
      if entry.name.include? '.tsv'
        puts "Extracting: #{entry.name} from #{path}"

        all_rows = zipfile.read(entry.name)
        .force_encoding('utf-8')
        .lines(chomp:true)

        if all_rows.size > 1
          attributes = all_rows.shift
            .split("\t")
            .map do |header|
              header
                .strip
                .gsub(/\#/, 'n')
                .gsub(/\(/, '')
                .gsub(/\)/, '')
                .gsub(/\:/, '')
                .gsub(/\s/, '_')
                .downcase
                .to_sym
            end

          models = []
          
          all_rows.each_index do |row_index|
            row = all_rows[row_index].split(/\t/)
            model = {}

          
            row.each_index do |cell_index|
              cell = row[cell_index]

              if attributes[cell_index]
                if cell.include? '$'
                  model[attributes[cell_index]] = currency_to_number(cell)
                else
                  model[attributes[cell_index]] = cell
                end
              end
            end

            models.push(model)
          end

          data.concat(models)
        end
      end
    end
  end

  data
end

# create + update data, based on order number
def sync_data(data)
  data.each do |d|
    # find by order num
    existingData = CommissionsReport.find_by(order_number: d[:order_number])

    # update or create
    if existingData
      existingData.update(d)
    else
      CommissionsReport.new(d).save()
    end
  end

end

def currency_to_number currency
  currency.to_s.gsub(/[$,]/,'').to_f
 end