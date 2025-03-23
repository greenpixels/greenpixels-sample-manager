## Autoloaded

extends Node

@export_storage var sources : Array[Source] = []

signal source_removed(source: Source)
signal source_added(source: Source)
