require File.expand_path('../test_helper', __FILE__)

class MongoidUser
  include Mongoid::Document
  self.attr_encrypted_options[:mode] = :per_attribute_iv_and_salt

  field :encrypted_email, :type => String
  field :encrypted_email_salt, :type => String
  field :encrypted_email_iv, :type => String
  attr_encrypted :email, :key => SECRET_KEY
end

class MongoidHash
  include Mongoid::Document
  self.attr_encrypted_options[:mode] = :per_attribute_iv_and_salt

  field :encrypted_value, :type => String
  field :encrypted_value_iv, :type => String
  field :encrypted_value_salt, :type => String
  attr_encrypted :value, :key => SECRET_KEY
end

class MongoidTest < Test::Unit::TestCase
  def setup
    if Mongoid::Config.respond_to?(:connect_to) # Mongoid < 3
      Mongoid::Config.connect_to('mongoid_test')

    else
      Mongoid::Config.master = Mongo::Connection.new.db('mongoid_test')
    end
    Mongoid::Config.purge!
  end

  def test_should_encrypt_email
    email = 'test@example.com'
    @mongoid_user = MongoidUser.new :email => email
    assert @mongoid_user.save
    assert_not_nil @mongoid_user.encrypted_email
    assert_not_equal @mongoid_user.email, @mongoid_user.encrypted_email
    assert_equal email, MongoidUser.first.email
  end

  def test_should_encrypt_hash
    hash = { :foo => :bar }
    @mongoid_hash = MongoidHash.new :value => hash
    assert @mongoid_hash.save
    assert_not_nil @mongoid_hash.encrypted_value
    assert_not_equal @mongoid_hash.value, @mongoid_hash.encrypted_value
    assert_equal hash, MongoidHash.first.value
  end
end
