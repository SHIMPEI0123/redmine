# Redmine 課員週次工数 × GitHub/CodeCommit × AWS CI/CD 演習

作成者：川原新平 / 学習用 / 2026-09-21

## 目標
Mac/Windows → GitHub → CodeConnections → CodePipeline → CodeBuild（静的/単体テスト・Docker build） → ECR → CodeDeploy → EC2（Docker Compose/Redmine + PostgreSQL）。CodeCommitには同じリポジトリを別 remote として push し、Git の保管先を比較します。CodeCommit は標準パイプラインのソースには接続しません（誤って同時デプロイしないため）。

## 成果物
- `Dockerfile`, `compose.yaml`, `.env.example`: ローカル実行
- `plugins/redmine_team_capacity/`: 課員別・案件別・週別予定を追加する自作Redmineプラグイン
- `buildspec.yml`: CIの構文検査/単体テストとDocker build/push
- `appspec.yml`, `deploy/`: EC2 CodeDeployのフックと本番compose
- `cloudformation/lab.yaml`: EC2, IAM, ECR, CodeCommit, CodeBuild, CodeDeploy, CodePipeline, S3
- `docs/SETUP_JA.md`: 初心者向け構築手順、`docs/TEST_JA.md`: 試験項目

## 仕様と制限
- プラグイン画面は管理者のみ。Redmine 標準の「作業時間」を実績として読む。予定は担当者×案件×週の手入力、同一キーは上書き。
- 週は月～日、基準 37.5 h/週、配賦率は予定÷37.5。人ごとの休暇/祝日/単価/権限委任、CSV取込、ドラッグ再配分は未実装。
- 実績は Redmine TimeEntry の spent_on を使用し、実績のない予定も表示。30人想定の学習機能であり、APIや大規模運用の性能は保証しない。
- PostgreSQL はEC2の永続Docker volume。DB/添付の独立バックアップ、TLS、可用性、監視、脆弱性対応は本番用追加設計が必要。
- EC2はパブリックサブネット上で外向き通信し、セキュリティグループにインバウンドを設定しない。Web閲覧はSSMのポート転送でローカル3000に接続する。
- CodeBuild のテストはRuby構文と集計関数の単体テスト。Redmine実DBの統合・画面テストは手動確認。未検証の本番デプロイを前提としない。

## 最短実行
1. `cp .env.example .env` して2値を強いランダム値に変更（Gitに追加しない）。
2. `docker compose up --build -d` → `http://localhost:3000`。初回起動には数分かかる場合あり。
3. Redmine管理者でログイン、案件/ユーザー作成、作業時間記録 → アプリケーションメニュー「課の工数」。
4. `docs/SETUP_JA.md` に従いGitHub、CodeConnections、CFn、SSM/ランタイム秘密情報を準備する。
5. GitHub `main` をpush → 自動CodePipelineを確認。CodeCommitへ別remote push。

## 秘密情報
以前共有されたAWSログイン用CSVなどの認証情報は使わず、zipにも同梱していません。AWS CLIはSSO・一時認証情報を推奨します。`.env`・秘密鍵・CSVをGitHub/CodeCommitへcommitしないでください。
