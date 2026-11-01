# tenbo-web

麻雀の対局記録・成績管理アプリ「天棒」のWeb版です。

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

- サインアップ画面
- プレイヤー名・メールアドレス・パスワードの入力チェック
- Firebase Authenticationのメールアドレス/パスワード登録
- Firebase Authプロフィールへのプレイヤー名保存
- 登録後のメールアドレス確認メール送信
- 登録完了時のメールアドレスのマスキング表示
- Firebase設定がない場合は登録を行わず、設定案内を表示

## 補足

- Firebase Authenticationのコンソールでメール/パスワード認証を有効にする必要があります。
- 確認メールのテンプレートや送信元などはFirebase Consoleで設定できます。
- 現時点ではログイン、ログアウト、パスワード再設定、Firestoreへのプレイヤー情報保存は未実装です。
