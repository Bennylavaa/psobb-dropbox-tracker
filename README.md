## PSOBB DropBox Tracker Addon

DropBox Tracker is incredibly useful at showing exactly what an item drop contains and where it is so, you can efficiently run over and grab drops you care about without having to run over each and every drop.

_Some psobb clients may also have minimap dots for rare drops and even allow you to customize which drops show up (see mapitem.txt on Ephinea). This adds on top of that with a much more intuitive overlay on important drops!_

----
_Note: for Phantasy Star Online: Blue Burst_


### REQUIRED Pre-Requisite

This fork uses APIs not yet in the upstream Solybum plugin. Use **one** of these:

* **[Bennylavaa's psobbaddonplugin fork](https://github.com/Bennylavaa/psobbaddonplugin)** — has the required APIs merged in
* **[Bennylavaa v0.3.7.1 prebuilt release](https://github.com/Bennylavaa/psobbaddonplugin/releases/tag/v0.3.7.1)** — easiest install, no compile needed
* **[Solybum upstream + PR #27](https://github.com/Solybum/psobbaddonplugin/pull/27)** — if you want to apply the patch yourself
You will also need SolyLib from here: https://github.com/Solybum/PSOBBMod-Addons
_Ignore if you already have one of the above working._

* [PSOBB Base Addon installation help](https://github.com/Solybum/psobbaddonplugin?tab=readme-ov-file#installation)


### Installation
* Recommended Process: [Semi-Automatic Updating](./docs/Semi-Automatic_Updating.md)

 OR

* Quick Install:
    1. Download as a .zip file from Github.
        * Extract .zip

    2. Place "DropBox Tracker" folder inside the "addons" folder, which is same folder where all the other psobb addons are.
        * Note: all files; *init.lua*, *configuration.lua* must be inside "DropBox Tracker"
        * *options.lua* file should be created if you make a settings change to store them.


### Configuration
This is straight-forward if you're at all used to other psobb lua addons utilizing imgui.
- Load up the game, and join or create a party to, and enter into an easy combat zone where you're not likely to die.
- Press ` (*backtick char*) to open addon menu, if it isn't already.
    - This is typically the same key as ~ (*tilde key*) on the keyboard, directly below esc (escape key).
- Click "DropBox Tracker" on the Main Menu to bring up the configuration menu.
- Double click the "DropBox Tracker - Configuration" window to expand it fully, if it isn't already.
- You'll now see all the various options and can adjust the tracker size, position, and color and thickness you'd like each type of drop to have.


### Features

This fork extends the original DropBox Tracker with several quality-of-life features on top of the per-item-popup core:

* **Compact Layout** _(default-on)_ — icon on the left, name + stats + counts stacked on the right, surrounded by a colored window border. Toggled in *Tracker Main → Display → Compact Layout*. Per-tracker scale slider + per-item override.
* **Weapon equippability overlay** _(default-on)_ — reads PMT race flags + ATP/ATA/MST stat requirements and draws an X over weapons your current class can't equip:
    * **Red X** — race/archetype mismatch (permanent, can never equip)
    * **Grey X** — stat requirement not met (could equip after leveling)
* **Per-item icon images** — drop PNGs into `images/<folder>/` and they render in the popup, tinted with the category's color. Includes smart fallback chains so a single silhouette can cover many items:
    * **Weapons** map by class byte: `saber.png` / `gun.png` / `cane.png`
    * **Techs** map by technique ID: `foie.png` / `barta.png` / `zonde.png` / ... / `megid.png`
    * Generic fallbacks per folder: `weapon.png`, `armor.png`, `barrier.png`, `unit.png`, `mag.png`, `tech.png`, `consumable.png`, `misc.png`
    * Each category can also have its own PNG that takes priority over fallbacks
* **Inventory pressure indicators**:
    * `[INV FULL]` — appended when your bag is full
    * `[N/max]` — per-item-type stack count for stackable consumables
    * `[X/Y]` — global inventory slot usage on every label
* **Custom Watch List** — comma-separated hex IDs that get highlighted regardless of category rules. Useful for one-off niche drops.
* **Per-item visual controls**:
    * **Box Border Thickness** (0–20) — outline around the icon
    * **Compact Border Thickness** (0–10) — outline around the whole compact popup
    * **Custom Image Color** — tint the icon image independently from the box border
    * **Custom Compact Scale** — make specific item types bigger/smaller than the rest
* **Distance + debug toggles** — show distance-to-item and raw item hex + PMT data on each label.


### Customizing Icons

PNG files in `images/<folder>/` are auto-discovered. White silhouettes on transparent background work best — they tint cleanly with each category's configured color.

| Folder | What goes here |
|---|---|
| `weapons/` | `saber.png`, `gun.png`, `cane.png` (by class), or `weapon.png` (generic), or `rareweapon.png`/`esweapon.png`/etc. (per category) |
| `techs/` | `foie.png`, `barta.png`, `zonde.png`, `grants.png`, `megid.png`, `shifta.png`, `resta.png`, etc. (one per tech), or `tech.png` (generic) |
| `armor/` | `armor.png` (generic frames), `barrier.png` (generic barriers), or per-category overrides |
| `units/` | `unit.png` (generic), or per-category overrides |
| `mags/` | `mag.png` |
| `consumables/` | `monomate.png`, `trifluid.png`, `staratomizer.png`, `hpmat.png`, etc. (one per consumable), or `consumable.png` (generic) |
| `misc/` | `meseta.png`, `musicdisk.png`, `clairesdeal.png`, `customwatch.png`, or `misc.png` (generic) |


### Demo
_Click each Image to Watch_

![alt text](./img/demo2.gif)
![alt text](./img/demo1.gif)


### Credits

* **X9Z0.M2** — original DropBox Tracker
* **Soly / Solybum** — `solylib` shared helpers
* **Bennylavaa** — fork of the addon plugin that exposes the APIs this version depends on
* This fork — extended compact layout, equippability overlay, dynamic icon fallback chains, per-category visual controls
