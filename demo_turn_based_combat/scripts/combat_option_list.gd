extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 'control label container'
# 	vbox (or other container) which contains a group title
# 	and radio buttons below, each radio button is 
# 	(circle, text). pass the func a array of string 
# 	(i.e., combat actions like move, attack, pass; attack
# 	options like normal attack, select arts, use special;
# 	arts like art1, art2, art3)
