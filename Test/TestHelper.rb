
module ID
    class TestHelper
        # Will perform all cleanup after a test, to ensure that the next test is not contaminated:
        # kill servers, removes temp db files, and temp sockets.
        # Can raise errors if there was a need to cleanup.
        def self.cleanup(warnings_as_errors = false)
            # Communication Server
            if Controllers::SystemCommunicationController.is_name_used?("CommunicationServer")
                unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("CommunicationServer")
                File.delete(unix_socket_file) if File.exist?(unix_socket_file)
                display_error("The Communication Server had to be manually killed.", warnings_as_errors)
            end
            
            # Communication Socket Files
            socket_files = Dir.entries($TempCommunicationDirectory).length - 2
            if socket_files > 0
                FileUtils.rm_rf($TempCommunicationDirectory)
                FileUtils.mkdir($TempCommunicationDirectory)
                display_error("There were #{socket_files} temp communication files that had to be manually deleted.", warnings_as_errors)
            end
            
            # Temporary Tables
            table_files = Dir.entries($TempTables).length - 2
            if table_files > 0
                FileUtils.rm_rf($TempTables)
                FileUtils.mkdir($TempTables)
                display_error("There were #{table_files} table files that had to be manually deleted.", warnings_as_errors)
            end
            
            # Data Storage
            data_files = Dir.entries($DataSystem).length - 2
            if data_files > 0
                FileUtils.rm_rf($DataSystem)
                FileUtils.mkdir($DataSystem)
                display_error("There were #{data_files} data files that had to be manually deleted.", warnings_as_errors)
            end
        end
        
        def self.display_error(message, warnings_as_errors)
            if warnings_as_errors
                raise message
            else
                warn message
            end
        end
    end
end