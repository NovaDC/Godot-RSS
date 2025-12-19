class_name RSSExampleFormattingTools

## RSSExampleFormattingTools
##
## Various formatting tools for RSS feed fields.
## This is not strictly necessary for operation of GodotRSS,
## but instead contributes to the examples for GodotRSS,
## while also serving as a rough example of what formatting functions can do.
## The functions in this class are not held to standards fit for production.

static var _comment_remove := RegEx.create_from_string("<!--(.*?)-->")
static var _cdata_strip := RegEx.create_from_string("<!\\[CDATA\\[(?<content>[^\\]]+?)\\]\\]>")
static var _man_close_re_cache:Dictionary = {}
static var _auto_close_re_cache:Dictionary = {}
static var _title_attr_capture_regex := RegEx.create_from_string(
"(?<tagstart>" +
	"<\\s*" +
	"(?<tagname>[_a-zA-Z0-9]+)" +
	"\\s*(?:.*?\\s*)??" +
	"(title ?= ?[\"'](?<title>[^\"']+?)[\"'])" +
	"(?:.*?\\s*)??>" +
")" +
"(?<content>.+?)" +
"(?<tagend><\\s*/\\s*\\k<tagname>\\s*>)"
)
static var _lang_attr_capture_regex := RegEx.create_from_string(
"(?<tagstart>" +
	"<\\s*" +
	"(?<tagname>[_a-zA-Z0-9]+)" +
	"\\s*(?:.*?\\s*)??" +
	"((xml:)?lang ?= ?[\"'](?<lang>[^\"']+?)[\"'])" +
	"(?:.*?\\s*)??>" +
")" +
"(?<content>.+?)" +
"(?<tagend><\\s*/\\s*\\k<tagname>\\s*>)"
)
static var _anchor_href_capture_regex := RegEx.create_from_string(
"<\\s*a\\s*(?:.*?\\s*)??(href ?= ?[\"'](?<href>[^\"']+?)[\"'])(?:.*?\\s*)?>" +
"(?<content>.+?)" +
"<\\s*/\\s*a\\s*>"
)

## @experimental: This function may not handle all html documents properly.
## @experimental: This function may be heavily refactored or removed in the future.
## @experimental: This function is primarily to be used with / as an example.
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
## @experimental: This function is primarily to be used with / as an example.
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
## @experimental: This function is primarily to be used with / as an example.
## A static function that removes any html comment in the provided [param html] body.[br]
static func html_remove_comments(html:String) -> String:
	return _comment_remove.sub(html, "", true)

## @experimental: This function may be heavily refactored or removed in the future.
## @experimental: This function is primarily to be used with / as an example.
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
## @experimental: This function is primarily to be used with / as an example.
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

