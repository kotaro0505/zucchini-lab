# ぷくぷく多肉

Godot 4.7 / GDScript / Compatibility renderer の縦画面3Dゲームです。

- エディタ: `project.godot` をGodot 4.xで開く
- 実行: F6/F5
- Web書き出し: `godot --headless --path . --export-release Web index.html`
- 操作: 育っている多肉を直接タップして収穫

多肉は楕円断面を持つ肉厚葉メッシュをGDScriptでプロシージャル生成し、11品種の形状データは `data/species-v2.json` に分離しています。日本語UIにはSIL OFLのZen Maru Gothicを同梱し、記録は `user://records.json` に保存されます。

造形確認用に `succulent_test.tscn`、11品種比較用に `species_gallery.tscn`、基本ロジック確認用に `logic_smoke.tscn` を用意しています。これらは通常プレイ画面には表示されません。
