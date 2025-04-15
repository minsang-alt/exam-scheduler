class RenameEncryptedPasswordToPasswordDigestInCustomers < ActiveRecord::Migration[8.0]
  def change
    rename_column :customers, :encrypted_password, :password_digest
  end
end
