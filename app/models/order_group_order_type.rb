class OrderGroupOrderType < ApplicationRecord
  belongs_to :orderGroup, :foreign_key => 'orderGroup_id'
  belongs_to :orderType, :foreign_key => 'orderType_id'
end
