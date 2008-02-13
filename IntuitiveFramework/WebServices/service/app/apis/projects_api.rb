

# FIXME: Rename to IntuitiveAPI
class ProjectsApi < ActionWebService::API::Base
  api_method :is_running,
			:returns => [:bool]
      
  api_method :register_project,
			:expects => [{:name => :string}, {:description => :string}, {:public_key => :string}, 
                    {:revision => :string}, {:project_number => :string}, {:branch_number => :string}, 
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}],
			:returns => [:bool]

  api_method :search_projects,
			:expects => [{:search => :string}],
			:returns => [[[{:name => :string}, {:description => :string}, {:public_key => :string}, 
                    {:revision => :string}, {:project_number => :string}, {:branch_number => :string}, 
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]]
      
  api_method :list_projects,
			:returns => [[[{:name => :string}, {:description => :string}, {:public_key => :string}, 
                      {:revision => :string}, {:project_number => :string}, {:branch_number => :string},
                      {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]]
                    
  api_method :register_identity_start,
      :expects => [{:name => :string}, {:public_key => :string}, {:description => :string},
                   {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}],
      :returns => [:string]
    
  api_method :register_identity_end,
      :expects => [{:name => :string}, {:public_key => :string}, {:description => :string},
                  {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer},
                  {:decrypted_test => :string}],
      :returns => [:bool]
    
  api_method :find_identity,
      :expects => [{:public_key => :string}],
      :returns => [[{:name => :string}, {:public_key => :string}, {:description => :string},
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]
      
  api_method :list_identities,
      :returns => [[[{:name => :string}, {:public_key => :string}, {:description => :string},
                     {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]]
      
  api_method :empty_everything,
      :returns => [:bool]
end
