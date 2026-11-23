# rvl-tools

![Lua](https://img.shields.io/badge/Lua-2C2D72?style=flat&logo=lua&logoColor=white)
![Version](https://img.shields.io/badge/version-v118-white?style=flat)
![Platform](https://img.shields.io/badge/platform-Delta%20%2F%20Mobile-black?style=flat)

RIVALS 向けオールインワンスクリプト。モジュール分割された本体を、高速ローダーが並列取得して単一チャンクとして実行する。

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/0rnx4/Silent/main/main.lua"))()
```

## 機能

**照準**
- サイレントエイム（フック方式、効かない環境では予備のカメラスナップが自動で働く）
- 予測：速度スムージング＋加速度項、ping 補正（EMA＋急変スナップ）
- エイムアシスト（部位・優先度・スティッキー・適応スムージング）
- トリガーボット / オートファイア

**ESP**
- ボックス（射影ベース）、チャムス、名前・武器・HP・距離ラベル
- チーム判定（Team / TeamColor / スポーンクラスタの3段判定、FFA対応）

**戦闘**
- ヒットボックス拡大、武器 MOD（反動・拡散・連射ほか）、自動リロード

**移動**
- 飛行、速度・ジャンプ力変更、壁抜け、無限ジャンプ、バニーホップ
- 自動ストレイフ（常時 / 発射中 / 空中、RenderStep 最終優先で駆動）
- 落下防止（奈落レスキュー）

**その他**
- FPS ブースト（ストリーミング追随）、フルブライト、カメラ FOV
- ヒット / キルサウンド（音量・カスタム ID）、クロスヘア編集、エモート再生
- プロファイル 1〜3（自動保存）、セーフモード（連続失敗時にフックを自動回避）
- 日本語 GUI（モノクロ、タッチ完全対応、依存パネルで子設定を出し分け）

## 構成

| ファイル | 役割 |
|---|---|
| `main.lua` | ローダー：並列取得・リトライ・CDN フォールバック・完全性チェック |
| `modules/00_core.lua` | 基盤：設定、予測、世代管理、ビーコン |
| `modules/01_teams.lua` | チーム判定・スポーン記録 |
| `modules/02_targeting.lua` | ターゲット選択 |
| `modules/03_hooks.lua` | サイレント用フック |
| `modules/04_mainloop.lua` | メインループ：照準・発射・ストレイフ・スナップ予備 |
| `modules/05_esp.lua` | ESP 描画 |
| `modules/06_systems.lua` | 戦闘・移動・FPS 等のシステム群 |
| `modules/07_gui_lib.lua` | GUI ライブラリ |
| `modules/08_gui_main.lua` | GUI 本体 |
| `modules/09_boot.lua` | 起動・監視 |

モジュールは連結すると単一ファイル版とバイト単位で同一になる。片方が更新されれば、もう片方も同期される。

## 動作環境

- HttpGet / loadstring / ファイル IO に対応した executor
- 設定は `rvl_tools_v3.json` に自動保存される
