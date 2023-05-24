class OrderGroup < ApplicationRecord
  has_many :columns, -> { order(sort: :asc) }, :class_name => 'ColumnGroup', :primary_key => 'column_group_id', :foreign_key => 'groupId'
end
