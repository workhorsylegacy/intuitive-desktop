
require 'openssl'
require 'base64'

module Models
    class EncryptionKey
	   attr_reader :is_public, :key

        def self.make_public_and_private_keys(key_bit_length=1024)
            rsa_data = OpenSSL::PKey::RSA.new(key_bit_length)
    
    		[EncryptionKey.new(rsa_data.public_key.to_s, true),
    		EncryptionKey.new(rsa_data.to_s, false)]
        end

    	def initialize(key, is_public)
    		@is_public = is_public
    		@key = OpenSSL::PKey::RSA.new(key)
    	end
  
        def encrypt(message)
    		if @is_public
          		Base64.encode64(@key.public_encrypt(message))
    		else
    			Base64.encode64(@key.private_encrypt(message))
    		end
        end
        
        def decrypt(message)
    		if @is_public
          		@key.public_decrypt(Base64.decode64(message))
    		else
    			@key.private_decrypt(Base64.decode64(message))
    		end
        end
    end
end


