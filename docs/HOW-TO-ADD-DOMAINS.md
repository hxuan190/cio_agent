# How to Add a New Domain to HFT-Harness

This guide shows teams how to extend the harness with domain-specific agents, services, skills, and rules.

## Philosophy

- **Core Harness:** Minimal, stable (session, hooks, state, config, core agents/skills)
- **Domains:** Pluggable extensions (agents call Go microservices)
- **Independence:** Domains don't modify core; can be developed/deployed independently
- **Composition:** Teams mix/match domains via manifests

## Step 1: Create Domain Directory Structure

```bash
# From repository root
mkdir -p domains/{domain-name}/{agents,services,skills,rules,config}

# Example: Creating a DEX operations domain
mkdir -p domains/dex-operations/{agents,services,skills,rules,config}
```

### Directory Layout

```
domains/dex-operations/
├── agents/                    # Domain-specific agents (Markdown)
│   ├── order-aggregator.md
│   ├── liquidity-analyzer.md
│   └── execution-optimizer.md
├── services/                  # Go microservices
│   ├── order-aggregator/
│   │   ├── main.go
│   │   ├── service.go
│   │   └── go.mod
│   ├── liquidity-analyzer/
│   └── execution-engine/
├── skills/                    # Domain knowledge (reusable patterns)
│   ├── dex-pool-patterns.md
│   ├── slippage-calculation.md
│   └── execution-routing.md
├── rules/                     # Domain-specific standards
│   ├── performance.md         # <1s latency, <0.5% slippage
│   ├── security.md            # Private key isolation, signed txs
│   └── testing.md             # Devnet simulation, load tests
└── config/
    └── dex-operations.yaml    # Domain manifest
```

## Step 2: Create Domain Agents

**File:** `domains/{domain-name}/agents/{agent-name}.md`

```markdown
---
name: order-aggregator
description: Fetches and ranks orders from multiple DEX pools for best execution
domain: dex-operations
depends:
  - golang-hft-optimizer     # Reuse core patterns
  - cost-aware-llm-pipeline
---

# Order Aggregator Agent

You are an expert at fetching orders from Raydium, Orca, and Serum pools.

## Your Workflow

1. Accept user input: token mint, swap direction (buy/sell), amount
2. Validate input using rules/security.md
3. Call service: POST /aggregate?mint={mint}&amount={amount}
4. Analyze response: slippage, impact, routing options
5. Optimize using golang-hft-optimizer patterns
6. Return decision: "Route to Raydium (0.3% slippage)"

## Service Contract

**Call:** `POST http://localhost:5000/order-aggregator/aggregate`

**Request:**
```json
{
  "mint": "EPjFWaLb3cwQB9nQF5w6Hro4xxmWzJURv6H2hLb5y5K",
  "direction": "buy",
  "amount": "1000000"
}
```

**Response:**
```json
{
  "pools": [
    {
      "dex": "raydium",
      "outputAmount": "999400",
      "slippageBps": 6,
      "impact": 0.04
    }
  ],
  "bestRoute": {
    "dex": "raydium",
    "outputAmount": "999400",
    "slippageBps": 6
  }
}
```

## Important Constraints

- Always measure latency; log with `trace_id` (see rules/common/observability.md)
- Never expose private keys; use signed transaction model
- Validate RPC responses (see rules/common/security.md)
- All errors must wrap using fmt.Errorf(...: %w, err) (see rules/golang/patterns.md)
```

## Step 3: Create Domain Services (Go Stubs)

**File:** `domains/{domain-name}/services/{service-name}/main.go`

```golang
package main

import (
  "context"
  "flag"
  "log"
  "net/http"
)

func main() {
  port := flag.String("port", "5000", "HTTP port")
  flag.Parse()

  mux := http.NewServeMux()

  // Health check
  mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
  })

  // Domain-specific endpoints
  mux.HandleFunc("/aggregate", handleAggregate)

  log.Printf("Starting order-aggregator on port %s", *port)
  if err := http.ListenAndServe(":"+*port, mux); err != nil {
    log.Fatal(err)
  }
}

// TODO: Implement aggregate service
func handleAggregate(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(http.StatusNotImplemented)
}
```

**File:** `domains/{domain-name}/services/{service-name}/go.mod`

```
module hft-harness/domains/dex-operations/order-aggregator

go 1.21

require (
  github.com/rs/zerolog v1.31.0
)
```

## Step 4: Create Domain Skills (Reusable Knowledge)

**File:** `domains/{domain-name}/skills/{skill-name}.md`

```markdown
# DEX Pool Patterns

## Raydium Pool Structure

Raydium uses a **Constant Product Automated Market Maker (CPAMM)**:

```
output = (inputAmount * outputReserve) / (inputReserve + inputAmount)
slippage = (expectedOutput - actualOutput) / expectedOutput * 100
```

## Orca Pool Structure

Orca uses **Concentrated Liquidity** (similar to Uniswap V3):
- Pricing ticks
- User-provided lower/upper bounds
- Slippage can be higher at tick boundaries

## Best Practices

1. **Always query pools before routing** - pool reserves change constantly
2. **Calculate slippage using math/big** - never float64
3. **Check LP lock status** - some pools have locked liquidity
4. **Monitor impact trends** - high impact suggests concentrated liquidity

## Example: Slippage Calculation

[Provide concrete code example using math/big]
```

## Step 5: Create Domain Rules

**File:** `domains/{domain-name}/rules/performance.md`

```markdown
# DEX Operations Performance Standards

## Latency Requirements

- Pool fetch: <500ms
- Slippage calculation: <100ms
- Route selection: <300ms
- Total execution: <1s

## Precision Requirements

- All amounts: Use math/big
- Slippage: Minimum 0.0001% precision
- Prices: Minimum 0.01 SOL precision

## Testing Standards

- Devnet simulation: 10+ swap sizes
- Load test: 100 concurrent requests
- Latency benchmark: P95 < 1s
```

## Step 6: Create Domain Manifest

**File:** `domains/{domain-name}/config/{domain-name}.yaml`

```yaml
name: dex-operations
version: 1.0.0
description: DEX order aggregation, execution, and optimization

dependencies:
  - solana-infra              # Uses RPC for on-chain data

agents:
  - order-aggregator
  - liquidity-analyzer
  - execution-optimizer

skills:
  - dex-pool-patterns
  - slippage-calculation
  - execution-routing
  - cost-aware-llm-pipeline   # Reuse core skill

services:
  - order-aggregator
  - liquidity-analyzer
  - execution-engine

ports:
  order-aggregator: 5001
  liquidity-analyzer: 5002
  execution-engine: 5003
```

## Step 7: Register Domain (Installation)

Add to root `harness.yaml`:

```yaml
domains:
  - solana-infra
  - dex-operations           # Your new domain
  - mev-security             # (future)
```

Or install selectively:

```bash
./install.sh --domain dex-operations
```

## Step 8: Test Domain Independence

```bash
# 1. Start core harness
./install.sh --core-only

# 2. Install your domain
./install.sh --domain dex-operations

# 3. Test agent
claude-code
> /tdd                       # Should work
> Let me fetch orders        # Should call your agent
```

## Step 9: Verify Compliance

Before merging, ensure:

- [ ] All agents follow ARCHITECTURE.md patterns
- [ ] All services follow rules/ (performance, security, observability)
- [ ] Services expose `/health` endpoint
- [ ] All errors wrap with fmt.Errorf(...: %w, err)
- [ ] All logs include trace_id, latency_ms, service_name
- [ ] No secret paths (.env, keypair.json) in code
- [ ] Latency benchmarks meet targets (P95)
- [ ] Domain manifest correct and complete

## Common Patterns

### Agent → Service Communication

```
Agent (Node.js, Claude context)
  ↓
HTTP REST call to service
  ↓
Service (Go microservice)
  ↓
Return JSON response
  ↓
Agent analyzes + decides
```

### Multi-Service Coordination

```
Agent calls Service A
Service A may call Service B (via shared solana-infra RPC)
Results aggregated in state store
Agent makes final decision
```

### State Persistence

```
Agent decision + service responses → state store
State store enables:
- Audit trail (why was token X flagged?)
- Pattern extraction (which DEX has lower slippage?)
- Evaluation (cost per execution over time)
```

## Extending Core Harness (When Needed)

If you need to modify core/ (rare):

1. **Document why** (core should be stable)
2. **Propose on GitHub** (discuss with team)
3. **Validate across domains** (ensure change doesn't break others)
4. **Add to rules/** (document new patterns)

Example: If all domains need a new logging field, that belongs in `rules/common/observability.md`.

## Next Steps

1. Follow this guide to create your domain
2. Test with `/tdd` and `/plan` commands
3. Contribute back (patterns, optimizations, learnings)
4. Phase 2: Cross-domain coordination (multiple domains running together)
