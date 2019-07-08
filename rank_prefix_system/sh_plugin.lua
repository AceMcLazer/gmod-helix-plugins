local PLUGIN = PLUGIN

PLUGIN.name = "Rank Prefix System"
PLUGIN.author = "Xemon"
PLUGIN.description = "Rank system that add prefixes before the player's name."

ix.util.Include("sh_config.lua")
ix.util.Include("sh_message.lua")

function PLUGIN:InitializedPlugins()
    for k, v in pairs(categories) do
        if sql.TableExists("rank_prefix_system_" .. v) then return end

        local createTable = "CREATE TABLE rank_prefix_system_" .. v .. "(char INTEGER, rank INTEGER)"
        local createTable = sql.Query(createTable)
    end
end

function PLUGIN:OnCharacterCreated(client, char)
    if manageCharacter(true, char) then
        setName(char, "", ranksPrefix[prefixFactions[char:GetFaction()]][1])
    end
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

    return true
end

ix.command.Add("Promote", {
    description = "Promotes the given player by rank up.",
    privilege = "Rank System",
    arguments = {
        ix.type.character
    },
    OnRun = function(self, client, target)
        if updateRank(true, client, target) == false then
            client:SLChatMessage({Color(165, 173, 173), "[Rank System] ", Color(255, 255, 255), "You can't promote ", target:GetPlayer():Name(), "!"})
        end
    end
})

ix.command.Add("Demote", {
    description = "Demotes the given player by rank down.",
    privilege = "Rank System",
    arguments = {
        ix.type.character
    },
    OnRun = function(self, client, target)
        if updateRank(false, client, target) == false then
            client:SLChatMessage({Color(165, 173, 173), "[Rank System] ", Color(255, 255, 255), "You can't demote ", target:GetPlayer():Name(), "!"})
        end
    end
})

function updateRank(promote, client, target)
    local clientChar = client:GetChar()

    local clientCharID = clientChar:GetID()
    local targetID = target:GetID()

    local clientFaction = clientChar:GetFaction()
    local targetFaction = target:GetFaction()

    if !canUpdateRank(clientChar, clientCharID, clientFaction, target, targetID, targetFaction, promote) then return false end

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
        client:SLChatMessage({Color(165, 173, 173), "[Rank System] ", Color(255, 255, 255), "You succesfully promoted ", targetName, "! ", targetName, "'s new rank is ", newPrefix, "."})
    else
        client:SLChatMessage({Color(165, 173, 173), "[Rank System] ", Color(255, 255, 255), "You succesfully demoted ", targetName, "! ", targetName, "'s new rank is ", newPrefix, "."})
    end

    setName(target, oldPrefix, newPrefix)
end

function canUpdateRank(clientChar, clientCharID, clientFaction, target, targetID, targetFaction, promote)
    cantPromote = false

    local clientCategory = prefixFactions[clientFaction]
    local targetCategory = prefixFactions[targetFaction] 

    if (clientCategory == nil) or (targetCategory == nil) then
        cantPromote = true
    elseif clientCategory != targetCategory then
        cantPromote = true
    elseif clientCategory == targetCategory then
        local clientRank = "SELECT rank FROM rank_prefix_system_" .. clientCategory .. " WHERE char=" .. clientCharID
        local clientRank = sql.QueryValue(clientRank)
        local clientRank = tonumber(clientRank)

        local targetRank = "SELECT rank FROM rank_prefix_system_" .. targetCategory .. " WHERE char=" .. targetID
        local targetRank = sql.QueryValue(targetRank)
        local targetRank = tonumber(targetRank)

        if clientChar == target then
            if manageCharacter(true, target) then
                setName(target, "", ranksPrefix[targetCategory][1])
                clientRank = 1
                targetRank = 1
            end
        elseif targetRank == nil then
            if manageCharacter(true, target) then
                setName(target, "", ranksPrefix[targetCategory][1])
                targetRank = 1
            end
        elseif clientRank == nil then
            if manageCharacter(true, clientChar) then
                setName(clientChar, "", ranksPrefix[clientCategory][1])
                clientRank = 1
            end
        end

        if clientRank <= targetRank then
            cantPromote = true
        end

        if promote then
            if targetRank == #ranksPrefix[targetCategory] then
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