extends Resource
class_name Source

@export_storage var source_path := ""
@export_storage var source_name := ""
@export_storage var should_search_recursive := true
@export_storage var found_audio_file_paths : Array[String] = []
@export_storage var should_search_async := false
@export_storage var is_ignored := false :
	set(value):
		if value == is_ignored: return
		is_ignored = value
		ignore_changed.emit(is_ignored, self)
@export_storage var is_searching := false :
	set(value):
		if is_searching == value: return
		is_searching = value
		
		if is_searching:
			search_started.emit()
		else:
			search_ended.emit()
		
signal search_started
signal search_ended
signal ignore_changed(value: bool, source: Source)

var open_search_calls = 0 :
	set(value):
		open_search_calls = value
		is_searching = open_search_calls != 0

func create_component():
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label_button = Button.new()
	label_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ignore_button = Button.new()
	
	ignore_button.text = "👁"
	ignore_button.pressed.connect(func():
		is_ignored = !is_ignored
		ignore_button.text = "👁" if not is_ignored else "🚫"
	)
	var delete_button = Button.new()
	delete_button.pressed.connect(func(): _handle_delete(container))
	label_button.text = source_name
	
	
	search_ended.connect(func():
		label_button.text = source_name
		ignore_button.disabled = false
	)
	
	search_started.connect(func():
		label_button.text = source_name + " (Indexing ...)"
		ignore_button.disabled = true
	)
	
	delete_button.text = "✖"
	container.add_child(label_button)
	container.add_child(ignore_button)
	container.add_child(delete_button)
	return container

func _handle_delete(component: Node):
	var index = SourceCatalogue.sources.array.find(self)
	if index != -1:
		SourceCatalogue.sources.array.remove_at(index)
		SourceCatalogue.source_removed.emit(self)
	component.queue_free()

func async_find_sound_files(on_sound_add: Callable, on_finish: Callable, origin_node : Node, depth = 0, path = source_path):
	if not DirAccess.dir_exists_absolute(path) or not path.is_absolute_path():
		push_error(source_name + ": " + path + " does not exist.")
		return
	open_search_calls += 1
	if depth == 0:
		## If we have not yet called this recurively, then we clear the found audio files
		found_audio_file_paths = []
		
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				if should_search_recursive == true: 
					async_find_sound_files(on_sound_add, on_finish, origin_node, depth + 1, full_path)
			elif file_is_supported_and_valid_audio_file(full_path):
				if should_search_async: await origin_node.get_tree().process_frame
				_handle_sound_file(full_path, on_sound_add)
			file_name = dir.get_next()
	else:
		push_error(source_name + ": " + source_path + " does not exist.")
		return
	on_finish.call(self)
	open_search_calls -= 1

func file_is_supported_and_valid_audio_file(file_path : String):
	return file_path.ends_with(".mp3") or file_path.ends_with(".wav") or file_path.ends_with(".ogg")

func _handle_sound_file(file_path: String, callback: Callable):
	found_audio_file_paths.push_back(file_path)
	callback.call(file_path)
