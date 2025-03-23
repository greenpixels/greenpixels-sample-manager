extends Window
class_name AddSourcePopup

@onready var file_dialog := %FileDialog
@onready var open_file_dialog_button := %OpenFileDialogButton
@onready var path_input := %PathInput
@onready var source_name_input := %SourceNameInput
@onready var submit_button := %SubmitButton

var source_name := "" :
	set(value):
		if not is_node_ready(): await ready
		source_name = value
		source_name_input.text = source_name
		_validate()
		
var source_path := "" :
	set(value):
		if not is_node_ready(): await ready
		source_path = value
		path_input.text = source_path
		_validate()
		
signal source_added(source_name: String, source_path: String)

func _ready() -> void:
	visibility_changed.connect(_validate)

func _validate():
	submit_button.disabled = source_name.strip_edges().is_empty() or source_path.strip_edges().is_empty() or not source_path.is_absolute_path()

func _on_open_file_dialog_button_pressed() -> void:
	file_dialog.visible = true

func _on_file_dialog_dir_selected(dir: String) -> void:
	source_path = dir

func _on_path_input_text_changed() -> void:
	source_path = path_input.text

func _on_source_name_input_text_changed() -> void:
	source_name = source_name_input.text

func _on_source_added(_source_name: String, _source_path: String) -> void:
	source_name = ""
	source_path = ""

func _on_submit_button_pressed() -> void:
	var current_source_path = source_path.strip_edges()
	var current_source_name = source_name.strip_edges()
	source_added.emit(current_source_name, current_source_path)
	close_requested.emit()
