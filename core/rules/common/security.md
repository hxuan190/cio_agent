# Security Standards for HFT-Harness

## Secret Paths (MANDATORY BLOCK)

**Rule:** AI assistants MUST NOT read, write, or process these paths:

- `.env`, `.env.*` (environment variables with secrets)
- `*keypair.json`, `*secret*.json`, `*private*.json` (wallet keys, private keys)
- `~/.solana/id.json`, `~/.config/*` (local wallet configs)
- `SECRETS_*`, `PRIVATE_*` (environment variables)
- Any file containing: `PRIVATE_KEY`, `SECRET_KEY`, `API_KEY`, `PASSWORD`

**Implementation:**

```golang
// Block secret path access
var blockedPaths = []string{
  ".env",
  "keypair.json",
  "secret.json",
  "private.json",
  "id.json",
}

func isBlockedPath(path string) bool {
  for _, blocked := range blockedPaths {
    if strings.Contains(path, blocked) {
      return true
    }
  }
  return false
}

// Example: Pre-hook validation
func validateFileRead(path string) error {
  if isBlockedPath(path) {
    return fmt.Errorf("SECURITY: blocked path: %s", path)
  }
  return nil
}
```

## Input Validation (MANDATORY)

**Rule:** Validate ALL external inputs (RPC responses, user input, API responses).

### Token Address Validation

```go
// ✓ CORRECT
func ValidateTokenMint(mint string) error {
  if len(mint) != 44 {
    return errors.New("invalid mint length")
  }
  if !isBase58(mint) {
    return errors.New("mint must be base58-encoded")
  }
  return nil
}

// ✗ WRONG - No validation
func GetToken(mint string) (*Token, error) {
  return rpc.GetTokenMetadata(mint)  // What if mint is malicious?
}
```

### RPC Response Validation

```go
// ✓ CORRECT - Validate every RPC response
type TokenMetadata struct {
  Supply          string `json:"supply"`
  HolderCount     int    `json:"holder_count"`
  TopHolderPercent float64 `json:"top_holder_percent"`
}

func (m *TokenMetadata) Validate() error {
  if m.Supply == "" {
    return errors.New("missing supply")
  }
  if m.HolderCount < 0 {
    return errors.New("negative holder count")
  }
  if m.TopHolderPercent < 0 || m.TopHolderPercent > 100 {
    return errors.New("invalid holder percent")
  }
  return nil
}
```

## Transaction Signing (MANDATORY)

**Rule:** NEVER sign transactions without explicit user confirmation.

```go
// ✓ CORRECT - Requires explicit approval
func SignTransaction(ctx context.Context, tx *Transaction) error {
  // Get user confirmation (external system, never auto-sign)
  approved, err := getUserApproval(ctx, tx)
  if !approved {
    return errors.New("user rejected transaction")
  }

  // Sign only if approved
  return signer.Sign(tx)
}

// ✗ WRONG - Auto-signing without approval
func SignTransaction(tx *Transaction) (*SignedTx, error) {
  return signer.Sign(tx)  // No approval check!
}
```

## API Key Management

**Rule:** Never log, print, or expose API keys.

```go
// ✓ CORRECT - Mask sensitive values
logger.Info().
  Str("rpc_url", "https://api.devnet.solana.com").  // Safe
  Str("api_key", maskKey(apiKey)).                   // Masked
  Msg("rpc_configured")

func maskKey(key string) string {
  if len(key) < 8 {
    return "***"
  }
  return key[:4] + "..." + key[len(key)-4:]
}

// ✗ WRONG - Exposes API key in logs
logger.Info().
  Str("api_key", apiKey).
  Msg("rpc_configured")
```

## SQL Injection Prevention

**Rule:** Always use parameterized queries; never concatenate user input into SQL.

```golang
import "database/sql"

// ✓ CORRECT - Parameterized query
stmt, err := db.Prepare("SELECT * FROM tokens WHERE mint = ?")
defer stmt.Close()
row := stmt.QueryRow(userMint)

// ✗ WRONG - SQL injection risk
query := "SELECT * FROM tokens WHERE mint = '" + userMint + "'"
row := db.QueryRow(query)
```

## Rate Limiting

**Rule:** Implement rate limiting to prevent abuse.

```go
import "golang.org/x/time/rate"

type RateLimiter struct {
  limiter *rate.Limiter
}

func (rl *RateLimiter) CheckLimit(ctx context.Context) error {
  if !rl.limiter.Allow() {
    return errors.New("rate limit exceeded")
  }
  return nil
}
```

## Error Messages (MANDATORY)

**Rule:** Never expose internal state in error messages.

```go
// ✓ CORRECT - User-safe error
if err != nil {
  logger.Error().Err(err).Msg("failed_to_fetch_token")
  return nil, errors.New("token analysis failed")  // Safe message
}

// ✗ WRONG - Exposes internal details
if err != nil {
  return nil, fmt.Errorf("database connection pool exhausted: %v", err)
}
```

## Audit Logging

**Rule:** Log all security-relevant events with trace ID.

```go
logger.Warn().
  Str("trace_id", traceID).
  Str("event", "high_risk_score").
  Str("mint", mint).
  Float64("risk_score", 85.5).
  Msg("security_alert_generated")
```

## CORS & HTTPS (API Services)

**Rule:** Enforce HTTPS; restrict CORS to known domains.

```go
// ✓ CORRECT
import "github.com/rs/cors"

handler := cors.New(cors.Options{
  AllowedOrigins: []string{"https://trusted-domain.com"},
  AllowedMethods: []string{"GET", "POST"},
}).Handler(mux)

// Server should only listen on HTTPS
http.ListenAndServeTLS(":443", "cert.pem", "key.pem", handler)
```

## Dependency Security

**Rule:** Keep dependencies up-to-date; audit for CVEs.

```bash
# Check for known vulnerabilities
go list -json -m all | nancy sleuth

# Update dependencies
go get -u ./...

# Verify checksums
go mod verify
```
