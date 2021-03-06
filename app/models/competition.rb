class Competition < ActiveRecord::Base
	has_many :entries, dependent: :destroy
	has_many :robots, through: :entries
	has_and_belongs_to_many :categories
	belongs_to :user
	has_one :winner, class_name: "Win", dependent: :destroy

	validates :name, presence: true, length: { minimum: 5, maximum: 50 }
	validates :description, presence: true, length: { minimum: 5, maximum: 2500 }
	validates :categories, presence: true

	include Viewable

	extend FriendlyId
	friendly_id :name, use: :history

	def should_generate_new_friendly_id?
		slug.blank? || name_changed?
	end

	before_create :open_competition

	def self.most_entered
		Competition.all.sort_by { |competition| competition.entries.count }.reverse
	end

	def close
		winning_entry = self.entries.sort_by(&:votes).reverse.first
		winning_robot = Robot.find(winning_entry.robot_id)
		winner_user = winning_robot.user

		self.winner = winning_robot.wins.build(robot_id: self.id, user_id: winner_user.id, votes: winning_entry.votes)
		self.update_attribute(:open, false)
	end

	private
		def open_competition
			self.open = true
		end
end