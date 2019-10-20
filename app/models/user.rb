class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  has_many :novels, dependent: :destroy
  has_many :pictures, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :novel_bookmark, through: :bookmarks, source: :novel
  has_many :impressions, dependent: :destroy
  has_many :story_impressions, through: :impressions, source: :story
  has_many :active_relationships, class_name:  "Relationship",foreign_key: "follower_id",
                                                dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :passive_relationships, class_name:  "Relationship",foreign_key: "followed_id",
                                                dependent:   :destroy
  has_many :followers, through: :passive_relationships, source: :follower
  has_one_attached :image
  has_many :rooms,foreign_key: "sender_id", dependent: :destroy
  has_many :dm_user, through: :rooms, source: :receiver
  validates :name, presence:true, length:{ maximum:50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence:true, length:{ maximum:255 },format: { with: VALID_EMAIL_REGEX },
             uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    has_secure_password


  def self.digest(string)
  cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                BCrypt::Engine.cost
  BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(attribute,token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

   # ユーザーの永続ログインを破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  def activate
    # レシーバー自身を示すか確認
    self.update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def follow(other_user)
    following << other_user
  end

  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def story?(story)
    novels.include?(story)
  end

  def bookmark?(other_novel)
    novel_bookmark.include?(other_novel)
  end

  def bookmark(other_novel)
    novel_bookmark << other_novel
  end

  def unbookmark(other_novel)
    bookmarks.find_by(novel_id: other_novel.id).destroy
  end



private

  def downcase_email
    self.email.downcase!
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

end
