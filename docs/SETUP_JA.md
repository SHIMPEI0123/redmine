# 構築・改修手順（Mac / Windows PowerShell）
作成者：川原新平

## 0. 役割
`git add` = 差分をステージ、`git commit` = ローカル履歴確定、`git push` = リモートに転送。GitHub/CodeCommitは双方ともGitサーバー。CodePipelineはステージ制御、CodeBuildはテスト・Docker作成、ECRは完成イメージ、CodeDeployはEC2側の更新実行。

## 1. 準備
Git、Docker Desktop、AWS CLI v2、VS Code、AWS Session Manager pluginをインストール。AWSは権限付与済みの一時認証/SSOを使用し、`aws sts get-caller-identity` で検証。作業リージョンは `us-east-1`（既存のAWS演習に合わせた値。変更可能）。AWS操作用アクセスキーを `.env` やGitに格納しない。

## 2. ローカルで起動
Macターミナル（Windows PowerShellの場合は `cp` → `Copy-Item`）：

```bash
cp .env.example .env
```

`.env`内の2値を**別々の強いランダム値**に編集。Mac/WSLなら `openssl rand -hex 32` を2回使う。`REPLACE_...` のまま起動しない。

```bash
docker compose up --build -d
docker compose ps
docker compose logs --tail=100 redmine
```

ブラウザ `http://localhost:3000`。Redmine初回の管理者資格情報は利用イメージの初期案内に従って直ちに変更。ユーザー作成、案件作成、作業時間の登録を行った後、管理者で「課の工数」を開いて週次予定を保存。一般ユーザーではアクセスできないことを確認。

終了: `docker compose down`（`-v` は付けない。DBが消える）。

## 3. GitHub に登録
GitHub画面でPrivateリポジトリ `redmine-team-cicd` を**初期README無し**で作成。以下の `YOUR_GITHUB_USER` を置換。

```bash
git init
git branch -M main
git add .
git status
git diff --cached --name-only
git commit -m "feat: redmine team capacity lab"
git remote add origin https://github.com/YOUR_GITHUB_USER/redmine-team-cicd.git
git push -u origin main
```

`.env`, `*.pem`, `*credentials*.csv` が `git diff --cached --name-only` に無いことを目視で確認。GitHub認証はブラウザ認証、credential manager、または必要範囲のトークンを使用する（通常パスワードpush不可）。

## 4. AWS GitHub Connection
AWS Console → Developer Tools → Connections / CodeConnections → Create connection → GitHub → GitHub Appの認可で**このリポジトリのみ**選択。ステータス `AVAILABLE` を確認してARNを控える。CLI/CFnだけで新規Connectionを作ると `PENDING` のままになるため、Consoleで認可する。AWS公式: https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html

## 5. CloudFormation
VPC ID と **Internet Gatewayへのデフォルトルートを持つパブリックサブネット** IDを調べる。EC2へローカル3000へのポート転送でアクセスするため、SGのインバウンドはゼロ。既存Redmineや他コンテナへこのテンプレートを流用しない。

Mac/Linux:
```bash
export AWS_REGION=us-east-1
export VPC_ID=vpc-REPLACE
export SUBNET_ID=subnet-REPLACE
export GITHUB_REPO=YOUR_GITHUB_USER/redmine-team-cicd
export CONNECTION_ARN=arn:aws:codeconnections:us-east-1:123456789012:connection/REPLACE
aws cloudformation validate-template --template-body file://cloudformation/lab.yaml --region "$AWS_REGION"
aws cloudformation deploy --stack-name redmine-team-lab \
  --template-file cloudformation/lab.yaml --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides VpcId="$VPC_ID" PublicSubnetId="$SUBNET_ID" \
    GitHubRepo="$GITHUB_REPO" ConnectionArn="$CONNECTION_ARN"
aws cloudformation describe-stacks --stack-name redmine-team-lab --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs' --output table
```
Windows PowerShellでは上の `export` を `$env:AWS_REGION="us-east-1"` のように変更。複数行 `\` はPowerShellで使えないため、`aws cloudformation deploy` を1行で実行（またはバッククォートで継続）。

**重要:** CloudFormationを作成するとGitHub mainの初期pushを検知し、**準備前にパイプラインのデプロイが失敗する場合がある**。初回失敗は6節の準備後「Release change」で再実行。EC2 user-dataが失敗したら `/var/log/cloud-init-output.log` を調査。

## 6. EC2を初期設定（SSM）
CloudFormation Outputs の `InstanceId` を使用。EC2がSSMでオンラインになってからSession Managerのシェルを開く:
```bash
aws ssm start-session --target i-REPLACE --region us-east-1
```
EC2上（Session Managerシェル内）:
```bash
sudo docker compose version
sudo systemctl status codedeploy-agent --no-pager
sudo mkdir -p /etc/redmine-team
sudo sh -c 'umask 077; touch /etc/redmine-team/runtime.env'
sudo vi /etc/redmine-team/runtime.env
```
以下の2行を**それぞれ強いランダム値**へ置換して保存:
```ini
POSTGRES_PASSWORD=REPLACE_WITH_LONG_RANDOM_STRING
REDMINE_SECRET_KEY_BASE=REPLACE_WITH_64_HEX_CHARACTERS
```
`chmod`で保護:
```bash
sudo chown root:root /etc/redmine-team/runtime.env
sudo chmod 600 /etc/redmine-team/runtime.env
sudo systemctl restart codedeploy-agent
```
初期化完了後 CodePipeline → `redmine-team-github` → Release change を実行して3段階 Source/Build/Deployを確認。

### Webアクセス
別ターミナル（Mac/Windows、Session Manager pluginが必要）:
```bash
aws ssm start-session --region us-east-1 --target i-REPLACE \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3000"],"localPortNumber":["3000"]}'
```
PowerShellの場合は`--parameters`のクォートを環境に合わせる。`http://localhost:3000` にアクセス。`curl -I http://localhost:3000/login` はHEADのレスポンスが変わる場合があるため、検証は `curl -f http://localhost:3000/login` のGETを使う。

## 7. CodeCommit を体験する（パイプラインとは独立）
CFnの`CodeCommitCloneUrl`を取得し、`git-remote-codecommit` またはAWS CLIのCredential helperと適切なIAM認証を設定。HTTPSの手動例（認証未設定だと失敗）:
```bash
git remote add aws https://git-codecommit.us-east-1.amazonaws.com/v1/repos/redmine-team-lab
git remote -v
git push aws main
```
GitHub/CodeCommitへの2つのpushは**別操作**。`git push origin main` はGitHubにのみ反映。`git push aws main` はCodeCommitにのみ反映。通常のパイプラインはGitHub変更しか検知しない。

**CodeCommitをSourceに切り替える学習:** CodePipelineの既存SourceをGUIでEditし、CodeCommitの`redmine-team-lab/main`へ変更。GitHub接続アクションと**排他的に切替**し、ビルド/デプロイは同一のものを使用する。CodeCommitソースの変更検知はConsoleでEventBridge設定、または`Release change`手動で試す。同時に別パイプラインを稼働させない。終了後はGitHubに戻す。詳細: https://docs.aws.amazon.com/codepipeline/latest/userguide/triggering.html

## 8. 改修して自動デプロイ
例: `plugins/redmine_team_capacity/app/views/team_capacity/index.html.erb` のタイトルを「課の工数（更新版）」に変更。
```bash
git add plugins/redmine_team_capacity/app/views/team_capacity/index.html.erb
git commit -m "feat: update capacity dashboard title"
git push origin main
```
CodePipelineのSource→Build→Deploy、CodeBuildログのPASS、ECRの短いcommit SHAタグ、CodeDeployのValidateService、SSM転送で画面表示を確認。

## 9. 切り分け
- Source失敗 → ConnectionがAVAILABLEか、対象repo権限、branch `main`、Pipelineロール。
- Build失敗 → CodeBuildログ、Docker privileged、ECR権限、Ruby構文/テスト。
- Deploy失敗 → EC2 SSM/agent、`/var/log/aws/codedeploy-agent/codedeploy-agent.log`、`/opt/codedeploy-agent/deployment-root`、`/etc/redmine-team/runtime.env`、ECR pull権限。
- 起動失敗 → `sudo docker compose --project-name redmine-team -f /opt/redmine-team/compose.prod.yaml ps`（環境変数不足なら`runtime.env`と`image.env`を環境へexport）、`sudo docker logs redmine-team-redmine-1`。
- Docker/CodeDeploy agent未導入 → `/var/log/cloud-init-output.log`。CloudFormation CREATE_COMPLETE はユーザーデータの成功を保証しない。

## 10. 終了・費用・本番との差
課金対象はEC2稼働、EBS、パブリックIPv4、CodeBuild時間、CodePipeline、S3、ECR等。練習が終わればバックアップ要否を確認してCFnを削除する。ECRイメージやS3アーティファクトが残るとスタック削除が失敗しうる。Volume削除/DB消失に注意。本番構成にはALB/HTTPS、DB別配置、バックアップ復元試験、監視、権限分離、プラグイン互換性/移行とロールバックの追加設計が必要。
