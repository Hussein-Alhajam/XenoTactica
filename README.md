# XenoTactica 
***A tactical, turn-based game with Xenoblade inspired combat***

## Explore a 2D World
Explore and interact with a 2D environment like in classic RPGs. Roam freely, speak with NPCs, and find secrets, but be prepared for adversary with enemies, traps, and puzzles.
  
## Turn Based Combat on a Grid
Combat occurs in a grid based arena separate from the open world exploration. Player characters and enemy units take actions in turns - the order determined by an unit's agility, which can change throughout a battle.  
On an unit's turn, they are able to take 1 movement action and 1 attack/item action. A movement action is done by moving the unit a limited number of grid tiles from their position, which is determined by their Stamina stat (?). An attack/item action is done by using any attack-based ability (Attack, Arts, Special), or by using any item.
  
## Xenoblade Chronicles 2 Inspired Combat Mechanics
An "unique" combat system new to the tactical genre. In Xenoblade Chronicles 2 (XC2), combat is live-action with unique *Driver Arts* and *Blade Specials* mechanics that enable synergistic effects and combos. This game takes the Arts and Specials mechanics and applies them to a turn based system. 
  
### Arts
Each (player controlled) character has a selection of three (3) Arts. Each Art has a different number of charge that needs to be filled before they can be used. Using Normal Attacks charges the Arts by one (1) each, and using Arts charges the other Arts by one (1) each. Arts have various effects; high damaging attacks with bonuses based on positioning, healing and buffs for characters, debuffs for enemies, and more. 

#### Reactions
Speaking of more, we cannot forget Xenoblade's iconic Break-Topple mechanic. XC2 (and other Xenoblade games) includes a powerful "Reaction" combo effect that allow you to control the flow of combat. For a simplied overview, all Reaction effects come from Arts; certain Arts have specific Reaction effects attached to them (e.g., an Art can have the 'Break' effect, while another Art can have the 'Topple' effect). 'Break' is an effect that can be applied to an enemy that lasts for a short duration. During the 'Break' duration, if a 'Topple' Art is used, the enemy will be aflicted with the 'Toppled' status, preventing any actions, for a short duration. Specific to XC2, using a 'Launch' Art will cause the enemy to be 'Launched' into the air, preventing any actions and increasing damage applied to them, for a short duration. Using a 'Smash' Art while the enemy is 'Launched' slams the enemy into the ground, applying heavy damage on them, ending the combo, and allowing it to be started again. In XenoTactica, instead of having the effects last for seconds, they will instead be based on turn durations.
  
### Speicals
Specials come in a group of four (4) for each character, refered to as Levels (i.e., Level 1 Special - Level 4 Special). Unlike Arts, the level of Special cannot be selected; instead, the character has a Special guage that is charged up by using Arts, and this guage determines what level Special is used when using a character's Special. For example, if the guage is charged to level 2, then a Level 2 Special will be used; you cannot select to use the Level 1 Special.

#### Special Combos 
Referred to as Blade Combos in XC2, this is a system tied in with the Spcials mechanic. In XC2 and this game, characters have a specific element tied to them (such as Fire, Water, or Ice); their Specials are based on this element. Because it's rather complicated (and not needed for this explanation), the Blade Combos specific to XC2 will be skipped; instead, only the Special Combos system of XenoTactica will be discussed; although there are of course many similarities. The Special Combo has three (3) stages. Using a Special initiates a Special Combo at stage 1 with the element of the character. You can advance the stages of a Special Combo by using a Special of the same level or higher - doing so will swap the current element of the Special Combo to the element of the Special used. With a stage 1 Special Combo, you can advance to stage 2 by using any Special that is level 2 or higher; with a stage 2 Special Combo, you can advance to stage 3 by using any Special that is level 3 or higher. For now, each stage of the Special Combo simply does an instance of damage, with each stage doing more damage, and the final stage ending the combo and applying effects depending on the element. For example, getting to a stage 3 Special Combo using a fire element Special (of level 3 or 4) will apply a burn damage over time effect on the enemy. The stages of a Special Combo only lasts for a few turns before the combo expires and must be started from the beginning; however, the entire party can contribute to the combo, so you build each character's Special level until you can use them back to back to quickly complete a Special Combo fully. 

##### Special Combo effects, Orbs, and Chain Attacks
This section talks about future mechanics that may be implemented. If you have played the Xenoblade games (and specifically XC2), you would know about Chain Attacks, Elemental Orbs, and the Blade Combo effects. Their explanation will be skipped because they won't be implemented yet, but these are all mechanics that are theoretically possible and would add more depth to the combat. The only mechanic here that may be implemented in the current iteration of XenoTactica would be the Special Combo effects. These would an unique effect for each element and would be applied when a Speical with that element is used to advance the Special Combo, with the strength of the effects varying depending on the combo stage. For example, the ice element could give a 10%/20%/30% reduction for stage 1/2/3 of the combo, respectively, to the opponents Art charge rate, slowing down how often they use their Arts. Only one element's effect will be active depending on what the combo is on; for example, with a stage 1 fire combo, using a ice Special that advances it to a stage 2 ice combo would overwrite the fire's damage over time, and apply the ice's slow Art charge. 

## Future Plans 
- Story / lore
- More areas to explore (goes along with story)
- More enemies 
- Swappable party and more characters that join you so party has members to swap
- Customizable character equipment (equip different weapons, arts, accessories, etc. to characters)
- Chain Attacks (mentioned above)
- 
## Unimplemented Features
*list anything we weren't able to implement*
