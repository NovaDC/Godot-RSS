@tool
class_name RSSEditorPlugin
extends EditorPlugin

const PLUGIN_NAME := "RSS"

const PLUGIN_ICON := preload("res://addons/godot-rss/icon.svg")

func  _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON
