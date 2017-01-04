class CharactersGroup < ActiveRecord::Base

  has_one :avatar, as: :cover, class_name: 'Avatar'
  accepts_nested_attributes_for :avatar

  has_many :characters

  validates :name, uniqueness: true

end
