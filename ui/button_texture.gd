extends TextureButton


var Cnf = ConfigFile.new()
var _config_path : String = "user://settings.ini"

@export var play_sfx : bool = true
@export var setting_key : String

@onready var sfx_pressed := $AudioPressed

func _ready() -> void:
	if toggle_mode == true:
		button_pressed = Cnf.get_value("options", setting_key, button_pressed)
		_on_toggled(button_pressed)

func _on_mouse_entered() -> void:
	if toggle_mode == false:
		modulate = Color.GRAY
func _on_mouse_exited() -> void:
	if toggle_mode == false:
		modulate = Color.WHITE


func _on_pressed() -> void:
	if play_sfx == true:
		sfx_pressed.play()


func _on_toggled(btn_pressed: bool) -> void:
	if toggle_mode == true:
		var err_cnf = Cnf.load(_config_path)
		if err_cnf == OK and setting_key.is_empty() == false:
			Cnf.set_value("options", setting_key,btn_pressed)
			Cnf.save(_config_path)
		
		if btn_pressed == true:
			modulate = Color.WHITE
		else:
			modulate = Color.DIM_GRAY
