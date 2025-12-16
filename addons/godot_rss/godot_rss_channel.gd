@tool
@icon("res://addons/godot_rss/icon.svg")
class_name RSSChannel
extends Resource

## RSSChannel
##
## SOURCE: https://www.w3schools.com/XML/xml_rss.asp
## Represent a [code]channel[/code] as used in a [RSS] feed. Can be generated in engine,
## or created using one of the included static methods to load from URLs, or files,
## or directly from [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate.

## The [XMLNode] name used for a [RSSChannel].
const CHANNEL_TAG_NAME := "channel"


## The title/name of the channel.
@export var title:String = ""
## A description of the channel.
@export var description:String = ""
## A link to the related channel's webpage (not necessarily to the channel's rss feed).
@export var link:String = ""
## All [GodotRSSItems] in this channel.
@export var items:Array[RSSItem] = []

## Optionally, contains either a ISO639-2 language code
## (see https://www.loc.gov/standards/iso639-2/)
## or one of the codes listed here (https://www.rssboard.org/rss-language-codes),
## specifying the language the channel is in.
@export var language:String = ""
## Optionally, contains information used to notify about copyrighted material.
@export var copyright:String = ""
## Optionally, the date the feed was last modified.
@export var modified_date:String = ""
## Optionally, the date this feed was last published.
@export var publication_date:String = ""
## Optionally, the software used to generate this rss channel.
@export var generating_software:String = ""
## Optionally, a email to the webmaster of this channel.
@export var webmaster_email:String = ""
## Optionally, a email for the editor of this channel.
@export var editor_email:String = ""
## Optionally, a url to the documentation of the format used in this specific feed.
@export var docs_url:String = ""
## Optionally, [u]t[/u]ime [u]t[/u]o [u]l[/u]ive - or the amount of time (in minutes)
## before the channel should be updated. [br]
## A value below 0 means that it is undefined or not required.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var ttl_min:int = -1
## Optionally, a list of hours with (0 being midnight and 23 being 11PM)
## that the feed should avoid being updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var skip_hours:Array[int] = []
## Optionally, a list of [enum RSSDays] that the feed should avoid being updated on.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var skip_days:Array[RSS.RSSDay] = []
## Optionally, contains the PICS rating (https://www.w3.org/PICS/) information for the RSS channel.
@export var rating:String = ""
## Optionally, specifies the categories of this channel as the keys,
## optionally with a non empty string value representing the category's domain
## (using either a general name or a url) that that defines that specific category's taxonomy
## (what categories are what and what they mean).[br]
## Some example entries for this dictionary:
## [codeblock]
## {
## 	"Sports" : "syndic8",
## 	"Global News/United States" : "",
## 	"Game Updates" : "https://github.com/NovaDC"
## }
## [/codeblock]
@export var categories:Dictionary = {}
## Optionally, the image associated with the specific channel.
@export var channel_image:RSSImageData = RSSImageData.new()
@export_subgroup("Text Input")
## Optionally, if defined, show the channels text input field, with this as it's description.
## NOTE: Most RSS readers ignore this.
@export var text_input_description:String = ""
## Optionally, if defined, show the channels text input field, with this as it's name.
## NOTE: Most RSS readers ignore this.
@export var text_input_name:String = ""
## Optionally, if defined, show the channels text input field, with this defining the url link of
## the CGI script used to process the input.
## NOTE: Most RSS readers ignore this.
@export var text_input_link:String = ""
## Optionally, if defined, show the channels text input field, with this defining the
## text used on (of the [i]title[/i] of) the [code]submit[/code] button of the text field.
## NOTE: Most RSS readers ignore this.
@export var text_input_title:String = ""
@export_subgroup("Cloud")
## Optionally, the cloud domain to be used to notify when the channel is updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var cloud_domain:String = ""
## Optionally, the cloud path to be used to notify when the channel is updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var cloud_path:String = ""
## Optionally, the cloud port to be used to notify when the channel is updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var cloud_port:int = 80
## Optionally, the cloud's register procedure to be used to notify when the channel is updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var cloud_register_procedure:String = ""
## Optionally, the cloud protocol to be used to notify when the channel is updated.[br]
## NOTE: This RSS channel is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
@export var cloud_protocol:String = ""

## Loads a [RSS] feed right from a given [String]'s [param data].
static func load_string(data:String, description_to_bbcode := false) -> RSSChannel:
	return load_xml_document(XML.parse_str(data), description_to_bbcode)

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data].
static func load_xml_document(document:XMLDocument, description_to_bbcode := false) -> RSSChannel:
	if document.root == null:
		return null
	return load_xml_node(document.root, description_to_bbcode)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data].
static func load_xml_node(node:XMLNode, description_to_bbcode := false) -> RSSChannel:
	var created := RSSChannel.new()

	if node.name != CHANNEL_TAG_NAME:
		return null

	for child in node.children:
		match (child.name):
			"title", "link", "copyright", "language":
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
			"cloud":
				created.cloud_domain = child.attributes.get("domain", "")
				created.cloud_path = child.attributes.get("path", "")
				created.cloud_port = int(child.attributes.get("port", 80))
				created.cloud_register_procedure = child.attributes.get("registerProcedure", "")
				created.cloud_protocol = child.attributes.get("protocol", "")
			"category":
				created.categories[child.content] = child.attributes.get("domain", "")
			"docs":
				created.docs_url = child.content
			"generator":
				created.generating_software = child.content
			"image":
				created.channel_image = RSSImageData.load_xml_node(child, description_to_bbcode)
			"lastBuildDate":
				created.modified_date = child.content
			"managingEditor":
				created.editor_email = child.content
			"pubDate":
				created.publication_date = child.content
			"rating":
				created.rating = child.content
			"skipDays":
				for day_node in child.children:
					if day_node.name == "day":
						created.skip_days.append(RSS.string_to_rss_day(day_node.content))
			"skipHours":
				for hour_node in child.children:
					if hour_node.name == "hour":
						created.skip_days.append(int(hour_node.content))
			"textInput":
				for data_node in child.children:
					match(data_node.name):
						"description":
							created.text_input_description = data_node.content
						"name":
							created.text_input_name = data_node.content
						"title":
							created.text_input_title = data_node.content
						"link":
							created.text_input_link = data_node.content
			"ttl":
				created.ttl_min = int(child.content)
			"webMaster":
				created.webmaster_email = child.content

			"item":
				created.items.append(RSSItem.load_xml_node(child, description_to_bbcode))

	return created
