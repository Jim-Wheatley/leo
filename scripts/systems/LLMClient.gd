extends Node
## Minimal HTTP client for LM Studio's OpenAI-compatible /v1/chat/completions endpoint.
## 
## Usage:
##   var client = LLMClient.new()
##   var response = await client.call_completions(messages, max_tokens)
##   if response.ok:
##       var content = response.content
##   else:
##       print("Error: ", response.error)

class_name LLMClient

const BASE_URL = "http://127.0.0.1:1234"
const BASE_URL_FALLBACK = "http://localhost:1234"
const ENDPOINT = "/v1/chat/completions"
const TIMEOUT_SECONDS = 60.0

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	http_request.timeout = TIMEOUT_SECONDS
	add_child(http_request)

## Call the LLM with a list of messages. Returns a dict with ok, content, and error fields.
func call_completions(messages: Array, max_tokens: int = 512) -> Dictionary:
	var request_body = {
		"model": "local-model",
		"messages": messages,
		"temperature": 0.7,
		"max_tokens": max_tokens
	}
	
	var json_string = JSON.stringify(request_body)
	var headers = ["Content-Type: application/json"]
	var urls_to_try = [
		BASE_URL + ENDPOINT,
		BASE_URL_FALLBACK + ENDPOINT
	]
	
	var attempt_errors: Array = []
	
	for url in urls_to_try:
		var request_error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
		if request_error != OK:
			attempt_errors.append("%s -> send failed (code %d)" % [url, request_error])
			continue
		
		# Wait for response
		# Signal provides: result (request status), response_code, headers, body
		var signal_result = await http_request.request_completed
		var request_result: int = signal_result[0]
		var response_code: int = signal_result[1]
		var body: PackedByteArray = signal_result[3]
		var body_string: String = body.get_string_from_utf8()
		
		# If request failed before HTTP response, include engine result code.
		if request_result != 0:
			attempt_errors.append("%s -> request result %d (no HTTP response)" % [url, request_result])
			continue
		
		# Check HTTP status
		if response_code != 200:
			attempt_errors.append("%s -> HTTP %d: %s" % [url, response_code, body_string])
			continue
		
		# Parse JSON response
		var response = JSON.parse_string(body_string)
		if response == null:
			attempt_errors.append("%s -> failed to parse JSON" % url)
			continue
		
		# Check for API errors
		if response.has("error"):
			attempt_errors.append("%s -> API error: %s" % [url, response["error"].get("message", "Unknown")])
			continue
		
		# Extract the message content
		if response.has("choices") and response["choices"].size() > 0:
			var choice = response["choices"][0]
			if choice.has("message") and choice["message"].has("content"):
				var content = choice["message"]["content"]
				return {"ok": true, "error": "", "content": content}
		
		attempt_errors.append("%s -> invalid response format" % url)
	
	return {
		"ok": false,
		"error": "All endpoints failed: %s" % " | ".join(attempt_errors),
		"content": ""
	}
