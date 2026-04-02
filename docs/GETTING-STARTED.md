# HFT-Harness: Getting Started & Productivity Guide

## Quick Start (5 Minutes)

### 1. Fork & Clone
```bash
git clone <repo> hft-harness
cd hft-harness
git checkout hft/harness-init  # or merge to main first
```

### 2. Explore the Structure
```bash
# Core infrastructure (stable, don't modify)
ls core/

# Shared patterns (reusable across domains)
ls shared/skills/

# Where YOU add your domain
mkdir domains/my-domain
```

### 3. Read the Docs (10-15 minutes)
```bash
# Start here - understand the philosophy
cat docs/ARCHITECTURE.md

# Then follow step-by-step
cat docs/HOW-TO-ADD-DOMAINS.md

# See reference implementations
cat docs/EXTENSION-EXAMPLES.md
```

### 4. Create Your First Domain
```bash
# Follow HOW-TO-ADD-DOMAINS.md
mkdir -p domains/solana-infra/{agents,services,skills,rules,config}

# Create your first agent
cat > domains/solana-infra/agents/rpc-monitor.md << 'EOF'
---
name: rpc-monitor
description: Monitor Solana RPC health
domain: solana-infra
---

# RPC Monitor Agent
Monitor RPC latency and detect failures.
EOF

# Create service stub
mkdir -p domains/solana-infra/services/rpc-wrapper
cat > domains/solana-infra/services/rpc-wrapper/main.go << 'EOF'
package main

import "net/http"

func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
  })
  http.ListenAndServe(":5000", mux)
}
EOF
```

---

## Productivity Workflows

### Workflow 1: Start a New Domain (Solana Infrastructure)

**Goal:** Create a domain that provides Solana RPC wrapper + WebSocket aggregator

**Time:** 2-3 hours (with this guide)

#### Step 1: Scaffold (5 min)
```bash
mkdir -p domains/solana-infra/{agents,services,skills,rules,config}
```

#### Step 2: Write 3 Agents (20 min)
```bash
# domains/solana-infra/agents/rpc-monitor.md
# domains/solana-infra/agents/ws-subscription-manager.md
# domains/solana-infra/agents/validator-health-checker.md
```

**Agent Template:**
```markdown
---
name: rpc-monitor
description: One sentence describing what this agent does
domain: solana-infra
depends: [golang-hft-optimizer, cost-aware-llm-pipeline]
---

# Agent Name

You are an expert at X.

## Workflow

1. Accept user input
2. Call service: POST /service/endpoint
3. Analyze response
4. Make decision
5. Return result + reasoning

## Service Contract

POST /rpc-monitor/health

Request: {}
Response: {latency_ms: 45, status: "ok"}
```

#### Step 3: Create Service Stubs (30 min)
```bash
# domains/solana-infra/services/rpc-wrapper/main.go
# domains/solana-infra/services/ws-aggregator/main.go
# domains/solana-infra/services/validator-monitor/main.go
```

**Service Stub Template:**
```golang
package main

import (
  "net/http"
  "github.com/rs/zerolog"
)

var logger = zerolog.New(nil)

func main() {
  mux := http.NewServeMux()

  // Health check (required)
  mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
  })

  // Domain endpoints
  mux.HandleFunc("/rpc-monitor/health", handleHealth)

  http.ListenAndServe(":5000", mux)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-Type", "application/json")
  // TODO: Implement
  w.WriteHeader(http.StatusNotImplemented)
}
```

#### Step 4: Create Skills & Rules (20 min)
```bash
# domains/solana-infra/skills/solana-rpc-patterns.md
# domains/solana-infra/skills/websocket-optimization.md
# domains/solana-infra/rules/performance.md
# domains/solana-infra/rules/security.md
```

**Skill Template:**
```markdown
# Solana RPC Patterns

## Connection Pooling

Maintain a pool of 3-5 RPC endpoints. Round-robin through them.

## Retry Strategy

- Transient error (timeout): Retry with exponential backoff (100ms, 200ms, 400ms)
- Permanent error (invalid method): Fail immediately
- Use fmt.Errorf(...: %w, err) to preserve error chain

## Example Code

[Code snippet using golang-hft-optimizer patterns]
```

**Rules Template:**
```markdown
# Solana Infrastructure Performance Standards

## Latency Budgets

- RPC call: <100ms (P95)
- WebSocket subscription: <50ms
- Validator health check: <200ms

## Precision Requirements

- All token amounts: Use math/big
- Prices: Minimum 0.001 SOL precision

## Testing Standards

- Devnet integration: 10+ RPC calls
- Load test: 100 concurrent subscriptions
```

#### Step 5: Create Domain Manifest (10 min)
```yaml
# domains/solana-infra/config/solana-infra.yaml

name: solana-infra
version: 1.0.0
description: Solana RPC wrapper, WebSocket aggregator, validator monitoring

agents:
  - rpc-monitor
  - ws-subscription-manager
  - validator-health-checker

skills:
  - solana-rpc-patterns
  - websocket-optimization
  - golang-hft-optimizer
  - cost-aware-llm-pipeline

services:
  - rpc-wrapper
  - ws-aggregator
  - validator-monitor

ports:
  rpc-wrapper: 5000
  ws-aggregator: 5001
  validator-monitor: 5002
```

#### Step 6: Test with Claude Code (30 min)
```bash
# Start Claude Code
claude-code

# Run tests
> /tdd

# Plan implementation
> /plan

# Ask agent to fetch RPC status
> Let me check Solana RPC health

# Should output: "Calling rpc-monitor service..."
```

#### Step 7: Verify Compliance (10 min)
```bash
# Checklist from HOW-TO-ADD-DOMAINS.md

✅ All agents follow ARCHITECTURE.md patterns
✅ All services follow rules/ (performance, security, observability)
✅ Services expose /health endpoint
✅ All errors wrap with fmt.Errorf(...: %w, err)
✅ All logs include trace_id, latency_ms, service_name
✅ No secret paths (.env, keypair.json) in code
✅ Latency benchmarks meet targets (P95)
✅ Domain manifest correct and complete
```

---

### Workflow 2: Add Observability to Existing Service

**Goal:** Instrument a service with Zerolog + Loki logging

**Time:** 30 minutes

#### Step 1: Import Zerolog
```go
import "github.com/rs/zerolog"

var logger = zerolog.New(os.Stderr).With().
  Str("service_name", "rpc-wrapper").
  Logger()
```

#### Step 2: Log All Calls with Required Fields
```go
// At function entry
start := time.Now()
traceID := r.Header.Get("X-Trace-ID")

// ... do work ...

// At function exit
latencyMS := time.Since(start).Milliseconds()

logger.Info().
  Str("trace_id", traceID).
  Int64("latency_ms", latencyMS).
  Str("endpoint", "fetch_rpc").
  Int("result_count", len(results)).
  Msg("rpc_call_complete")
```

#### Step 3: Log Errors with Context
```go
if err != nil {
  logger.Error().
    Err(err).
    Str("trace_id", traceID).
    Int64("latency_ms", latencyMS).
    Msg("rpc_call_failed")
  return nil, err
}
```

#### Step 4: Deploy to Loki
```bash
# Logs automatically flow to Loki if configured
# Query in Grafana: {service_name="rpc-wrapper"}
```

---

### Workflow 3: Optimize Hot Path (Zero-Allocation)

**Goal:** Refactor a token analysis loop for sub-millisecond latency

**Time:** 1-2 hours (first time), then 15 min (with experience)

#### Step 1: Identify Hot Path
```go
// ❌ SLOW - Allocates per iteration
func AnalyzeTokens(tokens []string) []Analysis {
  var results []Analysis
  for _, token := range tokens {
    analysis := make(map[string]interface{})  // ALLOCATES!
    analysis["mint"] = token
    results = append(results, analysis)         // GROWS!
  }
  return results
}
```

#### Step 2: Use sync.Pool + Pre-allocation
```go
// ✅ FAST - Zero-allocation
var analysisPool = sync.Pool{
  New: func() interface{} {
    return &Analysis{
      Holders: make([]Holder, 0, 1000),
    }
  },
}

func AnalyzeTokens(tokens []string) []Analysis {
  results := make([]Analysis, 0, len(tokens))  // Pre-allocate once

  for _, token := range tokens {
    analysis := analysisPool.Get().(*Analysis)
    analysis.Mint = token
    // ... populate fields ...
    results = append(results, *analysis)

    // Reset and return to pool
    analysis.Holders = analysis.Holders[:0]
    analysisPool.Put(analysis)
  }
  return results
}
```

#### Step 3: Use math/big for Precision
```go
// ❌ WRONG - Loses precision
slippage := 0.003

// ✅ RIGHT - Precise decimals
slippage := new(big.Float).SetString("0.003")
```

#### Step 4: Benchmark
```bash
go test -bench=. -benchmem

# Goal: 0 B/op (zero allocations)
# Example: BenchmarkAnalyzeToken-8  1000000   1234 ns/op   0 B/op  0 allocs/op
```

#### Step 5: Reference
```bash
# See shared/skills/golang-hft-optimizer.md for:
# - Sharded maps (contention reduction)
# - Lock-free caches (Copy-On-Write)
# - CPU pinning (latency-critical paths)
# - Cache line padding (false sharing prevention)
# - Bounds check elimination (BCE)
```

---

### Workflow 4: Cross-Domain Coordination

**Goal:** Make dex-operations domain call solana-infra RPC

**Time:** 30 minutes

#### Step 1: Declare Dependency
```yaml
# domains/dex-operations/config/dex-operations.yaml

dependencies:
  - solana-infra  # Can call RPC via solana-infra
```

#### Step 2: Agent Calls Both Services
```markdown
# domains/dex-operations/agents/order-aggregator.md

## Workflow

1. Accept user input: token mint, swap amount
2. Call solana-infra RPC: GET http://localhost:5000/token/{mint}
3. Call dex-operations service: POST /order-aggregator/aggregate
4. Combine results: "Best rate on Raydium (0.3% slippage)"
```

#### Step 3: Service Calls Upstream Service
```go
// domains/dex-operations/services/order-aggregator/main.go

func handleAggregate(w http.ResponseWriter, r *http.Request) {
  traceID := r.Header.Get("X-Trace-ID")

  // Call upstream RPC service
  resp, err := http.Get("http://localhost:5000/token/" + mint)
  if err != nil {
    logger.Error().
      Err(err).
      Str("trace_id", traceID).
      Msg("rpc_call_failed")
  }

  // ... process response ...
}
```

#### Step 4: Test
```bash
# Start both domains
docker-compose up -d

# Agent calls both services
claude-code
> Find the best swap for 100 USDC
# Should route through solana-infra → dex-operations
```

---

## Rules & Standards Quick Reference

### 🔴 MANDATORY (Will Block)
| Rule | File | Impact |
|------|------|--------|
| Error wrapping with fmt.Errorf(...: %w, err) | rules/golang/patterns.md | All Go services |
| Structured logging (Zerolog) | rules/common/observability.md | Debugging, monitoring |
| Trace ID on all logs | rules/common/observability.md | Correlation, debugging |
| Block secret paths (.env, keypair.json) | rules/common/security.md | Security enforcement |
| Input validation (RPC, user, API responses) | rules/common/security.md | Attack prevention |

### ⚠️ STRICT (Performance-Critical)
| Rule | File | Target |
|------|------|--------|
| Zero-allocation in hot paths | rules/hft/performance.md | <5s total execution |
| Use math/big for decimals | rules/hft/performance.md | Precision, no rounding |
| sync.Pool for reusable objects | rules/hft/performance.md | GC pressure reduction |
| Latency budgets (<100ms RPC, <1s liquidity) | rules/hft/performance.md | Performance SLA |
| Benchmark before shipping | rules/hft/performance.md | Production readiness |

### ℹ️ RECOMMENDED (Best Practices)
- Use sharded maps instead of global mutexes
- Use channels for coordination (over mutexes)
- Pre-allocate slices with known capacity
- CPU pin latency-critical goroutines
- Avoid heap escapes (pass-by-value when possible)

---

## Common Commands

```bash
# List all agents
ls core/agents/

# List all skills
ls shared/skills/

# See current rules
cat rules/golang/patterns.md
cat rules/common/observability.md
cat rules/hft/performance.md
cat rules/common/security.md

# Read documentation
cat docs/ARCHITECTURE.md
cat docs/HOW-TO-ADD-DOMAINS.md
cat docs/EXTENSION-EXAMPLES.md

# Start developing
mkdir domains/my-domain
# Follow HOW-TO-ADD-DOMAINS.md

# Test with Claude Code
claude-code
> /tdd
> /plan
> /code-review
```

---

## Production Checklist

Before shipping a domain to production:

- [ ] All services have `/health` endpoint
- [ ] All errors use fmt.Errorf(...: %w, err)
- [ ] All logs include trace_id, latency_ms, service_name
- [ ] Hot paths use sync.Pool + pre-allocation
- [ ] Decimals use math/big (never float64)
- [ ] Benchmarks show 0 allocations (or justified)
- [ ] Load tested (100+ concurrent requests)
- [ ] Latency meets SLA (P95 within budget)
- [ ] No .env, keypair.json, secrets in code
- [ ] Domain manifest complete
- [ ] Documentation up-to-date

---

## FAQ

**Q: How do I add a new skill?**
A: Create `shared/skills/{name}.md` following the template in EXTENSION-EXAMPLES.md. Update domain manifests to reference it.

**Q: Can I modify core/?**
A: Rarely. Core should be stable. If all domains need a change, propose it (discuss with team), implement, update `rules/`.

**Q: How do I test my domain?**
A: Follow Workflow 1, Step 6. Use `/tdd`, `/plan`, `/code-review` commands in Claude Code.

**Q: What's the evaluation loop?**
A: Measure execution → Extract patterns → Feedback to agents. See ARCHITECTURE.md.

**Q: How do I optimize for latency?**
A: Follow Workflow 3. Reference `shared/skills/golang-hft-optimizer.md`. Benchmark everything.

---

## Next Steps

1. **Read** `docs/ARCHITECTURE.md` (5 min)
2. **Follow** `docs/HOW-TO-ADD-DOMAINS.md` (30 min)
3. **Create** your first domain (2-3 hours)
4. **Test** with Claude Code (30 min)
5. **Optimize** using HFT patterns (1-2 hours)
6. **Deploy** to production (your infrastructure)

Welcome to HFT-Harness! 🚀
