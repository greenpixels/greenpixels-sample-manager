## Autoloaded

extends Node

const SAVE_PATH := "user://sources.tres"

@export_storage var sources : SourceArray = SourceArray.new()

@warning_ignore("unused_signal")
signal source_removed(source: Source)
@warning_ignore("unused_signal")
signal source_added(source: Source)

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var loaded_sources = ResourceLoader.load(SAVE_PATH)
		if loaded_sources is SourceArray:
			sources = loaded_sources
			await get_tree().process_frame
			for source in sources.array:
				source_added.emit(source)
		
	source_removed.connect(func(_source: Source):
		_handle_sources_changed()
	)
	source_added.connect(func(_source : Source):
		_handle_sources_changed()
	)

func _handle_sources_changed():
	ResourceSaver.save(sources, SAVE_PATH)
