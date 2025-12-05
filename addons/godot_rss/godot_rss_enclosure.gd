@tool
@icon("res://addons/godot_rss/icon.svg")
extends Resource
class_name RSSEnclosure

## RSSEnclosure
##
## SOURCE: https://www.w3schools.com/XML/xml_rss.asp
## Represent a [code]item[/code]'s enclosed media files and used in [RSSItem]. Can be generated in
## engine, or created using one of the included static methods to load from URLs, or files,
## or directly from [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate. 

## The [XMLNode] name used for a [RSSEnclosure].
const ENCLOSURE_TAG_NAME := "enclosure"

## A url of the media file.
@export var url:String = ""
## The expected type (content type or mime type) of the enclosed file.
@export var type:String = "*/*"
## The expected size (length in bytes) of the media file.
@export var size:int = 0

## Loads a [RSS] feed right from a given [String]'s [param data]. 
static func load_string(data:String) -> RSSEnclosure:
	return load_xml_document(XML.parse_str(data))

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data]. 
static func load_xml_document(document:XMLDocument) -> RSSEnclosure:
	if document.root == null:
		return null
	return load_xml_node(document.root)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data]. 
static func load_xml_node(node:XMLNode) -> RSSEnclosure:
	var created := RSSEnclosure.new()
	
	if node.name != ENCLOSURE_TAG_NAME:
		return null
	
	created.size = int(node.attributes.get("length", node.attributes.get("size", 0)))
	created.url = node.attributes.get("url", "")
	created.type = node.attributes.get("type", "")
	
	return created
