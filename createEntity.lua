--createEntity.lua
local CreateEntity = {}

function CreateEntity.SetBlackBox(tCreateSurface, player_index, tName, tPosition, tForce, tMinnable,black_box_number)
    local entity = tCreateSurface.create_entity({
        name = tName,
        position = tPosition,
        force = tForce,
        minable = tMinnable  -- これによりエンティティの解体ができなくなる
    })
    CreateEntity.tagEntityAsBlackBoxRelated(entity,player_index,black_box_number)

    return entity
end

function CreateEntity.CreateEntitySurface(tCreateSurface, player_index, tName, tPosition, tForce, tMinnable,black_box_number)
    local entity = tCreateSurface.create_entity({
        name = tName,
        position = tPosition,
        force = tForce,
        minable = tMinnable  -- これによりエンティティの解体ができなくなる
    })
    CreateEntity.tagEntityAsBlackBoxRelated(entity,player_index,black_box_number)

    return entity
end

function CreateEntity.tagEntityAsBlackBoxRelated(entity, player_index, black_box_number)
    local entry = {
        name = "black-box-assembler",
        unit_number = black_box_number,
    }
    if not global.blackBoxRelatedEntities[player_index] then
        global.blackBoxRelatedEntities[player_index] = {}
    end
    if not global.blackBoxRelatedEntities[player_index][black_box_number] then
        global.blackBoxRelatedEntities[player_index][black_box_number] = {}
        --初めにBlackBoxを登録する
        table.insert(global.blackBoxRelatedEntities[player_index][black_box_number], entry)
    end
    entry = {
        name = entity.name,
        unit_number = entity.unit_number,
    }

    if entity and entity.valid then
        table.insert(global.blackBoxRelatedEntities[player_index][black_box_number], entry)
    end
end

function CreateEntity.removeNumber(removeNumber, player_index, black_box_number)
    if global.blackBoxRelatedEntities[player_index] and global.blackBoxRelatedEntities[player_index][black_box_number] then
        for i, entry in ipairs(global.blackBoxRelatedEntities[player_index][black_box_number]) do
            if entry.unit_number == removeNumber then
                table.remove(global.blackBoxRelatedEntities[player_index][black_box_number], i)
                return
            end
        end
    end
end


return CreateEntity