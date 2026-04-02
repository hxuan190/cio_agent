# Go Patterns for HFT-Harness

## Error Wrapping (MANDATORY)

**Rule:** Always wrap errors using `fmt.Errorf("...: %w", err)` to preserve error chains.

```go
// ✓ CORRECT
if err != nil {
  return fmt.Errorf("failed to fetch token %s: %w", mint, err)
}

// ✗ WRONG - loses error chain
if err != nil {
  return errors.New("failed to fetch token")
}

// ✗ WRONG - %v doesn't chain
if err != nil {
  return fmt.Errorf("failed to fetch token: %v", err)
}
```

## Interface Design

**Rule:** Accept interfaces, return concrete types.

```go
// ✓ CORRECT
func (s *Service) Analyze(ctx context.Context, r io.Reader) (*Result, error)

// ✗ WRONG
func (s *Service) Analyze(ctx context.Context, r *bytes.Buffer) (*Result, error)
```

## Context Propagation

**Rule:** Always propagate context through function calls for cancellation support.

```go
// ✓ CORRECT
func (s *Service) Process(ctx context.Context) error {
  select {
  case <-ctx.Done():
    return ctx.Err()
  }
}

// ✗ WRONG - ignores cancellation
func (s *Service) Process(ctx context.Context) error {
  // ... no context check
}
```

## Zero Values

**Rule:** Leverage Go's zero values; don't over-initialize.

```go
// ✓ CORRECT
var tokens []string  // Ready to use, no nil check needed for append
var mu sync.Mutex    // Ready to use immediately

// ✗ WRONG
tokens := make([]string, 0)  // Unnecessary allocation
mu := &sync.Mutex{}           // Unnecessary pointer
```

## Table-Driven Tests

**Rule:** Use table-driven tests for multiple scenarios.

```go
func TestAnalyze(t *testing.T) {
  tests := []struct {
    name    string
    input   string
    want    int
    wantErr bool
  }{
    {"safe", "ABC", 0, false},
    {"high_concentration", "XYZ", 85, false},
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      got, err := Analyze(tt.input)
      if (err != nil) != tt.wantErr {
        t.Errorf("wantErr %v, got %v", tt.wantErr, err)
      }
    })
  }
}
```

## Defer for Cleanup

**Rule:** Use defer for resource cleanup (close files, unlock mutexes).

```go
// ✓ CORRECT
func (s *Service) Process(file *os.File) error {
  defer file.Close()
  // ... use file
  return nil
}
```

## Error Handling: Transient vs Permanent

**Rule:** Distinguish transient (retry-able) errors from permanent ones.

```go
// ✓ CORRECT
func isTransient(err error) bool {
  if err == context.Canceled || err == context.DeadlineExceeded {
    return false  // Permanent
  }
  if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
    return true   // Transient
  }
  return false
}
```

## Package Organization

**Rule:** Organize by functionality, not by type.

```
// ✓ CORRECT
cmd/
  server/
    main.go
internal/
  domain/
    token.go
  service/
    analyzer.go
  repository/
    sqlite.go

// ✗ WRONG
cmd/
  main.go
pkg/
  models/
    token.go
  handlers/
    handler.go
  repositories/
    repo.go
```
