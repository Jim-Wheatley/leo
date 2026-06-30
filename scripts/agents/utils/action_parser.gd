extends RefCounted
## ActionParser — extracts [ACTION: verb target ...] tags from an agent's reply.
##
## Agents speak in plain natural language but may embed structured actions:
##   [ACTION: move market]
##   [ACTION: speak Player]
##   [ACTION: give Player pigment]
##   [ACTION: inspect commission]
##
## AgentManager calls ActionParser.parse(reply) to get a list of structured
## actions, then routes the recognised ones to game systems. The parser is
## deliberately forgiving: LLM output is untrusted, so it NEVER rejects or
## crashes — unknown verbs come back flagged recognized=false for the caller
## to log and ignore, and malformed/empty tags are simply skipped.
##
## All methods are static; nothing here touches game state.

class_name ActionParser

## Verbs the simulation knows how to route. Extend as you wire up more systems
## in AgentManager. Anything not in here still parses, just recognized=false.
const KNOWN_VERBS := [
	"move",     # change location:        [ACTION: move market]
	"speak",    # address someone:        [ACTION: speak Player]
	"give",     # hand over an item:      [ACTION: give Player pigment]
	"take",     # acquire an item:        [ACTION: take pigment]
	"inspect",  # examine something:      [ACTION: inspect commission]
	"work",     # labour on something:    [ACTION: work commission]
	"wait",     # pass the turn:          [ACTION: wait]
	"emote",    # express a mood/gesture: [ACTION: emote sigh]
]

## Lazily-compiled, reused across calls. Matches "[ACTION: ... ]" case-
## insensitively; the inner capture is everything up to the closing bracket.
static var _regex: RegEx = null


## Parse every [ACTION: ...] tag in `text`. Returns an Array of Dictionaries:
##   { verb: String (lowercased), target: String, args: Array[String],
##     recognized: bool, raw: String }
## Returns [] when there are no (valid) tags.
static func parse(text: String) -> Array:
	var actions: Array = []
	if text == null or text.strip_edges() == "":
		return actions

	_ensure_regex()
	for m in _regex.search_all(text):
		var inner := m.get_string(1).strip_edges()
		if inner == "":
			continue  # malformed: "[ACTION:]" — skip, don't crash

		# Split on any run of whitespace; drop empties from double spaces.
		var tokens: PackedStringArray = inner.split(" ", false)
		var clean: Array[String] = []
		for t in tokens:
			var ts := t.strip_edges()
			if ts != "":
				clean.append(ts)
		if clean.is_empty():
			continue

		var verb := clean[0].to_lower()
		var target := clean[1] if clean.size() > 1 else ""
		var args: Array[String] = []
		if clean.size() > 2:
			args = clean.slice(2)

		actions.append({
			"verb": verb,
			"target": target,
			"args": args,
			"recognized": verb in KNOWN_VERBS,
			"raw": m.get_string(0),
		})

	return actions


## Return `text` with every [ACTION: ...] tag removed and whitespace tidied —
## i.e. just the spoken/narrated prose, suitable for the dialogue UI.
static func strip_actions(text: String) -> String:
	if text == null or text == "":
		return ""
	_ensure_regex()
	var stripped := _regex.sub(text, "", true)
	# Collapse the double spaces / stray newlines left where tags were removed.
	var ws := RegEx.new()
	ws.compile("[ \\t]{2,}")
	stripped = ws.sub(stripped, " ", true)
	return stripped.strip_edges()


## Human-readable one-liner for logging a parsed action.
static func describe(action: Dictionary) -> String:
	var s := "%s" % action.get("verb", "?")
	if action.get("target", "") != "":
		s += " -> %s" % action["target"]
	var args: Array = action.get("args", [])
	if not args.is_empty():
		s += " (%s)" % ", ".join(args)
	if not action.get("recognized", false):
		s += "  [UNKNOWN VERB]"
	return s


static func _ensure_regex() -> void:
	if _regex == null:
		_regex = RegEx.new()
		# (?i) case-insensitive; capture everything up to the first ']'.
		_regex.compile("(?i)\\[ACTION:\\s*([^\\]]*)\\]")
