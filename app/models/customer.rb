class Customer < ApplicationRecord
  has_many :reservations

  validates :name, :email, :phone, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{10,11}\z/ }

end 