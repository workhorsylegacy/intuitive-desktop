
require 'fileutils'

module ID; module Controllers
    class RevisionedFileSystemController        
        def self.patch(dest_file, source_file)
            command = "patch #{dest_file} #{source_file}"
            IO.popen(command, 'r+') do |io|
                io.close_write
                io.readlines # Read the return result so we will wait for the command to finnish
            end
        end
        
        def self.diff(original_file, new_file, result_file)
            message = "The file '#{original_file}' cannot be diffed, because it does not exist."
            raise message unless File.file?(original_file)
            
            message = "The file '#{new_file}' cannot be diffed, because it does not exist."
            raise message unless File.file?(new_file)
            
            command = "diff #{original_file} #{new_file} > #{result_file}"
            IO.popen(command, 'r+') do |io|
                io.close_write
                io.read # Read the return result so we will wait for the command to finnish
            end
            
            # Delete the result file if it is no difference
            File.delete(result_file) if File.size(result_file) == 0
        end
        
        # TODO: Someone break this up into a class of its own, where we can have it span multiple methods and be more easily verified by unit tests.
        def self.diff_folders(original_folder, changed_folder, result_folder, revision_number = :next)
            # Add '/' to the end of names that are missing it
            original_folder += '/' if original_folder.slice(-1..-1) != '/'
            changed_folder += '/' if changed_folder.slice(-1..-1) != '/'
            result_folder += '/' if result_folder.slice(-1..-1) != '/'
            
            # Make sure the revision_number is valid
            message = "The revision number of '#{revision_number}' is invalid. It must be a whole number or :next."
            raise message unless revision_number.is_a?(Fixnum) || revision_number == :next
            
            # Make sure the result folder exists
            Dir.mkdir(result_folder) unless File.directory?(result_folder)
            
            # Get the real revision_number if it was :next
            if revision_number == :next
                revision_number = (Dir.entries(result_folder) - ['.', '..']).sort.last
                revision_number = revision_number == nil ? 0 : revision_number.to_i + 1
            end
            result_folder += "#{revision_number}/"
            
            # Make sure the revision folder exists and is empty
            FileUtils.rm_rf(result_folder) if File.directory?(result_folder)
            Dir.mkdir(result_folder)
            
            # Create a map of original entries to old
            file_map = {}
            directory_map = {}
            
            # Create a file map that is the same as the original branch on both sides
            unprocessed_entries =
            (Dir.entries(original_folder) - ['.', '..']).collect do |entry|
                next if entry == ".file_system_changes"
                name = "#{original_folder}#{entry}"
                name += '/' if File.directory?(name)
                name
            end.compact
    
            while unprocessed_entries.length > 0
                entry = unprocessed_entries.pop
                
                if File.file?(entry)
                    name = entry.slice(original_folder.length..-1)
                    file_map[name] = :same
                elsif File.directory?(entry)
                    name = entry.slice(original_folder.length..-1)
                    directory_map[name] = :same
                    Dir.mkdir("#{result_folder}#{name}")
                    
                    (Dir.entries(entry) - ['.', '..']).each do |child_entry|
                        name = "#{entry}#{child_entry}"
                        name += '/' if File.directory?(name)
                        unprocessed_entries.push name
                    end
                end        
            end
    
            # Add the changes from the .file_system_changes file to the map
            if File.file?("#{changed_folder}.file_system_changes")
                # Copy the .file_system_changes to the delta
                FileUtils.cp("#{changed_folder}.file_system_changes", "#{result_folder}.file_system_changes")
            
                File.open("#{changed_folder}.file_system_changes", 'r') do |f|
                    count = 0
                    while f.eof? == false
                        command, source, dest = f.readline.split(',').collect { |n| n.strip }
                        count += 1
                        
                        case command.to_sym
                            when :delete_file:
                                file_map[source] = :delete_file
                            when :delete_directory:
                                # Mark this directory as deleted
                                directory_map[source] = :delete_directory
                                FileUtils.rm_rf("#{result_folder}#{source}")
                                
                                # Mark any nested directories as deleted
                                directory_map.keys.each do |directory|
                                    directory_map[directory] = :delete_directory if directory.slice(0..source.length) == source
                                end
                                
                                # Mark any nested files as deleted
                                file_map.keys.each do |file|
                                    file_map[file] = :delete_file if file.include?(source)
                                end
                            when :new_file:
                                file_map[source] = :new_file
                            when :new_directory
                                directory_map[source] = :new_directory
                                FileUtils.mkdir("#{result_folder}#{source}")
                            when :move_file:
                                file_map[source] = dest
                            when :move_directory:
                                directory_map[source] = dest
                                
                                # Move any nested directories too
                                directory_map.keys.each do |directory|
                                    after = directory.slice(source.length..-1)
                                    directory_map[directory] if directory.include?(source)
                                end
                                
                                # Move any nested files too
                                file_map.keys.each do |file|
                                    if file.include?(source)
                                        after = file.slice(source.length..-1)
                                        file_map[file] = dest + after
                                    end
                                end
                                
                                Dir.mkdir("#{result_folder}#{source}") unless File.directory?("#{result_folder}#{source}")
                                FileUtils.mv("#{result_folder}#{source}", "#{result_folder}#{dest}")
                            else raise "The command '#{command}' on line #{count} of the file '#{changed_folder}.file_system_changes' is unknown."
                        end
                    end
                end
            end
            
            # Use the map to diff the original and changed entries
            file_map.each_pair do |file, action|
                if action.is_a? String
                    # Do nothing
                elsif action == :same
                    diff("#{original_folder}#{file}", "#{changed_folder}#{file}", "#{result_folder}#{file}")
                elsif action == :new_file
                    FileUtils.touch("#{result_folder}#{file}")
                    diff("#{result_folder}#{file}", "#{changed_folder}#{file}", "#{result_folder}#{file}")
                elsif action == :delete_file
                    # Do nothing
                else
                    raise "The command '#{action}' is unknown."
                end
            end
        end
        
        def self.patch_folders(delta_folder, dest_folder, revision_number = :head)
            # Add '/' to the end of names that are missing it
            delta_folder += '/' if delta_folder.slice(-1..-1) != '/'
            dest_folder += '/' if dest_folder.slice(-1..-1) != '/'
            
            # Make sure the revision_number is valid
            message = "The revision number of '#{revision_number}' is invalid. It must be a whole number or :head."
            raise message unless revision_number.is_a?(Fixnum) || revision_number == :head
            
            FileUtils.rm_rf(dest_folder) if File.directory?(dest_folder)
            Dir.mkdir(dest_folder)
            
            # Get the real revision_number if it was :head
            if revision_number == :head
                revision_number = (Dir.entries(delta_folder) - ['.', '..']).sort.last
                revision_number = revision_number == nil ? 0 : revision_number.to_i + 1
            end
        
            # Get a sorted list of all the delta folders before this one
            delta_folders = 
            (Dir.entries(delta_folder) - ['.', '..']).sort.collect do |folder|
                next unless folder.to_i <= revision_number
                "#{delta_folder}#{folder}/"
            end.compact
    
            file_map = {}
            delta_folders.each do |curr_delta_folder|
                # Use the .file_system_changes file to change the file and directory structure
                if File.file?("#{curr_delta_folder}.file_system_changes")
                    File.open("#{curr_delta_folder}.file_system_changes", 'r') do |f|
                        count = 0
                        while f.eof? == false
                            count += 1
                            command, source, dest = f.readline.split(',').collect { |n| n.strip }
    
                            case command.to_sym
                                when :delete_file:
                                    File.delete("#{dest_folder}#{source}")
                                    file_map.delete(source)
                                when :delete_directory:
                                    # Mark this directory as deleted
                                    FileUtils.rm_rf("#{dest_folder}#{source}")
                                    
                                    # Mark any nested files as deleted
                                    file_map.keys.each do |file|
                                        if file.include?(source)
                                            after = file.slice(source.length..-1)
                                            file_map[file] = source + after 
                                        end
                                    end
                                when :new_file:
                                    FileUtils.touch("#{dest_folder}#{source}")
                                    file_map[source] = source
                                when :new_directory
                                    FileUtils.mkdir("#{dest_folder}#{source}")
                                when :move_file:
                                    FileUtils.mv("#{dest_folder}#{source}", "#{dest_folder}#{dest}")
                                    file_map[source] = dest
                                when :move_directory:                                
                                    # Move any nested files too
                                    file_map.keys.each do |file|
                                        if file.include?(source)
                                            after = file.slice(source.length..-1)
                                            file_map[file] = dest + after
                                        end
                                    end
                                    
                                    Dir.mkdir("#{dest_folder}#{source}") unless File.directory?("#{dest_folder}#{source}")
                                    FileUtils.mv("#{dest_folder}#{source}", "#{dest_folder}#{dest}")
                                else raise "The command '#{command}' on line #{count} of the file '#{curr_delta_folder}.file_system_changes' is unknown."
                            end
                        end
                    end
                end
                
                # Patch the files
                file_map.each do |source, dest|
                    next unless File.file?("#{curr_delta_folder}#{source}")
                    patch("#{dest_folder}#{dest}", "#{curr_delta_folder}#{source}")
                end
            end
        end
        
        def self.new_directory(root_directory, directory_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            directory_name += '/' if directory_name.slice(-1..-1) != '/'
            
            # Make sure the directory does not already exist and is not a file
            message = "Cannot create the directory '#{directory_name}', because a file with that name exists."
            raise message if File.file?(directory_name)
            
            message = "Cannot create the directory '#{directory_name}', because it already exists."
            raise message if File.directory?(directory_name)
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("new_directory, " + directory_name.slice(root_directory.length..-1) + "\n")
            end
            
            # Make the directory
            Dir.mkdir(directory_name)
        end
        
        def self.new_file(root_directory, file_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            
            # Make sure the file does not already exist and is not a directory
            message = "Cannot create the file '#{file_name}', because a directory with that name exists."
            raise message if File.directory?(file_name)  
            
            message = "Cannot create the file '#{file_name}', because it already exists."
            raise message if File.file?(file_name)
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("new_file, " + file_name.slice(root_directory.length..-1) + "\n")
            end
            
            # Make the file
            FileUtils.touch(file_name)
        end
        
        def self.delete_directory(root_directory, directory_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            directory_name += '/' if directory_name.slice(-1..-1) != '/'
            
            # Make sure the directory exist and is not a file
            message = "Cannot delete the directory '#{directory_name}', because it is a file."
            raise message if File.file?(directory_name) 
            
            message = "Cannot delete the directory '#{directory_name}', because it does not exist."
            raise message unless File.directory?(directory_name)       
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("delete_directory, " + directory_name.slice(root_directory.length..-1) + "\n")
            end
            
            # Delete the directory and all files
            FileUtils.rm_rf(directory_name)
        end
        
        def self.delete_file(root_directory, file_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            
            # Make sure the file exist and is not a directory
            message = "Cannot delete the file '#{file_name}', because it is a directory."
            raise message if File.directory?(file_name)
            
            message = "Cannot delete the file '#{file_name}', because it does not exist."
            raise message unless File.file?(file_name)
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("delete_file, " + file_name.slice(root_directory.length..-1) + "\n")
            end
            
            # Delete the file
            File.delete(file_name)
        end
        
        def self.move_directory(root_directory, source_directory_name, dest_directory_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            source_directory_name += '/' if source_directory_name.slice(-1..-1) != '/'
            dest_directory_name += '/' if dest_directory_name.slice(-1..-1) != '/'
            
            # Make sure the directory exist and is not a file
            message = "Cannot move the directory '#{source_directory_name}', because it is a file."
            raise message if File.file?(source_directory_name)
            
            message = "Cannot move the directory '#{source_directory_name}', because it does not exist."
            raise message unless File.directory?(source_directory_name)  
            
            message = "Cannot move the directory '#{source_directory_name}' to '#{dest_directory_name}', because the destination is a file."
            raise message if File.directory?(dest_directory_name)
            
            message = "Cannot move the directory '#{source_directory_name}' to '#{dest_directory_name}', because the destination directory already exists."
            raise message unless File.directory?(source_directory_name)          
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("move_directory, " + 
                      source_directory_name.slice(root_directory.length..-1) + 
                      ", " + 
                      dest_directory_name.slice(root_directory.length..-1) + 
                      "\n")
            end
            
            # Move the directory
            FileUtils.mv(source_directory_name, dest_directory_name)
        end
        
        def self.move_file(root_directory, source_file_name, dest_file_name)
            # Add '/' to the end of names that are missing it
            root_directory += '/' if root_directory.slice(-1..-1) != '/'
            
            # Make sure the source file exists and is not a directory, and the dest file does not exists
            message = "Cannot move the file '#{source_file_name}', because it is a directory."
            raise message if File.directory?(source_file_name)  
            
            message = "Cannot move the file '#{source_file_name}', because does not exists."
            raise message unless File.file?(source_file_name)
            
            message = "Cannot move the file '#{source_file_name}' to '#{dest_file_name}', because the destination file is a directory."
            raise message if File.directory?(dest_file_name)
            
            message = "Cannot move the file '#{source_file_name}' to '#{dest_file_name}', because the destination file already exists."
            raise message if File.file?(dest_file_name)
            
            # Note the changes in the change file
            File.open("#{root_directory}.file_system_changes", 'a') do |f|
                f.write("move_file, " + 
                    source_file_name.slice(root_directory.length..-1) + 
                    ", " + 
                    dest_file_name.slice(root_directory.length..-1) + 
                    "\n")
            end
            
            # Move the file
            FileUtils.mv(source_file_name, dest_file_name)
        end
    end
end; end
