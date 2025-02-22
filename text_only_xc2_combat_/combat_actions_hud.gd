extends CanvasLayer

var is_arts_selected # make into FSM
var arts	 # should arts and specials be its own node?
var specials_list
# need better way to change text on the labels
var texts

# make this into its own node?
class Art extends Node:
	var art_name
	var damage # affects damage / healing of art
	var position_effect # bonus front/back/side dmg
	var aoe # num representing range of attack's effect (e.g., 2 means it hits 2x2 grid)
	var type # damaging / healing / buff / debuff
	
	var current_charge = 0
	var max_charge

	func _init(new_name: String = "", new_damage: float = 0, 
		new_effect: String = "none", new_aoe: float = 0, 
		type: String = "damage", new_max_charge: int = 1):
		self.art_name = new_name
		self.damage = new_damage
		self.position_effect = new_effect
		self.aoe = new_aoe
		self.type = type
		self.max_charge = new_max_charge

	func set_art_name(new_name):
		self.art_name = new_name

	func set_damage(new_damage):
		self.damage = new_damage

	func set_position_effect(new_effect): #:= "none", default to none?
		self.position_effect = new_effect

	func set_type(new_type): # default to damage?
		self.type = new_type

	func set_aoe(num := 1): 
		self.aoe = num

	func set_max_charge(charge_num):
		self.max_charge = charge_num

	func charge_art(num):
		if not is_charged():
			if self.current_charge + num > self.max_charge:
				self.current_charge = self.max_charge
			else:
				self.current_charge = self.current_charge + num

	func is_charged():
		return self.current_charge == self.max_charge
	
	func use_art():
		print("art " + str(self.art_name) + " used \n Charged Special Level")

		self.current_charge = 0


# make this into its own node?
class Special extends Node:
	var special_name

	var damage # affects damage of special
	var element # element that special applies (maybe just have this be part of character - or inheirhet element from character)
	var aoe # num representing range of attack's effect
	var healing # a bool or num determining how much the special heals for

	func _init(new_name: String = "", new_damage: float = 0 ,new_element: String = "fire", new_aoe: float = 0, new_healing: float = 0):
		self.special_name = new_name
		self.damage = new_damage
		self.element = new_element
		self.aoe = new_aoe
		self.healing = new_healing
	
	func set_special_name(new_name):
		self.special_name = new_name

	func set_damage(new_damage):
		self.damage = new_damage

	func set_element(new_element):
		self.element = new_element

	func set_aoe(num):
		self.aoe = num

	func set_healing(num):
		self.healing = num

	func use_special():
		print("special " + str(self.special_name) + " used")

# make this into its own node?
class SpecialList extends Node:
	var specials_list
	
	var current_charge = 0

	func set_specials(): # pass list of specials?
		# hard coded list for now
		# need some way to set it up so we can give each character their own specials
		var special1 = Special.new("chroma dust", 10, "light", 1, 0)
		var special2 = Special.new("photon edge", 15, "light", 3, 0)
		var special3 = Special.new("lightning buster", 25, "light", 2, 0)
		var special4 = Special.new("sacred arrow", 50, "light", 3, 0)
		self.specials_list = [special1, special2, special3, special4]

	func add_special_charge(num):
		# unlike arts, all specials have 4 charges/stages
		if self.current_charge < 4:
			if self.current_charge + num > 4:
				self.current_charge = 4
			else: 
				self.current_charge = self.current_charge + num

	func use_special():
		if self.current_charge > 0:
			self.specials_list[self.current_charge - 1].use_special()
			self.current_charge = 0
		else: 
			print("no special charge")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	texts = [$UpText, $LeftText, $DownText, $RightText] 
	
	test_init()
	
	update_text(0, "Items")
	update_text(1, "Special " + str(specials_list.current_charge))
	update_text(2, "Arts")
	update_text(3, "Attack")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if not is_arts_selected:
		if Input.is_action_just_pressed("attack"):
			$ActionText.text = "Used Attack \n Arts Charged by 1"
			charge_arts(1)
			# charge arts
		if Input.is_action_just_pressed("special"):
			use_special()
		if Input.is_action_just_pressed("items_selection"):
			$ActionText.text = "entered items selection \n (not implemented)"
		if Input.is_action_just_pressed("arts_selection"):
			$ActionText.text = "entered arts selection"
			is_arts_selected = true
			
		update_text(0, "Items")
		update_text(1, "Special " + str(specials_list.current_charge))
		update_text(2, "Arts")
		update_text(3, "Attack")

	else:
		if Input.is_action_just_pressed("left_art"):
			use_art(0)
		if Input.is_action_just_pressed("up_art"):
			use_art(1)
		if Input.is_action_just_pressed("right_art"):
			use_art(2)

		if Input.is_action_just_pressed("arts_back"):
			$ActionText.text = "exited arts selection"
			is_arts_selected = false

		update_text(0, str(arts[1].art_name) + " " + str(arts[1].current_charge) + "/" + str(arts[1].max_charge))
		update_text(1, str(arts[0].art_name) + " " + str(arts[0].current_charge) + "/" + str(arts[0].max_charge))
		update_text(2, "Exit Arts")
		update_text(3, str(arts[2].art_name) + " " + str(arts[2].current_charge) + "/" + str(arts[2].max_charge))


func test_init():
	var art1 = Art.new("anchor shot")
	var art2 = Art.new("spinning edge")
	var art3 = Art.new("sword bash")
	art1.set_max_charge(5)
	art2.set_max_charge(4)
	art3.set_max_charge(3)

	arts = [art1, art2, art3]
	
	specials_list = SpecialList.new()
	specials_list.set_specials()


func use_art(num):
	if arts[num].is_charged():
		charge_arts(1)
		arts[num].use_art()
		
		#charge special
		specials_list.add_special_charge(1)

	else:
		$ActionText.text = "art " + str(arts[num].art_name) + " not charge"


func charge_arts(num):
	for art in arts:
		art.charge_art(num)


func use_special():
	specials_list.use_special()


# need better way to change text on labels, this is very hard coded
func update_text(num, new_text):
	texts[num].text = new_text
