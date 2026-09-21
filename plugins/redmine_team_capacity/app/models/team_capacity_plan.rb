class TeamCapacityPlan < ApplicationRecord
  belongs_to :user
  belongs_to :project
  validates :planned_hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 168 }
  validates :week_start, presence: true
  validate :week_must_start_monday

  private

  def week_must_start_monday
    errors.add(:week_start, 'は月曜日を指定してください') if week_start && week_start.cwday != 1
  end
end
