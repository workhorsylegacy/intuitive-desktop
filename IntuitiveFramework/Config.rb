

module ID
    class Config
        def self.load_config
            # Make sure the mode constant is defined
            $ID_CONFIG_LOADED = true
            ensure_initialized
            envs = [:test, :production, :development]
            raise "The $ID_ENV global can only be set with #{envs.join(', ')}" unless envs.include? $ID_ENV
            
            # Load the config yaml
            File.open($IntuitiveFramework_Config, 'r') do |f|
                $ID_CONFIG = YAML.load(f.read)
            end
            
            # Expand relative paths to be absolute
            path = File.dirname(File.expand_path(__FILE__)) + '/'
            start = $ID_CONFIG[$ID_ENV]
            [:data_dir, :comm_dir, :table_dir].each do |key|
                start[key] = path + start[key] unless ['/', '~'].include? start[key][0..0]
            end
            
            # Expand home paths to be absolute
            start = $ID_CONFIG[$ID_ENV]
            [:data_dir, :comm_dir, :table_dir].each do |key|
                start[key] = File.expand_path(start[key]) + '/' if start[key][0..0] == '~'
            end
            
            # Create any directories that are missing
            [:data_dir, :comm_dir, :table_dir].each do |key|
                dir = ""
                $ID_CONFIG[$ID_ENV][key].split('/').each do |part|
                    dir += "/#{part}"
                    Dir.mkdir(dir) unless File.directory?(dir)
                end
            end
        end
        
        def self.ip_address
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:ip_address]
        end
        
        def self.port
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:port]
        end
        
        def self.web_service
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:web_service]
        end
        
        def self.data_dir
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:data_dir]
        end
        
        def self.comm_dir
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:comm_dir]
        end
        
        def self.table_dir
            ensure_initialized
            $ID_CONFIG[$ID_ENV][:table_dir]
        end
        
        private
        
        def self.ensure_initialized
            raise "The $ID_ENV global has not been set." unless defined? $ID_ENV
            raise "The configuration has not been loaded" unless defined? $ID_CONFIG_LOADED
        end
    end
end