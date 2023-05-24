class OrderType < ApplicationRecord
  has_one :orderGroupOrderType, :foreign_key => 'orderType_id'
  has_one :orderGroup, through: :orderGroupOrderType
end
