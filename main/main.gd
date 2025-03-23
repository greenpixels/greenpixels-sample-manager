extends PanelContainer

@onready var add_source_popup := %AddSourcePopup
@onready var source_list := %SourceList
@onready var audio_list := %AudioList
@onready var player := %AudioStreamPlayer
@onready var audio_progress_slider := %AudioProgressSlider

var sound_map : Dictionary[String, int] = {}

func _ready() -> void:
	SourceCatalogue.source_removed.connect(_handle_source_removed)

func _handle_source_removed(source: Source):
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
					
func _path_to_node_name(path: String):
	return path.replace("/", "-").replace(".", "_").replace(",", "_")

func _on_add_source_button_pressed() -> void:
	add_source_popup.show()
	
func _on_add_source_popup_close_requested() -> void:
	add_source_popup.hide()

func _on_add_source_popup_source_added(source_name: String, source_path: String) -> void:
	var source = Source.new(source_path, source_name)
	var is_success = source.async_find_sound_files(_handle_sound_file)
	if is_success:
		SourceCatalogue.sources.push_back(source)
		source_list.add_child(source.create_component())
	
func _handle_sound_file(file_path: String):
	if sound_map.has(file_path):
		sound_map[file_path] += 1
	else:
		sound_map[file_path] = 1
		_add_new_sound_entry(file_path)

func _add_new_sound_entry(file_path: String):
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = file_path.split("/")[-1]
	button.name = _path_to_node_name(file_path)
	button.set_meta("audio_path", file_path)
	audio_list.add_child(button)
	button.pressed.connect(func(): _handle_button_press(button))

func _process(delta: float) -> void:
	if player.stream:
		audio_progress_slider.value = player.get_playback_position() / (player.stream as AudioStream).get_length()
	else:
		audio_progress_slider.value = 0

func _handle_button_press(button: Button):
	if player.playing:
		player.stop()
	player.stream = null
	player.stream_paused = false
	
	var full_file_path = button.get_meta("audio_path") as String
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
