# Spin & Survive

A Roblox base-defense game. Everyone in the server shares the same wave
timer. When a wave starts, you can **opt in** (your base fights and can earn
currency and take damage) or **opt out** (a shield bubble goes up around
your base — zombies ignore you, your turrets go idle, and you're safe but
earn nothing that wave). Survive to earn coins, spend them on luck-weighted
wheel spins to unlock better weapons and turrets, and buy permanent Luck
upgrades that shift the odds toward rarer spins.

## Core loop

1. Join the server and get assigned one of 6 base plots.
2. Every ~20s a wave countdown starts; zombies spawn at the map's edge and
   walk toward opted-in players' base cores.
3. Kill zombies with your equipped hand weapon (left-click, hitscan) and
   your equipped turrets (up to 4 slots, auto-fire) to protect your core.
4. Survive time and kills earn coins; clearing a wave pays a bonus and
   heals your core.
5. Spend coins on Bronze/Silver/Gold wheels for weapons, turrets, bonus
   coins, or Luck — or buy Luck upgrades directly. Luck shifts wheel odds
   away from Common rewards toward Rare/Epic/Legendary.
6. Repeat with better gear and better odds.

## Project layout

This is a [Rojo](https://rojo.space/) project — plain-text Luau, synced
into Roblox Studio rather than edited there.

```
src/
  ReplicatedStorage/Modules/   Shared data: Config, WeaponData, DefenseData,
                                ZombieData, WheelData, Rarity, RemoteDefinitions
  ServerScriptService/Server/  All game logic and authority:
                                PlotManager, ZombieAI, TurretController,
                                CurrencyService, WaveManager, EquipmentService,
                                WheelService, DataService, init.server.luau
  StarterPlayer/StarterPlayerScripts/Client/
                                HUD, ShopUI (wheels + luck), EquipUI
                                (weapon/turret loadout), WeaponController
                                (click-to-fire), GameState, init.client.luau
```

Plots, turrets, and zombies are all built procedurally from Parts at
runtime — no pre-made Studio models or custom assets are required to run
the game.

## Running it

1. Install [Aftman](https://github.com/LPGhatguy/aftman) (or Rojo directly)
   and run `aftman install` in this directory to get the pinned Rojo version.
2. Install the [Rojo Studio plugin](https://create.roblox.com/store/asset/13916111004).
3. `rojo serve` in this directory, then connect from the Rojo plugin in
   Studio, or `rojo build -o SpinAndSurvive.rbxl` to produce a place file
   directly.
4. Play-test with multiple clients (Studio's "Start Server + N Players")
   to see the shared wave and opt-in/opt-out behavior.

## Tuning the game

Nearly every number — wave pacing, zombie stats, weapon/turret stats, wheel
costs and odds, Luck's effect on those odds — lives in
`src/ReplicatedStorage/Modules/`. Add a new weapon, turret, zombie type, or
wheel tier by adding an entry to the matching `*Data.luau` list; nothing
else needs to change.

## Data & persistence

`DataService` (server) stores each player's currency, Luck, owned/equipped
weapons and turrets in a Roblox `DataStore`, autosaving periodically and on
leave. This is a single-server MVP implementation (no cross-server session
locking) — fine for a single running server, but worth swapping for a
proper session-locked data library (e.g. ProfileService) before running
multiple servers off the same DataStore key space.

## Suggested next steps

- Swap the Part-based zombies/turrets for real rigged models and animations.
- Add PathfindingService so zombies path around obstacles instead of
  walking straight at the core.
- Add a real spin animation/wheel graphic in `ShopUI` instead of the text
  result flash.
- Session-locked data storage (ProfileService or similar) for multi-server
  safety.
