# ぷくぷく多肉

Godot 4.7 / GDScript / Compatibility renderer の縦画面3Dゲームです。

- エディタ: `project.godot` をGodot 4.xで開く
- 実行: F6/F5
- Web書き出し: `godot --headless --path . --export-release Web index.html`
- 操作: 育っている多肉を直接タップして収穫

現在の生育試作はラウイ1株に限定し、`assets/models/laui_leaf_final_candidate.glb` の New／Young／Mid／Mature モーフを各葉ノードへ独立適用します。中心へ新葉を追加し、葉齢に応じて外側へ移動・展開します。株ルートのscaleによる拡大は行いません。日本語UIにはSIL OFLのZen Maru Gothicを同梱し、記録は `user://records.json` に保存されます。

造形確認用に `succulent_test.tscn`、11品種比較用に `species_gallery.tscn`、基本ロジック確認用に `logic_smoke.tscn` を用意しています。これらは通常プレイ画面には表示されません。

ジュレ危険度や事前警告は表示せず、GETまたはジュレで1株が消えるたび、短い間を置いて空き位置へ小苗が1株だけ補充されます。ラウイ／ゴールデンラウイ／アフィニスの比較には `reference_trio.tscn` を使用できます。
