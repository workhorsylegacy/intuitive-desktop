


module ID; module Helpers
    class EasySocket
        def initialize(type)
            # Make sure the type is valid
            valid_types = [:net, :system]
            raise "The type can only be '#{valid_types.join(', ')}'." unless valid_types.include? type
            
            @type = type
            @is_open = false
        end
        
        def write_message(message, args)
            out_socket = nil
            begin
                case @type
                    when :system:
                      out_socket = UNIXSocket.new(args[:name])
                      out_socket.write YAML.dump(message)
                    when :net:
                      out_socket = TCPSocket.open(args[:ip_address], args[:port])
                      out_socket.send(YAML.dump(message), 0)
                    else; raise "Only :net and :system are supported for type."
                end
            ensure
                out_socket.close if out_socket
            end
        end
        
        def close
            @is_open = false
            @in_socket.close
            @read_thread.kill if @read_thread
            @read_thread = nil
        end
        
        def read_messages(args)
            # Make sure a block was given
            raise "Block required" unless block_given?
        
            @read_thread = Thread.new do
                begin
                    @in_socket = 
                    case @type
                        when :net:
                            unless args.has_key? :ip_address and args.has_key? :port
                                raise "Socket of type :net requires arguments :ip_address and :port in args hash."
                            end
                            TCPServer.new(args[:ip_address], args[:port])
                        when :system:
                            unless args.has_key? :name
                                raise "Socket of type :system requires arguments :name in args hash."
                            end
                            UNIXServer.new(args[:name])
                        else
                            raise "Only :net and :system are supported for type."
                    end
                rescue Errno::EADDRINUSE
                    case @type
                        when :net: raise "The network could not bind to the address '#{args[:ip_address]}:#}{args[:port]}' because it is already in use."
                        when :system: raise "The system socket could not bind to the name '#{@name}' because it is already in use."
                    end
                end
              
                # Have the system socket file garbage collected with the socket
                if @in_socket.is_a? UNIXServer
                    ObjectSpace.define_finalizer(@in_socket) do
                        FileUtils.rm(args[:name])
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
                      rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                          IO.select([@in_socket])
                          retry
                      end
                      
                      yield(message_as_yaml)
                end
            end
            
            @read_thread.join
            @read_thread = nil
        end
    end
end; end