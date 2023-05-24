require 'pathname'

class DevController < ActionController::Base
  def describeTable(tableName)
    client = Salesforce.getClient()


    q = client.describe(tableName)
    data = {
      :q => q,
      :fields => q.fields.map(&:name),
      :rels => q.childRelationships.map do |x|
        {
          name: x.relationshipName,
          field: x.field,
          model: x.childSObject
        }
      end
    }

    render :json => data
  end

  def selectAccounts
    client = Salesforce.getClient()


    q = client.query('select Name, Partner_Account__r.Name, Marketplace_Name__r.Name, Marketplace_Name__r.MSM1__r.Name, Marketplace_Name__r.OwnerId, Marketplace_Name__r.Owner.Name from Account limit 10')

    data = q

    render :json => data
  end

  def dev
    # describeTable('Marketplace_Name__c')
    # describeTable('Account')
    describeTable('Order')
    # selectAccounts()
  end
end
