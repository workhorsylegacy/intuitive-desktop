class ProjectsApi < ActionWebService::API::Base
  api_method :is_running,
			:returns => [:bool]
      
  api_method :register_project,
			:expects => [{:name => :string}, {:description => :string}, {:user_id => :string}, 
                    {:revision => :string}, {:project_number => :string}, {:branch_number => :string}, 
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}],
			:returns => [:bool]

  api_method :search_projects,
			:expects => [{:search => :string}],
			:returns => [[[{:name => :string}, {:description => :string}, {:user_id => :string}, 
                    {:revision => :string}, {:project_number => :string}, {:branch_number => :string}, 
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]]
      
  api_method :list_projects,
			:returns => [[[{:name => :string}, {:description => :string}, {:user_id => :string}, 
                      {:revision => :string}, {:project_number => :string}, {:branch_number => :string},
                      {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]]]
                      
  api_method :run_project,
      :expects => [{:revision => :string}, {:project_number => :string}, {:branch_number => :string},
                    {:ip_address => :string}, {:port => :integer}, {:connection_id => :integer}]
                    
  api_method :register_identity,
      :expects => [{:name => :string}, {:user_id => :string}, {:description => :string}],
      :returns => [:bool]
    
  api_method :search_identities,
      :expects => [{:search => :string}],
      :returns => [[{:name => :string}, {:user_id => :string}, {:description => :string}]]
      
  api_method :list_identities,
      :returns => [[[{:name => :string}, {:user_id => :string}, {:description => :string}]]]
      
  api_method :empty_everything,
      :returns => [:bool]
end
