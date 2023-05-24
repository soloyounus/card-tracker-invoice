class AccountBalance
  attr_accessor :credits
  attr_accessor :debits

  def initialize()
    @credits = OrderAmounts.new
    @debits = OrderAmounts.new
  end

  def credit(wh = 0.00, re = 0.00)
    @credits.add(wh, re)
    self
  end

  def debit(wh = 0.00, re = 0.00)
    @debits.add(wh, re)
    self
  end

  def add(bal)
    credit(bal.credits.wholesale, bal.credits.retail)
    debit(bal.debits.wholesale, bal.debits.retail)
    self
  end
end
