extends Resource

class_name CombatArt

@export var art_name: String
@export var power: float # scales the str/eth of char; affects damage / healing of art
@export var num_hits: int # number of hits of the art
@export var hit_ratio: Array[float] # the % of 'damage' the i hit does
@export 	var position_effect: String # bonus front/back/side dmg
@export var aoe: int # num representing range of attack's effect (e.g., 2 means it hits 2x2 grid)
#@export var aoe: float # use a l-system type approach to determing the 'aoe/range' of an attack
							# if we can get the position (the 1x1 cell) of the attack and it's direction
							# then we can determine the aoe usinig relatve directions
							# e.g., r = right, l = left, w = walk/foward, s = back to start position, h = hit (mark cell as part of attack)
							# e.g., aoe = "lwhrwhwhsrwhlwhwh" 
								# gives something like	x o x, where x is cell that attack hits
								#						x o x, o is no hit
								#					   	x 0 x, 0 is start position and no hit
							# this allows the attack to easily rotate 
							# biggest 'hurdle' of this would be to create the function to interpret the string
								# could use a num at the start of the string which represents size of matrix (if using matrix?)
@export var attribute: String # damaging / healing / buff / debuff
@export var reaction: Array[String]
@export var current_charge: int 
@export var max_charge: int

var battle_scene: Node2D


func is_charged():
	return current_charge >= max_charge


func charge_art(num):
	# check if the art is not charged
	if not is_charged():
		# if it isn't, check whether adding the num will go over max charge
		if current_charge + num > max_charge:
			# if it does get over, simply set current charge to max
			current_charge = max_charge
		else: 
			# otherwise, add the num
			current_charge = current_charge + num
	# if it's already max charge, do nothing
	#else:
		#print(art_name + " is fully charged")


func reset_charge():
	# reset the charge to 0
	current_charge = 0


func use_art():
	if is_charged(): # duplicated in character.gd, not sure which is better to get rid of 
		reset_charge()
		#print(art_name + " art used")
		battle_scene.update_action_log(art_name + " art used")
	else:
		battle_scene.update_action_log(art_name + " is not charged")

#func use_art(enemy: Node): ?
	#reset_charge()
	# calculate and do damage to enemy
	# emit signal to charge special?
	#print(art_name + "art used, charged special")
