require_relative '../lib/team_capacity/weekly_hours'

def check(label, expected, actual)
  raise "#{label}: expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
  puts "PASS #{label}"
end

result = TeamCapacity::WeeklyHours.aggregate(30, 26.5)
check('planned', 30.0, result[:planned])
check('actual', 26.5, result[:actual])
check('difference', -3.5, result[:difference])
check('allocation', 80.0, result[:allocation_pct])
check('empty', 0.0, TeamCapacity::WeeklyHours.aggregate(0, 0)[:allocation_pct])
begin
  TeamCapacity::WeeklyHours.aggregate(-1, 0)
  raise 'negative hours must raise'
rescue ArgumentError
  puts 'PASS rejects-negative'
end
