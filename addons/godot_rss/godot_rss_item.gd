@tool
@icon("res://addons/godot_rss/icon.svg")
extends Resource
class_name RSSItem

## RSSItem
##
## SOURCE: https://www.w3schools.com/XML/xml_rss.asp
## Represents a [code]item[/code] as used in a [RSSChannel]. Can be generated in engine,
## or created using one of the included static methods to load from URLs, or files, or directly from
## [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate. 

## The [XMLNode] name used for a [RSSItem].
const ITEM_TAG_NAME := "item"

## The title/name of the item.
@export var title:String = ""
## A description of the item.
@export var description:String = ""
## A link to the related item's webpage (not necessarily to the channel's rss feed).
@export var link:String = ""

## Optionally, the name of the source this item's information is from.
@export var source_name:String = ""
## Optionally, the url of the source this item's information is from.
@export var source_url:String = ""
## Optionally, the date this item was last published.
@export var publication_date:String = ""
## Optionally, this item's author's email
@export var author_email:String = ""
## Optionally, a url pointing to a webpage hosting comments about this item.
@export var comments_url:String = ""
## Optionally, specifies the categories of this item as the keys,
## optionally with a non empty string value representing the category's domain
## (using either a general name or a url) that that defines that specific category's taxonomy
## (what catagories are what and what they mean).[br]
## The categories are in addition to the categories
## specified in the channel that this item is in as well.[br]
## Some example entries for this dictionary:
## [codeblock]
## {
## 	"Sports" : "syndic8",
## 	"Global News/United States" : "",
## 	"Game Updates" : "https://github.com/NovaDC"
## }
## [/codeblock]
@export var categories:Dictionary = {}
## Optionally, when defined, this is consitered a [u]g[/u]lobally [u]u[/u]nique [u]id[/u]entifier
## for the item, with no particular format enforced (unless it is a permalink).
## When [guid_is_permalink] is [code]true[/code] (by default it is),
## this guid is expected to be a url permalink to this specific item.
@export var guid:String = ""
## When true (dy default it is), guid is also a permalink to this specific item.
@export var guid_is_permalink:bool = true
## Optionally, holds all the [RSSEnclosure] data representing the item's enclosed media files.
@export var enclosed_media:Array[RSSEnclosure] = []

## Loads a [RSS] feed right from a given [String]'s [param data]. 
static func load_string(data:String, description_to_bbcode := false) -> RSSItem:
	return load_xml_document(XML.parse_str(data), description_to_bbcode)

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data]. 
static func load_xml_document(document:XMLDocument, description_to_bbcode := false) -> RSSItem:
	if document.root == null:
		return null
	return load_xml_node(document.root, description_to_bbcode)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data]. 
static func load_xml_node(node:XMLNode, description_to_bbcode := false) -> RSSItem:
	var created := RSSItem.new()
	
	if node.name != ITEM_TAG_NAME:
		return null
	
	for child in node.children:
		match (child.name):
			"title", "link":
				#exact same name, exact same type,
				#for both the child node and godot rss channel object
				created.set(child.name, child.content)
			"description":
				var raw_content := child.dump_str(true) if child.content == "" else child.content
				if description_to_bbcode:
					raw_content = RSS.html_to_bbcode(raw_content)
				else:
					raw_content = RSS.clean_description(raw_content)
				created.description = raw_content
			"author":
				created.author_email = child.content
			"category":
				created.categories[child.content] = child.attributes.get("domain", "")
			"comments":
				created.comments_url = child.content
			"guid":
				created.guid = child.content
				var is_perma = child.attributes.get("isPermaLink", false)
				if is_perma is String:
					if "true" in is_perma.strip_edges().to_lower():
						is_perma = true
					else:
						is_perma = false
				created.guid_is_permalink = bool(is_perma)
			"pubDate":
				created.publication_date = child.content
			"source":
				created.source_name = child.content
				created.source_url = child.attributes.get("url", "")
			
			"enclosure":
				created.enclosed_media.append(RSSEnclosure.load_xml_node(child))
	
	return created
