# send-slack-region.el - Slack Region Sender for Emacs

Emacs で範囲選択（リージョン）したテキストを、コマンドライン経由で Slack の指定チャンネルに送信するツールです。

- `send-slack`: Slack API (`chat.postMessage`) を利用して標準入力のテキストを投稿するシェルスクリプト
- `send-slack-region.el`: Emacs 上で選択したテキストを `send-slack` に渡すラッパー

## 特徴
- チャンネル名と ID のマッピングを Emacs 側で管理
- 一度設定した送信先チャンネルを記憶
- 必要に応じて送信先を切り替え可能
- Keychain（macOS）または環境変数から Slack API トークンを取得

## 前提条件

- Slack API トークンを取得済みであること
  - `chat:write` 権限が必要
- `curl` および `jq` コマンドがインストールされていること
- Emacs で `.el` ファイルをロードできる環境

## インストール

1. レポジトリをクローンします。

```bash
git clone https://github.com/taichi-e/send-slack-region.el.git
cd  send-slack-region.el
```
2. send-slack に実行権限を付与します。
```bash
chmod +x send-slack
send-slack-region.el を Emacs のロードパスに追加し、初期化ファイルにロード設定を追記します。
```
3. `send-slack-region.el` を Emacs のロードパスに追加し、初期化ファイルにロード設定を追記します。
```elisp
(add-to-list 'load-path "/path/to/slack-region-poster")
(require 'send-slack-region)
```
## 設定
### Slack API トークンの設定
環境変数で設定
```bash
export SLACK_TOKEN="xoxb-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxxxxxxxx"
```
### macOS Keychain を利用
send-slack 内で参照されるサービス名・アカウント名に合わせて登録します。
```bash

security add-generic-password -s slack-user-token -a slack-status -w "xoxb-xxxxxxxxxx-..."
```
### チャンネル一覧の設定
send-slack-region.el 内の my/slack-channel-alist にチャンネル名と ID を設定します。

```elisp
(defcustom my/slack-channel-alist
  '(("transix-chat"  . "CC60UMESX")
    ("transix-log1"  . "CBHGUB8F3")
    ("random"        . "C2222222222"))
  "Alist of Slack channels: (NAME . CHANNEL-ID)."
  :type '(alist :key-type string :value-type string))
```
## 使い方
1. Emacs でテキストを選択します（通常のリージョンや Evil の Visual 選択など）。
2. C-c s s で現在設定されているチャンネルへ送信します。
3. C-c s c で送信先チャンネルを切り替えられます。
4. 一度だけ別チャンネルに送りたい場合は C-u C-c s s でその場で選択できます。

## ライセンス
MIT License
