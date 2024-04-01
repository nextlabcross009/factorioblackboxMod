-- blackbox.lua
local Black_box_debug = require("black_box_debug")
local Blackbox = {}

--前方宣言
local getStateNameById
local debugPrintAllBlackBoxStates
local set_en_black_box_entity_st
local cycleSt
local cycleDisp
local oneCycleDisp
local cycleDispAllBlackBoxes
local oneCycleSt
local cycleStAllBlackBoxes
local isAssemblyPartsBoxComp
local isCanCompIngridiantJud
local isElectricityConsumptionComp
--end





function Blackbox.BlackboxInit()
    global.en_black_box_entity_st = global.en_black_box_entity_st or {}
    global.EN_black_Box_entity_St = {
        None = 1,
        InPreparation = 2,
        InOperation = 3,
        Stop = 4,
    }
    global.isCanCompIngridiantBlackBox = global.isCanCompIngridiantBlackBox or {}

    --デバッグ用に変数を登録
    Black_box_debug.SetGuiNum(set_en_black_box_entity_st)
end
function Blackbox.Update(player_index)
    cycleSt(player_index)
    cycleDisp(player_index)
end

-- 状態を更新する関数
function Blackbox.SetdateBlackBoxState(player_index, blackBoxID, newState)
    if not global.en_black_box_entity_st[player_index] then
        global.en_black_box_entity_st[player_index] = {}
    end

    global.en_black_box_entity_st[player_index][blackBoxID] = newState
    game.players[player_index].print("Player " .. player_index .. " のブラックボックス " .. blackBoxID .. " の状態を " .. newState .. " に更新しました。")
end
function Blackbox.InitdateBlackBoxState(player_index, blackBoxID)
    Blackbox.SetdateBlackBoxState(player_index, blackBoxID, global.EN_black_Box_entity_St.Stop)
end
-- 状態を取得する関数
function Blackbox.GetBlackBoxState(player_index, blackBoxID)
    if global.en_black_box_entity_st[player_index] and global.en_black_box_entity_st[player_index][blackBoxID] then
        return global.en_black_box_entity_st[player_index][blackBoxID]
    else
        -- 状態が未設定の場合は None を返す
        return global.en_black_box_entity_st.None
    end
end

-- エンティティがブラックボックスに関連しているかどうかをチェックする関数
local function find_related_black_box(entity, player_index)
    if not global.blackBoxRelatedEntities[player_index] then
        return nil
    end

    for black_box_number, entities in pairs(global.blackBoxRelatedEntities[player_index]) do
        for _, value in ipairs(entities) do
            if entity.unit_number == value.unit_number then
                -- ブラックボックスと関連している場合はそのブラックボックスのIDを返す
                return black_box_number
            end
        end
    end

    -- 関連するブラックボックスが見つからない場合はnilを返す
    return nil
end

-- 関連するブラックボックスエンティティを取得する関数
function Blackbox.GetRelatedBlackBoxEntity(player_index, event)
    local entity = event.entity
    --触れたエンティティからブラックボックスと関連しているかを確認する
    --関連していれば、そのブラックボックスのナンバーを取得
    local black_box_number = find_related_black_box(entity,player_index)
    --ナンバーからblack_box_info.black_Box_entitiesを取得する
    if black_box_number ~= nil then
        return Blackbox.GetBlackBoxEntity(player_index, black_box_number)
    end
end
-- 関連するブラックボックスエンティティを取得する関数
function Blackbox.GetRelatedBlackBoxEntity_notEvent(player_index, entity)
    --触れたエンティティからブラックボックスと関連しているかを確認する
    --関連していれば、そのブラックボックスのナンバーを取得
    local black_box_number = find_related_black_box(entity,player_index)
    --ナンバーからblack_box_info.black_Box_entitiesを取得する
    if black_box_number ~= nil then
        return Blackbox.GetBlackBoxEntity(player_index, black_box_number)
    end
end



-- ブラックボックスに関連するエンティティのunit_numberを使って、対応するブラックボックスエンティティの詳細を取得する関数
function Blackbox.GetBlackBoxEntity(player_index, black_box_number)
    if not global.black_boxes[player_index] then
        return nil
    end

    local black_Box_entities = global.black_boxes[player_index].black_Box_entities
    for _, entity in pairs(black_Box_entities) do
        if entity.black_box_number == black_box_number then
            return entity
        end
    end

    return nil
end
--[[ function Blackbox.GetBlackBoxEntity(player_index,event)
    local unit_number = event.entity.unit_number

        -- プレイヤーに紐づいたblack_boxesが存在しない場合はnilを返す
        if not global.black_boxes[player_index] then
            return nil
        end
    
        local black_Box_entities = global.black_boxes[player_index].black_Box_entities
        for _, entity in pairs(black_Box_entities) do
            if entity.black_box_number == unit_number then
                return entity
            end
        end
    
        -- 該当するエンティティが見つからない場合はnilを返す
        return nil
end ]]



-- ブラックボックスの生産処理関
--[[ function Blackbox.process_black_box_production(player_index)
    local player = game.players[player_index]
    if not global.black_boxes[player_index] or not global.black_boxes[player_index].black_Box_entities then
        player.print("No black box entity information available.")
        return
    end

    -- 選択されたレシピの取得
    local production_recipe = global.selected_recipe[player_index]
    if not production_recipe then
        player.print("No recipe selected for production.")
        return
    end

    for _, entity_info in ipairs(global.black_boxes[player_index].black_Box_entities) do
        local input_inventory = entity_info.iriguti.beforeBox.get_inventory(defines.inventory.chest)
        if not input_inventory.valid then
            player.print("Input inventory is missing or invalid.")
            return
        end

        -- レシピの材料がすべて入力インベントリにあるか確認
        local isCanCompIngridiant = true
        for _, ingredient in pairs(production_recipe.ingredients) do
            if input_inventory.get_item_count(ingredient[1]) < ingredient[2] then
                isCanCompIngridiant = false
                break
            end
        end

        if isCanCompIngridiant and (not global.makeTime[player_index] or game.tick >= global.makeTime[player_index] + (production_recipe.production_time * 60)) then
            -- 材料を削除して製品を生成
            for _, ingredient in pairs(production_recipe.ingredients) do
                input_inventory.remove({name = ingredient[1], count = ingredient[2]})
            end

            local output_inventory = entity_info.deguti.afterBox.get_inventory(defines.inventory.chest)
            if not output_inventory.valid then
                player.print("Output inventory is missing or invalid.")
                return
            end

            for _, product in pairs(production_recipe.products) do
                output_inventory.insert({name = product[1], count = product[amount]})
            end

            -- 生産完了の通知
            player.print("Production complete: " .. production_recipe.name)
            -- 次の製作時間をリセットまたは更新
            global.makeTime[player_index] = game.tick
        elseif not isCanCompIngridiant then
            player.print("Not enough ingredients for production.")
        end
    end
end ]]

-- 生産タイマーの更新関数
function Blackbox.update_production_timer(player, production_timer_bar, production_recipe)
    -- 生産開始時間と終了時間を計算
    local start_time = global.makeTime[player.index] or 0
    local end_time = start_time + (production_recipe.production_time * 60)
    local total_ticks = end_time - start_time

    -- 現在の進捗を計算
    local current_tick = game.tick
    local elapsed_ticks = current_tick - start_time
    local progress = math.min(elapsed_ticks / total_ticks, 1) -- 0以上1以下にする

    -- プログレスバーを更新
    production_timer_bar.value = progress

    -- 生産完了の場合
    if current_tick >= end_time then
        -- プログレスバーをリセット
        production_timer_bar.value = 0
        -- 次の製作時間をリセット
        global.makeTime[player.index] = nil
    end
end

-- on_tickイベントで呼び出される関数
function Blackbox.on_tick(player_index)
    local player = game.players[player_index]
    local gui_element = player.gui.center.custom_assembler_gui

    -- GUIが開かれていない場合はスキップ
    if not gui_element then return end

    -- 選択されたレシピがない場合はスキップ
    local production_recipe = global.selected_recipe[player_index]
    if not production_recipe then return end

    if not global.black_boxes[player_index] or not global.black_boxes[player_index].black_Box_entities then
        return  -- ブラックボックスエンティティの情報がない場合は処理を終了
    end

    -- 各ブラックボックスエンティティに対して生産タイマーと条件を確認
    for _, entity_info in ipairs(global.black_boxes[player_index].black_Box_entities) do
        local input_inventory = entity_info.iriguti.beforeBox.get_inventory(defines.inventory.chest)

        -- 素材が足りているか確認
        local isCanCompIngridiant = true
        global.isCanCompIngridiantBlackBox[player_index][entity_info.black_box_number] = isCanCompIngridiant
        for _, ingredient in ipairs(production_recipe.ingredients) do
            if not input_inventory or input_inventory.get_item_count(ingredient[1]) < ingredient[2] then
                isCanCompIngridiant = false
                global.isCanCompIngridiantBlackBox[player_index][entity_info.black_box_number] = isCanCompIngridiant
                break
            end
        end

        if not isCanCompIngridiant then
            -- 素材が足りない場合は次のエンティティへ
            goto continue
        end

        -- 生産タイマーの更新と生産処理の実行
        if not entity_info.makeTime or game.tick >= entity_info.makeTime + (production_recipe.production_time * 60) then
            -- 生産処理を実行
            Blackbox.process_black_box_production_for_entity(player_index, entity_info)
            -- 次の製作時間を更新
            entity_info.makeTime = game.tick + (production_recipe.production_time * 60)
        end

        ::continue::
    end
end
--local関数
cycleSt = function(player_index)

    cycleStAllBlackBoxes(player_index)

end
cycleStAllBlackBoxes = function (player_index)
    if not global.en_black_box_entity_st then
        return
    end
    -- player_indexに紐づくすべてのブラックボックスIDを繰り返し処理
    if not global.en_black_box_entity_st[player_index] then
        return
    end

    for blackBoxID, state in pairs(global.en_black_box_entity_st[player_index]) do
        oneCycleSt(player_index, blackBoxID) -- 状態名を取得

    end
end
oneCycleSt = function (player_index, blackBoxID)
    local state = global.en_black_box_entity_st[player_index][blackBoxID]
    if state == global.EN_black_Box_entity_St.None then

        return
    elseif state == global.EN_black_Box_entity_St.InPreparation then
        if isAssemblyPartsBoxComp() and 
        isElectricityConsumptionComp() and
        isCanCompIngridiantJud(player_index,blackBoxID) then
            state = global.EN_black_Box_entity_St.InOperation
        end

        return
    elseif state == global.EN_black_Box_entity_St.InOperation then

        return
    elseif state == global.EN_black_Box_entity_St.Stop then

        state = global.EN_black_Box_entity_St.InPreparation
        return
    else
        return
    end
end

isAssemblyPartsBoxComp = function ()

    return true
end
isElectricityConsumptionComp = function ()
    return true
end
isCanCompIngridiantJud = function (player_index,blackBoxID)
    if global.isCanCompIngridiantBlackBox[player_index][blackBoxID] then
        return true
    else
        return false
    end
end

cycleDisp = function(player_index)

    cycleDispAllBlackBoxes(player_index)
end


oneCycleDisp = function(player_index,blackBoxID)
    local state = global.en_black_box_entity_st[player_index][blackBoxID]
    if state == global.EN_black_Box_entity_St.None then

        return
    elseif state == global.EN_black_Box_entity_St.InPreparation then
        return
    elseif state == global.EN_black_Box_entity_St.InOperation then
        return
    elseif state == global.EN_black_Box_entity_St.Stop then
        --game.players[player_index].print("global.EN_black_Box_entity_St.Stop")
        return
    else
        return
    end
end


cycleDispAllBlackBoxes =  function(player_index)
    if not global.en_black_box_entity_st then
        return
    end
    -- player_indexに紐づくすべてのブラックボックスIDを繰り返し処理
    if not global.en_black_box_entity_st[player_index] then
        --game.players[player_index].print("指定されたプレイヤーにはブラックボックスが存在しません。")
        return
    end

    for blackBoxID, state in pairs(global.en_black_box_entity_st[player_index]) do
        oneCycleDisp(player_index, blackBoxID) -- 状態名を取得

    end
end


-- 状態名を返す関数を再利用
getStateNameById = function (stateId)
    for name, id in pairs(global.EN_black_Box_entity_St) do
        if id == stateId then
            return name
        end
    end
    return "Unknown"  -- 該当する状態がない場合
end
-- すべてのプレイヤーのすべてのブラックボックスの状態をデバッグ出力する関数
debugPrintAllBlackBoxStates = function()
    for player_index, blackBoxes in pairs(global.en_black_box_entity_st) do
        for blackBoxID, stateId in pairs(blackBoxes) do
            local stateName = getStateNameById(stateId)
            return "Player " .. tostring(player_index) .. " のブラックボックス " .. tostring(blackBoxID) .. " の状態: " .. stateName
        end
    end
end
set_en_black_box_entity_st = function()

    Black_box_debug.AddText(debugPrintAllBlackBoxStates())
end

return Blackbox