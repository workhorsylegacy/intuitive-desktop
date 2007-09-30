

module Controllers
  class DataController
    # Criteria is a hash like:
    #  :user_ids => ["user_id"],
    #  :names => ["name of a project"]}
    def self.find_projects(criteria)
        # Make sure the criteria is non empty hash
        message = "The criteria should be a Hash like {:user_ids => [], :names => []}"
        raise message unless criteria.is_a?(Hash) and criteria.length > 0
    
        projects = []
    
        # Get all the branches
        branches = (Dir.entries($DataSystem) - ['.', '..']).collect do |entry|
            next unless File.directory?("#{$DataSystem}#{entry}/") && entry.split('_').first == "branch"
                
            Models::Branch.from_existing("#{$DataSystem}#{entry}/")
        end.compact
        
        # Get the project names that match the search
        if criteria[:names]
            project_names = branches.collect {|b| b.projects.collect {|p| p.name}}.flatten.uniq
            project_names = criteria[:names].collect do |name|
                SearchController.find_similar_strings(name, project_names)
            end.flatten
            
            projects.concat(project_names.collect do |name|
                branches.collect do |branch|
                    branch.projects.select do |project|
                        project.name.downcase == name.downcase
                    end
                end
            end.flatten.compact)            
        end
        
        # Get the identity ids that match the search
        if criteria[:user_ids]
            identity_ids = branches.collect {|b| b.user_id }.flatten.uniq      
            
            
            projects = identity_ids.collect do |id|
              branches.collect do |branch|
                  branch.projects if branch.user_id == id
              end
            end.flatten.compact            
        end
        
        # Return an array of projects with no duplicates
        unique_projects = {}
        projects.each do |project|
            next if unique_projects.has_key?(project.project_number)
            unique_projects[project.project_number] = project
        end
        unique_projects.values        
    end
    
    # Criteria is a hash like:
    #  :user_ids => [user.public_universal_key],
    #  :names => ["name of a project"]}    
    def self.find_projects_over_network(communicator, local_connection, document_server_connection, criteria)
            # Ask the server for any projects
            communicator.send(local_connection, document_server_connection, {:command => :find_projects,
                                                                             :criteria => criteria})
          
            # Get the server's response
            message = communicator.wait_for_command(local_connection, :found_projects)
            
            # Return just the projects
            return message[:projects]
    end
    
    def self.run_project_over_network(communicator, local_connection, document_server_connection, window, program, project, branch)
        # Tell the Server that we want to run the project
        message = {:command => :run_project,
                    :project_number => project.project_number,
                    :branch_number => branch.branch_number}
        communicator.send(local_connection, document_server_connection, message)
        
            # Wait for the server to ok the process and give up a new connection to it
            message = communicator.wait_for_command(local_connection, :ok_to_run_project)
            new_server_connection = message[:new_connection]
            
            # Confirm that we got the new server connection
            message = { :command => :confirm_new_connection }
            communicator.send(local_connection, new_server_connection, message)
            
            # Get a new connection for the Model and Controller
            message = communicator.wait_for_command(local_connection, :got_model_and_controller_connections)
            model_connections = message[:model_connections]
            main_controller_connection = message[:main_controller_connection]
            document_states = message[:document_states]
            document_views = message[:document_views]
            main_view_name = message[:main_view_name]
            
            # Create a proxy Models and Controller
            models = {}
            model_connections.each do |model_connection|
                model = Helpers::Proxy.get_proxy_to_object(communicator, model_connection)
                models[model.name] = model
            end
            
            controller = Helpers::Proxy.get_proxy_to_object(communicator, main_controller_connection)
            
            # Connect the Program to the Models and Controller
            program.models = models
            program.states = Models::Data::XmlModelCreator::models_from_documents(document_states)
            
            program.views = Views::View.views_from_documents(program, document_views)
            program.views.each do |name, view|
                program.main_view = view if name == main_view_name
            end
            
            program.main_controller = controller
            program.setup_bindings
            
            # Add this program to a tab on the window
            window.add(program)
    end
    
    def self.run_project_locally(window, program, project)
            # Connect the Program to the Models
            program.models = Models::Data::XmlModelCreator::models_from_documents(project.document_models)
            program.states = Models::Data::XmlModelCreator::models_from_documents(project.document_states)

            # Connect the program to the Views
            program.views = Views::View.views_from_documents(program, project.document_views)
            program.views.each do |name, view|
                program.main_view = view if name == project.main_view_name
            end
            
            message = "The project's main view '#{project.main_view_name}' was not found in the list of views."
            raise message unless program.main_view
            
            # Connect the Program to the Controllers
            project.document_controllers.each { |document| Kernel.eval(document.data) }
            program.main_controller = Kernel.eval(project.main_controller_class_name).new(program.models)
            
            program.setup_bindings
            
            # Add this program to a tab on the window
            window.add(program)
    end
    
        def self.move_to_next_revision(branch)
            # Just return if the current revision is head
            return false unless branch.base_revision_number < branch.head_revision_number
            
            # Move to the next revision
            branch.send(:base_revision_number=, branch.base_revision_number + 1)
            create_workspace_from_revision(branch, branch.base_revision_number)
            
            # Return true if there are more revisions to move to
            return branch.base_revision_number != branch.head_revision_number
        end
        
        def self.move_to_previous_revision(branch)
            # Just return if the current revision is 0
            return false if branch.base_revision_number == 0
            
            # Move to the previous revision
            branch.send(:base_revision_number=, branch.base_revision_number - 1)
            create_workspace_from_revision(branch, branch.base_revision_number)
            
            # Return true if there are more revisions to move to
            return branch.base_revision_number != 0
        end
        
        def self.save_revision(branch)
            # Determine if this is the first revision
            is_first_revision = branch.base_revision_number == -1
            branch.send(:base_revision_number=, 0) if is_first_revision
            
            # Make sure the revision the workspace is based on is up to date
            create_revision_from_deltas(branch, branch.base_revision_number)
            new_delta_number = branch.head_revision_number + 1
            
            # Get the paths of the original, changed, and result folders
            original_folder = "#{branch.folder_name}revisions/#{branch.base_revision_number}/"
            changed_folder = "#{branch.folder_name}workspace/"
            result_folder = "#{branch.folder_name}deltas/"
            
            # Save the differences
            RevisionedFileSystemController.diff_folders(original_folder, changed_folder, result_folder)
            File.delete("#{changed_folder}.file_system_changes") if File.file?("#{changed_folder}.file_system_changes")
        
            # Update the revision number
            branch.send(:base_revision_number=, new_delta_number) unless is_first_revision
            create_revision_from_deltas(branch, branch.base_revision_number)
        end
        
        private
        def self.create_workspace_from_revision(branch, revision_number)
            # Make sure the revision is up to date
            create_revision_from_deltas(branch, revision_number)
            
            # Copy the revision to the workspace
            FileUtils.rm_rf("#{branch.folder_name}workspace/")
            FileUtils::cp_r("#{branch.folder_name}revisions/#{revision_number}/", "#{branch.folder_name}workspace/")
        end
        
        def self.create_revision_from_deltas(branch, revision_number)
            RevisionedFileSystemController.patch_folders("#{branch.folder_name}deltas/", "#{branch.folder_name}revisions/#{revision_number}/", revision_number)
        end
    end
end
