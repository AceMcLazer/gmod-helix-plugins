local PLUGIN = PLUGIN

PLUGIN.name = "Rank Prefix System"
PLUGIN.author = "Xemon"
PLUGIN.description = "Ranks' system with prefixes."

ix.util.Include("sh_config.lua")

function PLUGIN:InitializedPlugins()
    for k, v in pairs(categories) do
        if sql.TableExists("rank_prefix_system_" .. v) then return end

        local createTable = "CREATE TABLE rank_prefix_system_" .. v .. "(char INTEGER, rank INTEGER)"
        local createTable = sql.Query(createTable)
    end
end

function PLUGIN:OnCharacterCreated(client, char)
    manageCharacter(true, char)

    setName(char, "", ranksPrefix[prefixFactions[char:GetFaction()]][1])
end

function PLUGIN:PreCharacterDeleted(client, char)
    manageCharacter(false, char)
end

function manageCharacter(create, char)
    local charID = char:GetID()
    local faction = char:GetFaction()

    if prefixFactions[faction] == nil then return end
    
    local category = prefixFactions[faction]

    if create then
        query = "INSERT INTO rank_prefix_system_" .. category .. "(char, rank) VALUES(" .. charID .. ", 1)"
    else
        query = "DELETE FROM rank_prefix_system_" .. category .. " WHERE char=" .. charID
    end

    local query = sql.Query(query)
end

ix.command.Add("Promote", {
    description = "Promotes the given player by rank up.",
    privilege = "Rank Prefix System",
    adminOnly = false,
    arguments = {
        ix.type.character
    },
    OnRun = function(self, client, target)
        if updateRank(true, client, target) == false then
            client:PrintMessage(HUD_PRINTTALK, "You can't promote the target!")
        end
    end
})

ix.command.Add("Demote", {
    description = "Demotes the given player by rank down.",
    privilege = "Rank Prefix System",
    adminOnly = false,
    arguments = {
        ix.type.character
    },
    OnRun = function(self, client, target)
        if updateRank(false, client, target) == false then
            client:PrintMessage(HUD_PRINTTALK, "You can't degrade the target!")
        end
    end
})

function updateRank(promote, client, target)
    local clientChar = client:GetChar()

    local clientCharID = clientChar:GetID()
    local targetID = target:GetID()

    local clientFaction = clientChar:GetFaction()
    local targetFaction = target:GetFaction()

    if !canUpdateRank(clientCharID, clientFaction, targetID, targetFaction, promote) then return false end

    local category = prefixFactions[targetFaction]

    local clientRank = "SELECT rank FROM rank_prefix_system_" .. category .. " WHERE char=" .. clientCharID
    local clientRank = sql.QueryValue(clientRank)
    local clientRank = tonumber(clientRank)

    local targetRank = "SELECT rank FROM rank_prefix_system_" .. category .. " WHERE char=" .. targetID
    local targetRank = sql.QueryValue(targetRank)
    local targetRank = tonumber(targetRank)

    if promote == true then
        newRank = targetRank + 1
    else
        newRank = targetRank - 1
    end

    local updateRank = "UPDATE rank_prefix_system_" .. category .. " SET rank=" .. newRank .. " WHERE char=" .. targetID
    local updateRank = sql.Query(updateRank)

    local targetName = target:GetPlayer():Name()

    local oldPrefix = ranksPrefix[category][targetRank]
    local newPrefix = ranksPrefix[category][newRank]

    if promote == true then
        client:PrintMessage(HUD_PRINTTALK, "You succesfully promote " .. targetName .. "! " .. targetName .. "'s new rank is " .. newPrefix .. ".")
    else
        client:PrintMessage(HUD_PRINTTALK, "You succesfully degrade " .. targetName .. "! " .. targetName .. "'s new rank is " .. newPrefix .. ".")
    end

    setName(target, oldPrefix, newPrefix)
end

function canUpdateRank(clientCharID, clientFaction, targetID, targetFaction, promote)
    cantPromote = false

    if (prefixFactions[clientFaction] == nil) or (prefixFactions[targetFaction] == nil) then
        cantPromote = true
    end

    if clientFaction != targetFaction then
        cantPromote = true
    end

    local category = prefixFactions[targetFaction] 

    if category != nil then
        local clientRank = "SELECT rank FROM rank_prefix_system_" .. category .. " WHERE char=" .. clientCharID
        local clientRank = sql.QueryValue(clientRank)
        local clientRank = tonumber(clientRank)

        local targetRank = "SELECT rank FROM rank_prefix_system_" .. category .. " WHERE char=" .. targetID
        local targetRank = sql.QueryValue(targetRank)
        local targetRank = tonumber(targetRank)

        if clientRank < targetRank then -- change operator to <=
            cantPromote = true
        end

        if promote then
            if targetRank == #ranksPrefix[category] then
                cantPromote = true
            end
        else
            if targetRank == 1 then
                cantPromote = true
            end
        end
    end

    return !cantPromote
end

function setName(plyChar, oldPrefix, newPrefix)
    local name = plyChar:GetName()

    if oldPrefix != "" then
        local oldPrefixLen = string.len(oldPrefix)
        name = string.sub(name, oldPrefixLen + 2)
    end

    plyChar:SetName(newPrefix .. " " .. name)
end