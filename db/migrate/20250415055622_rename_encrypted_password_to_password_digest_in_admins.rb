class RenameEncryptedPasswordToPasswordDigestInAdmins < ActiveRecord::Migration[8.0]
  def change
    rename_column :admins, :encrypted_password, :password_digest
  end
end
