extends Resource

class_name Character

@export_group("Character Info")
@export var title: String # the name of the character
@export var icon: Texture2D
@export var char_texture: Texture2D

@export_group("Character Stats")
@export var strength: int # the 'general' damage that the character does
							# affects attacks, maybe affect art and special?
@export var ether: int # basically strength but for 'magic'
						# affects magic and healing arts?
@export var defense: int # protects against phyiscal
@export var resistance: int # protects against ether
@export var agility: int # affects how often the character can act
@export var element: String # fire/water/wind/electric/earth/ice/light/dark

@export_group("Abilities")
@export var arts_list: Array[CombatArt]
@export var specials_list: Array[CombatSpecial]

var special_charge: int = 0

var battle_scene: Node2D

func pass_battle_scene():
	for art in arts_list:
		art.battle_scene = battle_scene
	for special in specials_list:
		special.battle_scene = battle_scene


func charge_arts(num):
	for art in arts_list:
		art.charge_art(num)


func use_art(num):
	if arts_list[num].is_charged(): # duplicated in combat_art.gd, not sure which is better to get rid of
		charge_arts(1)
		arts_list[num].use_art() # could return bool from .use_art()?
		charge_special(1)
	else:
		battle_scene.update_action_log(arts_list[num].art_name + " is not charged")


func is_special_charged():
	return special_charge >= 4


func charge_special(num):
	# check if the special is not max charge (4)
	if not is_special_charged():
		# if it isn't, check whether adding the num will go over max charge
		if special_charge + num > 4:
			# if it does get over, simply set current charge to max
			special_charge = 4
		else: 
			# otherwise, add the num
			special_charge = special_charge + num
	# if it's already max charge, do nothing


func reset_special_charge():
	# reset the charge to 0
	special_charge = 0


func use_special():
	if special_charge > 0:
		specials_list[special_charge - 1].use_special()
		reset_special_charge()
	else:
		battle_scene.update_action_log("Special has no charge")
