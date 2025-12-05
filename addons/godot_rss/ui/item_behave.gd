@tool
@icon("res://addons/godot_rss/icon.svg")
extends PanelContainer

## The [RSSItem] to display.
@export var item:RSSItem = null:
	get:
		return item
	set(_value):
		if item != null and item.changed.is_connected(_update):
			item.changed.disconnect(_update)
		item = _value
		if item != null and not item.changed.is_connected(_update):
			item.changed.connect(_update)
		_update()

@onready var title_label:Label = $VBoxContainer/Title
@onready var desc_label = $VBoxContainer/Desc

func _ready():
	_update()

func _update():
	if item == null:
		return
	
	title_label.text = item.title
	desc_label.text = item.description
