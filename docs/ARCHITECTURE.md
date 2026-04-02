# HFT-Harness Architecture

## Overview

A **minimalist, modular AI Agent Harness** for Golang HFT/DEX infrastructure projects. Inherits ECC's proven session, hooks, state, and config patterns while pruning 80% of non-essential skills, agents, commands, and language rules.

**Design Philosophy:**
- **Core Harness:** Lean, stable foundation (session, hooks, state, config)
- **Shared Patterns:** Cross-domain reusable skills and rules
- **Pluggable Domains:** Independent extensions (agents + Go services)
- **Evaluation-Driven:** Continuous learning via state store

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   Claude AI Agent                         │
│              (Orchestration & Decision-Making)           │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ↓
      ┌────────────────────────────────────────┐
      │      Core Harness (Stable)             │
      │  • Session Manager (persistence)       │
      │  • Hooks System (event-driven)         │
      │  • State Store (decisions, patterns)   │
      │  • Config/Install (manifest-based)    │
      │  • ~12 Core Agents (generalizable)     │
      │  • ~25 Core Skills (reusable patterns) │
      │  • Common + Golang + HFT Rules         │
      └────────────────────────────────────────┘
                           │
                ┌──────────┼──────────┐
                ↓          ↓          ↓
         ┌──────────┐ ┌──────────┐ ┌──────────┐
         │ Domain 1 │ │ Domain 2 │ │ Domain 3 │
         │solana-   │ │dex-      │ │mev-      │
         │infra     │ │operations│ │security  │
         │          │ │          │ │          │
         │• 3 agents│ │• 3 agents│ │• 3 agents│
         │• 3 svcs  │ │• 3 svcs  │ │• 3 svcs  │
         │• skills  │ │• skills  │ │• skills  │
         │• rules   │ │• rules   │ │• rules   │
         └──────────┘ └──────────┘ └──────────┘
                │          │          │
                └──────────┼──────────┘
                           ↓
           HTTP REST Calls (JSON)
                           ↓
         ┌────────────────────────────────────┐
         │    Go Microservices (Services)      │
         │ • Solana RPC wrapper                │
         │ • WebSocket aggregator              │
         │ • Order aggregator                  │
         │ • Liquidity analyzer                │
         │ • Transaction monitor               │
         │ • Risk scorer                       │
         └────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    ↓             ↓
                 Solana RPC    DEX APIs
                 (on-chain)    (off-chain)
```

## Core Components

### 1. Session Manager (`core/session/`)

**Purpose:** Persistent agent state across conversations

**Features:**
- Markdown-based session files: `~/.claude/session-data/{date}-{id}-session.tmp`
- Session resumption: "Continue from yesterday's analysis"
- Session aliases: Human-friendly identifiers
- Metadata extraction: date, ID, filesystem stats

**How Agents Use It:**
```javascript
// Agent code (Node.js, within Claude context)
const session = await sessionManager.load(sessionId)
const previousContext = session.context
const decisions = session.decisions  // History of what was decided
```

### 2. Hooks System (`core/hooks/`)

**Purpose:** Event-driven automation and quality gates

**Lifecycle Events:**
- `SessionStart` — Initialize domain, load context
- `PreToolUse` — Block unsafe operations (e.g., reading .env)
- `PostToolUse` — Analyze outputs (e.g., detect MEV patterns)
- `SessionEnd` — Persist state, generate summaries

**Hook Profiles (Enable/Disable):**
- `minimal` — Security gates only
- `standard` (default) — Security + quality checks
- `strict` — Security + quality + observability

### 3. State Store (`core/state/`)

**Purpose:** SQLite database for decision history, patterns, learnings

**Entities:**
- `session` — Agent sessions
- `decision` — What was decided and why
- `tokenAnalysis` — Per-token risk assessments
- `riskScore` — Composite risk grades
- `alertEvent` — Detected rug pulls, sandwich attacks, etc.

**Enables Evaluation Loop:**
```
Measure execution → Extract patterns → Feed back to agents
```

Example Query:
```sql
SELECT COUNT(*) as sandwich_attacks
FROM alertEvent
WHERE alertType = 'sandwich_detected'
  AND timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY)
  AND tokenAddress IN (SELECT address FROM trackedTokens)
```

### 4. Config/Install System (`core/manifests/`)

**Purpose:** Manifest-driven selective installation

**Mechanism:**
1. User selects profile (core, developer, domain-specific)
2. Manifest lists components: agents, skills, rules, services
3. Install script applies profile: copies files, runs migrations
4. State store tracks what's installed (enables updates)

**Example Manifest:**
```yaml
profile: dex-operations
components:
  core:
    - agents: [architect, code-reviewer, go-reviewer]
    - skills: [golang-patterns, backend-patterns, cost-aware-llm]
    - rules: [common, golang, hft]
  domains:
    solana-infra:
      - agents: [rpc-monitor, ws-manager]
      - services: [rpc-wrapper, ws-aggregator]
    dex-operations:
      - agents: [order-aggregator, execution-optimizer]
      - services: [order-aggregator, execution-engine]
```

## Domain Architecture

### Domain Structure

Each domain is **independent and self-contained**:

```
domains/{domain-name}/
├── agents/          # Claude agents (orchestration)
├── services/        # Go microservices (execution)
├── skills/          # Reusable knowledge
├── rules/           # Domain standards
└── config/          # Domain manifest
```

### Agent-to-Service Communication

**Agent (Claude context):**
- Accepts user input
- Validates inputs
- Decides when to call service
- Analyzes service response
- Makes final decision

**Service (Go microservice):**
- Exposes HTTP REST API
- Executes domain logic
- Returns JSON response
- Logs with trace_id + latency

**Example Flow:**

```
User: "Find the best swap for 100 USDC"
  ↓
[order-aggregator agent]
  • Validates: USDC mint, amount, direction
  • Calls: POST /order-aggregator/aggregate
  • Response: {pools: [{dex: raydium, slippageBps: 6}]}
  • Analyzes: slippage acceptable? (see rules/hft/performance.md)
  • Decides: "Route to Raydium (0.3% slippage)"
  ↓
[Agent returns to user]
  • Records decision in state store
  • Logs: trace_id, latency, decision rationale
```

## Domains (Examples)

### Domain 1: Solana Infrastructure

**Agents:** rpc-monitor, ws-subscription-manager, validator-health-checker

**Services:** rpc-wrapper, ws-aggregator, validator-monitor

**Purpose:** Foundation for all Solana operations

**Standards:** Performance (<100ms RPC), >99.9% uptime, TLS validation

### Domain 2: DEX Operations

**Agents:** order-aggregator, liquidity-analyzer, execution-optimizer

**Services:** order-aggregator, liquidity-analyzer, execution-engine

**Purpose:** Order routing, execution, slippage minimization

**Standards:** <1s latency, <0.5% slippage, signed transactions only

### Domain 3: MEV/Security

**Agents:** sandwich-detector, exploit-scanner, flashloan-monitor

**Services:** sandwich-detector, exploit-scanner, flashloan-monitor

**Purpose:** Detect attacks, assess risk, prevent exploitation

**Standards:** <500ms detection, comprehensive pattern database

## Rules Hierarchy

```
rules/
├── common/                    # All domains
│   ├── security.md           # Block secrets, validate input, sign txs
│   └── observability.md      # Zerolog + Loki, trace_id, latency_ms
├── golang/                    # Go-specific patterns
│   └── patterns.md           # Error wrapping, interfaces, context, zero values
├── hft/                       # HFT-specific constraints
│   └── performance.md        # Zero-allocation, sync.Pool, math/big, latency budgets
└── {domain}/                  # Domain-specific (optional)
    ├── performance.md        # Domain latency targets
    ├── security.md           # Domain-specific constraints
    └── testing.md            # Domain test standards
```

**Rule Enforcement:**
- Hooks validate at pre-tool-use time
- Code review agents check compliance
- State store tracks violations

## Evaluation Loop

**Goal:** Continuously improve agent decisions

**Flow:**

```
1. Agent executes → records decision + metrics in state store
2. Service returns response → latency, success, data volume
3. Hook captures execution → latency, error, resources
4. State store accumulates: 1000s of decisions
5. Pattern extraction: "When risk > 85%, use Raydium not Orca"
6. Feedback to agents: Next time, prefer Raydium when high-risk detected
7. Measure improvement: Cost per execution decreases
```

**Evaluation Queries:**

```sql
-- What DEX has lowest slippage?
SELECT dex, AVG(slippageBps) as avg_slippage
FROM execution_history
WHERE tokenType = 'alt'
GROUP BY dex
ORDER BY avg_slippage;

-- When was sandwich risk highest?
SELECT token, hour, COUNT(*) as sandwich_count
FROM sandwich_alerts
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY token, hour
ORDER BY sandwich_count DESC;

-- Cost improvement over time
SELECT DATE(executedAt) as day, AVG(costPerExecution) as avg_cost
FROM execution_metrics
GROUP BY DATE(executedAt)
ORDER BY day;
```

## Security Model

### Input Validation Boundary

```
├─ User input → Validate (agent)
├─ RPC response → Validate (service)
├─ DEX API response → Validate (service)
└─ Transaction signing → Require explicit approval (never auto-sign)
```

### Secret Protection

**Blocked Paths:**
- `.env`, `.env.*`
- `*keypair.json`, `*secret.json`, `*private.json`
- `SECRETS_*`, `PRIVATE_*` environment variables

**Enforcement:** Hooks check file reads; block at pre-tool-use

### Audit Trail

```
trace_id → Links all logs + decisions + service calls
           For replay, debugging, audit, compliance
```

## Deployment Topology

### Local Development

```
┌─────────────────────────┐
│  Claude IDE (macOS/Win) │
├─────────────────────────┤
│ core/ + 1 domain        │
│ (agents code)           │
├─────────────────────────┤
│ Docker Compose          │
├─────────────────────────┤
│ Go services (localhost) │
│ SQLite (local)          │
└─────────────────────────┘
```

### Production

```
┌─────────────────────────┐
│   Claude Cloud          │
│   (agents coordinating) │
├─────────────────────────┤
│   Kubernetes            │
├─────────────────────────┤
│   Multiple Go services  │
│   (stateless, scalable) │
├─────────────────────────┤
│   RocksDB / Postgres    │
│   (distributed state)   │
└─────────────────────────┘
```

## Phases

### Phase 1: Core Harness (Complete)
- ✓ Pruned 80% bloat
- ✓ Organized into core/ + shared/
- ✓ Created rules/ (common, golang, hft)
- ✓ Documentation: HOW-TO-ADD-DOMAINS.md

### Phase 2: Teams Add Domains (Your Turn)
- Create: domains/solana-infra/ (RPC, WebSocket, validators)
- Follow: HOW-TO-ADD-DOMAINS.md
- Test: Session persistence, hooks, agent calls

### Phase 3: Multi-Domain Orchestration
- Add: domains/dex-operations/
- Add: domains/mev-security/
- Test: Domains collaborate via state store

### Phase 4: Evaluation & Optimization
- Extract patterns: "Which DEX has lowest slippage?"
- Feedback: Improve agent prompts based on learnings
- Measure: Cost per execution over time

## Next: Fork and Extend

1. Clone this repo: `git clone ... hft-harness`
2. Create your domain: `mkdir domains/my-domain`
3. Follow: `docs/HOW-TO-ADD-DOMAINS.md`
4. Deploy: Solana RPC wrapper, order aggregator, MEV detector

Welcome to the HFT-Harness!
