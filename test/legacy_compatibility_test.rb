# -*- encoding: utf-8 -*-
require File.expand_path('../test_helper', __FILE__)

# Test to ensure that existing representations in database do not break on
# migrating to new versions of this gem. This ensures that future versions of
# this gem will retain backwards compatibility with data generated by earlier
# versions.
class LegacyCompatibilityTest < Test::Unit::TestCase
  def self.setup
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_tables
  end

  def self.create_tables
    silence_stream(STDOUT) do
      ActiveRecord::Schema.define(:version => 1) do
        create_table :legacy_nonmarshalling_pets do |t|
          t.string :name
          t.string :encrypted_nickname
          t.string :encrypted_birthdate
          t.string :salt
        end
        create_table :legacy_marshalling_pets do |t|
          t.string :name
          t.string :encrypted_nickname
          t.string :encrypted_birthdate
          t.string :salt
        end
      end
    end
  end

  setup

  class LegacyNonmarshallingPet < ActiveRecord::Base
    PET_NICKNAME_SALT = Digest::SHA256.hexdigest('my-really-really-secret-pet-nickname-salt')
    PET_NICKNAME_KEY = 'my-really-really-secret-pet-nickname-key'
    PET_BIRTHDATE_SALT = Digest::SHA256.hexdigest('my-really-really-secret-pet-birthdate-salt')
    PET_BIRTHDATE_KEY = 'my-really-really-secret-pet-birthdate-key'

    self.attr_encrypted_options[:mode] = :single_iv_and_salt

    attr_encrypted :nickname,
      :key => proc { Encryptor.encrypt(:value => PET_NICKNAME_SALT, :key => PET_NICKNAME_KEY) }
    attr_encrypted :birthdate,
      :key => proc { Encryptor.encrypt(:value => PET_BIRTHDATE_SALT, :key => PET_BIRTHDATE_KEY) }
  end

  class LegacyMarshallingPet < ActiveRecord::Base
    PET_NICKNAME_SALT = Digest::SHA256.hexdigest('my-really-really-secret-pet-nickname-salt')
    PET_NICKNAME_KEY = 'my-really-really-secret-pet-nickname-key'
    PET_BIRTHDATE_SALT = Digest::SHA256.hexdigest('my-really-really-secret-pet-birthdate-salt')
    PET_BIRTHDATE_KEY = 'my-really-really-secret-pet-birthdate-key'

    self.attr_encrypted_options[:mode] = :single_iv_and_salt

    attr_encrypted :nickname,
      :key => proc { Encryptor.encrypt(:value => PET_NICKNAME_SALT, :key => PET_NICKNAME_KEY) },
      :marshal => true
    attr_encrypted :birthdate,
      :key => proc { Encryptor.encrypt(:value => PET_BIRTHDATE_SALT, :key => PET_BIRTHDATE_KEY) },
      :marshal => true
  end

  def test_nonmarshalling_backwards_compatibility
    self.class.setup
    pet = LegacyNonmarshallingPet.create!(
      :name => 'Fido',
      :encrypted_nickname => 'uSUB6KGzta87yxesyVc3DA==',
      :encrypted_birthdate => 'I3d691B2PtFXLx15kO067g=='
    )

    assert_equal 'Fido', pet.name
    assert_equal 'Fido the Dog', pet.nickname
    assert_equal '2011-07-09', pet.birthdate
  end

  def test_marshalling_backwards_compatibility
    self.class.setup
    # Marshalling formats changed significantly from Ruby 1.8.7 to 1.9.3.
    # Also, Date class did not correctly support marshalling pre-1.9.3, so here
    # we just marshal it as a string in the Ruby 1.8.7 case.
    if RUBY_VERSION < '1.9.3'
      pet = LegacyMarshallingPet.create!(
        :name => 'Fido',
        :encrypted_nickname => 'xhayxWxfkfbNyOS2w1qBMPV49Gfvs6dcZFBopMK2zQA=',
        :encrypted_birthdate => 'f4ufXun4GXzahH4MQ1eTBQ=='
      )
    else
      pet = LegacyMarshallingPet.create!(
        :name => 'Fido',
        :encrypted_nickname => '7RwoT64in4H+fGVBPYtRcN0K4RtriIy1EP4nDojUa8g=',
        :encrypted_birthdate => 'bSp9sJhXQSp2QlNZHiujtcK4lRVBE8HQhn1y7moQ63bGJR20hvRSZ73ePAmm+wc5'
      )
    end

    assert_equal 'Fido', pet.name
    assert_equal 'Mummy\'s little helper', pet.nickname

    # See earlier comment.
    if RUBY_VERSION < '1.9.3'
      assert_equal '2011-07-09', pet.birthdate
    else
      assert_equal Date.new(2011, 7, 9), pet.birthdate
    end
  end
end

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
