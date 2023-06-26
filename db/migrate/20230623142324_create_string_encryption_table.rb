# frozen_string_literal: true

class CreateStringEncryptionTable < ActiveRecord::Migration[7.0]
  def change
    create_table :string_encryptions do |t|
      t.text :original_string, null: false
      t.text :encrypted_string, null: false
      t.text :enc_type, null: false, index: true

      t.timestamps
    end
  end
end
