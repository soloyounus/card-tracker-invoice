class ReportFormRecord < ApplicationFormRecord
  attr_accessor :start_date, :end_date, :partner_id, :invoice_number

  validate :require_start_date,
    :require_end_date,
    :valid_date_fields,
    :check_end_date_before_start_date

  validates :partner_id, presence: true
  validates :invoice_number, numericality: { only_integer: true }

  def require_start_date
    unless start_date.present?
      errors.add(:start_date, 'must be present')
    end
  end

  def require_end_date
    id = partner_id.to_i

    if id === -2 || id === -1
      unless end_date.present?
        errors.add(:end_date, 'must be present')
      end
    end
  end

  def valid_date_fields
    if start_date.present?
      s = DateFormRecord.new(start_date)

      unless s.valid?
        s.errors.each do |attribute, error|
          errors.add("start_date_#{attribute}".to_sym, error)
        end
      end
    end

    if end_date.present?
      e = DateFormRecord.new(end_date)

      unless e.valid?
        s.errors.each do |attribute, error|
          errors.add("end_date_#{attribute}".to_sym, error)
        end
      end
    end
  end

  def check_end_date_before_start_date
    id = partner_id.to_i

    if (id === -2 || id === -1) && start_date.present? && end_date.present?
      d1 = Date.civil(start_date[:year].to_i, start_date[:month].to_i)
      d2 = Date.civil(end_date[:year].to_i, end_date[:month].to_i)

      if d2 < d1
        errors.add(:end_month, "must be greater than or equal to start month")
      end
    else
      self.end_date = nil
    end
  end
end
