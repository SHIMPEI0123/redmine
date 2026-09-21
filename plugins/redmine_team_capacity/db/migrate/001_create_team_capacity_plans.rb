class CreateTeamCapacityPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :team_capacity_plans do |t|
      t.references :user, null: false
      t.references :project, null: false
      t.date :week_start, null: false
      t.decimal :planned_hours, precision: 7, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :team_capacity_plans, [:user_id, :project_id, :week_start],
              unique: true, name: 'idx_team_capacity_weekly_unique'
  end
end
