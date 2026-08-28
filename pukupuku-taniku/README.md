# ぷくぷく多肉

Godot 4.7 / GDScript / Compatibility renderer の縦画面3Dゲームです。

- エディタ: `project.godot` をGodot 4.xで開く
- 実行: F6/F5
- Web書き出し: `godot --headless --path . --export-release Web index.html`
- 操作: 育っている多肉を直接タップして収穫

多肉は葉メッシュをGDScriptでプロシージャル生成し、品種データは `data/species.json` に分離しています。記録は `user://records.json` に保存されます。
