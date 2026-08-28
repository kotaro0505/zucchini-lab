# 多肉サファリ

メキシコ原生地風の荒野をジープで駆け、多肉を集めて岩を避けるスマートフォン縦画面向け短時間ゲームです。

## 起動方法

ES Modules を使用するため、`taniku-safari/` をHTTPサーバーで配信してください。

```powershell
cd taniku-safari
python -m http.server 8080
```

ブラウザで `http://localhost:8080/` を開きます。

## 現在の仕様

- 左右ドラッグ追従、透視投影スポーン、岩衝突ゲームオーバー
- 時間経過で速度と難易度が上昇
- 通常4種、Rare、Special、BIGラウイの全7種
- レア個体をローカル保存するCollection Box
- 多層の山・荒野・路面・前景、タイヤ跡、砂埃、車体の揺れと傾き
- Web Audio による取得・レア・BIG・クラッシュ効果音
- 5レーン相当のウェーブ配置、速度連動パララックス、左右2本の動的タイヤ痕
- `ScoreManager` と `LeaderboardService` を分離したローカルランキング

## 改善候補

`src/data.js` へ品種追加が可能です。iOS版では `LocalLeaderboardService` を同じインターフェースの `GameCenterLeaderboardService` に差し替え、WORLD HIGH SCORE、MAX GET、MAX SPEEDを送信できます。今後はデイリーミッション、図鑑詳細、個体差、コンボ、天候・時間帯、正式BGM、端末振動、Capacitorラッパーを追加できます。
