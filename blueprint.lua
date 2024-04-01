-- blueprint.lua

local Blueprint = {}

function Blueprint.create_blueprint_from_chunk(surface, chunk_position)
    local entities = surface.find_entities_filtered{area = {left_top = {x = -64, y = -64}, right_bottom = {x = 64, y = 64}}}
    local blueprint_entities = {}

    for _, entity in pairs(entities) do
        if entity.name ~= "player" and entity.name ~= "character" then -- プレイヤーエンティティは除外
            table.insert(blueprint_entities, {
                entity_number = _, -- 一意の識別子
                name = entity.name,
                position = {entity.position.x - (chunk_position.x * 64), entity.position.y - (chunk_position.y * 64)}, -- チャンク内の相対位置
                direction = entity.direction,
                force = entity.force.name,
                -- 必要に応じて他の属性を追加
            })
        end
    end
    --#TODO新しいレシピを選択する処理が必要
    local recipeName = global.blackBoxRecipeList[1].recipe.name .. "_bp"
    local blueprint_data = {
        entities = blueprint_entities,
        item = "blueprint",
        label = recipeName,
        version = game.active_mods.base
    }

    return blueprint_data
end

function Blueprint.add_blueprint_to_player_inventory(player, blueprint_data)
    if player and player.valid then
        local inventory = player.get_main_inventory()
        if inventory and inventory.valid then
            local blueprint_item = inventory.insert({name = "blueprint", count = 1})
            if blueprint_item then
                local blueprint = inventory.find_item_stack("blueprint")
                blueprint.set_blueprint_entities(blueprint_data.entities)
                blueprint.label = blueprint_data.label
                blueprint.allow_manual_label_change = false -- ラベルの手動変更を禁止
            end
        end
    end
end
-- 指定されたアイテムを除外してブループリントをプレイヤーに提供する関数
function Blueprint.blueprint_excluding_items(blueprint_data, player, excluded_items)
    -- 除外するアイテムをフィルタリング
    local filtered_entities = {}

    for _, entity in pairs(blueprint_data.entities) do
        if not table.contains(excluded_items, entity.name) then
            table.insert(filtered_entities, entity)
        end
    end

    -- フィルタリング後のエンティティ情報でブループリントデータを更新
    local updated_blueprint_data = {
        entities = filtered_entities,
        item = "blueprint",
        label = blueprint_data.label,
        version = blueprint_data.version
    }
    return updated_blueprint_data

end

-- table.contains関数（既に定義されていると仮定）
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

return Blueprint
