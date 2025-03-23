## Autoloaded

extends Node

@export_storage var sources : Array[Source] = []

@warning_ignore("unused_signal")
signal source_removed(source: Source)
@warning_ignore("unused_signal")
signal source_added(source: Source)
