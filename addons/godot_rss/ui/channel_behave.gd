@tool
@icon("res://addons/godot_rss/icon.svg")
extends PanelContainer

const _ITEM_SCENE : PackedScene = preload("res://addons/godot_rss/ui/item.tscn")

@export var channel:RSSChannel = null:
	get:
		return channel
	set(_value):
		if channel != null and channel.changed.is_connected(_update):
			channel.changed.disconnect(_update)
		channel = _value
		if channel != null and not channel.changed.is_connected(_update):
			channel.changed.connect(_update)
		_update()

@export var image_size_max := Vector2.ONE * 64

var _managed_children:Array[Control] = []

@onready var item_container:Container = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var title_label:Label = $VBoxContainer/Title
@onready var desc_label:Label = $VBoxContainer/Desc
@onready var copyright_label:Label = $VBoxContainer/Copyright
@onready var channel_image:TextureRect = $VBoxContainer/TextureRect

func _ready():
	_update()

func _update():
	if channel == null or _ITEM_SCENE == null:
		return
	
	title_label.text = channel.title
	desc_label.text = channel.description
	copyright_label.text = channel.copyright
	
	#Remove the example image, so it doesn't show as the real image loads.
	channel_image.texture = null
	var image := await channel.channel_image.get_image()
	if image != null:
		channel_image.texture = ImageTexture.create_from_image(image)
		var size_override := image.get_size().min(image_size_max)
		channel_image.texture.set_size_override(size_override)
	else:
		channel_image.texture = null
	
	for child in _managed_children:
		_managed_children.erase(child)
		child.queue_free()
	
	for item in channel.items:
		var new_item := _ITEM_SCENE.instantiate()
		item_container.add_child(new_item)
		_managed_children.append(new_item)
		new_item.item = item
	
	set_deferred("name", channel.title)
