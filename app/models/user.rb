class User < ActiveRecord::Base
  has_many :questions
  
  validates_presence_of :email
  validates_length_of :email, :within => 6..100 #r@a.wk
  validates_uniqueness_of :email
  validates_format_of :email, :with => /\A#{'[\w\.%\+\-]+'}@#{'(?:[A-Z0-9\-]+\.)+'}#{'(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'}\z/i
  
  validates_presence_of :password, :if => lambda { |u| u.encoded_password.nil? }
  validates_presence_of :password_confirmation, :if => lambda { |u| u.encoded_password.nil? }
  validates_confirmation_of :password
  validates_presence_of :encoded_password, :if => lambda { |u| u.password.nil? }

  attr_accessor :password, :password_confirmation

  before_create :encode_password

  def encode_password
    self.encoded_password = Base64.encode64(self.password)
  end

  def decoded_password
    Base64.decode64(self.encoded_password)
  end

  def voter_id!
    unless voter_id
      Pairwise.server(PAIRWISE_PARAMS.merge(:user => email, :pass => decoded_password))
      self.update_attribute(:voter_id, Pairwise.voter.first)
    end
  end
end
