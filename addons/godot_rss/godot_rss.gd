@tool
@icon("res://addons/godot_rss/icon.svg")
extends Resource
class_name RSS

## RSS
##
## A class used to enclose an rss feed, inclusing all it's channels. Can be generated in engine,
## or created using one of the included static methods to load from URLs, or files, or directly from
## [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate. 
## NOTE: This does [b]NOT[/b] support parsing ATOM feeds.

## A enum containing the days of the week mapping a RSS channel's [code]skipDays[/code] optional tag.
enum RSSDay {
	Sunday = 1,
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday
}

const _STR_TO_RSS_DAY:Dictionary = {
	"sun" : RSSDay.Sunday,
	"mon" : RSSDay.Monday,
	"tue" : RSSDay.Tuesday,
	"wed" : RSSDay.Wednesday,
	"thu" : RSSDay.Thursday,
	"fri" : RSSDay.Friday,
	"sat" : RSSDay.Saturday
}

## The [XMLNode] name used for [RSS] data.
const RSS_TAG_NAME := "rss"
## The [XMLNode] attribute name used to declair the [RSS] version used.
const VERSION_ATTR_NAME := "version"
## The default headers used when getting http data.
const DEFAULT_HTTP_HEADERS:Array[String] = ["User-Agent: RSS/1.0 (Godot)",
							  "Accept: text/xml,\
								application/xhtml+xml,\
								application/xml,\
								text/*;q=0.9,\
								application/*;q=0.5;\
								*/*;q=0.1"\
							 ]

## The version of RSS used in this RSS feed.
@export var version := ""

## The [RSSChannel]s used in this RSS feed.
@export var channels:Array[RSSChannel] = []

## Gets [PackedByteArray] data from the given [param host] URL at the given [param path].[br]
## Due to how Godot handels http, it's important to accurately split the
## URL's [param host] from the URL's [param path]. See [method url_split_host_path].[br]
## When [param port] [code]< 0[/code], the appropriate port will be automatically determined from
## the [param host]'s scheme, if given.
static func get_http_bytes(host:String,
						   path := "/",
						   headers:Array[String] = DEFAULT_HTTP_HEADERS,
						   port:int = -1
						  ) -> PackedByteArray:
	var http_client := HTTPClient.new()

	if host.is_empty():
		return PackedByteArray()

	if http_client.connect_to_host(host, port) != OK:
		return PackedByteArray()

	while http_client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		http_client.poll()
		await Engine.get_main_loop().process_frame

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		return PackedByteArray()

	path = "/" + path.lstrip("/").rstrip("/")

	if http_client.request(HTTPClient.METHOD_GET, path, headers) != OK:
		return PackedByteArray()

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		await Engine.get_main_loop().process_frame

	if not http_client.get_status() in [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]:
		return PackedByteArray()

	if not http_client.has_response():
		return PackedByteArray()

	if not http_client.is_response_chunked() and http_client.get_response_body_length() < 0:
		return PackedByteArray()

	var rb = PackedByteArray()
	while http_client.get_status() == HTTPClient.STATUS_BODY:
		rb.append_array(http_client.read_response_body_chunk())
		http_client.poll()
		await Engine.get_main_loop().process_frame

	http_client.close()
	return rb

## Split's the given [param url]'s host and path as expected by [get_http_bytes].
## Returns a list with 2 items. The first is the host, the second is the path.
static func url_split_host_path(url:String) -> Array[String]:
	var index := url.find("/", url.find("://")+"://".length()+1)
	return [url.substr(0, index), url.substr(index)]

## Loads a locally saved [XMLDocument] as [RSS].
static func load_file(path:String) -> RSS:
	return RSS.load_xml_document(XML.parse_file(path))

## Loads RSS data from the given [param host] URL at the given [param path].[br]
## Due to how Godot handels http, it's important to accurately split the
## URL's [param host] from the URL's [param path]. See [method url_split_host_path].[br]
## NOTE: This RSS feed is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.
static func load_url(host:String,
					 path := "/",
					 headers:Array[String] = DEFAULT_HTTP_HEADERS,
					 port:int = -1
					) -> RSS:
	var rb = await get_http_bytes(host, path, headers, port)
	
	if rb.is_empty():
		return null
	
	return load_data(rb)

## Loads a [RSS] feed right from a given [String]'s [param data]. 
static func load_string(data:String) -> RSS:
	return load_xml_document(XML.parse_str(data))

## Loads a [RSS] feed right from a given [PackedByteArray]'s [param data]. 
static func load_data(data:PackedByteArray) -> RSS:
	if data.is_empty():
		return
	return RSS.load_xml_document(XML.parse_buffer(data))

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data]. 
static func load_xml_document(document:XMLDocument) -> RSS:
	if document.root == null:
		return null
	return load_xml_node(document.root)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data]. 
static func load_xml_node(node:XMLNode) -> RSS:
	if node.name != RSS_TAG_NAME:
		#This isn't a rss feed at all! Perhaps you loaded html or svg data by accident?
		return null
	
	var created := RSS.new()
	created.version = node.attributes.get(VERSION_ATTR_NAME, "")
	for child in node.children:
		created.channels.append(RSSChannel.load_xml_node(child))
	
	return created

## Converts a given [param string] to a [RSSDay] as expected when parsing a [RSSChannel]'s
## [member RSSChannel.skip_days].
static func string_to_rss_day(string:String) -> RSSDay:
	string = string.to_lower().strip_edges().rstrip(".").substr(0, 3)
	assert(_STR_TO_RSS_DAY.has(string))
	return _STR_TO_RSS_DAY[string]
