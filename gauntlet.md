Game Outline
============

I want to create a video game.
It will be 3D, using a game engine that is free for open source usage.
The game is an RPG/battle arena hybrid, a bit like a gauntlet or "trial" game.
Single player, no networking or multiplayer is needed.

**Engine:** Godot 4.7 (GDScript)

Gameplay
--------

The gameplay involved entering an arena and defeating one or more enemies; once the enemies
are defeated a glowing portal opens near the north wall. Walking the party leader into the
portal advances to the next arena.

The arenas should be selected from a variety of shapes eg. round, square, semicircular;
with a variety of terrains, eg. grassy, snow, indoor castle, desert. (Currently only a square
grassy arena is implemented.)

The enemies are chosen at random, and get harder as the player progresses up the levels.
Enemy HP, strength, defense, and speed scale with the current level. The number of enemies
also increases with level (capped at 4 per arena). Every 10 levels there is a boss enemy
which is much stronger than the normal enemies (not yet implemented). Enemies
are various fantasy style creatures and monsters.

After defeating the boss, there is a "rest stop" arena where players can replenish items,
and purchase new weapons, accessories and spells (not yet implemented).

Between levels, the party is partially healed (25% of max HP) and all items are replenished
to their maximum counts.

If all three party members are defeated, a "GAME OVER" message is displayed and the game
restarts at level 1 after a 3-second delay.

Player Characters
-----------------

The player controls a party of 3 characters with different appearances. One character is
the party leader (but may be switched during play) and is directly controlled by the player.
The other characters follow in formation behind the party leader.
Camera is third person, hovering above the party leader to see an area of the battle arena.

Combat
------

Combat is a realtime/turn based hybrid. Each character chooses an action (either by automation
called "tactics" to be described later) or by directly player input. The character then waits
a charging time depending on the action chosen, when the charge is complete they perform the action.
The loop then repeats. Enemies also follow the same process, but their actions are programmed by
automation only.

If the player selects an action for a character while another is charging, then the charge is cancelled
and the new action starts to charge; there is no credit for the partial charge.

After a character's attack action completes, if the target is still alive, the character automatically
begins charging attack on the same target again. This auto-repeat is cancelled if the player opens
the command menu or manually cancels the charge.

Characters and enemies should move during the charging phase to remain within range of the target of the action.
The party leader can be moved manually by the player and this overrides the automatic movement temporarily.
Other characters only returns to their formation behind party leader if they are not charging or performing
an action.

When a character or enemy begins charging an action, a coloured arc is drawn between the attacker and
the target — blue for player characters attacking, orange for enemies, green for item usage. The arc
fades out over 2 seconds.

All party members (including the leader) follow their configured tactics whenever they are idle.
The default tactic for every character is "Enemy - Closest → Attack". Manual commands issued to
the party leader via the command menu take precedence — tactics only fire when the leader is idle.
Moving the leader with the left stick overrides the automatic charge movement temporarily.

Controls
--------
The game should use a gamepad for input (with keyboard for backup).

| Action | Gamepad | Keyboard |
|--------|---------|----------|
| Move party leader | Left stick | WASD |
| Camera orbit | Right stick | IJKL |
| Confirm (A) | Cross | Enter |
| Cancel (B) | Circle | Backspace |
| Enemy select next/prev | D-pad left/right | Left/right arrows |
| Leader switch next/prev | D-pad up/down | Up/down arrows |
| Open main menu | Triangle | M |
| Tactics: switch character | L1 / R1 | Q / E |
| Quit game | — | Escape |

The camera follows the party leader with smooth exponential interpolation and a raised pivot
point to avoid floor clipping. When the player moves, the camera drags behind the movement
direction. The right stick (or IJKL) can manually orbit the camera; it auto-recentres when
the player moves.

Pressing left/right enters enemy selection mode. Each press moves to the next enemy in
the arena placing a circle/cursor on them and displaying info at the top left of the screen.

Pressing up/down instantly switches the party leader to the next/previous alive character.
The camera glides smoothly to the new leader. The leader's row in the character info panel
is highlighted with a blue background.

Pressing A opens the command selection window. A menu appears at the bottom left with the
available combat actions. Selection in this menu uses up/down and A to confirm, B to cancel.
The game pauses while the menu is open. The menu stays open (showing the selected action
highlighted in green) while choosing a target. For actions that need a target, use the
circle/cursor — left/right for enemies, up/down for party members.

UI
--
The UI contains 4 main areas.

 * top left is the info area; this shows info about a selected enemy when in selection mode, or choosing
   a target in command mode.
 * top right shows the current level number.
 * bottom left is for the command selection window which only appears in this mode (after pressing A).
   The menu supports submenus (e.g. Item opens a list of available items with counts).
 * bottom right is the character info area. This area shows one horizontal row per character with:
     * a small bar showing the name of the action being charged and its progress — yellow while
       charging, green while the action is executing
     * Character's name (cyan for the party leader, yellow with ">" prefix when selected as target)
     * Character's hit points (HP) — text overlaid on the bar
     * Character's mana points (MP) — text overlaid on the bar
     * The party leader's row has a blue-tinted background highlight
     * Any status effects shown with icons (not yet implemented)

Additionally:
 * A "GAME OVER" message appears in the centre of the screen when all party members are defeated,
   restarting at level 1 after a 3-second delay.
 * Billboarded HP bars float above each character (blue) and enemy (orange) in the 3D world.
 * Floating damage numbers appear above targets when hit — blue for damage to enemies, orange for
   damage to characters, green with a "+" prefix for healing.

Character Stats
---------------

Characters have the following stats:
* hit point (HP)
* mana points (MP)
* strength (STR)
* defense (DEF)
* agility (AGL)
* luck (LCK)

Characters also have a level (LVL) and experience (EXP).
Characters have skill points (SP) they can spend to learn new skills.

Experience & Levelling
----------------------

Characters earn EXP in two ways:
* **Killing blow** — the character who lands the killing blow on an enemy earns
  EXP equal to 10 x the enemy's level
* **Arena clear bonus** — when the party advances through the portal, all alive
  party members earn EXP equal to 15 x the arena level

EXP needed to level up: 50 x level^1.5 (e.g. level 1→2 needs 50, level 2→3 needs 141,
level 3→4 needs 260, etc.)

On level up, the character's stats increase by fixed growth rates that differ per
character, and they are fully healed (HP and MP restored to max).

| Stat Growth | Hero | Warrior | Mage |
|-------------|------|---------|------|
| HP          | +12  | +15     | +8   |
| MP          | +4   | +2      | +8   |
| STR         | +3   | +4      | +1   |
| DEF         | +2   | +3      | +1   |
| AGL         | +2   | +1      | +3   |
| LCK         | +1   | +1      | +2   |

A "LEVEL UP!" floating number appears above the character in yellow when they level up.
The character info panel shows each character's level next to their name and an EXP bar
showing progress toward the next level.

Every level gained, the character gets 5 skill points (SP) to spend.

Combat Actions
--------------

The combat actions are:
* attack - use the character's weapon to attack the enemy (info about weapons and damage later)
* magic - opens a submenu (info about all spells later)
  * red magic - offensive magic
  * green magic - healing and protective magic
  * blue magic - status effects and debuffs
  * arcane magic - top tier ultimate spells
* item - use an item (all items later)

Weapons & Attacking
-------------------

Characters each get one weapon and all start with a dagger.
The dagger is a close range weapon and has a low power (POW) stat.
Other weapons have higher power stats.

Magic
-----
See [magic.md](docs/magic.md)

Elements
--------
Some enemies have elemental affinity. This means they might be resistant to a particular
element (dealing half damage), or even absorb that element (damage heals instead). Enemies may also have a weakness for a specific element, causing it to do 1.5x damange.

The elements are earth, water/aqua, lightning/thunder, fire, air/aero and ice/blizzard.
(Some elements have slightly different names when naming spells).
They come in opposed pairs:
* earth <-> air
* water <-> lightning
* fire <-> ice

Items
-----

Items are used via the command menu's Item submenu. The player selects an item, then selects
a party member to use it on. The character charges the item use (twice as fast as an attack)
and a green arc is shown between the user and the target.

Items are replenished to their maximum counts after advancing to the next arena.

* potion (x3) - restores 25% of the character's HP
* hi-potion (x1) - restores 50% of the character's HP
* revive (x1) - restores a KOed character to 25% HP; the character reappears at the
  location where they were defeated

Status Effects
--------------
None for now

Main Menu
---------
The main menu, opened by "X"/Triangle (playstation), or "M" on the keyboard.
It shows the characters with their stats on the right, and the menu entries 
on the left.

Show the following entries:
 * Tactics - open tactics editor
 * Skills - open the skill grid


Tactics - Character "AI"
------------------------

Each character has a set of tactics that the player can set.
A tactic is a condition and action pair. They are evaluated from top
to bottom whenever a character needs to pick their next action.
The first condition that is satisfied causes that action to be chosen.
Conditions also have an implied target; for example, "Enemy - Closest" 
implicitly targets the closest enemy, and "Ally - HP < 50%" implicily
targets the party member with less than 50% HP.

There is a menu entry for customising tactic in the main menu.
When selected, it opens the tactics editor.

The editor shows the list of tactics as a grid, for now with 5 rows; all initially are
empty. A cursor points to one of the cells of this grid and can be moved with the d-pad
(or keyboard equivalent). A/Cross will select the current cell and perform an action.

Each row has 3 columns:
 1. an on/off toggle - selecting will toggle this row (off rows are skipped when selecting
    actions)
 2. the condition - selecting this will open a submenu to choose a condition
 3. the action - selecting will open a submenu to choose an action

B/Circle returns to the main menu.

The tactics menu also shows the current character being edited, and the shoulder buttons
(L1/R1 on playstation, and Q/E on keyboard) can be used to switch between characters.

Tactics - Conditions
--------------------

Conditions are as follows:
* Enemy - Any: triggers is any enemy is detected, selects one at random
* Enemy - Closest: triggers if an enemy is detected, selects the closest
* Enemy - Party Leader Target: triggers if the part leader is targetting an enemy
    and targets the same enemy

* Ally - KO: ally has 0 hp
* Ally - HP < 75%: ally less than 75% HP
* Ally - HP < 50%: ally less than 50% HP
* Ally - Any: trigger if any ally makes sense for the selected action (see the
  note about implicit conditions in the Tactics - Actions heading)

For Enemy condition, color the whole row in pale red; for Ally conditions use
pale blue. Rows that are toggelled off (or have no condition set) use Gray.

Tactics - Actions
-----------------

Actions are as follows:
* Attack - use the attack action
* Item: <item> - one action per item in the game, uses the specific item

Some actions also include an implicit condition which is AND-ed with the
chosen condition. For example, items like potions will not be used
if the target already has 100% HP; item like revive (not implemented yet) will not
get used if the character is not KO'ed (0 HP). Items will only be selected for
use if the pary has enough in inventory.

Skills
------

See [skill grid](docs/skills.md)

Remaining TODOs
===============

Combat & Actions
----------------
* Magic system — red/green/blue/arcane spell schools (Fire implemented as MVP:
  Mage only, 10 MP cost, 2.5s charge, ranged, 2x STR + 1.5x level damage,
  fire projectile visual, red targeting arc)
* More spells for each school
* Status effects — buffs, debuffs, icons in character info area
* More weapon types with different POW stats and ranges
* Character stats screen in main menu (stats on right side)

Arenas & Progression
--------------------
* Multiple arena shapes (round, square, semicircular)
* Multiple terrain types (grassy, snow, indoor castle, desert)
* Boss enemies every 10 levels (much stronger than normal)
* Rest stop arena after boss (replenish items, purchase weapons/accessories/spells)
* Arena variety selection (random or sequential)

Tactics
-------
* More conditions (e.g. "Enemy - Weakest", "Ally - Being Targeted")
* More actions as they are added (spells, defend, etc.)
* Save/load tactic configurations

Visual & Audio
--------------
* Low-poly character and enemy models (currently colored capsules)
* Attack/hit/death animations
* Sound effects and background music
* Particle effects for attacks, healing, portal
* Arena environment decoration (trees, rocks, torches, etc.)

UI & Polish
-----------
* Main menu character stats panel (right side)
* Damage/heal number animations (scale bounce, etc.)
* Screen shake on hits
* Battle start/end transitions
* Save/load game state