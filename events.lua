-- events.lua
-- このファイルの責務：
-- - Factorioのイベントに対するリスナー定義
-- - イベントリスナーを通じたゲーム内のアクションへの応答

local Gui = require("gui")
local Teleport = require("teleport")
local Sync = require("sync")
local ItemCount = require("item_count")
local Blackbox = require("blackbox")
local Blueprint = require("blueprint")
local CreateEntity = require("createEntity")
local Black_box_debug = require("black_box_debug")

local function isTableEmpty(t)
    return next(t) == nil
end

-- 変数の内容を出力する関数
local function printVariable(name, value, Player_index)
    local player = game.players[Player_index]
    if type(value) == "table" then
        if isTableEmpty(value) then
            player.print(name .. " : {}") -- 空のテーブルの場合は {} を出力
        else
            player.print(name .. " : " .. tostring(value.name)) -- その他の型の場合
        end
    elseif value == nil then
        player.print(name .. " : NULL") -- nil の場合
    else
        player.print(name .. " : " .. tostring(value)) -- その他の型の場合
    end
end
-- グローバル変数の内容を確認する関数
local function debug_print_global_variables(player_index)
    local player = game.players[player_index]
    if not player then
        player.print("Playerが存在していません")
        return  -- プレイヤーが存在しない場合は処理を中断
    end
    player.clear_console()
    -- カウンタをインクリメントして出力
    global.debug_print_counter = (global.debug_print_counter or "NULL") + 1
    player.print("Debug Print Call #" .. tostring(global.debug_print_counter or "NULL"))

    local black_box_info = global.black_boxes[player_index]

    -- global.is_countingの値に基づいて出力を行う
    printVariable("global.is_counting", global.is_counting,player_index)
        

    -- black_Box_entitiesの情報の出力
    if black_box_info and black_box_info.black_Box_entities then
        for index, entity_info in ipairs(black_box_info.black_Box_entities) do
            player.print("Black_Box_Entity index#" .. index .. ":")
            printVariable("  Number", entity_info.black_box_number, player_index)
            printVariable("  Set Recipe", entity_info.setRecipe, player_index)
            printVariable("  Electricity Consumption", entity_info.electricityConsumption, player_index)
            printVariable("  assemblyPartsBox", entity_info.assemblyPartsBox, player_index)
            printVariable("  Black Boxes Surface", entity_info.black_boxes_surface, player_index)
            -- 入口チェスト情報の出力
            if entity_info.iriguti then
                printVariable("  Iriguti Before Box", entity_info.iriguti.beforeBox,  player_index)
                printVariable("  Iriguti After Box", entity_info.iriguti.afterBox , player_index)
            end
            -- 出口チェスト情報の出力
            if entity_info.deguti then
                printVariable("  Deguti Before Box", entity_info.deguti.beforeBox, player_index)
                printVariable("  Deguti After Box", entity_info.deguti.afterBox, player_index)
            end
            -- 特殊カウントボックスの出力
            if entity_info.specialCountBox then
                printVariable("  Special Count Box", entity_info.specialCountBox, player_index)
            end
        end
    end
    -- 選択しているレシピ
    if global.selected_recipe and global.selected_recipe[player_index] then
        printVariable("  Selected Recipe", global.selected_recipe[player_index], player_index)
    end
end


local function try_delete_custom_surface(player_index)
    local player = game.players[player_index]
    if not player then
        return
    end

    if global.black_boxes and global.black_boxes[player_index] then
        local black_box_entities = global.black_boxes[player_index].black_Box_entities
        if black_box_entities then
            for _, entity_info in ipairs(black_box_entities) do
                if entity_info.black_boxes_surface and game.surfaces[entity_info.black_boxes_surface.name] then
                    game.delete_surface(entity_info.black_boxes_surface)
                    player.print("テレポート先削除成功: " .. entity_info.black_boxes_surface.name)
                else
                    player.print("テレポート先削除失敗: サーフェスが見つからないか、無効です。")
                end
            end
            global.black_boxes[player_index] = nil  -- グローバル変数から削除
        else
            player.print("プレイヤーに関連付けられたテレポート先がありません。")
        end
    else
        player.print("プレイヤーに関連付けられたテレポート先がありません。")
    end
end

-- エンティティが解体された際のイベントリスナー
local function on_entity_removed(event)
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end

    -- ブラックボックスアセンブラーが解体された場合
    if entity.name == "black-box-assembler" then
        local player_index = entity.last_user and entity.last_user.index or nil
        if not player_index or not global.black_boxes or not global.black_boxes[player_index] then
            return
        end

        local black_box_entities = global.black_boxes[player_index].black_Box_entities

        for _, black_box_entity in ipairs(black_box_entities) do
            if black_box_entity.black_box_number == entity.unit_number then
                -- 入口と出口のエンティティを解体する
                if black_box_entity.iriguti.beforeBox and black_box_entity.iriguti.beforeBox.valid then
                    black_box_entity.iriguti.beforeBox.destroy()
                end
                if black_box_entity.iriguti.afterBox and black_box_entity.iriguti.afterBox.valid then
                    black_box_entity.iriguti.afterBox.destroy()
                end
                if black_box_entity.deguti.beforeBox and black_box_entity.deguti.beforeBox.valid then
                    black_box_entity.deguti.beforeBox.destroy()
                end
                if black_box_entity.deguti.afterBox and black_box_entity.deguti.afterBox.valid then
                    black_box_entity.deguti.afterBox.destroy()
                end

                -- ランプを解体する
                if black_box_entity.iriguti.afterRamp and black_box_entity.iriguti.afterRamp.valid then
                    black_box_entity.iriguti.afterRamp.destroy()
                end
                if black_box_entity.iriguti.beforeRamp and black_box_entity.iriguti.beforeRamp.valid then
                    black_box_entity.iriguti.beforeRamp.destroy()
                end
                if black_box_entity.deguti.afterRamp and black_box_entity.deguti.afterRamp.valid then
                    black_box_entity.deguti.afterRamp.destroy()
                end
                if black_box_entity.deguti.beforeRamp and black_box_entity.deguti.beforeRamp.valid then
                    black_box_entity.deguti.beforeRamp.destroy()
                end

                -- 特別カウントボックスを解体する
                if black_box_entity.specialCountBox and black_box_entity.specialCountBox.valid then
                    black_box_entity.specialCountBox.destroy()
                end

                -- 製造用パーツボックスを解体する
                if black_box_entity.assemblyPartsBox and black_box_entity.assemblyPartsBox then
                    black_box_entity.assemblyPartsBox.destroy()
                end

                -- テレポート先のサーフェスを削除する
                try_delete_custom_surface(player_index)

                -- プレイヤーに紐づいたブラックボックスのエンティティ情報を削除する
                --table.remove(global.black_boxes[player_index].black_Box_entities, _)
                break
            end
        end
    end
end

local function set_tab_isBlackBoxRelated(entity)
    if not entity.tags then
        entity.tags = {}
    end
    entity.tags["isBlackBoxRelated"] = true
end


-- エンティティが建設されたときのイベントリスナー
script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local surface = entity.surface
    local player_index = event.player_index
    local player = game.players[player_index]

    if entity.name == "black-box-assembler" then
        if not global.black_boxes then
            global.black_boxes = {}
        end

        if not global.black_boxes[player_index] then
            global.black_boxes[player_index] = {}

        end
        if not global.black_boxes[player_index].black_Box_entities then
            global.black_boxes[player_index].black_Box_entities = {}
        end
        if global.black_boxes[player_index].surface then
            global.black_boxes[player_index].surface = {}
        end

        local surfaceinfo = {
            return_positions = {entity.position.x+2,entity.position.y},
            return_surfaces = player.surface,
        }
        global.black_boxes[player_index].surface = surfaceinfo

        -- テレポート先のサーフェスと関連情報を取得するカスタム関数の呼び出し
        local black_box_entity = Teleport.create_custom_surface(player,event)
        local black_box_entity_number = entity.unit_number
        -- テレポート元に入口用と出口用のチェストを設置
        local irigutiBoxBefore = CreateEntity.CreateEntitySurface(surface,player_index,"irigutiBox", {entity.position.x - 1, entity.position.y} , player.force,false,black_box_entity_number)
        local degutiBoxBefore = CreateEntity.CreateEntitySurface(surface,player_index,"degutiBox", {entity.position.x + 1, entity.position.y} , player.force,false,black_box_entity_number)
        -- 入口用ランプ(irigutiRamp)の設置
        local irigutiRamp = CreateEntity.CreateEntitySurface(surface,player_index,"irigutiRamp",  {irigutiBoxBefore.position.x, irigutiBoxBefore.position.y - 1} , player.force,false,black_box_entity_number)

        -- 出口用ランプ(degutiRamp)の設置
        local degutiRamp = CreateEntity.CreateEntitySurface(surface,player_index,"degutiRamp", {degutiBoxBefore.position.x, degutiBoxBefore.position.y - 1} , player.force,false,black_box_entity_number)

        black_box_entity.iriguti.beforeBox = irigutiBoxBefore
        black_box_entity.deguti.beforeBox = degutiBoxBefore
        black_box_entity.iriguti.beforeRamp = irigutiRamp
        black_box_entity.deguti.beforeRamp = degutiRamp



        -- ブラックボックスエンティティの新しい情報を作成
        local new_entity_info = {
            black_box_number = entity.unit_number,
            black_Box_entity = entity,
            setRecipe = nil,
            electricityConsumption = nil,
            assemblyPartsBox = nil,  -- 製造用パーツボックスのエンティティを後でセットする
            black_boxes_surface = black_box_entity.black_boxes_surface,
            iriguti = black_box_entity.iriguti,
            deguti = black_box_entity.deguti,
            specialCountBox = black_box_entity.specialCountBox,
        }

        player.print("db")
        -- 製造用パーツボックスの設置と情報の追加
        new_entity_info.assemblyPartsBox = CreateEntity.CreateEntitySurface(
            surface,
            player_index,
            "assemblyPartsBox",
            {entity.position.x-1, entity.position.y + 1} ,
            player.force,
            false,
            black_box_entity_number)


--[[         --ブラックボックス以外解体できないようにtabをつける
        set_tab_isBlackBoxRelated(new_entity_info.iriguti.beforeBox)
        set_tab_isBlackBoxRelated(new_entity_info.iriguti.afterBox)
        set_tab_isBlackBoxRelated(new_entity_info.iriguti.beforeRamp)
        set_tab_isBlackBoxRelated(new_entity_info.iriguti.afterRamp)

        set_tab_isBlackBoxRelated(new_entity_info.deguti.beforeBox)
        set_tab_isBlackBoxRelated(new_entity_info.deguti.afterBox)
        set_tab_isBlackBoxRelated(new_entity_info.deguti.beforeRamp)
        set_tab_isBlackBoxRelated(new_entity_info.deguti.afterRamp)

        set_tab_isBlackBoxRelated(new_entity_info.specialCountBox)
        set_tab_isBlackBoxRelated(new_entity_info.assemblyPartsBox) ]]
        -- 新しいブラックボックスエンティティ情報をグローバル変数に追加
        table.insert(global.black_boxes[player_index].black_Box_entities, new_entity_info)

        --#TODO エンティティを動的に指定する仕組みを追加する
        
        Blackbox.InitdateBlackBoxState(
            player_index,entity.unit_number
        )

        player.print("ブラックボックスエンティティが追加されました。")
    end
end)









-- GUI内のボタンがクリックされた際のイベントリスナー
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    local player = game.players[event.player_index]
    local black_box = global.black_boxes[event.player_index]

    if not (element and element.valid) then return end

    if element.name == "start_count_button" then
        global.countdowns[event.player_index] = game.tick + (60 * 5)  -- 60 ticksは1秒に相当

        -- 必要に応じてプレイヤーに通知
        player.print("  カウントダウン開始 ")
        -- カウント開始時にテレポート後の入口チェストの内容を特別カウントボックスにコピー
        Sync.sync_irigutiChest2specialchest()
        ItemCount.start_measurement_time(player.index)
        for _, chest in pairs(game.surfaces['nauvis'].find_entities_filtered{type="container"}) do
            global.last_item_count[chest.unit_number] = chest.get_inventory(defines.inventory.chest).get_item_count()
        end
        global.is_counting[event.player_index] = true
        ItemCount.start_item_countdown(event.player_index)
    elseif element.name == "stop_count_button" then


        game.players[player.index].print("カウントダウン終了！")
        ItemCount.end_measurement_time(player.index)
        ItemCount.end_item_countdown(player.index,black_box.in_black_box) -- カウントダウン終了時の処理を実行

        -- カウントダウンを削除
        global.countdowns[player.index] = nil
        global.is_counting[player.index] = false



        --ブループリントの作成
        local black_Box_entities = Blackbox.GetRelatedBlackBoxEntity_notEvent(event.player_index,black_box.in_black_box)
        if  black_Box_entities == nil then
            
            return
        end
        local blueprintSurface =  black_Box_entities.black_boxes_surface

        local blueprintChunkPosition = {x = 0, y = 0} --原点を設定。
        local bluePrintData =  Blueprint.create_blueprint_from_chunk(blueprintSurface, blueprintChunkPosition)
        local excluded_items = { --除外するアイテムリスト
            "irigutiRamp",
            "degutiRamp",
            "irigutiBox",
            "degutiBox",
            "assemblyPartsBox",
            "special-count-box",
            "flying-text",
        }
        bluePrintData = Blueprint.blueprint_excluding_items(bluePrintData, player, excluded_items)

        --レシピの追加
        --#TODO新規レシピを追加したらカウントさせる必要がある。
        local recipe_count = #global.blackBoxRecipeList
        global.blackBoxRecipeList[recipe_count].assemblyPartsBluePrint = bluePrintData
        --プレイヤーインベントリ
        Blueprint.add_blueprint_to_player_inventory(player, bluePrintData)

    elseif element.name == "close_button" then -- 閉じるボタンがクリックされた場合
        if player.gui.left.custom_gui_frame then
            player.gui.left.custom_gui_frame.destroy() -- GUIフレームを削除し、GUIを閉じる
        end
    elseif element.name == "close_custom_gui" then
        if element.parent.name == "custom_assembler_gui" then
            element.parent.destroy()
        end
    --リストを開いたときに実行される
    elseif element.type == "drop-down" and element.name == "recipe_dropdown" then
        player.print("drop-downをクリック：リストが開かれました")
        -- global.blackBoxRecipeList がnullまたは空リストではないことを確認
        if not global.blackBoxRecipeList or #global.blackBoxRecipeList == 0 then
            player.print("レシピリストがありません。")
            return  -- 早期リターン
        end
    end

end)

-- レシピの材料とそれ以外のアイテムを分ける関数
local function segregate_entities_by_recipe(assemblyPartsBlueprint, recipeData)
    local assemPorts = {}

    -- レシピの材料の数量を辞書形式で取得
    local recipe_ingredient_counts = {}
    for _, ingredient in pairs(recipeData.ingredients) do
        if not recipe_ingredient_counts[ingredient[1]] then
            recipe_ingredient_counts[ingredient[1]] = ingredient[2]
        else
            recipe_ingredient_counts[ingredient[1]] = recipe_ingredient_counts[ingredient[1]] + ingredient[2]
        end
    end

    -- エンティティがレシピの材料かどうかを確認し、材料でなければassemPortsに追加、材料の場合はカウントを減らす
    for _, entity in pairs(assemblyPartsBlueprint.entities) do
        if recipe_ingredient_counts[entity.name] and recipe_ingredient_counts[entity.name] > 0 then
            -- 材料のカウントを減らす
            recipe_ingredient_counts[entity.name] = recipe_ingredient_counts[entity.name] - 1
        else
            -- 材料でない、または必要な材料の数を満たした後のアイテムをassemPortsに追加
            table.insert(assemPorts, entity)
        end
    end

    return assemPorts
end

--GUIのレシピを選択したときのイベントハンドラ
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local element = event.element
    local player = game.players[event.player_index]
    
    -- 最後に触れたブラックボックスエンティティの情報を取得
    local entity_number = global.last_touched_entity[player.index]
    if not entity_number then return end

    if element.type == "drop-down" and element.name == "recipe_dropdown" then
        local selected_index = element.selected_index
        local last_touched_entity_number = global.last_touched_entity[player.index]
        local recipe = nil
        local entity_info_found = nil
        local select_Black_Box_Entitie


        local last_touched_entity_number = global.last_touched_entity[player.index]
        if last_touched_entity_number then
            for _, entity_info in pairs(global.black_boxes[player.index].black_Box_entities) do
                if entity_info.black_box_number == last_touched_entity_number then
                    -- 触れているブラックボックスエンティティのレシピ情報を更新
                    select_Black_Box_Entitie = entity_info
                    break -- 対象のエンティティを見つけたらループを終了
                end
            end
        end
        --設定されているレシピと選択したレシピを比較して、差がある場合は選択されたレシピを設定する。



        --レシピが設定されているかを確認。
        if select_Black_Box_Entitie.setRecipe then
            --レシピがある場合
            --設定されているレシピと選択したレシピを比較
            if(select_Black_Box_Entitie.setRecipe.name == global.blackBoxRecipeList[selected_index].recipe.name) then

                --同じ場合は処理なし
            else
                --異なる場合は選択されたレシピを設定する
                select_Black_Box_Entitie.setRecipe = global.blackBoxRecipeList[selected_index].recipe
            end

        else
            --レシピがない場合
            --選択されたレシピを格納する
            --選択したレシピを格納し表示用の変数に代入
            select_Black_Box_Entitie.setRecipe = global.blackBoxRecipeList[selected_index].recipe
        end

        recipe = select_Black_Box_Entitie.setRecipe

        -- 選択されたレシピをグローバル変数に格納し、エンティティ情報を更新
        if recipe then
            -- GUIにレシピ情報を表示
            local details_frame = player.gui.center.custom_assembler_gui.recipe_details
            details_frame.recipe_info.text = "レシピ名: " .. recipe.name .. "\n材料:\n"
            for _, ingredient in ipairs(recipe.ingredients) do
                details_frame.recipe_info.text = details_frame.recipe_info.text .. ingredient[1] .. " x" .. ingredient[2] .. "\n"
            end
            details_frame.recipe_info.text = details_frame.recipe_info.text .. "生産時間: " .. recipe.production_time .. "秒\n製品:\n"
            for _, product in ipairs(recipe.products) do
                details_frame.recipe_info.text = details_frame.recipe_info.text .. product[1] .. " x" .. product[2] .. "\n"
            end
            player.print("レシピ " .. recipe.name .. " が選択されました。")
        end

        -- 選択されたレシピに基づいて要求チェストの要求を設定
--[[         if recipe and select_Black_Box_Entitie.assemblyPartsBox and select_Black_Box_Entitie.assemblyPartsBox.valid then
            local chest = select_Black_Box_Entitie.assemblyPartsBox
            -- 要求スロットをクリア
            for i = 1, chest.request_slot_count or 0 do
                chest.clear_request_slot(i)
            end

            -- 新しい要求を設定
            for i, ingredient in ipairs(recipe.ingredients) do
                chest.set_request_slot({name = ingredient[1], count = ingredient[2]}, i)
            end
            player.print("要求チェストが更新されました: " .. recipe.name)
        end ]]
    -- 使用例：エンティティリストとレシピを与えて素材とそれ以外を分ける

        if recipe and select_Black_Box_Entitie.assemblyPartsBox and select_Black_Box_Entitie.assemblyPartsBox.valid then
                local chest = select_Black_Box_Entitie.assemblyPartsBox
            for i = 1, chest.request_slot_count or 0 do
                chest.clear_request_slot(i)
            end

            
            -- アイテムの名前とその総数を保持するテーブル
            local item_counts = {}

            -- 非材料エンティティのリストをループしてアイテムの総数を計算
            for _, entity in ipairs(global.blackBoxRecipeList[selected_index].assemblyPartsBluePrint.entities) do
                if item_counts[entity.name] then
                    item_counts[entity.name] = item_counts[entity.name] + 1
                else
                    item_counts[entity.name] = 1
                end
            end

            -- アイテムの総数に基づき要求チェストに要求を設定
            local slot_index = 1
            for item_name, count in pairs(item_counts) do
                chest.set_request_slot({name = item_name, count = count}, slot_index)
                slot_index = slot_index + 1

                -- 要求スロットの数を超えないようにチェック
                if slot_index > chest.request_slot_count then
                    player.print("要求チェストの要求最大値を超えました。")
                    break
                end
            end

            player.print("要求チェストが更新されました: " .. recipe.name)
        end
    end
end)



-- エンティティがブラックボックスに関連しているかどうかをチェックする関数
local function is_entity_blackbox_related(entity,player_index,black_box_number)
    -- プレイヤーとブラックボックスナンバーに基づいた関連エンティティの存在を確認
    if not global.blackBoxRelatedEntities[player_index] or not global.blackBoxRelatedEntities[player_index][black_box_number] then
        return false
    end
    -- エンティティがブラックボックスシステムに関連するものであるかを示すグローバル変数をチェック
    for key, value in pairs(global.blackBoxRelatedEntities[player_index][black_box_number]) do

        if entity.unit_number == value.unit_number then
            return true
        end
    end

    return false
end

-- プレイヤーによるエンティティの解体を試みる前に発生するイベントのハンドラを登録します。
script.on_event(defines.events.on_pre_player_mined_item, function(event)
    local entity = event.entity
    local player = game.players[event.player_index]
    local player_index = player.index
    --#TODO　解体不可のエンティティを解体し時のプレイヤーへのメッセージについては時間があれば実装する。
    -- エンティティがブラックボックスに紐づけられているかどうかを判定
    if entity and entity.valid and is_entity_blackbox_related(entity,player_index) then
        -- プレイヤーに警告メッセージを表示
        game.players[event.player_index].print("このエンティティはブラックボックスに関連しています。解体するには、関連するブラックボックスを先に解体してください。")
        -- エンティティを再生成
        local surface = entity.surface
        local position = entity.position
        local force = entity.force
        local name = entity.name
        -- 再生成前に必要なパラメータを保存しておく
        local newEntity =surface.create_entity{name = name, position = position, force = force}
        local black_box_number =
        --CreateEntity.tagEntityAsBlackBoxRelated(newEntity,player_index,black_box_number)
        CreateEntity.removeNumber(entity.unit_number, player_index)
        game.players[event.player_index].print("db")
    end
end)



-- エンティティをクリックしたとき
script.on_event(defines.events.on_gui_opened, function(event)
    if not (event.entity and event.entity.valid) then return end
    local player = game.players[event.player_index]
    local player_index = player.index
    local black_box = global.black_boxes[player_index]

    if event.entity.name == "irigutiRamp" or event.entity.name == "degutiRamp" then
        -- irigutiRamp または degutiRamp がクリックされた場合、テレポート処理を実行
        Teleport.teleport_player(player, event.entity.name,event)

        player.opened = nil
        if global.player_positions[player_index] == "after" then
            Gui.open_custom_gui(player,event)
            --中に入ったブラックボックスを記憶する。
            local blackBoxEntity = Blackbox.GetRelatedBlackBoxEntity(player_index, event)
            if blackBoxEntity == nil then

                return
            end
            black_box.in_black_box = blackBoxEntity.black_Box_entity
        else
            --外に出た時はブラックボックスの記憶を解除する。
            black_box.in_black_box = nil
            player.gui.left.custom_gui_frame.destroy()
        end
    elseif event.entity.name == "black-box-assembler" then
        global.last_touched_entity[player_index] = event.entity.unit_number
        Gui.open_custom_assembler_gui(player,event)
        if not global.last_touched_entity then
            global.last_touched_entity = {}
        end
    end
end)

-- エンティティの上をマウスオーバーしたとき
script.on_event(defines.events.on_selected_entity_changed, function(event)
    local player = game.players[event.player_index]
    if player.selected then
        local entity = player.selected
        -- 既存のGUIフレームが存在するか確認
        local existing_frame = player.gui.left.custom_gui_frame
        if existing_frame then
            -- エンティティ情報を表示するためのサブフレームを作成または更新
            local info_frame = existing_frame.my_custom_gui or existing_frame.add{type="frame", name="my_custom_gui", caption="エンティティ情報"}
            -- サブフレーム内の既存のラベルをクリア
            if info_frame["entity_info_label"] then
                info_frame["entity_info_label"].destroy()
            end
            if info_frame["entity_number_label"] then
                info_frame["entity_number_label"].destroy()
            end
            -- 新しいエンティティ情報をサブフレームに追加
            info_frame.add{type="label", name="entity_info_label", caption="エンティティの種類: " .. entity.name}
            -- エンティティのナンバーを表示
            if entity.unit_number then
                info_frame.add{type="label", name="entity_number_label", caption="エンティティのナンバー: " .. tostring(entity.unit_number)}
            end
            -- 他の情報もここに追加できます
        end
    else
        -- エンティティが選択されていない場合は、エンティティ情報フレームを削除
        local existing_frame = player.gui.left.custom_gui_frame
        if existing_frame and existing_frame.my_custom_gui then
            existing_frame.my_custom_gui.destroy()
        end
    end
end)











-- 一定間隔のイベント
script.on_event(defines.events.on_tick, function(event)
    --初期化イベント
    if not global.give_items_next_tick then
        return
    end
    for player_index, tick_to_give in pairs(global.give_items_next_tick) do
        if game.tick >= tick_to_give then
            -- アイテムを付与する関数を呼び出す
            Black_box_debug.give_initial_items(game.players[player_index])
            -- 処理したので、このプレイヤーをリストから削除
            global.give_items_next_tick[player_index] = nil
        end
    end


    -- 定期的な同期処理を実行（例: 1秒ごと）
    if event.tick % 60 == 0 then
        for _, player in pairs(game.players) do
            if player.connected then  -- 接続中のプレイヤーのみ対象
                --debug_print_global_variables(player.index)
                Black_box_debug.cycle(player)
                Blackbox.Update(player.index)
                
            end
        end
        --　同期処理はブラックボックスで生産するためbeforeはアイテム計測用としてしようしなくなっため同期処理をしないように変更
        -- Sync.sync_chests()
        
    end
    for player_index, _ in pairs(game.connected_players) do
        Blackbox.on_tick(player_index)
    end
end)


-- エンティティがプレイヤーによって解体されたときと死亡したときのイベントを購読
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)
script.on_event(defines.events.on_entity_died, on_entity_removed)

