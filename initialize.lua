-- initialize.lua
-- このファイルの責務：
-- - グローバルテーブルの初期化
local Black_box_debug = require("black_box_debug")
local Blackbox = require("blackbox")
local Initialize = {}

function Initialize.global_tables()
    global.is_counting = global.is_counting or {}
    global.material_count = global.material_count or {}
    global.last_item_count = global.last_item_count or {}
    global.countdowns = global.countdowns or {}
    global.black_boxes = global.black_boxes or {}
    global.item_count = global.item_count or {}
    global.player_positions = global.player_positions or {"before"}
    global.blackBoxRecipeList = global.blackBoxRecipeList or {}
    global.blackBoxRelatedEntities = global.blackBoxRelatedEntities or {} --ブラックボックスに関連するエンティティを保存。意図せず解体られないように使用
    -- #TODO プレイヤーがどのブラックボックでどのレシピを選択したかを判断できるようにする。現状一つのレイシしか選択できないため、
    global.selected_recipe = global.selected_recipe or {}
    global.debug_print_counter = 0
    global.makeTime = global.makeTime or {}
    global.last_touched_entity = {} --プレイヤーが最後に触れたエンティティ

    for _, player in pairs(game.players) do
        local player_index = player.index
        -- 各プレイヤーのブラックボックス情報を初期化
        global.black_boxes[player_index] = {
            surface = {  -- テレポート先のサーフェス情報
                return_positions = nil,
                return_surfaces = nil,
            },
            in_black_box = nil,    --テレポートして、中に入っているブラックボックスのエンティティ
            black_Box_entities = {  -- black_Box_entityを複数持つためのリスト
            -- 各エンティティはテーブルとして定義
                {
                    black_box_number = nil,                   --ユニークナンバー
                    black_Box_entity = nil,
                    setRecipe = nil,                --設定しているレシピ
                    electricityConsumption = nil,   --使用電力
                    assemblyPartsBox = nil,     --製造用パーツを入れるボックス
                    black_boxes_surface = nil,      --テレポート先のサーフェス
                    iriguti = {  -- 入口チェスト情報
                        beforeBox = nil,  -- テレポート前チェスト情報
                        afterBox = nil,   -- テレポート後チェスト情報
                        beforeRamp = nil,  -- テレポート前ランプ情報（テレポートスイッチ）
                        afterRamp = nil,   -- テレポート後ランプ情報（テレポートスイッチ）
                    },
                    deguti = {  -- 出口チェスト情報
                        beforeBox = nil,  -- テレポート前チェスト情報
                        afterBox = nil,   -- テレポート後チェスト情報
                        beforeRamp = nil,  -- テレポート前ランプ情報（テレポートスイッチ）
                        afterRamp = nil,   -- テレポート後ランプ情報（テレポートスイッチ）
                    },
                    specialCountBox = nil,
                },
            -- 必要に応じてさらにエンティティを追加
            },
        }
        global.item_count[player_index] = {
            measurementTime = nil,
            iriguti = {  -- 入口チェスト情報
                beforeBoxCount = nil,  -- テレポート前カウント用
                afterBoxCount = nil,   -- テレポート後カウント用
            },
            deguti = {  -- 出口チェスト情報
                beforeBoxCount = nil,  -- テレポート前カウント用
                afterBoxCount = nil,   -- テレポート後カウント用
            },
        }
    end
    -- デバッグメッセージを全プレイヤーのコンソールに出力
    for _, player in pairs(game.players) do
        player.print("Initialize.global_tables() が呼び出されました。")
    end

    Blackbox.BlackboxInit()
    Black_box_debug.Init()
end

return Initialize
