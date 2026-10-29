Game Outline
============

I want to create a video game.
It will be 3D, using a game engine that is free for open source usage.
The game is an RPG/battle arena hybrid, a bit like a gauntlet or "trial" game.
Single player, no networking or multiplayer is needed.

Gameplay
--------

The gameplay involved entering an arena and defeating one or more enemies; once the enemies
are defeated a door or portal opens to allow you to move to the next arena.

The arenas should be selected from a variety of shapes eg. round, square, semicircular; 
with a variety of terrains, eg. grassy, snow, indoor castle, desert.

The enemies are chosen at random, and get harder as the player progresses up the levels. Every
10 levels there is a boss enemy which is much stronger than the normal enemies. Enemies
are various fantasy style creatues and monsters.

After defeating the boss, there is a "rest stop" arena where players can replenish items,
and purchase new weapons, accessories and spells.

Player Characters
-----------------

The player controls a party of 3 characters with different appearances. One character is
the party leader (but may be switched during play) and is directly controlled by the player.
The other characters follow in formation behind the party leader.
Camera is third person, hovering above the party leader to see an area of the battle arena.

Combat
------

Combat is a realtime/turn based hybrid. Each character chooses an action (either by automation
called "tactics" to be described later) or by direcly player input. The character then waits
a charging time depending on the action chosen, when the charge is complete they perform the action.
The loop then repeats. Enemies also follow the same process, but their actions are programmed by
automation only.

If the player selects an action for a character while another is charging, then the charge is cancelled
and the new action starts to charge; there is no credit for the partial charge.

Characters and enemies should move during the charging phase to remain within range of the target of the action.
The party leader can be moved manually by the player and this overrides the automatic movement temporarily.
Other characters only returns to their formation behind party leader if they are not charing or performing
an action.

Controls
--------
The game should use a gamepad for input (with keyboard for backup).
The left stick controls the party leader movement. The camera position is adjusted by the right stick.
The camera should "follow" the player and re-centre as they move.

Pressing left/right arrows should enter an enemy selection mode. Each press moves to the next enemy in
the arena placing a circle/cursor on them and displaying info at the top left of the screen.

Pressing up/down arrows enters a mode to change the party leader, each character is selected in turn
with the same circle/cursor. Pressing A will change the leader to the selected character. The camera should
snap to the new character and the mode should return to normal.

Pressing A will open the command selection window. A menu appears at the bottom left with the available
combat actions. Selection in this menu uses up/down arrows and A to confirm, B to cancel.
For actions that need a target, use the same circle/cursor, and up/down for selecting a character
or left/right for an enemy.

UI
--
The UI contains 3 main areas.

 * top left is the info area; this shows info about a selected enemy when in selection mode, or choosing
   a target in command mode.
 * bottom left is for the command selection window which only appears in this mode (after pressing A).
 * bottom right is the character info area. This area shows a grid with one row for each character, and
   rows for:
     * a small bar showing the name of the action being charged and it's progress - this changes color
       when the action is happening
     * Character's name
     * Character's hit points (HP)
     * Character's mana points (MP)
     * Any status effects shown with icons

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
None for now

Items
-----

* potion - restores 25% of the character's HP
* hi-potion - restores 50% of the character's HP
* revive - restores a KOed character to 25% HP

Status Effects
--------------
None for now

