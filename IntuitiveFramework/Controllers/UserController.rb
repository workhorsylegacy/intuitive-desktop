
path = File.dirname(File.expand_path(__FILE__))
require "#{path}/Namespace"

# FIXME: Rename to IdentityController and change Virtual Identity to just Identity.
module ID; module Controllers
	class UserController
=begin
        def self.register_identity(communicator, local_connection, server_connection, user)
            # Tell the server we want to register an identity
            message = { :command => :register_identity,
                        :public_key => user.public_universal_key,
                        :name => user.name }
            communicator.send_net_message(local_connection, server_connection, message)

            # Wait for the server to ok the process and give up a new connection to it
            while (message = communicator.get_net_message(local_connection, :ok_to_register_on_new_connection)) == nil
                sleep 0.1
            end
            new_server_connection = message[:new_connection]
            
            # Confirm that we got the new server connection
            message = { :command => :confirm_new_connection }
            communicator.send_net_message(local_connection, new_server_connection, message)

			     # Start the test
            satisfy_identity_ownership_test(communicator, local_connection, new_server_connection, user)
        end
=end
        def self.create_ownership_test(public_key)
            # Get the Identity information
#            begin
                crypto = ID::Models::EncryptionKey.new(public_key, true)
#            rescue
#                raise "FIXME: This may be throwing because the local Models module is hiding the IntuitiveFramework one"
#            end
            
            # Generate a random number and encrypt it with the user's public key
            srand
            decrypted_proof = rand(2**256).to_s
            encrypted_proof = crypto.encrypt(decrypted_proof)
            
            @@pending_identity_tests ||= {}
            @@pending_identity_tests[public_key] = decrypted_proof
            
            # Return the random number encrypted
            encrypted_proof
        end

        def self.passed_ownership_test?(public_key, decrypted_proof)
            # Get the Identity information
            crypto = Models::EncryptionKey.new(public_key, true)
            @@pending_identity_tests ||= {}
            original_proof = @@pending_identity_tests[public_key]
            
            # Return if the proof was good or not
            return decrypted_proof == original_proof
        end
        
        def self.clear_ownership_test(public_key)
            @@pending_identity_tests ||= {}
            @@pending_identity_tests.delete(public_key)
            
            nil
        end
        
        def self.answer_ownership_test(private_key, encrypted_proof)
            # Get the Identity information
            crypto = Models::EncryptionKey.new(private_key, false)
            
            crypto.decrypt(encrypted_proof)
        end
=begin
        def self.find_user(communicator, local_connection, server_connection, user_public_key)
            message = {:command => :find_virtual_identity, 
                        :public_key => user_public_key}
            communicator.send_command(local_connection, server_connection, message)
			   
            message = communicator.wait_for_command(local_connection, :found_virtual_identity)
			   
            user = Models::User.new
		    user.name = message[:name]
		    user.public_universal_key = message[:public_key]
		    user
        end
=end
        def self.create_user(name)
            public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
            user = Models::User.new
            user.name = name
            user.public_universal_key = public_key.key.to_s
            user.private_key = private_key.key.to_s
            user.save!
            user
        end
        
        def self.destroy_user(user)
            user.destroy
        end
	end
end; end

