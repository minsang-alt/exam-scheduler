class Customer < ApplicationRecord
  has_many :reservations
  has_secure_password

  validates :name, :email, :phone, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{10,11}\z/ }
  validates :password, presence: true, length: { minimum: 6 }, on: :create

end 