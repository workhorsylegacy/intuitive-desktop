
module ID
    class TestHelper
        # Will perform all cleanup after a test, to ensure that the next test is not contaminated:
        # kill servers, removes temp db files, and temp sockets.
        # Can raise errors if there was a need to cleanup.
        def self.cleanup(warnings_as_errors = false)
            # Communication Socket Files
            socket_files = Dir.entries(ID::Config.comm_dir).length - 2
            if socket_files > 0
                FileUtils.rm_rf(ID::Config.comm_dir)
                FileUtils.mkdir(ID::Config.comm_dir)
                display_error("There were #{socket_files} temp communication files that had to be manually deleted.", warnings_as_errors)
            end
            
            # Temporary Tables
            table_files = Dir.entries(ID::Config.table_dir).length - 2
            if table_files > 0
                FileUtils.rm_rf(ID::Config.table_dir)
                FileUtils.mkdir(ID::Config.table_dir)
                display_error("There were #{table_files} table files that had to be manually deleted.", warnings_as_errors)
            end
            
            # Data Storage
            data_files = Dir.entries(ID::Config.data_dir).length - 2
            if data_files > 0
                FileUtils.rm_rf(ID::Config.data_dir)
                FileUtils.mkdir(ID::Config.data_dir)
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