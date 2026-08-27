# zucchini-lab

スマートフォンで遊べる試作Webゲームを、ゲームごとの独立フォルダで安全に管理・公開するゲーム工場です。

## 公開中のゲーム

| フォルダ | ゲーム | 公開URL |
| --- | --- | --- |
| [`pon-rush/`](./pon-rush/) | ポン！ラッシュ | <https://kotaro0505.github.io/zucchini-lab/pon-rush/> |

`pon-rush/` の既存URLは維持します。今後のゲームも、リポジトリ直下に専用フォルダを追加して公開します。

## 工場の構成

```text
zucchini-lab/
├─ AGENTS.md       # Codex向けの分離・自動公開ルール
├─ publish.ps1     # ゲーム単位の安全なcommit・push・Pages確認
├─ new-game.ps1    # 上書きしない新規ゲームフォルダ作成
├─ pon-rush/       # ポン！ラッシュ専用。中身を他ゲームと共有しない
│  └─ index.html
└─ <new-game>/     # 新しいゲームごとの専用フォルダ
   └─ index.html
```

## 新しいゲームを作る

新規Codexチャットは担当ゲーム未設定で開始します。最初のゲーム制作依頼からゲーム名と未使用slugを決め、そのチャット内だけで担当ゲームとして保持します。担当ゲームをリポジトリ内のファイルや他チャットへ共有しません。

```powershell
./new-game.ps1 -Slug "pinball" -Title "クラシック・ピンボール"
```

既存フォルダや予約名には上書きしません。作成後は、そのフォルダ内だけでゲームを実装します。

## ゲームを公開する

```powershell
./publish.ps1 -Game "pinball" -Message "Add pinball game" -Paths @("pinball/index.html")
```

スクリプトは指定ゲームのフォルダ外をstageせず、`main` へのpush、GitHub Pagesビルド待機、ゲーム公開URLのHTTP 200と内容一致確認まで行います。

工場設定だけを変更する場合は、既存ゲームを検証対象として明示します。

```powershell
./publish.ps1 -Factory -VerifyGame "pon-rush" -Message "Update factory settings" -Paths @("AGENTS.md", "README.md")
```
