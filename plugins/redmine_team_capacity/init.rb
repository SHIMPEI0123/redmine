Redmine::Plugin.register :redmine_team_capacity do
  name 'Team capacity / weekly hours'
  author '川原新平'
  description '担当者×案件の週次予定工数とRedmine作業時間を照合する学習用プラグイン'
  version '0.1.0'
  requires_redmine version_or_higher: '6.1.0'
  menu :application_menu, :team_capacity,
       { controller: 'team_capacity', action: 'index' },
       caption: '課の工数', if: Proc.new { User.current.logged? && User.current.admin? }
end
