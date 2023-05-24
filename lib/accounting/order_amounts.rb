# represents the wholesale and retail amounts
class OrderAmounts
  attr_accessor :wholesale
  attr_accessor :retail

  def initialize(wholesale = 0.00, retail = 0.00)
    @wholesale = wholesale
    @retail = retail
  end

  def add(wh = 0.00, re = 0.00)
    @wholesale += wh.round(2)
    @retail += re.round(2)
  end
end
