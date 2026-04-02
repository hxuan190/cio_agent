# HFT Performance Standards

## Zero-Allocation in Hot Paths (MANDATORY)

**Rule:** No allocations in latency-critical code paths.

**Critical Paths:**
- Token analysis (per-token analysis loop)
- Risk score computation (per-token scoring)
- Order aggregation (per-pool aggregation)
- Transaction parsing (per-transaction deserialization)

### Using sync.Pool for Object Reuse

```go
// ✓ CORRECT - Reuse buffers via sync.Pool
var bufferPool = sync.Pool{
  New: func() interface{} {
    return make([]byte, 0, 1024)
  },
}

func ProcessTokens(tokens []string) error {
  buf := bufferPool.Get().([]byte)
  defer bufferPool.Put(buf[:0])  // Reset and return

  for _, token := range tokens {
    buf = append(buf, token...)
    // ... process
    buf = buf[:0]  // Reset for next iteration
  }
  return nil
}

// ✗ WRONG - Allocates new buffer per token
func ProcessTokens(tokens []string) error {
  for _, token := range tokens {
    buf := make([]byte, 0, 1024)  // Allocates every iteration!
    // ... process
  }
  return nil
}
```

### Pre-allocation for Known Sizes

```go
// ✓ CORRECT - Pre-allocate with exact capacity
holders := make([]*Holder, 0, expectedCount)
for _, h := range rawHolders {
  holders = append(holders, &h)
}

// ✗ WRONG - Grow dynamically
var holders []*Holder
for _, h := range rawHolders {
  holders = append(holders, &h)  // May allocate multiple times
}
```

## Decimal Math (MANDATORY)

**Rule:** Use `math/big` for token amounts and prices; never use `float64`.

```go
import "math/big"

// ✓ CORRECT - Precise decimal math
slippage := new(big.Float).SetString("0.003")  // 0.3%
amount := new(big.Int).SetString("1000000000", 10)

// ✗ WRONG - float64 loses precision
slippage := 0.003  // Rounding errors accumulate
amount := 1000000000.0  // Token amounts may have 18+ decimals
```

### Example: Slippage Calculation

```go
func CalculateSlippage(inputAmount, outputAmount, expectedOutput *big.Float) *big.Float {
  difference := new(big.Float).Sub(expectedOutput, outputAmount)
  slippage := new(big.Float).Quo(difference, expectedOutput)
  slippage.Mul(slippage, big.NewFloat(100))  // Convert to percentage
  return slippage
}
```

## Concurrency: Channels Over Mutexes

**Rule:** Prefer channels for coordination; use mutexes only for shared state.

```go
// ✓ CORRECT - Channels coordinate work
func AggregateParallel(ctx context.Context, tokens []string) error {
  results := make(chan *Analysis, len(tokens))

  for _, token := range tokens {
    go func(t string) {
      result, err := analyze(ctx, t)
      if err != nil {
        results <- nil
        return
      }
      results <- result
    }(token)
  }

  // Collect results
  analyses := make([]*Analysis, 0, len(tokens))
  for i := 0; i < len(tokens); i++ {
    if r := <-results; r != nil {
      analyses = append(analyses, r)
    }
  }
  return nil
}

// ✗ WRONG - Unnecessary mutexes
func AggregateParallel(tokens []string) error {
  var mu sync.Mutex
  var analyses []*Analysis

  var wg sync.WaitGroup
  for _, token := range tokens {
    wg.Add(1)
    go func(t string) {
      defer wg.Done()
      result := analyze(t)
      mu.Lock()
      analyses = append(analyses, result)  // Serializes updates!
      mu.Unlock()
    }(token)
  }

  wg.Wait()
  return nil
}
```

## Latency Budgets

| Operation | Target P95 | Notes |
|-----------|-----------|-------|
| Token analysis | <500ms | Per-token holder concentration, LP lock |
| Liquidity analysis | <1s | DEX pool fetch + slippage calculation |
| Risk score | <100ms | Aggregate scoring |
| Order routing | <1s | Multi-pool analysis + best route selection |
| Total execution | <5s | All 4 above + decision making |

## Benchmarking

**Rule:** Benchmark all hot paths before shipping.

```go
func BenchmarkAnalyzeToken(b *testing.B) {
  token := &Token{
    Mint: "EPjFWaLb...",
    Supply: "1000000",
    HolderCount: 150,
  }

  b.ResetTimer()
  for i := 0; i < b.N; i++ {
    Analyze(token)
  }
}

// Run with: go test -bench=. -benchmem
// Output: BenchmarkAnalyzeToken-8  1000000   1234 ns/op   0 B/op  0 allocs/op
```

## Atomicity for Counters

**Rule:** Use `atomic` package for lock-free counters.

```go
import "sync/atomic"

type Metrics struct {
  tokenCount   int64
  analysisTime int64
}

func (m *Metrics) IncrementTokenCount() {
  atomic.AddInt64(&m.tokenCount, 1)
}

func (m *Metrics) GetTokenCount() int64 {
  return atomic.LoadInt64(&m.tokenCount)
}
```

## Memory Profiling

**Rule:** Profile on staging before production deploy.

```bash
# Generate CPU profile (30s)
curl http://localhost:6060/debug/pprof/profile?seconds=30 > cpu.prof

# Generate heap profile
curl http://localhost:6060/debug/pprof/heap > heap.prof

# Analyze with pprof
go tool pprof cpu.prof
(pprof) top10
```

## String Operations

**Rule:** Use `strings.Builder` for string concatenation in loops.

```go
// ✓ CORRECT - Efficient string building
var sb strings.Builder
for _, token := range tokens {
  sb.WriteString(token)
  sb.WriteString(",")
}
result := sb.String()

// ✗ WRONG - Creates new string each iteration
var result string
for _, token := range tokens {
  result += token + ","  // O(n²) time!
}
```
