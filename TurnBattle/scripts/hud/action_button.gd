extends PanelContainer


@onready var main_label: Label = $TextList/MainText
@onready var sub_label: Label = $TextList/SubText
@onready var button: Button = $ActionButton

var action_name: String
var detail_text: String


func setup(new_action_name: String, new_detail_text: String):
	#print("from setup")
	#print(new_action_name)
	#print(new_detail_text)
	main_label.text = new_action_name

	sub_label.text = new_detail_text
	sub_label.visible = new_detail_text != ""


func _ready():
	pass
	#if action_name:
		#main_label.text = action_name
	#if detail_text:
		#sub_label.text = detail_text
		#sub_label.visible = detail_text != ""
