# 試験項目（学習用）
作成者：川原新平

|ID|区分|手順|期待結果|
|---|---|---|---|
|T01|静的|Ruby -c init/controller|構文OK|
|T02|単体|weekly_hours_test.rb|PASS 6件、差分/配賦率/負数拒否|
|T03|ローカル|docker compose up --build -d|Redmineログイン画面表示|
|T04|権限|一般ユーザーで/team_capacityにアクセス|403|
|T05|管理画面|管理者で「課の工数」にアクセス|週一覧を表示|
|T06|予定登録|月曜、担当者、案件、30hを登録|30hとして表示|
|T07|上書き|同一キーを25hで保存|行重複せず25hになる|
|T08|実績|Redmine作業時間26.5hを対象週に入力|実績26.5h、差分1.5h（予定25hの場合）|
|T09|週境界|日曜と翌月曜の実績を登録|別の週として集計|
|T10|配賦率|予定30h入力|80.0% (30/37.5)|
|T11|ソース|git add→commit→push origin main|GitHubに変更が存在|
|T12|CI|CodePipeline Build|テスト/イメージbuild/push成功|
|T13|CD|CodeDeploy ValidateService|localhost:3000/login GET成功|
|T14|反映|画面タイトルを変更してpush|EC2の画面タイトル更新|
|T15|CodeCommit|git push aws main|CodeCommitのみ変更、GitHubパイプラインは起動しない|
|T16|永続性|docker compose down/up（-vを使わない）|工数/作業時間/添付が保持|
|T17|再デプロイ|無変更ソースの再実行|同じイメージURIを再利用（既存immutable tagへのpushはスキップ）|
|T18|障害|不正なプラグイン構文をpush|Build失敗、Deployは実行されない|

**留意事項**: PostgreSQLをEC2ローカルvolumeに保持する単一構成。EC2消失・DBマイグレーションを伴うロールバック・認可の網羅試験は未実装。実業務データは使わない。
