
path = File.dirname(File.expand_path(__FILE__))
require "#{path}/Namespace"

# FIXME: Rename to IdentityController and change Virtual Identity to just Identity.
module Controllers
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
        def self.satisfy_identity_ownership_test(communicator, local_connection, remote_connection, user)
            # Get an encrypted challenge from the remote machine
            while (message = communicator.get_net_message(local_connection, :challenge_identity_ownership)) == nil
                sleep 0.1
            end
            encrypted_message = message[:encrypted_proof]
            decrypted_message = Models::EncryptionKey.new(user.private_key, false).decrypt(encrypted_message)
			   
            # Send it back to the other machine unencrypted
            message = { :command => :prove_identity_ownership,
                      :public_key => user.public_universal_key,
                      :decrypted_proof => decrypted_message }
            communicator.send_net_message(local_connection, remote_connection, message)
			   
            # Make sure we got a confirmation
            while (message = communicator.get_net_message(local_connection, :confirmed_identity_ownership)) == nil
                sleep 0.1
            end
            
            message
        end

        def self.require_identity_ownership_test(communicator, local_connection, remote_connection, user_name, user_public_key)
            # Get the Virtual Identity information
            public_key = Models::EncryptionKey.new(user_public_key, true)
            
            # Generate a random number and encrypt it with the user's public key
            decrypted_proof = rand(2**256).to_s
            encrypted_proof = public_key.encrypt(decrypted_proof)

            out_message = { :command => :challenge_identity_ownership,  
                        :encrypted_proof => encrypted_proof}
            communicator.send_net_message(local_connection, remote_connection, out_message)
            
            # Wait for the remote machine to send proof back
            while (message = communicator.get_net_message(local_connection, :prove_identity_ownership)) == nil
                sleep 0.1
            end

            # Get the Virtual Identity information
            connection = message[:source_connection]
            public_key = Models::EncryptionKey.new(message[:public_key], true)
            remote_decrypted_proof = message[:decrypted_proof]
            
            # Make sure the proof was good
            if decrypted_proof != remote_decrypted_proof
                raise "Filed to prove identity for #{name}."
            else
                # The identity ownership was proven
                out_message = { :command => :confirmed_identity_ownership, 
                                :connection => connection, 
                                :name => user_name, 
                                :public_key => public_key}
                communicator.send_net_message(local_connection, connection, out_message)
            end
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
end

