require File.expand_path('../test_helper', __FILE__)

class LegacyMongoidUser
  include Mongoid::Document
  field :encrypted_email, :type => String
  self.attr_encrypted_options[:mode] = :single_iv_and_salt
  attr_encrypted :email, :key => SECRET_KEY
end

class LegacyMongoidHash
  include Mongoid::Document
  field :encrypted_value, :type => String
  self.attr_encrypted_options[:mode] = :single_iv_and_salt
  attr_encrypted :value, :key => SECRET_KEY
end

class LegacyMongoidArray
  include Mongoid::Document
  field :encrypted_value, :type => Array
  field :encrypted_value_iv, :type => String
  field :encrypted_value_salt, :type => String
  self.attr_encrypted_options[:mode] = :single_iv_and_salt
  attr_encrypted :value, :key => 'really secret', :type => Array, :marshal => false
end

class LegacyMongoidTest < Test::Unit::TestCase
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
    @mongoid_user = LegacyMongoidUser.new :email => email
    assert @mongoid_user.save
    assert_not_nil @mongoid_user.encrypted_email
    assert_not_equal @mongoid_user.email, @mongoid_user.encrypted_email
    assert_equal email, LegacyMongoidUser.first.email
  end

  def test_should_encrypt_hash
    hash = { :foo => :bar }
    @mongoid_hash = LegacyMongoidHash.new :value => hash
    assert @mongoid_hash.save
    assert_not_nil @mongoid_hash.encrypted_value
    assert_not_equal @mongoid_hash.value, @mongoid_hash.encrypted_value
    assert_equal hash, LegacyMongoidHash.first.value
  end

  def test_should_encrypt_enumerable_array
    ary = [ 'foo', 'bar', 'baz' ]
    @mongoid_array = LegacyMongoidArray.new :value => ary
    assert @mongoid_array.save
    assert_not_nil @mongoid_array.encrypted_value
    assert @mongoid_array.encrypted_value.size == 3
    assert @mongoid_array.encrypted_value != ary
    assert_equal ary, LegacyMongoidArray.first.value
  end
end
