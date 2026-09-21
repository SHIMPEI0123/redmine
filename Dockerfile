# 学習時点のRedmine 6.1系。運用時はイメージdigest固定・脆弱性確認を実施。
FROM redmine:6.1.4
COPY plugins/redmine_team_capacity /usr/src/redmine/plugins/redmine_team_capacity
