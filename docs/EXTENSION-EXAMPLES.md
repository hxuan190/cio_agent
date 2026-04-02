# Extension Examples: 3 Reference Domains

These are **reference implementations** showing how to build domains. Copy the structure and adapt to your needs.

## Domain 1: Solana Infrastructure (`solana-infra`)

**Purpose:** Foundation for all Solana operations (RPC, WebSocket, validator monitoring)

**Structure:**
```
domains/solana-infra/
├── agents/
│   ├── rpc-monitor.md
│   ├── ws-subscription-manager.md
│   └── validator-health-checker.md
├── services/
│   ├── rpc-wrapper/
│   │   └── Handles RPC pooling, retry logic, metrics
│   ├── ws-aggregator/
│   │   └── Manages WebSocket subscriptions, deduplication
│   └── validator-monitor/
│       └── Polls chain state, tracks validator changes
├── skills/
│   ├── solana-rpc-patterns.md
│   ├── websocket-optimization.md
│   └── validator-health-checks.md
├── rules/
│   ├── performance.md (RPC <100ms, WS >99.9% uptime)
│   ├── security.md (TLS validation, no private keys)
│   └── testing.md (devnet, load testing)
└── config/
    └── solana-infra.yaml
```

**Key Agent (rpc-monitor.md):**
```markdown
---
name: rpc-monitor
description: Monitors Solana RPC health and latency
domain: solana-infra
---

# RPC Monitor Agent

You monitor the health of Solana RPC endpoints and recommend fallbacks.

## Workflow

1. Poll RPC health: GET /health
2. Measure latency: Time round-trip
3. If latency > 500ms: Recommend fallback
4. If health fails: Switch to backup endpoint
5. Log with trace_id, latency_ms, endpoint

## Success Criteria

- RPC latency <100ms (P95)
- Uptime >99.9%
- Automatic fallback when primary fails
```

**Key Service Stub (rpc-wrapper/main.go):**
```golang
package main

import (
  "context"
  "github.com/rs/zerolog"
  "net/http"
)

type RPCClient struct {
  endpoints []string
  current   int
  logger    zerolog.Logger
}

func (c *RPCClient) Call(ctx context.Context, method string) (interface{}, error) {
  // TODO: Implement RPC call with pooling, retry, metrics
  return nil, nil
}

func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
  })
  mux.HandleFunc("/call", func(w http.ResponseWriter, r *http.Request) {
    // TODO: Handle RPC call
  })
  http.ListenAndServe(":5000", mux)
}
```

---

## Domain 2: DEX Operations (`dex-operations`)

**Purpose:** Order aggregation, execution, liquidity analysis

**Structure:**
```
domains/dex-operations/
├── agents/
│   ├── order-aggregator.md (Fetch & rank pools)
│   ├── liquidity-analyzer.md (Calculate slippage)
│   └── execution-optimizer.md (Route selection)
├── services/
│   ├── order-aggregator/
│   │   └── Calls Raydium, Orca, Serum APIs
│   ├── liquidity-analyzer/
│   │   └── Precision math (math/big), impact calc
│   └── execution-engine/
│       └── Builds & signs transactions
├── skills/
│   ├── dex-pool-patterns.md (CPAMM, concentrated liquidity)
│   ├── slippage-calculation.md (Precision math)
│   └── execution-routing.md (Which DEX? Why?)
├── rules/
│   ├── performance.md (<1s total, <0.5% slippage)
│   ├── security.md (No private keys, signed txs only)
│   └── testing.md (Devnet simulation, load test)
└── config/
    └── dex-operations.yaml (Dependencies: solana-infra)
```

**Key Agent (order-aggregator.md):**
```markdown
---
name: order-aggregator
description: Aggregates orders from Raydium, Orca, Serum
domain: dex-operations
depends: [solana-infra, cost-aware-llm-pipeline]
---

# Order Aggregator Agent

You fetch orders from multiple DEXes and rank by slippage/impact.

## Workflow

1. Accept: token mint, swap direction, amount
2. Call RPC (via solana-infra): Get pool data
3. Call service: POST /order-aggregator/aggregate
4. Analyze: slippage, impact, fees
5. Decide: "Best route is Raydium (0.3% slippage vs 0.8% Orca)"
6. Log: trace_id, latency_ms, comparison metrics

## Service Contract

POST /order-aggregator/aggregate
```

**Key Skill (dex-pool-patterns.md):**
```markdown
# DEX Pool Patterns

## Raydium Formula

output = (inputAmount × outputReserve) / (inputReserve + inputAmount)
slippage = (expectedOutput - actualOutput) / expectedOutput

## Orca Formula

More complex due to concentrated liquidity ticks.

## Best Practices

1. Always use math/big for precision
2. Check LP lock status
3. Validate reserves > 0
4. Monitor impact trends

## Examples

[Provide Go code examples with math/big]
```

---

## Domain 3: MEV/Security (`mev-security`)

**Purpose:** Detect sandwich attacks, exploits, flashloans

**Structure:**
```
domains/mev-security/
├── agents/
│   ├── sandwich-detector.md (Analyze mempool)
│   ├── exploit-scanner.md (Pattern matching)
│   └── flashloan-monitor.md (Track flashloan usage)
├── services/
│   ├── sandwich-detector/
│   │   └── Mempool analysis, ordering risk
│   ├── exploit-scanner/
│   │   └── Known exploit patterns
│   └── flashloan-monitor/
│       └── Flashloan detection & alerting
├── skills/
│   ├── sandwich-detection.md (Mempool ordering, TX ordering)
│   ├── exploit-patterns.md (Common MEV exploits)
│   └── flashloan-basics.md (Mechanics, detection)
├── rules/
│   ├── performance.md (<500ms detection)
│   ├── security.md (Never propose malicious txs)
│   └── testing.md (Mempool simulation)
└── config/
    └── mev-security.yaml (Dependencies: solana-infra, dex-operations)
```

**Key Agent (sandwich-detector.md):**
```markdown
---
name: sandwich-detector
description: Detects sandwich attack risk in mempool
domain: mev-security
depends: [solana-infra, dex-operations]
---

# Sandwich Detector Agent

You analyze mempool ordering to detect sandwich attack risk.

## Workflow

1. User executes a swap
2. Post-execution, call MEV detector
3. Analyze: Is this swap sandwichable?
4. Return risk assessment:
   - Safe: <1% sandwich risk
   - Caution: 1-5% risk
   - Warning: 5-10% risk
   - Critical: >10% risk

## Service Contract

POST /sandwich-detector/analyze
{
  "swapMint": "...",
  "amount": "...",
  "expectedOutput": "...",
  "actualOutput": "...",
  "dex": "raydium"
}

Response: { riskPercent: 3.5, riskLevel: "caution", recommendation: "..." }
```

**Key Skill (sandwich-detection.md):**
```markdown
# Sandwich Detection

## How Sandwich Attacks Work

1. Attacker sees pending user swap in mempool
2. Attacker frontruns: buys same token → price increases
3. User swap executes at worse price
4. Attacker backruns: sells token → price decreases, keeps profit

## Detection Signals

- Unusual trading activity before TX
- Same token bought by multiple addresses
- Price impact > expected
- MEV reward > 0.1 SOL

## Protection

- Use private RPCs
- Set tight slippage tolerance
- Use DEXes with private order pools
- Monitor for sandwich risk post-execution
```

---

## How to Use These Examples

### Copy & Adapt

```bash
# Start with solana-infra (foundation)
cp -r docs/EXTENSION-EXAMPLES/solana-infra domains/

# Customize for your RPC endpoints
# Edit: domains/solana-infra/services/rpc-wrapper/main.go
# Add: Your RPC URLs, health check logic

# Build & test
cd domains/solana-infra/services/rpc-wrapper
go build -o rpc-wrapper
./rpc-wrapper --port 5000

# Agent should now work
claude-code
> /tdd                  # Test agent framework
> [Let me fetch RPC status]  # Uses your domain
```

### Domain Dependencies

```
solana-infra
  ↓
  ├─ dex-operations (calls RPC via solana-infra)
  │  ↓
  └─ mev-security (analyzes swaps from dex-operations)
```

When deploying:
1. Start solana-infra (foundation)
2. Then dex-operations (depends on solana-infra)
3. Then mev-security (depends on both)

### Testing Progression

**Phase 1 (solana-infra working):**
```bash
curl http://localhost:5000/health  # Should return 200
```

**Phase 2 (dex-operations working):**
```bash
curl -X POST http://localhost:5001/order-aggregator/aggregate \
  -d '{"mint": "...", "amount": "1000000"}'
```

**Phase 3 (mev-security working):**
```bash
curl -X POST http://localhost:5002/sandwich-detector/analyze \
  -d '{"swapMint": "...", "actualOutput": "..."}'
```

---

## What's Next?

1. **Pick a domain:** Start with solana-infra
2. **Copy structure:** Use this as template
3. **Implement services:** Add your Go code
4. **Test agents:** Verify agent-to-service calls
5. **Extend:** Add your domain-specific logic
6. **Measure:** Track performance, latency, accuracy

See `docs/HOW-TO-ADD-DOMAINS.md` for step-by-step guide.

Happy building! 🚀
