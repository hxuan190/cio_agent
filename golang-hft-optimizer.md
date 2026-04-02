---

name: golang-hft-optimizer

description: Core patterns extracted from production HFT systems. Use this skill to refactor ANY Golang code (Indexers, RPC handlers, Math engines) for microsecond latency and zero heap allocations.

origin: ECC

---



# Skill: HFT & Zero-Allocation Optimization (Golang)



**When to Use:** Apply this skill when you need to write or refactor "hot paths" (main loops, data stream processing, highly concurrent code) in High-Frequency Trading systems or any performance-critical backend.



## Strict Rules:



1. **Arenas & `sync.Pool` (Zero Allocation):** 

   Pre-allocate slices and state structures into an "Arena" at startup. Manage these arenas using `sync.Pool` (`AcquireArena` / `ReleaseArena`). Always reset the internal state (`a.slice = a.slice[:0]`) before returning to the pool instead of re-allocating.



2. **Sharded Maps (Contention Reduction):** 

   Never use a global `sync.RWMutex` for concurrent dictionaries accessed by thousands of goroutines. Instead, partition the map into an array of shards (e.g., `[16]shard`). Route keys to shards using a fast modulo (e.g., `key[0] % 16`), with each shard holding its own lock.



3. **Lock-Free Read Caches (Atomic COW):**

   For extremely high-read configuration or snapshot caches, apply Copy-On-Write logic. Compute the new state in a background goroutine, and then perform an atomic pointer swap (`atomic.Pointer`) to update the reference. This provides zero-contention, lock-free lookups for readers.



4. **Dual-Path Data Types (Fast / Precise):** 

   Maintain two structural paths for data processing. Use a "Fast/uint64" or similar primitive path for hot-loop operations and heuristic estimations to avoid heap allocation. Rely on the "Standard/*big.Int" path exclusively for exact calculations, RPC construction, or API settlement at the edges.



5. **Hot-Loop CPU Pinning (OS Thread Control):**

   Pin latency-critical, unyielding goroutines to a specific OS thread using `runtime.LockOSThread()`. This removes the Go runtime scheduler's overhead and eliminates OS context switching delays for the critical path.



6. **Runtime Tuning (GOGC & GOMEMLIMIT):**

   Configure `GOGC` to a very high value (e.g., `500` to `1000`) on production servers to drastically delay sweep phases, keeping `sync.Pool` objects "warm" and reused. MUST pair this with a strict `GOMEMLIMIT` as a hard safety net to prevent unbounded OOM crashes. Tune `GOMAXPROCS = runtime.NumCPU() / 2` to avoid hyperthread contention on heavy CPU-bound tasks.



7. **False Sharing Prevention (Padding Cache Lines):**

   When defining structs containing atomic variables that are continuously updated by multiple goroutines, you MUST insert Cache Line Padding (e.g., `_ [64]byte` or `_ cpu.CacheLinePad` from `golang.org/x/sys/cpu`) between the fields. This prevents CPU cores from continuously invalidating each other's caches (Cache Invalidation) when accessing the same 64-byte Cache Line.



8. **Zero-Copy String/Byte Conversions:**

   In high-speed I/O processing or deserialize functions, standard string casting and byte allocations (`string(byteSlice)`) are strictly forbidden. You MUST use `unsafe.String(unsafe.SliceData(b), len(b))` to convert `[]byte` to `string` and vice versa (Go 1.20+) to achieve Zero-Copy.



9. **Bounds Check Elimination (BCE):**

   In loops processing massively large arrays (graphs, tick arrays), use the BCE technique by providing a "hint" to the compiler at the top of the function (e.g., `_ = mySlice[length-1]`). This allows the Go compiler to safely omit redundant bounds check instructions that are normally inserted into every iteration of a for-loop on the hot-path.



10. **Avoid Channels for Ultra-Low Latency:**

    In ultra-high-speed Multi-Producer Multi-Consumer (MPMC) processing cores, DO NOT use Go Channels (which fundamentally rely on Mutex locks underneath, causing microsecond delays). Instead, implement or utilize a Lock-Free Ring Buffer structure based on CAS (Compare-And-Swap) array atomics.



## Anti-Patterns (Strictly Forbidden):



- **No Heap Object Initialization in Hot Paths:** `new()`, `make()`, or the use of `*big.Int` inside high-frequency calculation loops (like pathfinding, aggregators) are strictly forbidden. Everything must reside on the stack or be retrieved from `sync.Pool`.

- **No Global Mutexes:** Any `sync.RWMutex` that wraps a large resource (like a cache) operates as a severe bottleneck. You must shard data structures or use atomics.

- **No Blocking I/O in Compute Loops:** No disk logging, no DB queries, and no synchronous network requests in threads responsible for core calculations. Offload I/O to background channels.

- **Don't Overuse Pointers Arbitrarily:** Prioritize passing Value Types (Structs, Primitives) to ensure data remains on the Stack, minimizing "Heap Escape" which pressurizes the GC. Unless the struct is excessively large, pass-by-value is consistently more cache-friendly.

