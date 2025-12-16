@tool
class_name RSSEditorPlugin
extends EditorPlugin

const PLUGIN_NAME := "GodotRSS"

const PLUGIN_ICON := preload("res://addons/godot_rss/icon.svg")

const PLUGIN_VERSION := "v1.1.0.0"

func  _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON
