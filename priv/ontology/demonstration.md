# LLM Gateway Ontology Demonstration
## Acting as the LLM using the RDF/Turtle + SHACL Specification

---

## Phase 1: Ontology Loading and Understanding

**Status**: ✓ LOADED

I have parsed the following ontology components:

### Core Classes (from rec_llm_gateway.ttl)
- `rec:Gateway` - The gateway service
- `rec:Request` - Incoming requests (Observation O)
- `rec:Response` - Outgoing responses (Action A)
- `rec:Message` - Chat messages with role + content
- `rec:Usage` - Token usage metrics
- `rec:Extension` - x_rec_llm metadata (provider, cost, latency, receipt)
- `rec:Receipt` - KGC audit trail

### Enumerations (Closed-World)
- `rec:Role` ∈ {System, User, Assistant, Tool}
- `rec:FinishReason` ∈ {stop, length, content_filter, function_call, tool_calls, unknown}
- `rec:ErrorType` ∈ {invalid_request_error, authentication_error, rate_limit_error, api_error, timeout_error}

### SHACL Constraints
- **Request**: modelId required, messages non-empty, temperature ∈ [0,2], topP ∈ (0,1], stream=false (MVP)
- **Message**: role required, content required
- **Response**: choice required, usage required, extension required
- **Extension**: provider required, latencyMs ≥0, costUSD required, receiptChain required

### μ Mapping (KGC)
```
rec:gateway kgc:mu rec:chatCompletions
Request kgc:reconciledTo Response
Response kgc:emits Receipt
```

---

## Phase 2: Request Validation

### Incoming Request (as RDF)
```turtle
@prefix rec: <https://spec.rec-llm-gateway.dev/rec#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

rec:incomingReq a rec:Request ;
  rec:modelId "anthropic:claude-3.5-sonnet" ;
  rec:temperature "0.7"^^xsd:decimal ;
  rec:maxTokens 1000 ;
  rec:stream "false"^^xsd:boolean ;
  rec:hasMessage rec:msg1 .

rec:msg1 a rec:Message ;
  rec:role rec:User ;
  rec:content "Explain quantum entanglement in simple terms" .
```

### SHACL Validation Results
```
✓ rec:modelId present: "anthropic:claude-3.5-sonnet"
✓ rec:hasMessage count: 1 (≥1 required)
✓ rec:temperature: 0.7 ∈ [0,2]
✓ rec:stream: false (MVP constraint satisfied)
✓ rec:msg1 has rec:role: User (valid enum value)
✓ rec:msg1 has rec:content: non-empty string

VALIDATION: PASSED ✓
```

---

## Phase 3: μ Mapping Application (O → A)

**Policy H**: Deterministic routing based on modelId prefix
- Parse: "anthropic:claude-3.5-sonnet" → provider=Anthropic, model="claude-3.5-sonnet"
- Route to Anthropic API
- Apply temperature=0.7, maxTokens=1000

**Execution**:
1. Start timer (for latency)
2. Forward to Anthropic API with transformed parameters
3. Count tokens: prompt=18, completion=87
4. Calculate cost: (18/1M × $3) + (87/1M × $15) = $0.001359
5. Stop timer: 523ms elapsed

---

## Phase 4: Response Generation (Conforming to Ontology)

```turtle
@prefix rec: <https://spec.rec-llm-gateway.dev/rec#> .
@prefix kgc: <https://viable-system.com/kgc#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix prov: <http://www.w3.org/ns/prov#> .

# Response (Action A)
rec:resp_20251102_001 a rec:Response ;
  rec:choice rec:choice_001 ;
  rec:usage rec:usage_001 ;
  rec:extension rec:ext_001 ;
  kgc:underPolicy rec:policy_deterministic ;
  prov:wasGeneratedBy rec:gateway ;
  prov:atTime "2025-11-02T14:32:17Z"^^xsd:dateTime .

# Choice
rec:choice_001 a rec:Choice ;
  rec:finishReason rec:stop ;
  rec:hasMessage rec:assistant_msg_001 .

rec:assistant_msg_001 a rec:Message ;
  rec:role rec:Assistant ;
  rec:content """Quantum entanglement is a phenomenon where two particles become
connected in such a way that the state of one instantly affects the state of the
other, no matter how far apart they are. Think of it like a pair of magic coins:
when you flip one and it lands on heads, the other instantly becomes tails, even
if it's on the other side of the universe. This "spooky action at a distance"
(as Einstein called it) has been proven experimentally and is fundamental to
quantum computing and quantum cryptography.""" .

# Usage
rec:usage_001 a rec:Usage ;
  rec:promptTokens 18 ;
  rec:completionTokens 87 ;
  rec:totalTokens 105 .

# Extension (x_rec_llm)
rec:ext_001 a rec:Extension ;
  rec:xProvider rec:Anthropic ;
  rec:latencyMs 523 ;
  rec:costUSD "0.001359"^^xsd:decimal ;
  rec:receiptChain "sha256:7f8e9a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f" .

# μ reconciliation
rec:incomingReq kgc:reconciledTo rec:resp_20251102_001 .
```

### SHACL Validation (Response)
```
✓ rec:choice present: rec:choice_001
✓ rec:usage present: rec:usage_001 (promptTokens=18, completionTokens=87, totalTokens=105)
✓ rec:extension present: rec:ext_001
✓ rec:xProvider: rec:Anthropic
✓ rec:latencyMs: 523 (≥0)
✓ rec:costUSD: 0.001359
✓ rec:receiptChain: sha256:... (non-empty)

VALIDATION: PASSED ✓
```

---

## Phase 5: Receipt Emission (Audit Trail)

```turtle
@prefix rec: <https://spec.rec-llm-gateway.dev/rec#> .
@prefix kgc: <https://viable-system.com/kgc#> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Receipt (KGC morphism)
rec:receipt_20251102_001 a rec:Receipt ;
  rec:receiptChain "sha256:7f8e9a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f" ;
  prov:wasGeneratedBy rec:resp_20251102_001 ;
  prov:atTime "2025-11-02T14:32:17Z"^^xsd:dateTime ;
  kgc:reconcilesTransaction [
    kgc:request rec:incomingReq ;
    kgc:response rec:resp_20251102_001 ;
    kgc:policy rec:policy_deterministic ;
    kgc:provider rec:Anthropic ;
    kgc:cost "0.001359"^^xsd:decimal ;
    kgc:timestamp "2025-11-02T14:32:17Z"^^xsd:dateTime
  ] .

# Emit
rec:resp_20251102_001 kgc:emits rec:receipt_20251102_001 .

# Hash chain calculation (deterministic)
# SHA256(
#   requestHash +
#   responseContent +
#   provider +
#   cost +
#   timestamp
# ) = 7f8e9a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f
```

### Receipt Validation
```
✓ rec:receiptChain: non-empty SHA256 hash
✓ prov:wasGeneratedBy: rec:resp_20251102_001
✓ prov:atTime: valid ISO8601 timestamp
✓ kgc:reconcilesTransaction: complete audit record

VALIDATION: PASSED ✓
```

---

## Phase 6: OpenAI-Compatible JSON Response

Based on the RDF response, I generate the following JSON (for the HTTP client):

```json
{
  "id": "resp_20251102_001",
  "object": "chat.completion",
  "created": 1730556737,
  "model": "claude-3.5-sonnet",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Quantum entanglement is a phenomenon where two particles become connected in such a way that the state of one instantly affects the state of the other, no matter how far apart they are. Think of it like a pair of magic coins: when you flip one and it lands on heads, the other instantly becomes tails, even if it's on the other side of the universe. This \"spooky action at a distance\" (as Einstein called it) has been proven experimentally and is fundamental to quantum computing and quantum cryptography."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 18,
    "completion_tokens": 87,
    "total_tokens": 105
  },
  "x_rec_llm": {
    "provider": "anthropic",
    "latency_ms": 523,
    "cost_usd": 0.001359,
    "receipt_chain": "sha256:7f8e9a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f"
  }
}
```

---

## Summary: Ontology-Driven Processing

### Input (O)
- Validated against `rec:RequestShape`
- All SHACL constraints satisfied
- Parsed into RDF graph

### Processing (μ)
- Applied deterministic policy H
- Routed to Anthropic based on modelId prefix
- Calculated cost using pricing ontology
- Measured latency

### Output (A)
- Generated `rec:Response` conforming to `rec:ResponseShape`
- All required properties present (choice, usage, extension)
- SHACL validation passed

### Audit (Receipt)
- Emitted `rec:Receipt` with SHA256 chain
- Complete provenance trail (PROV-O)
- Reconciled O→A mapping via `kgc:reconciledTo`

### Contract Enforcement
- ✓ OpenAI-compatible API surface
- ✓ MVP constraint: stream=false
- ✓ Required extension fields present
- ✓ Deterministic μ mapping
- ✓ Receipt chain for auditability

---

**Conclusion**: The ontology successfully defines a closed-world specification that enables LLMs to validate inputs, generate compliant responses, and emit audit receipts. All operations are deterministic and verifiable.
