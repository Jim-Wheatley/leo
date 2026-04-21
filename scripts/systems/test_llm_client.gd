extends Node
## Quick test to verify LLMClient connects to LM Studio and gets a response.
## Attach to a test scene or run standalone.

var llm_client: LLMClient

func _ready():
	llm_client = LLMClient.new()
	add_child(llm_client)
	
	print("=== LLMClient Test ===")
	print("Testing connection to LM Studio at http://127.0.0.1:1234...")
	
	await test_simple_prompt()

func test_simple_prompt():
	var messages = [
		{
			"role": "system",
			"content": "You are a helpful assistant. Respond briefly."
		},
		{
			"role": "user",
			"content": "Say 'Hello from Godot!' and nothing else."
		}
	]
	
	print("\nSending request...")
	var response = await llm_client.call_completions(messages, 50)
	
	if response["ok"]:
		print("✓ Success!")
		print("Response: ", response["content"])
	else:
		print("✗ Failed!")
		print("Error: ", response["error"])
