-- Fulgor Loader - Sample Script
local Fulgor = loadstring(game:HttpGet("https://raw.githubusercontent.com/Bye-Bye-pass/Fulgor/main/Fulgor.luau"))()

local Window = Fulgor:CreateWindow({
    Title = "Fulgor Demo",
    Theme = "Volt",
})

-- Tab 1: Main
local MainTab = Window:CreateTab("Main")
local Actions = MainTab:CreateSection("Actions")

Actions:CreateButton("Show Notification", function()
    Fulgor:Notify({
        Title = "⚡ Fulgor",
        Content = "This is a sample notification!",
        Duration = 3,
    })
end)

Actions:CreateToggle("Auto Run", false, function(state)
    print("AutoRun:", state)
end)

Actions:CreateSlider("Speed", 0, 100, 50, function(v)
    print("Speed:", v)
end)

-- Tab 2: Settings
local SettingsTab = Window:CreateTab("Settings")
local ThemeSection = SettingsTab:CreateSection("Theme")

ThemeSection:CreateButton("Volt", function() Fulgor:SetTheme("Volt") end)
ThemeSection:CreateButton("Electric", function() Fulgor:SetTheme("Electric") end)
ThemeSection:CreateButton("Storm", function() Fulgor:SetTheme("Storm") end)
