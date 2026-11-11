# tenbo-web

麻雀牌を使ってリアルに対局するとき、点棒のやり取りの代わりに使う点数管理アプリ「天棒」のWeb版です。

## 開発環境

Flutter Webで開発しています。認証にはFirebase Authenticationを使用します。

## Firebaseの初期設定

1. Firebase Consoleでプロジェクトを作成します。
2. プロジェクトにWebアプリを追加し、Webアプリの設定値を確認します。
3. Authenticationの「Sign-in method」で「メール/パスワード」を有効にします。
4. 承認済みドメインに、利用する開発・公開ドメインを登録します。

Firebase Webアプリの設定値を指定して起動します（値はFirebase ConsoleのWebアプリ設定から取得）。

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_APP_ID=your-app-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
```

Firebase Webの設定値はクライアントアプリで利用する公開設定値であり、データベースへのアクセス制御はFirebase Security Rules等で別途設定してください。パスワードや秘密鍵をソースコードやクライアント側に埋め込まないでください。

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
- 卓作成時のオーナー参加情報登録
- 卓参加時のFirebase UID単位の参加情報登録（同一アカウントの重複登録防止）
- Firestoreの参加者一覧を購読し、ロビー画面へリアルタイム反映（対局人数を超える待機メンバーにも対応）
- ロビーで東・南・西・北の座席をクリックして自分を対局者に割り当て（既存プレイヤーとは交代）
- 座席割り当てをFirestoreトランザクションで更新し、複数端末間でリアルタイム同期
- 登録後のメールアドレス確認メール送信
- 登録完了時のメールアドレスのマスキング表示
- Firebase設定がない場合は登録を行わず、設定案内を表示

## 補足

- Firebase Authenticationのコンソールでメール/パスワード認証を有効にする必要があります。
- 確認メールのテンプレートや送信元などはFirebase Consoleで設定できます。
- 座席の手動変更は待機ロビーで対応済みです。起家決め、対局開始、対局中の点数管理、成績表示、アカウント管理の実処理、パスワード再設定、Firestoreへのプレイヤー情報保存は未実装です。
- 卓への参加は卓IDで行います。卓名はロビーでの表示に使用します。
