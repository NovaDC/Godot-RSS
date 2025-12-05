@tool
@icon("res://addons/godot_rss/icon.svg")
extends Resource
class_name RSSImageData

## RSSImageData
##
## SOURCE: https://www.w3schools.com/XML/xml_rss.asp
## Represent a [code]channel[/code]'s image as used in a [RSSChannel]. Can be generated in engine,
## or created using one of the included static methods to load from URLs, or files, or directly from
## [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate. 

## The [XMLNode] name used for a [RSSImageData].
const IMAGE_TAG_NAME := "image"

## The default size of a [RSSImageData]. Used as a fallback when not given.
const DEFAULT_SIZE := Vector2i(88, 31)

## A url of the webpage that offered the feed this image is from.
@export var source_link:String = ""
## The alt-text of the image, to be shown if the image is unavailable.
@export var title:String = ""
## The url the image is located at.
@export var image_url:String = ""

@export_group("Optional")
## Optionally, a description (to be used as a caption) of the image
@export var description:String = ""
## Optionally, a predefined display size of the image.
## Height will default to 31, and width will default to 88 if not explicitly specified.
@export var size := DEFAULT_SIZE

## Loads a [RSS] feed right from a given [String]'s [param data]. 
static func load_string(data:String) -> RSSImageData:
	return load_xml_document(XML.parse_str(data))

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data]. 
static func load_xml_document(document:XMLDocument) -> RSSImageData:
	if document.root == null:
		return null
	return load_xml_node(document.root)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data]. 
static func load_xml_node(node:XMLNode) -> RSSImageData:
	var created := RSSImageData.new()
	
	if node.name != IMAGE_TAG_NAME:
		return null
	
	for child in node.children:
		match (child.name):
			"title", "link":
				#exact same name, exact same type,
				#for both the child node and godot rss channel object
				created.set(child.name, child.content)
			"description":
				var raw_content := child.dump_str()
				raw_content = raw_content.replace("<description>", "")
				raw_content = raw_content.replace("</description>", "")
				created.description = raw_content
			"url":
				created.image_url = child.content
			"height":
				created.size.y = int(child.content)
			"width":
				created.size.x = int(child.content)
	
	return created

## Attempts to load the image at the given [member image_url].[br]
## NOTE: that this determines the image's type using the [member image_url]'s extention only,
## and may return null if godot does not support loading a image with that format.
func get_image() -> Image:
	var host := RSS.url_split_host_path(image_url)[0]
	var path := RSS.url_split_host_path(image_url)[1]
	var rb = await RSS.get_http_bytes(host, path)
	if rb.is_empty():
		return null
	var i := Image.new()
	var ext := path.split("?", 1)[0].split("#", 1)[0].rsplit(".", 1)[-1].strip_edges().to_lower()
	if ext == "jpeg":
		ext = "jpg"
	var method_name = "load_%s_from_buffer" % [ext]
	if i.has_method(method_name):
		i.call(method_name, rb)
		return i
	return null
