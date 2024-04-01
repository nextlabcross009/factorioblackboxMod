-- gui.lua
-- このファイルの責務：
-- - GUIの作成と管理
-- - プレイヤーのGUIアクションに対する応答定義

local Gui = {}

function Gui.open_custom_gui(player,event)
    local entity = event.entity
    if player.gui.left.custom_gui_frame then
       player.gui.left.custom_gui_frame.destroy()
       player.print("customGuiが存在するのでいったん破棄")
    end
    if player.gui.left.custom_gui_frame == nil then -- GUIフレームが存在しない場合
        local frame = player.gui.left.add{type="frame", name="custom_gui_frame", caption="Black Box Assembler"} -- フレームを追加
        frame.add{type="button", name="start_count_button", caption="Start Count"}
        frame.add{type="button", name="stop_count_button", caption="Stop Count"}
        player.print("customGuiを作成した")
    end

    
end

function Gui.open_custom_assembler_gui(player, event)
    local entity = event.entity
    if entity and entity.name == "black-box-assembler" then
        -- 既存のGUIを閉じる
        player.opened = nil
    
        -- カスタムGUIのフレームを作成
        local frame = player.gui.center.add{type="frame", name="custom_assembler_gui", caption="組み立て機設定", direction="vertical"}
    
        -- 生産タイマー
        local production_timer_flow = frame.add{type="flow", name="production_timer_flow", direction="horizontal"}
        production_timer_flow.add{type="label", caption="生産時間:"}
        production_timer_flow.add{type="progressbar", name="production_timer_bar", size=200, value=0}
    
        -- レシピ選択のドロップダウンリスト
        local dropdown = frame.add{type="drop-down", name="recipe_dropdown"}
        local dropdown_items = {}
        local selected_index = nil

        -- 触っているブラックボックスエンティティのレシピを特定
        local black_box_entities = global.black_boxes[player.index].black_Box_entities
        local tRecipe
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


        --レシピが設定されているかを確認。
        if select_Black_Box_Entitie.setRecipe then
            --レシピがある場合
            --select_Black_Box_Entitie.setRecipeを表示レシピへ
            tRecipe = select_Black_Box_Entitie.setRecipe

        else
            --レシピがない場合
            --表示のないrecipeへ
            tRecipe = nil
        end
        --リストの作成
        for index, recipeData in ipairs(global.blackBoxRecipeList) do
            if recipeData.recipe then  -- recipeDataがrecipeを持っていることを確認
                table.insert(dropdown_items, recipeData.recipe.name)
            end
        end

        dropdown.items = dropdown_items
        --開いたときのリスト上の選択している項目
        if selected_index then
            dropdown.selected_index = selected_index
        end

        -- レシピの詳細を表示するフレーム
        local recipe_details_frame = frame.add{type="frame", name="recipe_details", caption="レシピの詳細", direction="vertical"}
        local recipe_info = recipe_details_frame.add{type="text-box", name="recipe_info"}
        recipe_info.read_only = true  -- 編集不可に設定
        recipe_info.style.minimal_width = 500 -- 幅を適宜調整
        recipe_info.style.minimal_height = 300 -- 高さを適宜調整    

        -- 選択されたレシピをグローバル変数に格納し、エンティティ情報を更新
        if tRecipe then
            -- GUIにレシピ情報を表示
            local recipe_details_frame = player.gui.center.custom_assembler_gui.recipe_details
            recipe_details_frame.recipe_info.text = "レシピ名: " .. tRecipe.name .. "\n材料:\n"
            for _, ingredient in ipairs(tRecipe.ingredients) do
                recipe_details_frame.recipe_info.text = recipe_details_frame.recipe_info.text .. ingredient[1] .. " x" .. ingredient[2] .. "\n"
            end
            recipe_details_frame.recipe_info.text = recipe_details_frame.recipe_info.text .. "生産時間: " .. tRecipe.production_time .. "秒\n製品:\n"
            for _, product in ipairs(tRecipe.products) do
                recipe_details_frame.recipe_info.text = recipe_details_frame.recipe_info.text .. product[1] .. " x" .. product[2] .. "\n"
            end
        else
            recipe_info.text = "レシピを選択してください。"
        end

        -- 閉じるボタン
        frame.add{type="button", name="close_custom_gui", caption="閉じる"}
    end
end


-- アイテムカウント関数
function Gui.count_items_in_chest(chest)
    -- chestはチェストのエンティティオブジェクトを指します
    if not chest.valid then
        return
    end
    local inventory = chest.get_inventory(defines.inventory.chest)
    local item_count = inventory.get_item_count()  -- チェスト内の全アイテム数を取得
    local last_count = global.last_item_count[chest.unit_number] or 0
    local increase = item_count - last_count  -- 前回からの増加数を計算

    -- 結果を保存または表示
    global.last_item_count[chest.unit_number] = item_count  -- 最新のカウントを保存
    return increase  -- 増加数を返す
end

-- カウント結果をプレイヤーのコンソールに表示する関数
function Gui.display_count_result(player, count_result)
    if player and player.valid then
        player.print("Current count: " .. tostring(count_result))
    end
end


return Gui
