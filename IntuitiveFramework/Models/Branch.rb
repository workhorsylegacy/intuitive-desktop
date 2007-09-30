

module Models
    class Branch
        attr_reader :branch_number
        
        def initialize(name, user_id, from_existing = false)
            return if from_existing
        
            # Create the file structure
            Dir.mkdir($DataSystem) unless File.directory?($DataSystem)
            folder = Helpers::FileSystem::get_new_randomly_named_sub_directory($DataSystem, "branch_")
            @branch_number = folder.split('_').last.to_i
            
            ["#{self.folder_name}",
              "#{self.folder_name}deltas",
              "#{self.folder_name}workspace",
              "#{self.folder_name}revisions"].each do |n|
                Dir.mkdir(n) unless File.directory?(n)
            end
            
            # Record the creation of the name and user_id folders
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.workspace_folder}name")
            Controllers::RevisionedFileSystemController.new_file(self.workspace_folder, "#{self.workspace_folder}user_id")
            
            # Create the file for the base_revision_number at the branch root
            FileUtils.touch("#{self.folder_name}base_revision_number")
            
            self.name = name
            self.user_id = user_id
            self.base_revision_number = -1
            
            # Save the first revision
            Controllers::DataController::save_revision(self)
        end
        
        def folder_name
            "#{$DataSystem}branch_#{@branch_number}/"
        end
        
        def workspace_folder
            "#{self.folder_name}workspace/"
        end
        
        def name
            File.open("#{self.workspace_folder}name", 'r') { |f| return f.read }
        end
        
        def name=(value)
            File.open("#{self.workspace_folder}name", 'w') { |f| f.write(value) }
            value
        end
        
        def user_id
            File.open("#{self.workspace_folder}user_id", 'r') { |f| return f.read }
        end
        
        def user_id=(value)
            File.open("#{self.workspace_folder}user_id", 'w') { |f| f.write(value) }
            value
        end
        
        def base_revision_number
            File.open("#{self.folder_name}base_revision_number", 'r') { |f| return f.read.to_i }
        end
        
        def head_revision_number
            (Dir.entries("#{self.folder_name}deltas") - ['.', '..']).sort.last.to_i
        end
        
        # Returns all the projects in the workspace
        def projects
            # Create a project object for each project file
            (Dir.entries(self.workspace_folder) - ['.', '..']).collect do |entry|
                next unless File.directory?("#{self.workspace_folder}#{entry}/") && entry.split('_').first == "project"
                
                Project.from_existing(self, "#{self.workspace_folder}#{entry}/")
            end.compact
        end
        
        def self.from_existing(folder_name)
            new_branch = Branch.new(nil, nil, true)
            new_branch.instance_variable_set("@branch_number", folder_name.split('_').last.to_i)
            new_branch
        end
        
        def self.from_number(number)
            (Dir.entries($DataSystem) - ['.', '..']).each do |entry|
                next unless File.directory?("#{$DataSystem}#{entry}/") && entry.split('_').first == "branch"
                
                branch = Branch.from_existing("#{$DataSystem}#{entry}")
                return branch if branch.branch_number == number
            end
            
            raise "No Branch with the number '#{number}' found."
        end
        
        private
        
        def base_revision_number=(value)
            value = value.to_i
            File.open("#{self.folder_name}base_revision_number", 'w') { |f| f.write(value) }
            value
        end
    end
end