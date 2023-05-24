class ApplicationReportRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection :report
end
