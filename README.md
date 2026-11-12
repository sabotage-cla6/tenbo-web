# tenbo-web

麻雀牌を使ってリアルに対局するとき、点棒のやり取りの代わりに使う点数管理アプリ「天棒」のWeb版です。

## 開発環境

Flutter Webで開発しています。認証にはFirebase Authenticationを使用します。

## Firebase環境別設定

staging用・production用のFirebase Webアプリ設定と環境フラグをJSONファイルで管理します。

1. config/staging.example.json を config/staging.json にコピーします。
2. Firebase Consoleのstagingプロジェクトに登録したWebアプリの値を設定します。
3. config/production.example.json を config/production.json にコピーし、本番Firebaseプロジェクトの値を設定します。
4. 実際の設定ファイル（config/staging.json / config/production.json）はGit管理対象外です。

Firebase WebのAPIキー等はクライアントアプリ用の公開設定値です。秘密鍵やサービスアカウントキーなどの秘密情報は絶対に設定ファイルへ入れないでください。Firestore等のデータ保護はFirebase Security Rulesで行います。

### 設定項目

| キー | 説明 |
|---|---|
| APP_ENV | staging または production |
| SEND_EMAIL_VERIFICATION | アカウント作成時に確認メールを送るか |
| FIREBASE_API_KEY | Firebase WebアプリのAPIキー |
| FIREBASE_APP_ID | Firebase WebアプリのApp ID |
| FIREBASE_MESSAGING_SENDER_ID | FirebaseプロジェクトのSender ID |
| FIREBASE_PROJECT_ID | 接続先FirebaseプロジェクトID |
| FIREBASE_AUTH_DOMAIN | Firebase Authドメイン（省略可） |

stagingでは SEND_EMAIL_VERIFICATION=false、productionでは true にします。この設定は確認メールの送信を切り替えるもので、未確認メールアドレスでのログインを禁止する機能ではありません。

### ローカル起動

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define-from-file=config/staging.json
```

### ビルド・デプロイ

リポジトリのルートで次のコマンドを実行します。

```bash
# staging環境（tenbo-staging）へデプロイ
bash scripts/deploy-staging.sh

# production環境へデプロイ
bash scripts/deploy-production.sh
```

スクリプトは設定ファイルの環境名・必須項目・FirebaseプロジェクトIDを検証してから、Flutter Webをreleaseビルドし、HostingとFirestore Security Rulesを指定プロジェクトへデプロイします。stagingスクリプトは tenbo-staging 以外へのデプロイを拒否し、productionスクリプトはstagingプロジェクトへのデプロイを拒否します。

必要なコマンドはFlutter SDK、Firebase CLI、Python 3です。Firebase CLIには事前に firebase login しておいてください。

## 現在の実装

- ログイン画面
- ログイン後のトップページ（卓の作成・参加、成績、アカウントのメニュー）
- サインアップ画面
- プレイヤー名・メールアドレス・パスワードの入力チェック
- Firebase Authenticationのメールアドレス/パスワード登録
- Firebase Authenticationのメールアドレス/パスワードログイン
- 認証状態に応じたログイン画面・トップページの切り替え
- トップページからのログアウト
- Firebase Authプロフィールへのプレイヤー名保存
- Firestoreへの卓情報登録
- 卓作成後の対局準備ロビー表示（卓情報・ルール・座席の表示）
- 卓IDによる参加可能な卓の検索と、既存ロビーへの遷移
- 起家・場決め（対局者の座順をランダムに決定）
- 起家決め（現在の座順を維持して東の起家を選択）
- 対局中トップ画面（卓を囲むプレイヤーの点数・立直・焼き鳥、局情報、操作メニューの表示）
- 対局中トップ画面（卓上のプレイヤー配置・初期点数・局情報・操作メニュー）
- 環境設定による確認メール送信の切り替え
- 登録完了時のメールアドレスのマスキング表示
- Firebase設定がない場合は登録を行わず、設定案内を表示

## 補足

- Firebase Authenticationのコンソールでメール/パスワード認証を有効にする必要があります。
- 確認メールのテンプレートや送信元などはFirebase Consoleで設定できます。
- 座席の手動変更と起家・場決め、起家決めは待機ロビーで対応済みです。対局中トップ画面は表示のみ対応しています。リーチ・和了・点棒移動・流局・次局進行・精算の処理、対局状態のFirestore保存、成績表示、アカウント管理の実処理、パスワード再設定、Firestoreへのプレイヤー情報保存は未実装です。
- 卓への参加は卓IDで行います。卓名はロビーでの表示に使用します。
