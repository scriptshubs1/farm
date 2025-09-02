local from,to;
local db = require(game.ReplicatedStorage.Fsys).load("InventoryDB")
local inv = require(game.ReplicatedStorage.ClientModules.Core.ClientData)
local rarity = { "legendary","ultra_rare", "rare","uncommon","common",}
local function change()
    for i, v in pairs(inv.get_data()[game.Players.LocalPlayer.Name].inventory.pets) do
        if v.kind == from then
            v.kind = to
            v.id = to
        end
    end
end
local function pets()
    local p = {}
    local d = {}
    local ids_to_name = {}
    for _,rar in pairs(rarity) do
        table.insert(p, "-- "..rar.." --")
        for i,v in pairs(db.pets) do
            if v.rarity == rar then 
                table.insert(p, v.name)
                d[v.name] = i
                ids_to_name[i] = v.name
            end
        end
    end
    return p, d, ids_to_name
end
local all, all_ids, ids_to_name = pets()
local function f_inv()
    local f = {}
    local f_ids = {}
    for i, v in pairs(inv.get_data()[game.Players.LocalPlayer.Name].inventory.pets) do
        table.insert(f, ids_to_name[v.id])
        print(ids_to_name[v.id])
        f_ids[ids_to_name[v.id]] = v.id
    end
    return f, f_ids
end
local f,f_ids = f_inv()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()
local gui = Library:create{
    Name = "Adopt me changer | !jsp",
    Size = UDim2.fromOffset(600, 400),
    Theme = Library.Themes.Dark,
    Link = "https://github.com/!jsp/adopt_me"
}

gui:Credit{
	Name = "renardofficiel1 | !jsp",
	Description = "made this script",
	Discord = "renardofficiel1"
}
local Tab = gui:Tab{
	Name = "Change_pets",
	Icon = "rbxassetid://8569322835"
}
Tab:dropdown({
    Name = "From",
    StartingText = "N/A",
    Items = f,
    Description = "Select the pet you want to change",
    Callback = function(v)
        from = f_ids[v]
    end,
})
Tab:dropdown({
    Name = "To",
    StartingText = "N/A",
    Items = all,
    Description = "Select the pet you want to have",
    Callback = function(v)
        to = all_ids[v]
    end,
})
Tab:Button{
	Name = "Change",
	Description = nil,
	Callback = function() change() gui:Notification{
	Title = "Notification",
	Text = "Pet changed!",
	Duration = 3,
    }
end
}
