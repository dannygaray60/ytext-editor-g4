extends Control

var Cnf = ConfigFile.new()

var opened_filepath : String

var lines_notes : Dictionary

var _moving_window : bool

var _drag_position : Vector2

var _config_path : String = "user://settings.ini"

@onready var TxtNotes := $MarginContainer/VBoxContainer/VSplitContainer/HBoxContainer/TextEditNotes
@onready var TxtEdit := $MarginContainer/VBoxContainer/VSplitContainer/TextEditField
@onready var TxtLineNote :=  $MarginContainer/VBoxContainer/HBoxContainer/LineEditLineNote

@onready var BtnSoundEnabled := $Panel/PanelContainer/HBoxContainer/BtnSound
@onready var BtnUppercase := $Panel/PanelContainer/HBoxContainer/BtnUppercase
@onready var BtnExtraLine := $Panel/PanelContainer/HBoxContainer/BtnExtraLine

@onready var sfx_write := $Audio/Write
@onready var sfx_space := $Audio/Space
@onready var sfx_newline := $Audio/NewLine
@onready var sfx_backspace := $Audio/BackSpace
@onready var sfx_move := $Audio/Move
@onready var sfx_save := $Audio/Save

func _ready() -> void:
	
	reset_fields_vars()
	
	Cnf.load(_config_path)
	var recent_file : String = Cnf.get_value("misc", "recent_file", "")
	if recent_file.is_empty() == false:
		open_file(recent_file)

#	var syntax = CodeHighlighter.new()
#	syntax.clear_color_regions()
#	syntax.clear_keyword_colors()
#	syntax.clear_member_keyword_colors()
#	syntax.add_color_region("(",")",Color.DIM_GRAY)
#	syntax.update_cache()
#	TxtEdit.syntax_highlighter = syntax

func _process(_delta: float) -> void:
	
	if _moving_window == true:
		DisplayServer.window_set_position(
			Vector2(DisplayServer.window_get_position()) + get_global_mouse_position() - _drag_position
		)
	
	if Input.is_action_just_pressed("save_file"):
		save_file()
	if Input.is_action_just_pressed("open_file"):
		open_file(opened_filepath)
	if Input.is_action_just_pressed("fullscreen"):
		_on_btn_win_action("max")

func _input(event: InputEvent) -> void:

	if event is InputEventKey and event.is_pressed() and BtnSoundEnabled.button_pressed == true:
		
		if (
			get_viewport().gui_get_focus_owner().name != "TextEditNotes"
			and get_viewport().gui_get_focus_owner().name != "TextEditField"
		):
			return
		
		match event.keycode:
			KEY_SPACE:
				sfx_space.play()
			KEY_ENTER, KEY_KP_ENTER:
				sfx_newline.play()
				## setear linea extra
				if (
					BtnExtraLine.button_pressed == true 
					and get_viewport().gui_get_focus_owner().name == "TextEditField"
				):
					TxtEdit.set_line(
						TxtEdit.get_caret_line(), TxtEdit.get_line(TxtEdit.get_caret_line())+"\n"
					)
					TxtEdit.set_caret_line(TxtEdit.get_caret_line()+1)
			KEY_BACKSPACE:
				sfx_backspace.play()
			KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
				sfx_move.play()
			KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_SHIFT:
				pass
			_:
				sfx_write.play()

func file_dialog_popup() -> void:
	get_node("%FileDialog").popup_centered(Vector2i(800,600))

func open_file(filepath:String) -> void:

	## guardar nuevo archivo
	if get_node("%FileDialog").file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		_save_to_file(filepath)
	
	## leer archivo
	else:
		close_file()
		var F := FileAccess .open(filepath, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			
			if filepath.get_extension() == "txt":
				TxtEdit.text = F.get_as_text()
		
			elif filepath.get_extension() == "ytxt":
				var ytxt : Dictionary = F.get_var()
				TxtEdit.text = ytxt["text"]
				TxtNotes.text = ytxt["notes"]
				lines_notes = ytxt["lines_notes"]

	## si todo salio OK
	if FileAccess.get_open_error() == OK:
		set_vars(filepath)

func save_file() -> void:
	
	if opened_filepath.is_empty() == true:
		get_node("%FileDialog").set_file_mode(FileDialog.FILE_MODE_SAVE_FILE)
		get_node("%FileDialog").current_file = "New YText File.ytxt"
		file_dialog_popup()
	
	else:
		_save_to_file(opened_filepath)

func close_file() -> void:
	reset_fields_vars()

func set_vars(filepath:String) -> void:
	
	if filepath.get_extension() == "ytxt":
		get_node("%BtnExportText").visible = true
	else:
		get_node("%BtnExportText").visible = false
	
	opened_filepath = filepath
	get_node("%LabelFileName").text = filepath.get_file()
	get_node("%BtnCloseFile").visible = true
	
	Cnf.set_value("misc", "recent_file", filepath)
	Cnf.save(_config_path)

func reset_fields_vars() -> void:
	get_node("%BtnExportText").visible = false
	get_node("%LabelFileName").text = "YText Editor"
	get_node("%BtnCloseFile").visible = false
	opened_filepath = ""
	lines_notes = {}
	TxtEdit.clear()
	TxtNotes.clear()
	_set_maintextfield_focus()

func restore_window_size() -> void:
	DisplayServer.window_set_size(Vector2i(1280,720))

func _set_maintextfield_focus() -> void:
	TxtEdit.grab_focus()

func _save_to_file(filepath:String) -> void:
	var F := FileAccess.open(filepath, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
	
		if filepath.get_extension() == "txt":
			F.store_string(TxtEdit.text)
	
		elif filepath.get_extension() == "ytxt":
			F.store_var({
				"notes": TxtNotes.text,
				"text": TxtEdit.text,
				"lines_notes": lines_notes
			})
		## todo salio OK
		set_vars(filepath)
		sfx_save.play()

func _on_btn_win_action(opt: String) -> void:
	match opt:
		"min":
			restore_window_size()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		"max":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				get_node("%BtnMinimize").visible = true
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				restore_window_size()
				DisplayServer.window_set_position(
					DisplayServer.screen_get_size() * 0.5 - DisplayServer.window_get_size() * 0.5
				)
			
			else:
				get_node("%BtnMinimize").visible = false
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		"close":
			get_tree().quit()


func _on_btn_move_window_button_down() -> void:
	_moving_window = true
	_drag_position = get_local_mouse_position()
func _on_btn_move_window_button_up() -> void:
	_moving_window = false

## se ha cambiado de linea
func _on_text_edit_field_caret_changed() -> void:
	var txt_line = TxtEdit.get_line(TxtEdit.get_caret_line())
	
	## si es la primera letra de la linea, ponerla en mayuscula
	if txt_line.length() == 1 and BtnUppercase.button_pressed == true:
		txt_line = txt_line.to_upper()
		TxtEdit.set_line(TxtEdit.get_caret_line(), txt_line)
	
	if txt_line.length() > 43:
		TxtEdit.add_theme_color_override("current_line_color", Color("8b00033b"))
	else:
		TxtEdit.add_theme_color_override("current_line_color", Color("ffffff1a"))
	
	## mostrar linenote
	if lines_notes.has(TxtEdit.get_caret_line()) == true:
		TxtLineNote.text = lines_notes[TxtEdit.get_caret_line()]
	else:
		TxtLineNote.clear()


func _on_btn_open_file_pressed() -> void:
	get_node("%FileDialog").set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
	file_dialog_popup()


func _on_btn_clear_line_note_pressed() -> void:
	TxtLineNote.text = ""
	if lines_notes.has(TxtEdit.get_caret_line()) == true:
		lines_notes[TxtEdit.get_caret_line()] = ""
		lines_notes.erase(TxtEdit.get_caret_line())
	_set_maintextfield_focus()

## actualizar nota de linea
func _on_line_edit_line_note_text_changed(new_text: String) -> void:
	if new_text.is_empty() == false:
		lines_notes[TxtEdit.get_caret_line()] = new_text


func _on_line_edit_line_note_text_submitted(_new_text: String) -> void:
	_set_maintextfield_focus()


## recorrer lineas multiples editadas
## y eliminar line note que esté relacionada a esa linea
##FIX aunque al hacer enter se desmadra todo sobre la conexion entre la nota y la linea
func _on_text_edit_field_lines_edited_from(from_line: int, to_line: int) -> void:
	for n in range(to_line,from_line+1):
		if (
			TxtEdit.get_line(TxtEdit.get_caret_line()).is_empty() == true
			and lines_notes.has(n) == true
		):
			lines_notes.erase(n)


func _on_btn_export_text_pressed() -> void:
	if opened_filepath.is_empty() == false:
		var exported_filepath : String = opened_filepath.get_basename() + "_export.txt"
		var F := FileAccess.open(exported_filepath, FileAccess.WRITE)
		if FileAccess.get_open_error() == OK:
				F.store_string(TxtEdit.text)
