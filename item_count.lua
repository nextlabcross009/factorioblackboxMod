-- item_count.lua

local Blackbox = require("blackbox")

local ItemCount = {}

-- # [x] 組み立てきを置いたときにGUIをひらく ###### Thu Mar 21 12:07:16 JST 2024
-- # [ ] テレポート先のアイテムがテレポート後にコピーされているが先のアイテムが変化していないせいで、テレポート前のアイテムを無限に取得できる、こればぐ ###### Thu Mar 21 12:07:40 JST 2024

-- カウントダウンの秒数を設定
local countdown_duration_seconds = 10
-- 計測開始
function ItemCount.start_measurement_time(player_index)
    if not global.measurement_start_tick then
        global.measurement_start_tick = {}
    end
    -- 計測開始時刻を記録
    global.measurement_start_tick[player_index] = game.tick
    game.players[player_index].print("計測を開始しました。")
end

-- 計測終了と経過時間の計算
function ItemCount.end_measurement_time(player_index)
    if not global.measurement_start_tick or not global.measurement_start_tick[player_index] then
        game.players[player_index].print("計測が開始されていません。")
        return
    end
    -- 経過時間を計算 (tickを秒に変換)
    local elapsed_time = (game.tick - global.measurement_start_tick[player_index]) / 60
    -- 経過時間を格納
    if not global.item_count[player_index] then
        global.item_count[player_index] = {}
    end
    global.item_count[player_index].measurementTime = elapsed_time
    game.players[player_index].print("計測終了: " .. tostring(elapsed_time) .. " 秒経過しました。")

    -- 計測開始tickをリセット
    global.measurement_start_tick[player_index] = nil
end

-- カウントダウン開始時にアイテム数を記録する関数
function ItemCount.start_item_countdown(player_index)
    local player = game.players[player_index]

    -- `global.item_count` とそのサブテーブルの存在確認と初期化
    if not global.item_count then global.item_count = {} end
    if not global.item_count[player_index] then global.item_count[player_index] = {} end
    if not global.item_count[player_index].iriguti then global.item_count[player_index].iriguti = {} end
    if not global.item_count[player_index].deguti then global.item_count[player_index].deguti = {} end
    --#TODO ブラックブラックボックスエンティティの指定方法を追加する必要がある
    local black_Box_entities_info = global.black_boxes[player_index].black_Box_entities[1]

    -- 例: カウントボックスと出口ボックスのエンティティを指定
    local countBox_entity = black_Box_entities_info.specialCountBox
    local degutiBox_entity = black_Box_entities_info.deguti.afterBox

    -- カウントボックスのアイテム数を記録
    if countBox_entity and countBox_entity.valid then
        global.item_count[player_index].iriguti.beforeBoxCount = countBox_entity.get_inventory(defines.inventory.chest).get_contents()
    end

    -- 出口ボックスのアイテム数を記録
    if degutiBox_entity and degutiBox_entity.valid then
        global.item_count[player_index].deguti.beforeBoxCount = degutiBox_entity.get_inventory(defines.inventory.chest).get_contents()
    end

    -- カウントダウンを開始
    global.countdowns[player_index] = game.tick + (60 * countdown_duration_seconds)
    player.print("カウントダウンを開始しました。")
end


-- 終了時のアイテム数を取得する関数
local function getItemCountsAtEnd(black_box_info, boxType)
    if black_box_info and black_box_info[boxType] and black_box_info[boxType].afterBox and black_box_info[boxType].afterBox.valid then
        return black_box_info[boxType].afterBox.get_inventory(defines.inventory.chest).get_contents()
    end
    return {}
end

-- アイテム数の差分を計算する関数
local function calculateItemDiffs(startCounts, endCounts)
    local diffs = {}

    -- 開始時のリストをループして差分を計算
    for item, count_at_start in pairs(startCounts) do
        local count_at_end = endCounts[item] or 0
        diffs[item] = count_at_end - count_at_start
    end

    -- 終了時のリストで、開始時には存在しないアイテムを処理
    for item, count_at_end in pairs(endCounts) do
        if startCounts[item] == nil then
            diffs[item] = count_at_end  -- 新規アイテムはその数がそのまま差分に
        end
    end

    return diffs
end



-- カウントダウン終了時の処理
function ItemCount.end_item_countdown(player_index, blackbox)
    local player = game.players[player_index]
    local message = "カウントダウンが終了しました。"
    local changeDetected = false

    local black_Box_entities_info = Blackbox.GetRelatedBlackBoxEntity_notEvent(player_index, blackbox)
    if black_Box_entities_info == nil then
        player.print("black_Box_entities_infoがnil")
        return
    end

    local countBox_entity = black_Box_entities_info.specialCountBox
    if not global.item_count then
        return  player.print("初めにスタートボタンを押してください")
    end
    global.item_count[player_index].iriguti.afterBoxCount = countBox_entity.get_inventory(defines.inventory.chest).get_contents()
    global.item_count[player_index].deguti.afterBoxCount = getItemCountsAtEnd(global.black_boxes[player_index], "deguti")
    
    local irigutiBeforeBoxCount = global.item_count[player_index].iriguti.beforeBoxCount
    local irigutiAfterBoxCount = global.item_count[player_index].iriguti.afterBoxCount

    local degutiBeforeBoxCount = global.item_count[player_index].deguti.beforeBoxCount
    local degutiAfterBoxCount = global.item_count[player_index].deguti.afterBoxCount

    local irigutiDiffs = calculateItemDiffs(irigutiBeforeBoxCount or {}, irigutiAfterBoxCount or {})
    local degutiDiffs = calculateItemDiffs(degutiBeforeBoxCount or {}, degutiAfterBoxCount or {})

    for item, diff in pairs(irigutiDiffs) do
        message = message .. "\n入口ボックス内の" .. item .. ": 変化 " .. diff
        changeDetected = true
    end

    for item, diff in pairs(degutiDiffs) do
        message = message .. "\n出口ボックス内の" .. item .. ": 変化 " .. diff
        changeDetected = true
    end

    if not changeDetected then
        message = message .. "\nアイテムの差分はありませんでした。"
    end

    player.print(message)

    -- レシピの追加

    ItemCount.applyNewRecipe(player_index, irigutiDiffs, degutiDiffs)

    global.countdowns[player_index] = nil -- カウントダウンをリセット
end

local function addBlackBoxRecipe(player_index, ingredients, measurementTime, products)
    -- レシピの一意な名前を生成
    local recipe_name = "black-box-recipe-" .. player_index .. "-" .. #global.blackBoxRecipeList + 1

    -- 新しいレシピオブジェクトを作成
    local newRecipeData = {
        recipe = {
            name = recipe_name,
            player_index = player_index,
            ingredients = ingredients,  -- 例: { {name = "iron-plate", amount = 1} }
            production_time = measurementTime,
            products = products,  -- 例: { {name = "new-product", amount = 1} }
        },
        assemblyPartsBluePrint = nil  -- 新しいレシピにはまだブループリントが関連付けられていないため、nil
    }

    -- グローバルリストにレシピを追加
    table.insert(global.blackBoxRecipeList, newRecipeData)

    -- デバッグ用にプレイヤーに通知
    game.players[player_index].print("新しいブラックボックスレシピ「" .. recipe_name .. "」を追加しました。")
end

-- 新たなレシピを生成し、ゲームに追加する関数
function ItemCount.applyNewRecipe(player_index, irigutiDiffs, degutiDiffs)
    -- レシピの名前を定義
    local recipe_name = "special-recipe-" .. math.random(10000, 99999)

    -- ここで新たなレシピの名前、必要な材料、作成時間、生成されるアイテムを定義する
    local recipe_name = "new-special-recipe-" .. player_index
    local ingredients = {}
    local result = "new-product"
    local energy_required = 10 -- 仮の作成時間
    local products = {}
    local measurementTime = global.item_count[player_index].measurementTime

    --レシピの材料を設定
    -- アイテムの差分と新たに追加されたアイテムを材料としてレシピに追加
    for item, diff in pairs(irigutiDiffs) do
        if diff < 0 then -- 入口ボックスから減少したアイテムを材料として追加
            table.insert(ingredients, {item, -diff})
        end
    end

    --製品の設定
    for item, diff in pairs(degutiDiffs) do
        if diff > 0 then -- 出口ボックスから 増加したアイテムを製品として追加
            table.insert(products, {item, diff})
        end
    end

    -- nullチェック
    if not ingredients and not products then
        local player = game.players[player_index]
        player.print("材料、製品がないためレシピを追加できません。")
        return
    end

    addBlackBoxRecipe(player_index,ingredients,measurementTime,products)
end





return ItemCount
