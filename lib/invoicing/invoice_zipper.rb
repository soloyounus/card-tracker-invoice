require 'zip'
require 'securerandom'

class InvoiceZipper
  TMP_DIR = Rails.root.join('tmp', 'reports').to_s

  @zip = nil

  def initialize(dir_name, filename_tpl, filename_short, commissions_only)
    @filename_tpl = filename_tpl
    @filename_short = filename_short

    @files_dir = File.join(TMP_DIR, dir_name)
    @zip_filename = File.join(TMP_DIR, "#{filename_short}.zip")

    # prepare directories
    unless Dir.exist?(TMP_DIR)
      FileUtils.mkdir_p(TMP_DIR)
    end

    FileUtils.rm_rf(@files_dir)
    FileUtils.mkdir_p(@files_dir)

    # remove old zip
    if Pathname(@zip_filename).exist?
      FileUtils.rm_rf(@zip_filename)
    end

    @commissions_only = commissions_only
  end

  # Calls functions to write files in different formats and compress files
  def build_zip(invoice_objects)
    # collect PDF file names
    pdf_files = []
    # collect CSV strings (render a single file, below)
    csvs = []
    tsvs = []

    # collect formats
    invoice_objects.map { |x|
      fn = @filename_tpl.%  x[3]

      pdf = if x[0] then pdf_files << write_pdf(x[0], fn) end
      csv = if x[1] then csvs << x[1] end
      tsv = if x[2] then tsvs << x[2] end

      x
    }

    files = pdf_files

    # render csv as one file
    unless csvs.empty?
      csv_file = write_csv(csvs.join(''), @filename_short)
      files << csv_file
    end

     # render tsv as one file
     unless tsvs.empty?
      tsv_file = write_tsv(tsvs.join(''), @filename_short)
      files << tsv_file
    end

    # write zip 
    zip = write_zip(files)

    if zip
      @zip = zip
    end
  end

  def get_zip_filename
    if @zip != nil
      @zip_filename
    else
      nil
    end
  end

  private

  def write_pdf(pdf, file_name)
    file_key = SecureRandom.hex(8)
    file_name = "#{file_name}-#{file_key}.pdf"
    file_path = File.join(@files_dir, file_name)

    # @todo - handle failure?
    pdf.render_file(file_path)

    [file_name, file_path]
  end

  def write_csv(data, file_name) 
    file_key = SecureRandom.hex(8)
    file_name = "#{file_name}-#{file_key}.csv"
    file_path = File.join(@files_dir, file_name)

    # @todo - handle failure?
    File.open(file_path, 'w+') { |f|
      f << InvoiceBuilder.get_csv_header(@commissions_only) << data
    }

    [file_name, file_path]
  end


  def write_tsv(data, file_name) 
    file_key = SecureRandom.hex(8)
    file_name = "#{file_name}-#{file_key}.tsv"
    file_path = File.join(@files_dir, file_name)

    # @todo - handle failure?
    File.open(file_path, 'w+') { |f|
      f << InvoiceBuilder.get_csv_header(@commissions_only, "\t") << data
    }

    [file_name, file_path]
  end

  # @see return values of write_pdf and write_csv for param files Array[Array[String, String]]
  def write_zip(files)
    Zip::File.open(@zip_filename, Zip::File::CREATE) do |zipfile|
      files.each { |x|
        name = x[0]
        file_path = x[1]

        zipfile.add(name, file_path)
      }
    end

    # delete uncompressed files
    FileUtils.rm_rf(@files_dir)

    return @zip_filename
  end
end
