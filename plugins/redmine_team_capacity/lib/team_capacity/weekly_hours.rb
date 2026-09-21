# RedmineやDBに依存しない集計関数。CodeBuildで純粋な単体テストを実行可能。
module TeamCapacity
  module WeeklyHours
    CAPACITY_PER_WEEK = 37.5

    def self.aggregate(planned, actual)
      planned = planned.to_f
      actual = actual.to_f
      raise ArgumentError, 'hours must be nonnegative' if planned.negative? || actual.negative?

      {
        planned: planned.round(2),
        actual: actual.round(2),
        difference: (actual - planned).round(2),
        allocation_pct: (planned / CAPACITY_PER_WEEK * 100).round(1)
      }
    end
  end
end
