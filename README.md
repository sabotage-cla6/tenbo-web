# tenbo-web

麻雀の対局記録・成績管理アプリ「天棒」のWeb版です。

## 開発環境

Flutter Webで開発しています。

## 起動方法

開発コンテナ内で以下を実行してください。

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## 現在の実装

- サインアップ画面
- プレイヤー名・メールアドレス・パスワードの入力チェック
- 利用規約・プライバシーポリシーの仮ダイアログ

※ 現段階ではFirebase Authenticationに未接続のため、アカウント登録は行われません。
