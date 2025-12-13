extends Control

@export var description_to_bbcode := true

@onready var feed_container:Control = $VBoxContainer/Feed
@onready var host_textedit:TextEdit = $VBoxContainer/HBoxContainer/Host
@onready var path_textedit:TextEdit = $VBoxContainer/HBoxContainer/Path
@onready var load_button:Button = $VBoxContainer/HBoxContainer/Button

func _process(delta: float):
	size = get_viewport().size
	position = Vector2.ZERO

func _on_load_rss():
	feed_container.feed = await RSS.load_url(host_textedit.text, path_textedit.text, description_to_bbcode)
