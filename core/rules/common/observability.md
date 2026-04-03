# Observability Standards for HFT-Harness

## Structured Logging (MANDATORY)

**Tool:** Zerolog (high-performance JSON logging)

**Rule:** All logs MUST include: `service_name`, `trace_id`, `latency_ms`

```go
import "github.com/rs/zerolog"

logger := zerolog.New(os.Stdout).With().
  Str("service_name", "order-aggregator").
  Logger()

// Logging with required fields
logger.Info().
  Str("trace_id", traceID).
  Int64("latency_ms", elapsedMS).
  Str("mint", tokenMint).
  Int("pool_count", len(pools)).
  Msg("fetched_pools")

// Error logging with context
logger.Error().
  Err(err).
  Str("trace_id", traceID).
  Int64("latency_ms", elapsedMS).
  Str("mint", tokenMint).
  Msg("failed_to_fetch_pools")
```

## Log Levels

| Level | Use Case | Example |
|-------|----------|---------|
| `Debug` | Development, detailed execution flow | "starting pool aggregation" |
| `Info` | Normal operations, significant events | "fetched 150 pools from Raydium" |
| `Warn` | Degraded conditions, retries | "RPC timeout, retrying with fallback" |
| `Error` | Operational failures | "failed to deserialize pool data" |

## Trace IDs (Correlation)

**Rule:** Generate a trace_id at request entry; pass through all function calls.

```go
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  traceID := uuid.New().String()
  ctx := context.WithValue(r.Context(), "trace_id", traceID)

  h.analyze(ctx)  // Pass through
}

func (s *Service) Analyze(ctx context.Context) error {
  traceID := ctx.Value("trace_id").(string)

  logger.Info().
    Str("trace_id", traceID).
    Msg("analyzing_token")

  return nil
}
```

## Latency Tracking

**Rule:** Measure and log latency for all service calls.

```go
start := time.Now()
result, err := s.fetchPools(ctx, mint)
latencyMS := time.Since(start).Milliseconds()

logger.Info().
  Str("trace_id", traceID).
  Int64("latency_ms", latencyMS).
  Int("pool_count", len(result)).
  Msg("pool_fetch_complete")
```

## Log Aggregation Format (Loki-Compatible)

**Format:** Structured JSON with consistent field names

```json
{
  "timestamp": "2026-04-02T12:34:56.123Z",
  "level": "info",
  "service_name": "order-aggregator",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "latency_ms": 245,
  "mint": "EPjFWaLb3cwQB9nQF5w6Hro4xxmWzJURv6H2hLb5y5K",
  "pool_count": 42,
  "message": "fetched_pools"
}
```

## Metrics to Log

**Service Calls:**
- Latency (ms)
- Success/failure status
- Data volume (count, size)
- Trace ID for correlation

**Domain Events:**
- Risk score computed (with score value)
- Alert generated (with alert type)
- Pattern extracted (with pattern details)

## Example: Multi-Service Logging

```go
// Service A calls Service B
func (svc *OrderAggregator) Aggregate(ctx context.Context, mints []string) {
  traceID := ctx.Value("trace_id").(string)

  // Call Service B
  start := time.Now()
  liquidities, err := svc.client.AnalyzeLiquidity(ctx, mints)
  latencyMS := time.Since(start).Milliseconds()

  logger.Info().
    Str("trace_id", traceID).
    Str("service_called", "liquidity-analyzer").
    Int64("latency_ms", latencyMS).
    Int("mint_count", len(mints)).
    Int("result_count", len(liquidities)).
    Msg("liquidity_analysis_complete")

  // Process results
  // ...
}
```

## Alerting

**Rule:** Critical errors must trigger alerts immediately.

```go
logger.Error().
  Err(err).
  Str("trace_id", traceID).
  Str("severity", "critical").
  Str("alert_channel", "slack").
  Msg("rpc_connection_lost")
```
