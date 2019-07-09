categories = {} -- add to this table every ranks' category which you want on your server!
categories[1] = "army" -- example
-- every next category must have higher index (2, 3, 4, 5...)

prefixFactions = {} -- add individual factions to any category made before
prefixFactions[FACTION_NAME] = "category" -- pattern
prefixFactions[FACTION_ARMY] = "army" -- example
-- You have to delete the above examples, because they trigger errors (if factions like: FACTION_ARMY or FACTION_NAME doesn't exist)

ranksPrefix = {} -- this is table with every ranks list
ranksPrefix["categoryName"] = { -- pattern
    "Prefix1",
    "Prefix2",
    "Prefix3",
    "Prefix4"
}
ranksPrefix["army"] = { -- example
    "Recruit",
    "Officer",
    "Captain",
    "General",
    "Admiral"
}

minRank = {} -- here you can set min rank for promoting/demoting
minRank["categoryName"] = "rankNum" -- pattern
minRank["army"] = 2 -- example