if defined?(Mongoid)
  module AttrEncrypted
    module Adapters
      module Mongoid
        def self.extended(base) # :nodoc:
          class << base
            alias_method :included_without_attr_encrypted, :included
            alias_method :included, :included_with_attr_encrypted
          end
        end

        def included_with_attr_encrypted(base)
          included_without_attr_encrypted(base)
          base.attr_encrypted_options[:encode] = true
          base.attr_encrypted_options[:marshal] = true
        end
      end
    end
  end

  Mongoid::Document.extend AttrEncrypted::Adapters::Mongoid
end
