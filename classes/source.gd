extends Resource
class_name Source

@export_storage var source_path := ""
@export_storage var source_name := ""
@export_storage var is_recursive := true
@export_storage var found_audio_file_paths : Array[String] = [] 

func _init(_source_path : String, _source_name : String) -> void:
	source_name = _source_name
	source_path = _source_path

func create_component():
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label_button = Button.new()
	label_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var delete_button = Button.new()
	delete_button.pressed.connect(func(): _handle_delete(container))
	label_button.text = source_name
	delete_button.text = "✖"
	container.add_child(label_button)
	container.add_child(delete_button)
	return container

func _handle_delete(component: Node):
	var index = SourceCatalogue.sources.find(self)
	if index != -1:
		SourceCatalogue.sources.remove_at(index)
		SourceCatalogue.source_removed.emit(self)
	component.queue_free()

func async_find_sound_files(callback: Callable, path = source_path) -> bool:
	if not DirAccess.dir_exists_absolute(path) or not path.is_absolute_path():
		push_error(source_name + ": " + path + " does not exist.")
		return false
		
	if path == source_path:
		## If we have not yet called this recurively, then we clear the found audio files
		found_audio_file_paths = []
		
	var dir := DirAccess.open(path)
	var has_no_error = true
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				if is_recursive: 
					has_no_error = async_find_sound_files(callback, full_path)
				if not has_no_error:
					return false
			elif file_is_supported_and_valid_audio_file(full_path):
				_handle_sound_file(full_path, callback)
			file_name = dir.get_next()
	else:
		push_error(source_name + ": " + source_path + " does not exist.")
		return false
	return true

func file_is_supported_and_valid_audio_file(file_path : String):
	return file_path.ends_with(".mp3") or file_path.ends_with(".wav") or file_path.ends_with(".ogg")

func _handle_sound_file(file_path: String, callback: Callable):
	found_audio_file_paths.push_back(file_path)
	callback.call(file_path)
