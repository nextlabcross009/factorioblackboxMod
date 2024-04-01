-- control.lua
-- このファイルの責務：
-- - MODの主要なイベントハンドラーの初期化
-- - ゲームの起動と設定変更時のグローバルテーブルの初期化
local Initialize = require("initialize")
local Events = require("events")
local Gui = require("gui")
local Black_box_debug = require("black_box_debug")

-- 新しいゲームが始まるとき、MODがアップデートされたときに実行される
script.on_init(function()

end)
-- 設定変更時に実行
script.on_configuration_changed(function()

end)

-- 新しいプレイヤーオブジェクトが作成されたとき
script.on_event(defines.events.on_player_created, function(event)

    local player = game.players[event.player_index]
    if not player then
        return
    end
    Initialize.global_tables()
    Black_box_debug.open_debug_custom_gui(player)

    --5秒後にイベント発火
    global.give_items_next_tick = global.give_items_next_tick or {}
    global.give_items_next_tick[event.player_index] = game.tick + (60 * 3)
end)


-- ゲームがロードされるたびに実行されるイベントは、globalテーブルの変更を行わないようにします
script.on_load(function()
    -- ここではglobalテーブルに変更を加えず、必要に応じて関数の参照を復元するなどの処理を行います
    -- 例: グローバルな関数の参照をローカルな変数に割り当てるなど
    -- この例では具体的な処理は不要ですが、必要に応じて追加してください
end)
