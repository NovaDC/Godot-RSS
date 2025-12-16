@tool
@icon("res://addons/godot_rss/icon.svg")
class_name RSS
extends Resource

## RSS
##
## A class used to enclose an rss feed, including all it's channels. Can be generated in engine,
## or created using one of the included static methods to load from URLs, or files, or directly from
## [String]s, [PackedByteArray]s, [XMLDocument]s or [XMLNode]s.
## This script requires the 'GodotXML' plugin to operate.
## NOTE: This does [b]NOT[/b] support parsing ATOM feeds, only RSS.
## RSS and ATOM feeds are 2 distinct separate formats.

## A enum containing the days of the week mapping a RSS channel's
## [code]skipDays[/code] optional tag.
enum RSSDay {
	SUNDAY = 1,
	MONDAY,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY
}

const _STR_TO_RSS_DAY:Dictionary = {
	"sun" : RSSDay.SUNDAY,
	"mon" : RSSDay.MONDAY,
	"tue" : RSSDay.TUESDAY,
	"wed" : RSSDay.WEDNESDAY,
	"thu" : RSSDay.THURSDAY,
	"fri" : RSSDay.FRIDAY,
	"sat" : RSSDay.SATURDAY
}

## The [XMLNode] name used for [RSS] data.
const RSS_TAG_NAME := "rss"
## The [XMLNode] attribute name used to declare the [RSS] version used.
const VERSION_ATTR_NAME := "version"
## The default headers used when getting http data.
const DEFAULT_HTTP_HEADERS:Array[String] = ["User-Agent: " +
													RSSEditorPlugin.PLUGIN_NAME +
													"Client/" +
													RSSEditorPlugin.PLUGIN_VERSION +
													" (Godot)",
											"Accept: " +
													"application/rss+xml," +
													"text/xml," +
													"application/xml," +
													"text/plain;q=0.9," +
													"application/atom+xml;q=0.8," +
													"text/*;q=0.7," +
													"application/*;q=0.5," +
													"*/*;q=0.1",
											"Accept-Encoding: identity"]

static var _comment_remove := RegEx.create_from_string("<!--(.*?)-->")
static var _cdata_strip := RegEx.create_from_string("<!\\[CDATA\\[(?<content>[^\\]]+?)\\]\\]>")
static var _man_close_re_cache:Dictionary = {}
static var _auto_close_re_cache:Dictionary = {}
static var _title_attr_capture_regex := RegEx.create_from_string(
"(?<tagstart><\\s*(?<tagname>[_a-zA-Z0-9]+)\\s*(?:.*?\\s*)??(title ?= ?[\"'](?<title>[^\"']+?)[\"'])(?:.*?\\s*)??>)" +
"(?<content>.+?)" +
"(?<tagend><\\s*/\\s*\\k<tagname>\\s*>)"
)
static var _lang_attr_capture_regex := RegEx.create_from_string(
"(?<tagstart><\\s*(?<tagname>[_a-zA-Z0-9]+)\\s*(?:.*?\\s*)??((xml:)?lang ?= ?[\"'](?<lang>[^\"']+?)[\"'])(?:.*?\\s*)??>)" +
"(?<content>.+?)" +
"(?<tagend><\\s*/\\s*\\k<tagname>\\s*>)"
)
static var _anchor_href_capture_regex := RegEx.create_from_string(
"<\\s*a\\s*(?:.*?\\s*)??(href ?= ?[\"'](?<href>[^\"']+?)[\"'])(?:.*?\\s*)?>" +
"(?<content>.+?)" +
"<\\s*/\\s*a\\s*>"
)

## The version of RSS used in this RSS feed.
@export var version := ""

## The [RSSChannel]s used in this RSS feed.
@export var channels:Array[RSSChannel] = []

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored or removed in the future.
## A static function that replaces any html element (that [b]is not[/b] self closing)
## with the given [param tag_names]
## in the provided [param html] body, returning the result.[br]
## [param tag_names] may be either a single [String] or an
## [Array] (or [PackedStringArray]) of [String]s.[br]
## By default this will match all tags (using the [code].?+[/code] regex pattern).[br]
## Multiple tag names will be handled in the order they are iterated from the array.[br]
## All names in [param tag_names] must be treated as (uncompiled) strings of [RegEx] patterns,
## including them having the ability to contain wildcard patterns like [code].?+[/code],
## and must be escaped as a regex pattern, if necessary.
## Its opening tag is replaced with [param opening_with],
## and its closing tag with [param closing_with].
## When [param include_contents] is true (as by default),
## the contents (the remainder of the string contained within the tag,
## including both text and other elements)
## will be inserted between [param opening_with] and [param closing_with].[br]
## [br]
## For handling html tags that [b]are[/b] self closing, see [method replace_html_tag_self_closing].
static func replace_html_tag_manual_closing(html:String,
											tag_names:Variant = ".+?",
											opening_with := "",
											closing_with := "",
											include_contents := true
											) -> String:
	match typeof(tag_names):
		TYPE_STRING:
			tag_names = [tag_names]
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			pass
		_:
			assert(false)

	var sub := opening_with
	if include_contents:
		sub += "$content"
	sub += closing_with

	for tag_name in tag_names:
		var norm_html_tags:RegEx = null
		if not tag_name in _man_close_re_cache:
			norm_html_tags = RegEx.create_from_string("<\\s*" +
														tag_name +
														"\\s*(?:.*?\\s*)?>(?<content>.+?)<\\s*/\\s*" +
														tag_name +
														"\\s*>"
														)
			_man_close_re_cache[tag_name] = norm_html_tags
		else:
			norm_html_tags = _man_close_re_cache.get(tag_name)
		html = norm_html_tags.sub(html, sub, true)
	return html

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored or removed in the future.
## A static function that replaces any html element (that [b]is[/b] self closing)
## with the given [param tag_names]
## in the provided [param html] body, returning the result.[br]
## [param tag_names] may be either a single [String] or an
## [Array] (or [PackedStringArray]) of [String]s.[br]
## By default this will match all tags (using the [code].?+[/code] regex pattern).[br]
## Multiple tag names will be handled in the order they are iterated from the array.[br]
## All names in [param tag_names] must be treated as (uncompiled) strings of [RegEx] patterns,
## including them having the ability to contain wildcard patterns like [code].?+[/code],
## and must be escaped as a regex pattern, if necessary.
## The html element matched is entirely replaced with [param with].[br]
## [br]
## For handling html tags that [b]are not[/b] self closing,
## see [method replace_html_tag_manual_closing].
static func replace_html_tag_self_closing(html:String,
										tag_names:Variant = ".+?",
										with := ""
										) -> String:
	match typeof(tag_names):
		TYPE_STRING:
			tag_names = [tag_names]
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			pass
		_:
			assert(false)

	for tag_name in tag_names:
		var norm_html_tags:RegEx = null
		if not tag_name in _auto_close_re_cache:
			norm_html_tags = RegEx.create_from_string("<\\s*" + tag_name + "\\s*.*?\\s*(?:/\\s*)??>")
			_auto_close_re_cache[tag_name] = norm_html_tags
		else:
			norm_html_tags = _auto_close_re_cache.get(tag_name)
		html = norm_html_tags.sub(html, with, true)
	return html

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored or removed in the future.
## A static function that removes any html comment in the provided [param html] body.[br]
static func html_remove_comments(html:String) -> String:
	return _comment_remove.sub(html, "", true)

## @experimental: This function may be heavily refactored or removed in the future.
## A static function that strips away the surrounding characters of a html CDATA element.[br][br]
## Note that CDATA elements are more used in xml contexts,
## and used in cases where the parser should not parse the content inside the
## CDATA elements.
## Ex:
## [codeblock]
## <[![CDATA
## 		(!simple && !elegant) > nothing //Improve it next time
## ]]>
## [/codeblock]
## turns into
## [codeblock]
## (!simple && !elegant) > nothing //Improve it next time
## [/codeblock]
## instead of raising a parsing error.[br]
static func html_strip_cdata_braces(html:String) -> String:
	return _cdata_strip.sub(html, "$content", true)

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored in the future.
## "Cleans" the text (as provided in [param desc])
## as xml text sourced from a rss description (or similarly formatted) feild,
## in various ways, returning the result.
## [br][br]
## Regardless of [param strip_tags],
## certain problematic html tags will always be erased entirely
## (removing both the tags themselves and the content within the element).[br]
## All whitespace (besides the space character (" ") itself) will be removed.[br]
## All space characters (" ") will be deduplicated
## (multiple consecutive " " characters will be converted into a single one).
## All html/xml comments will be removed.
## [br][br]
## When [param strip_tags] is set (as by default),
## all html/xml tags will be stripped without removing their internal text elements.
## When [param xml_unescape] is set (as by default), text elements will be unescaped.[br]
## When [param xml_unescape] is set ([b]not[/b] by default),
## all square braces will be escaped for use in bbcode.
static func clean_description(desc:String,
							bbcode_escape_braces := false,
							xml_unescape := true,
							strip_tags := true
							) -> String:
	desc = html_remove_comments(desc)

	# While its quite unlikely that a rss text body would
	# have an entire html document in it, its not impossible.
	# just filtering out the absolutely unecessary stuff for safety...
	var bad_elements := PackedStringArray([
											"head",
											"script",
											"style",
											"template",
											"embed",
											"iframe",
											"form",
											])
	# removing the tags and their contents
	desc = replace_html_tag_manual_closing(desc, bad_elements, "", "", false)

	if strip_tags:
		desc = replace_html_tag_manual_closing(desc) #all tags
		desc = replace_html_tag_self_closing(desc) #all tags

	if xml_unescape:
		desc = desc.xml_unescape()
	desc = html_strip_cdata_braces(desc)

	var buff := ""
	for c in desc:
		match c:
			# basically the same as String.trim_escapes()
			# but wrapped into another loop we already have to do
			var esc when ord(esc) <= 31:
				pass
			# deduplicate more then 1 space in a row,
			# and strip spaces that occur at the very start of the string
			# (all other kinds of whitespace are totally removed elsewhere)
			" " when buff.length() == 0 or buff[-1] == " ":
				pass
			"[" when bbcode_escape_braces:
				buff += "[lb]"
			"]" when bbcode_escape_braces:
				buff += "[rb]"
			_:
				buff += c
	#we already stripped left spaces in the loop above, so we can save some time here
	return buff.strip_edges(false, true)

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored in the future.
## An experimental method that takes a text body (as provided in [param html])
## as xml text sourced from a rss description (or similarly formatted) feild and
## attempts to roughly translate any html formatting into godot compatible bbcode.[br]
## This method can currently only handle the formatting implied by certain html tags.
## The only tags that have their attributes parsed are anchor ([code]a[/code]) tags.[br]
## Any embeddings contained within the provided [param html] are stripped and ignored,
## along with all javascript, css formatting (inline or linked), all iframes,
## and many other common features of html.
## [br][br]
## This method is provided as a rough example that allows for the majority
## of html text to be handled roughly.
## It is not suggested to be used as-is in any production environment
## without proper consideration.
## It is also of note that this method is not optimised for performance,
## using [RegEx] parsing instead of a proper xml parser,
## and will likely not perform well in most cases.
static func html_to_bbcode(html:String) -> String:
	# We'll handle other (non useless) html tags and unescaping manually,
	# but bbcode bracket escaping is necessary to do before we insert any bbcode tags
	html = clean_description(html, true, false, false)

	html = _title_attr_capture_regex.sub(html, "$tagstart[hint=$href]$content[/hint]$tagend", true)
	html = _lang_attr_capture_regex.sub(html, "$tagstart[hint=$href]$content[/hint]$tagend", true)

	# This converts anchor tags (and only anchor tags)
	# into a url element with a tooltip for the link it directs to.
	html = _anchor_href_capture_regex.sub(html, "[url=$href][hint=$href]$content[/hint][/url]", true)

	html = replace_html_tag_self_closing(html, "wbr", "[shy]")
	html = replace_html_tag_self_closing(html, "hr" , "[hr]" )
	html = replace_html_tag_self_closing(html, "br" , "[br]" )

	html = replace_html_tag_manual_closing(html, "p", "[p]", "[/p]")

	html = replace_html_tag_manual_closing(html, ["b", "strong"], "[b]", "[/b]")

	html = replace_html_tag_manual_closing(html, ["i", "em", "cite"], "[i]"    , "[/i]"    )
	html = replace_html_tag_manual_closing(html, "address"          , "[br][i]", "[/i][br]")

	html = replace_html_tag_manual_closing(html, ["u", "ins"], "[u]", "[/u]")

	html = replace_html_tag_manual_closing(html, ["s", "strike", "del"], "[s]", "[/s]")

	var code_style_tags := PackedStringArray(["code", "samp", "dir", "var", "tt", "kbd"])
	html = replace_html_tag_manual_closing(html, code_style_tags, "[code]", "[/code]")

	html = replace_html_tag_manual_closing(html, "blockquote", "[indent][i]", "[/i][/indent]")
	html = replace_html_tag_manual_closing(html, "q"         , "[i]"        , "[/i]"         )

	html = replace_html_tag_manual_closing(html, "mark", "[bg_color=yellow]", "[/bg_color]")

	html = replace_html_tag_manual_closing(html, "center", "[center]", "[/center]")

	html = replace_html_tag_manual_closing(html, "h1"        , "[font_size=22]", "[/font_size]")
	html = replace_html_tag_manual_closing(html, ["h2", "h3"], "[font_size=20]", "[/font_size]")
	var size_18_tags := PackedStringArray(["h4", "h5", "h6", "summary"])
	html = replace_html_tag_manual_closing(html, size_18_tags, "[font_size=18]", "[/font_size]")
	html = replace_html_tag_manual_closing(html, "big"       , "[font_size=16]", "[/font_size]")
	html = replace_html_tag_manual_closing(html, "small"     , "[font_size=8]" , "[/font_size]")

	html = replace_html_tag_manual_closing(html, ["ul", "menu", "dl"], "[ul]"     , "[/ul]"      )
	html = replace_html_tag_manual_closing(html, "ol"                , "[ol]"     , "[/ol]"      )
	html = replace_html_tag_manual_closing(html, ["li", "dd"]        , ""         , "\n"         )
	html = replace_html_tag_manual_closing(html, "dt"                , "[indent]" , "[/indent]\n")

	# While the a xml parser could handle html attrs (and tags parsing),
	# this is a lot of extra overhead as well as possible additional security concerns
	# for a feature that is not the main focus of this addon.
	# As well, the amount of regex used is already pushing the boundaries of reasonable,
	# so it better to avoid using regex any more then it already is.
	# So, this version of this function will not support any type of xml attributes nor css styles.
	# Unfortunately, this means the more common types of text formatting
	# (including color, bg color, justification, size, and urls other than anchor links)
	# arn't supported.

	html = replace_html_tag_manual_closing(html) #all tags
	html = replace_html_tag_self_closing(html) #all tags

	return html.xml_unescape()

## Gets [PackedByteArray] data from the given [param host] URL at the given [param path].[br]
## Due to how Godot handles http, it's important to accurately split the
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

	if http_client.request(HTTPClient.METHOD_GET, path, PackedStringArray(headers)) != OK:
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

	var rb := PackedByteArray()
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
## Due to how Godot handles http, it's important to accurately split the
## URL's [param host] from the URL's [param path]. See [method url_split_host_path].[br]
## NOTE: This RSS feed is statically fetched and will not automatically update itself.
## Behaviour like this must be implemented manually.[br]
## [br]
## [param description_formatter] is a optional [Callable] used to
## format the text data provided by some text based fields or rss documents;
## currently, only the descriptions or channels, items, and channel images.
## Some feeds may prefer to provide plaintext,
## however, others might use for advances xml or html formatting.
## By supplying this paramiter with a valid [Callable] that accepts a single argument
## of the text to format and returns a formatted version of that text,
## all of these fields will receive the same type of text formatting adjustments.
## If the [param description_formatter] is not [Callable.is_valid], like it is by default,
## [param description_formatter] will be skipped and the text will pass through unformatted.
static func load_url(host:String,
					path := "/",
					description_formatter:Callable = Callable(null, "invalid"),
					headers:Array[String] = DEFAULT_HTTP_HEADERS,
					port:int = -1
					) -> RSS:
	var rb := await get_http_bytes(host, path, headers, port)

	if rb.is_empty():
		return null

	return load_data(rb, description_formatter)

## Loads a [RSS] feed right from a given [String]'s [param data].[br]
## See [method RSS.load_url] for more information about the [param description_formatter]
## paramiter, as it applies the same for [method RSS.load_url] as it does here.
static func load_string(data:String,
						description_formatter:Callable = Callable(null, "invalid")
						) -> RSS:
	return load_xml_document(XML.parse_str(data), description_formatter)

## Loads a [RSS] feed right from a given [PackedByteArray]'s [param data].[br]
## See [method RSS.load_url] for more information about the [param description_formatter]
## paramiter, as it applies the same for [method RSS.load_url] as it does here.
static func load_data(data:PackedByteArray,
					description_formatter:Callable = Callable(null, "invalid")
					) -> RSS:
	if data.is_empty():
		return
	return RSS.load_xml_document(XML.parse_buffer(data), description_formatter)

## Loads a [RSS] feed right from a given [XMLDocument]'s [param data].[br]
## See [method RSS.load_url] for more information about the [param description_formatter]
## paramiter, as it applies the same for [method RSS.load_url] as it does here.
static func load_xml_document(document:XMLDocument,
							description_formatter:Callable = Callable(null, "invalid")
							) -> RSS:
	if document.root == null:
		return null
	return load_xml_node(document.root, description_formatter)

## Loads a [RSS] feed right from a given [XMLNode]'s [param data].[br]
## See [method RSS.load_url] for more information about the [param description_formatter]
## paramiter, as it applies the same for [method RSS.load_url] as it does here.
static func load_xml_node(node:XMLNode,
							description_formatter:Callable = Callable(null, "invalid")
							) -> RSS:
	if node.name != RSS_TAG_NAME:
		#This isn't a rss feed at all! Perhaps you loaded html or svg data by accident?
		return null

	var created := RSS.new()
	created.version = node.attributes.get(VERSION_ATTR_NAME, "")
	for child in node.children:
		created.channels.append(RSSChannel.load_xml_node(child, description_formatter))

	return created

## Converts a given [param string] to a [RSSDay] as expected when parsing a [RSSChannel]'s
## [member RSSChannel.skip_days].
static func string_to_rss_day(string:String) -> RSSDay:
	string = string.to_lower().strip_edges().rstrip(".").substr(0, 3)
	assert(_STR_TO_RSS_DAY.has(string))
	return _STR_TO_RSS_DAY[string]
