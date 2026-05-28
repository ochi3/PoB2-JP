# PoB2-JP 日本語化パッチ

Path of Building Community (PoE2版) を日本語表示化するためのパッチです。  
PoB 本体は含まれていません。事前に公式版 PoB2 を用意してください。

現在は PoE2 版ベースで作成していますが、一応 PoE1 の PoB でも動作します。

---

# 導入方法

1. 公式の [PathOfBuildingCommunity-PoE2-Portable](https://github.com/PathOfBuildingCommunity/PathOfBuilding-PoE2/releases) をダウンロードします。

2. この[PoB2-JP](https://github.com/ochi3/PoB2-JP/releases/tag/poe2)をダウンロードします。

3. この zip に入っている `PoB2-JP` フォルダを、
   PoB 本体のフォルダ内にそのまま入れます。

例:

```text
PathOfBuildingCommunity-PoE2-Portable ←PoB公式からDLして解凍した奴
├─ Path of Building.exe
├─ Data
├─ Modules
├─ PoB2-JP ←ここでDLして解凍した奴
```

---

# フォルダ構成

```text
PathOfBuildingCommunity-PoE2-Portable
├─ Assets
├─ Classes
├─ Data
├─ lua
├─ Modules
├─ PoB2-JP ←コイツ
│  ├─ PoB2-JP.exe
│  ├─ PoB2-JP-UIOnly.exe
│  ├─ PoB2-JP-Reset.exe
│  └─ (翻訳データなど)
├─ SimpleGraphic
├─ TreeData
├─ Path of Building.exe
```


4. `PoB2-JP\PoB2-JP.exe` を起動します。

---

# 各ファイルの説明

## PoB2-JP.exe

まだ装備やパッシブの調整を行っていません。
しばらく作業はないのでUI版の使用をおすすめします。

- UI を日本語化
- スキル
- アイテム
- パッシブ
- Mod
- 各種ゲームデータ

などを含め、日本語化して PoB2 を起動します。

---

## PoB2-JP-UIOnly.exe

UI と設定項目のみを日本語化します。
UIのみのはずですが、一部変換されます。ﾄﾎﾎ

- UI だけ日本語化したい方に

---

## PoB2-JP-Reset.exe

PoB2-JP が変更したファイルを元に戻します。

以下の場合に使用してください。

- 英語表示へ戻したい
- 起動がおかしくなった
- アップデート前に戻したい

---

# バックアップについて

変更前のファイルは自動でバックアップされます。

```text
ファイル名.pob2jp.bak
```

という名前で保存されます。

---

# 注意事項

- 日本語化・復元を行う前に PoB2 を完全に終了してください。
- PoB のアップデート後は再度パッチを適用してください。
- 不具合が出た場合は `PoB2-JP-Reset.exe` で元に戻してください。
- このパッチは「表示の日本語化」が目的です。
- 一部翻訳されない箇所や、英語のまま残る部分があります。
"# PoB2-JP" 
