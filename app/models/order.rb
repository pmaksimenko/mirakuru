class Order < ActiveRecord::Base

  attr_accessor :is_new_order, :is_new_stage

  belongs_to :customer
  belongs_to :performance
  belongs_to :stage
  belongs_to :order_source

  has_many :orders_characters
  accepts_nested_attributes_for :orders_characters, allow_destroy: true

  has_many :characters, through: :orders_characters

  has_many :positions, dependent: :destroy

  enum source: [:partner, :site, :commercial]

  validates :child_name, :child_birthday, :performance_date, :performance_time,
            :guests_age_from, :guests_age_to, :additional_expense, presence: true

  belongs_to :contact

  enum status: [:fresh, :assigned, :prepared, :done, :canceled_by_customer, :canceled_by_owner, :failed]

  def sent_invitations_to_all
    invitations = positions.map(&:invitations).flatten
    invitations.select do |i|
      if i.status == 'empty'
        i.fire_events!(:sent_invitation)
      elsif i.status == 'sent'
        i.fire_events!(:sent_again)
      end
    end
  end

end
