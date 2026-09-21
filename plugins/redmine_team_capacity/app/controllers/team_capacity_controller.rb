require 'bigdecimal'
require_relative '../../lib/team_capacity/weekly_hours'

class TeamCapacityController < ApplicationController
  before_action :require_login
  before_action :only_administrator

  def index
    @week_start = parse_week(params[:week])
    @users = User.active.order(:lastname, :firstname).to_a
    @projects = Project.active.order(:name).to_a

    plans = TeamCapacityPlan.where(week_start: @week_start).to_a
    planned = plans.index_by { |p| [p.user_id, p.project_id] }
    actual = TimeEntry.where(spent_on: @week_start..(@week_start + 6))
                      .group(:user_id, :project_id).sum(:hours)
    users_by_id = @users.index_by(&:id)
    projects_by_id = @projects.index_by(&:id)
    all_keys = (planned.keys + actual.keys).uniq.sort
    @rows = all_keys.filter_map do |user_id, project_id|
      user = users_by_id[user_id]
      project = projects_by_id[project_id]
      next unless user && project
      hours = TeamCapacity::WeeklyHours.aggregate(planned[[user_id, project_id]]&.planned_hours || 0,
                                                  actual[[user_id, project_id]] || 0)
      { user: user, project: project }.merge(hours)
    end
    @weekly_total = @rows.group_by { |r| r[:user].id }.transform_values do |rows|
      TeamCapacity::WeeklyHours.aggregate(rows.sum { |r| r[:planned] },
                                          rows.sum { |r| r[:actual] })
    end
  end

  def save_plan
    week_start = parse_week(params[:week_start])
    user = User.active.find(params.require(:user_id))
    project = Project.active.find(params.require(:project_id))
    hours = BigDecimal(params.require(:planned_hours).to_s)
    plan = TeamCapacityPlan.find_or_initialize_by(user: user, project: project, week_start: week_start)
    plan.update!(planned_hours: hours)
    flash[:notice] = '予定工数を保存しました。'
    redirect_to team_capacity_path(week: week_start.iso8601)
  rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    flash[:error] = "予定工数を保存できませんでした: #{e.message}"
    redirect_to team_capacity_path
  end

  private

  def only_administrator
    render_403 unless User.current.admin?
  end

  def parse_week(value)
    return Date.current.beginning_of_week(:monday) if value.blank?
    Date.iso8601(value.to_s).beginning_of_week(:monday)
  rescue ArgumentError
    Date.current.beginning_of_week(:monday)
  end
end
