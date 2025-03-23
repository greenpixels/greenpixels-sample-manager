extends PanelContainer

@onready var add_source_popup := %AddSourcePopup
@onready var source_list := %SourceList
@onready var audio_list := %AudioList
@onready var player := %AudioStreamPlayer
@onready var audio_progress_slider := %AudioProgressSlider
@onready var search_input := %SearchInput

var sound_map : Dictionary[String, int] = {}
signal sound_map_changed
var is_dragging_audio_progress_slider := false

func _ready() -> void:
	SourceCatalogue.source_added.connect(_handle_source_added)
	SourceCatalogue.source_removed.connect(_handle_source_removed)

func _handle_source_removed(source: Source):
	_unlist_source_audio(source)

func _unlist_source_audio(source: Source):
	for path in source.found_audio_file_paths:
		if sound_map.has(path):
			sound_map[path] -= 1
			if sound_map[path] <= 0:
				sound_map.erase(path)
				var node = audio_list.get_node(_path_to_node_name(path))
				if node and is_instance_valid(node) and not node.is_queued_for_deletion():
					node.queue_free()
				else:
					push_error("Unable to delete node: " + path)
		else:
			push_warning("Sound map has no entry for " + path)
	sound_map_changed.emit()
	
func _handle_source_ignore_changed(is_ignored: bool, source: Source):
	if is_ignored:
		_unlist_source_audio(source)
	else:
		for audio_path in source.found_audio_file_paths:
			_handle_add_sound_file(audio_path)

# Some characters are not supported by Godot node names, so we replace them
# This could cause issues down the line if for example 2 files in the same folder have names like:
#
#	- my-file.wav
#   - my,file.wav
#
# They would ultimately be treated as one file, causing untested behaviour
# To circumvent this specific problem, every one of these special characters is replaced with another unique character
func _path_to_node_name(path: String):	
	return (
		path 
		.replace("/", "-")
		.replace("\\", "--")
		.replace(".", "_")
		.replace(",", "__")
		.replace(":", "___")
	)

func _on_add_source_button_pressed() -> void:
	add_source_popup.show()
	
func _on_add_source_popup_close_requested() -> void:
	add_source_popup.hide()

func _handle_source_added(source: Source) -> void:
	var source_component = source.create_component()
	source.async_find_sound_files(_handle_add_sound_file, _handle_searching_finished, self)
	source.ignore_changed.connect(_handle_source_ignore_changed)
	source_list.add_child(source_component)
	
func _handle_add_sound_file(file_path: String):
	if sound_map.has(file_path):
		sound_map[file_path] += 1
	else:
		sound_map[file_path] = 1
		_add_new_sound_entry(file_path)
	sound_map_changed.emit()

func _handle_searching_finished(source: Source):
	source.is_searching = false

func _add_new_sound_entry(file_path: String):
	var file_name = file_path.split("/")[-1]
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label_button = Button.new()
	label_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var explorer_button = Button.new()
	explorer_button.text = "Show in Explorer"
	
	label_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_button.text = file_name.substr(0, 40) + ("" if file_name.length() < 40 else "...")
	label_button.tooltip_text = file_name
	
	container.name = _path_to_node_name(file_path)
	container.set_meta("audio_path", file_path)
	var search_callback = Callable(func(): _handle_filter_change(container, file_name))
	FilterContext.search_value_changed.connect(search_callback)
	container.tree_exited.connect(func(): FilterContext.search_value_changed.disconnect(search_callback))
	label_button.pressed.connect(func(): _handle_button_press(container.get_meta("audio_path")))
	explorer_button.pressed.connect(func(): _show_in_explorer(container.get_meta("audio_path")))
	container.add_child(label_button)
	container.add_child(explorer_button)
	audio_list.add_child(container)

func _handle_filter_change(node: Node, file_name: String):
	if file_name == null or file_name.is_empty():
		push_error("Unable to find audio file as the path is not valid (null or empty)")
		return
		
	if FilterContext.search_value.strip_edges().is_empty():
		node.show()
		return
		
	var search_values : PackedStringArray = []
	if FilterContext.search_value.contains(";"):
		search_values = FilterContext.search_value.split(";")
	else:
		search_values.push_back(FilterContext.search_value)
	for search_value in search_values:
		if search_value.strip_edges().is_empty(): continue
		search_value = search_value.strip_edges().to_lower()
		if not file_name.to_lower().contains(search_value):
			node.hide()
			return
	node.show()

func _show_in_explorer(path_meta: Variant):
	var full_file_path = path_meta
	if full_file_path == null or full_file_path.is_empty():
		push_error("Unable to find audio file as the path is not valid (null or empty)")
		return
	OS.shell_show_in_file_manager(full_file_path, true)
		
func _process(_delta: float) -> void:
	if is_dragging_audio_progress_slider: return
	if player.stream:
		audio_progress_slider.value = player.get_playback_position() / (player.stream as AudioStream).get_length()
	else:
		audio_progress_slider.value = 0

func _handle_button_press(path_meta: Variant):
	if player.playing:
		player.stop()
	player.stream = null
	player.stream_paused = false
	
	var full_file_path = path_meta
	if full_file_path == null or full_file_path.is_empty():
		push_error("Unable to play audio file as the path is not valid (null or empty)")
		return
	if full_file_path.ends_with(".ogg"):
		player.stream = AudioStreamOggVorbis.load_from_file(full_file_path)
	elif full_file_path.ends_with(".mp3"):
		player.stream = AudioStreamMP3.load_from_file(full_file_path)
	elif full_file_path.ends_with(".wav"):
		player.stream = AudioStreamWAV.load_from_file(full_file_path)
	else:
		push_error("Unable to play audio file as the file does not have a supported file extenstion (wav, mp3, ogg)")
		return
	player.play(0)

func _on_play_button_pressed() -> void:
	if player.stream_paused:
		player.stream_paused = false
	else:
		player.play(0)

func _on_pause_button_pressed() -> void:
	player.stream_paused = !player.stream_paused

func _on_audio_progress_slider_drag_ended(value_changed: bool) -> void:
	is_dragging_audio_progress_slider = false
	var previous_pause_state = player.stream_paused
	if not player.stream or not value_changed: return
	player.play((player.stream as AudioStream).get_length() * audio_progress_slider.value)
	player.stream_paused = previous_pause_state

func _on_audio_progress_slider_drag_started() -> void:
	is_dragging_audio_progress_slider = true

func _on_spin_box_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

func _on_line_edit_text_changed(new_text: String) -> void:
	FilterContext.search_value = new_text


func _on_sound_map_changed() -> void:
	search_input.placeholder_text = "Search " + str(sound_map.size()) + " entries ..."
