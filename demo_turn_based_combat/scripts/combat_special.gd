extends Resource

class_name CombatSpecial

@export var special_name: String

@export_group("Damage")
@export var power: float # scales the str/eth of char; affects damage / healing
@export var num_hits: int # number of hits of the art
@export var hit_ratio: Array[float] # the % of 'damage' the i hit does
@export var attribute: String # physical/ether 

@export_group("Effects")
@export var aoe: int # num representing range of attack's effect (same as in art)
@export var heal_ratio: float # if special heals, ratio of damage that it heals
@export var affect_team: bool # if any effects affect the team or just self

#@export_group("VFX & SFX")
#@export var attack_animation: Sprite2D
#@export var sound_effect: 

var battle_scene: Node2D


func use_special(): # pass enemy: Node or something?
	#print(special_name + " special used")
	Global.battle_scene.update_action_log(special_name + " special used")
	# calculate and do damage to enemy
