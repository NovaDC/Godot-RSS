@tool
class_name RSSEditorPlugin
extends EditorPlugin

const PLUGIN_NAME := "GodotRSS"

const PLUGIN_ICON := preload("./icon.svg")

const PLUGIN_VERSION := "v1.1.0.0"
const ENSURE_SCRIPT_DOCS:Array[Script] = [
	preload("./rss.gd"),
	preload("./item.gd"),
	preload("./image_data.gd"),
	preload("./enclosure.gd"),
	preload("./channel.gd"),
]

# Every once ands a while the script docs simply refuse to update properly.
# This nudges the docs into a ensuring that the important scripts added by
# this addon are actually loaded.
func _ensure_script_docs():
	var edit := get_editor_interface().get_script_editor()
	for scr in ENSURE_SCRIPT_DOCS:
		edit.update_docs_from_script(scr)

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON

func _enter_tree() -> void:
	_ensure_script_docs()

func _enable_plugin() -> void:
	_ensure_script_docs()
