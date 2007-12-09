



module ID; module Models
    	class Category < ActiveRecord::Base
            establish_connection(Models::USER_DATABASE_CONNECTION)

    		has_and_belongs_to_many :documents
    		validates_presence_of :name
    		validates_uniqueness_of :name
    	end
end; end