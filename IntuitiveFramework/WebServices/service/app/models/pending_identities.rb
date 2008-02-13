class PendingIdentities < ActiveRecord::Base
  validates_presence_of :name, :description, :public_key, :ip_address, :port, :connection_id
end
