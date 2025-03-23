## Autoloaded

extends Node

@export_storage var search_value : String = "" :
	set(value):
		search_value = value
		search_value_changed.emit()

signal search_value_changed
