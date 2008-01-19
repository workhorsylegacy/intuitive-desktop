


module ID; module Helpers
    class EasySocket
        def initialize(args)
            # Make sure the type is valid
            @type = args.has_key?(:ip_address) ? :net : :system
            @is_open = false
            @name, @port, @ip_address = nil
            
            # Make sure the args are correct for the type
            case @type
                when :system:
                    raise "Socket of type :system requires arguments :name in args hash." unless args.has_key? :name
                    @name = args[:name]
                when :net:
                    unless args.has_key? :ip_address and args.has_key? :port
                        raise "Socket of type :net requires arguments :ip_address, and :port in args hash."
                    end
                    @ip_address = args[:ip_address]
                    @port = args[:port]
            end
            
            # If the name is :random, replace it with a random-unused name
            @name = self.class.get_random_unused_name if @name == :random
        end
        
        def name_as_file
            ID::Config.comm_dir + @name
        end
        
        def full_name
            retval = {}
            retval.merge!(:ip_address => @ip_address) if @ip_address
            retval.merge!(:port => @port) if @port
            retval.merge!(:name => @name) if @name
            retval
        end
        
        def write_message(message)
            out_socket = nil
            
            # Rewrite the source and destinations to be relative to the destination
            message.merge!(:source => self.full_name) unless message.has_key?(:source)
            
            # Make sure there is a destination
            raise "No :destination in the message." unless message.has_key? :destination
            destination = message[:destination]
            
            # Determine if the destination is a system or net socket
            is_remote = destination.has_key?(:ip_address) && destination.has_key?(:port)
            
            # Get the address for the destination
            dest_ip_address = destination[:ip_address]
            dest_port = destination[:port]
            dest_name = destination[:name]
            
            begin
                unless is_remote
                        begin
                            out_socket = UNIXSocket.new(ID::Config.comm_dir + dest_name)
                            out_socket.write YAML.dump(message)
                        rescue Errno::ENOENT
                            raise "No system socket called '#{dest_name}' to write to."
                        end
                else
                        begin
                            out_socket = TCPSocket.open(dest_ip_address, dest_port)
                            out_socket.send(YAML.dump(message), 0)
                        rescue Errno::ECONNREFUSED
                            raise "No net socket at '#{dest_ip_address}:#{dest_port}' to write to."
                        end
                end
            ensure
                out_socket.close if out_socket
            end
        end
        
        def close
            return unless @is_open
            @is_open = false
            @in_socket.close if @in_socket
            @in_socket = nil
            @read_thread.kill if @read_thread
            @read_thread = nil
        end
        
        def read_messages
            # Make sure a block was given
            raise "Block required" unless block_given?
        
            @read_thread = Thread.new do
                begin
                    @in_socket = case @type
                        when :net: TCPServer.new(@ip_address, @port)
                        when :system: UNIXServer.new(self.name_as_file)
                    end
                rescue Errno::EADDRINUSE
                    case @type
                        when :net: raise "The network could not bind to the address '#{@ip_address}:#{@port}' because it is already in use."
                        when :system: raise "The system socket could not bind to the name '#{@name}' because it is already in use."
                    end
                end
              
                # Have the system socket file garbage collected with the socket
                if @in_socket.is_a? UNIXServer
                    ObjectSpace.define_finalizer(@in_socket) do
                        FileUtils.rm(self.name_as_file)
                    end
                end
              
                @is_open = true
                while @is_open
                      message_as_yaml = nil
                      begin
                          # Get the yamled data from the socket
                          sock = @in_socket.accept_nonblock
                          message_as_yaml = sock.read
                          sock.close
                          
                          # Get the data from the yaml if there is any
                          next if message_as_yaml.length == 0
                      # Retry if there is an error. If we try to reselect the socket IO and fail, assume the socket was forced closed
                      rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                          begin
                              IO.select([@in_socket])
                          rescue IOError
                              break
                          end
                          retry
                      end
                      
                      yield(message_as_yaml)
                end
            end
            
            @read_thread.join
            @read_thread = nil
        end
        
        def self.get_random_unused_name
              new_name = nil
              loop do
                  srand
                  new_name = rand(2**16).to_s
                  break unless Servers::CommunicationServer.is_name_used?(new_name)
              end
              new_name
        end
    end
end; end