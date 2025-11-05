#!/bin/bash

echo "================================================"
echo "ReqLLMGateway Feature Demonstration"
echo "================================================"
echo ""

echo "✅ Test 1: Request Validation (Missing messages field)"
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4"}' | python3 -m json.tool
echo ""
echo ""

echo "✅ Test 2: Request Validation (Invalid messages format)"
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": "not an array"}' | python3 -m json.tool
echo ""
echo ""

echo "✅ Test 3: Provider Routing (Multiple providers accepted)"
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "anthropic:claude-3-sonnet", "messages": [{"role": "user", "content": "test"}]}' | python3 -m json.tool
echo ""
echo ""

echo "✅ Test 4: Streaming Rejection"
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "test"}], "stream": true}' | python3 -m json.tool
echo ""
echo ""

echo "✅ Test 5: Rate Limiting (100 requests in 5 seconds should trigger limit)"
echo "Making 105 rapid requests..."
for i in {1..105}; do
  curl -s -X POST http://localhost:4001/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "test"}]}' > /dev/null &
done
wait
echo "Last request (should show rate limit error):"
curl -s -X POST http://localhost:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "test"}]}' | python3 -m json.tool
echo ""
echo ""

echo "================================================"
echo "Demo Complete!"
echo "View LiveDashboard at: http://localhost:4001/dashboard"
echo "================================================"
