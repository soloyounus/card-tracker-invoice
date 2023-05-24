
class DateFormRecord < ApplicationFormRecord
  attr_accessor :day, :month, :year
  
  validates :day, numericality: { only_integer: true, less_than_or_equal_to: 31, greater_than_or_equal_to: 1 }
  validates :month, numericality: { only_integer: true, less_than_or_equal_to: 12, greater_than_or_equal_to: 1 }
  validates :year, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }
  validates :year, presence: true
end
