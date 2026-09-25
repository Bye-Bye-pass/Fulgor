<h1 align="center">⚡ Fulgor</h1>

<p align="center">
  <b>Latin: "Fulgor" — flash, brightness, lightning</b><br>
  A modern, lightweight, fully original UI library for Roblox.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-FFD400?style=flat-square">
  <img src="https://img.shields.io/badge/license-MIT-FFD400?style=flat-square">
  <img src="https://img.shields.io/badge/theme-Volt-FFD400?style=flat-square">
  <img src="https://img.shields.io/badge/status-active-FFD400?style=flat-square">
</p>

---

## ⚡ Overview

**Fulgor** is a fully original, dependency-free UI library for Roblox, built from scratch in Luau.

- 🎨 **3 built-in themes** — Volt, Electric, Storm
- 🧩 **9 components** — Button, Toggle, Slider, Textbox, Dropdown, Label, Keybind, Section, Tab
- 🪶 **Zero dependencies** — no external assets required
- 🎯 **Drag-to-move window** with smooth tween animations
- 🔔 **Toast notification system**
- 🌗 **Live theme switching** at runtime

---

## 🚀 Quick Start

```lua
local Fulgor = loadstring(game:HttpGet("https://raw.githubusercontent.com/Bye-Bye-pass/Fulgor/main/Fulgor.luau"))()

local Window = Fulgor:CreateWindow({ Title = "My Script" })
local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("General")

Section:CreateButton("Click Me", function()
    Fulgor:Notify({ Title = "⚡ Fulgor", Content = "Hello, world!" })
end)
