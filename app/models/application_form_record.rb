class ApplicationFormRecord
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  abstract_class = true

  def initialize(attributes = {})
    attributes
      .except(:utf8, :commit, :controller, :action)
      .each do |name, value|
        send("#{name}=", value)
      
      end
  end

  def persisted?
    false
  end

end
