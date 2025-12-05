@tool
@icon("res://addons/godot_rss/icon.svg")
extends PanelContainer

const _CHANNEL_SCENE:PackedScene = preload("res://addons/godot_rss/ui/channel.tscn")

## The [RSS] feed to display.
@export var feed:RSS = null:
	get:
		return feed
	set(_value):
		if feed != null and feed.changed.is_connected(_update):
			feed.changed.disconnect(_update)
		feed = _value
		if feed != null and not feed.changed.is_connected(_update):
			feed.changed.connect(_update)
		_update()

var _managed_children:Array[Control] = []

@onready var channel_container:Container = $_C/Channels

func _ready():
	_update()

func _update():
	if feed == null or _CHANNEL_SCENE == null:
		return
	
	for child in _managed_children:
		_managed_children.erase(child)
		child.queue_free()
	
	for channel in feed.channels:
		var new_channel := _CHANNEL_SCENE.instantiate()
		channel_container.add_child(new_channel)
		_managed_children.append(new_channel)
		new_channel.channel = channel
