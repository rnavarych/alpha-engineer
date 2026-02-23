# Backend Performance and Profiling

## When to load
Load when profiling CPU or memory in Node.js, Python, Java, Go, or .NET, or selecting benchmarking tools.

## Profiling Tools by Language

| Language | CPU Profiler | Memory Profiler | Key Commands |
|----------|-------------|-----------------|--------------|
| Node.js | `clinic flame`, `0x`, `--prof` | `clinic heapprofiler`, `--inspect` (Chrome DevTools) | `node --prof app.js && node --prof-process isolate-*.log` |
| Python | `py-spy`, `cProfile`, `scalene` | `memray`, `memory_profiler`, `tracemalloc` | `py-spy record -o profile.svg -- python app.py` |
| Java | `async-profiler`, JFR, JProfiler | VisualVM, `jmap`, Eclipse MAT | `java -XX:StartFlightRecording=filename=rec.jfr -jar app.jar` |
| Go | `pprof` (built-in), `fgprof` | `pprof` (heap), `runtime.MemStats` | `go tool pprof http://localhost:6060/debug/pprof/profile` |
| .NET | `dotnet-trace`, `dotnet-counters` | `dotnet-dump`, `dotnet-gcdump` | `dotnet-trace collect --process-id <PID>` |
| Rust | `cargo flamegraph`, `perf` | `heaptrack`, `DHAT` (Valgrind) | `cargo flamegraph -- ./target/release/myapp` |

## Node.js Profiling
```bash
# CPU flame graph with 0x
npx 0x app.js  # Opens flame graph in browser after Ctrl+C

# Clinic.js suite
npx clinic flame -- node app.js

# Built-in V8 profiler
node --prof app.js
node --prof-process isolate-0x*.log > profile.txt

# Heap snapshot for memory leaks
node --inspect app.js
# Open chrome://inspect -> Memory tab -> Take heap snapshot
```

## Python Profiling
```bash
py-spy record -o profile.svg --pid 12345
py-spy top --pid 12345  # Live top-like view

pip install scalene && scalene app.py  # CPU + memory + GPU, line-level

pip install memray
memray run app.py
memray flamegraph memray-app.bin -o flamegraph.html

python -m cProfile -o profile.prof app.py
snakeviz profile.prof  # Interactive sunburst visualization
```

## Java Profiling
```bash
# Java Flight Recorder (production-safe)
java -XX:StartFlightRecording=duration=60s,filename=recording.jfr -jar app.jar
# Analyze with JDK Mission Control (jmc)

# async-profiler (low-overhead, flame graphs)
./asprof -d 30 -f profile.html <pid>
# Supports: cpu, alloc, lock, wall-clock profiling

# GC analysis
java -Xlog:gc*:file=gc.log:time,level,tags -jar app.jar
```

## Go Profiling
```bash
# Add to HTTP server
import _ "net/http/pprof"  # Registers /debug/pprof/ endpoints

# CPU profile (30-second capture)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Benchmark with profiling
go test -bench=. -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof
go tool pprof -http=:8080 cpu.prof
```

## Benchmarking Tools

| Tool | Type | Language | Best For |
|------|------|----------|----------|
| **k6** | Load testing | JavaScript (Go engine) | HTTP, WebSocket, gRPC, browser |
| **wrk** | HTTP benchmarking | C + Lua | Simple HTTP benchmarks, low overhead |
| **hey** | HTTP benchmarking | Go | Quick CLI benchmarks |
| **Locust** | Load testing | Python | Python teams, distributed, web UI |
| **Gatling** | Load testing | Scala/Java | JVM teams, detailed reports |
| **JMH** | Micro-benchmarking | Java | JVM method-level benchmarks (handles JIT, warmup) |
| **BenchmarkDotNet** | Micro-benchmarking | .NET | .NET method-level, statistical analysis |
| **hyperfine** | CLI benchmarking | Rust | Comparing CLI command performance |

```javascript
// k6 load test example
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('https://api.example.com/items');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

## Memory Leak Identification
- **Node.js**: Heap snapshots via `--inspect` + Chrome DevTools. Compare 3 snapshots over time.
- **Python**: `tracemalloc.start()` + `tracemalloc.take_snapshot()`. Compare with `compare_to()`.
- **Java**: `jmap -dump:live,format=b,file=heap.hprof <pid>`. Analyze with Eclipse MAT or VisualVM.
- **Go**: `go tool pprof .../heap`. Look at `inuse_space` vs `alloc_space`.

### Common Leak Sources
- Event listeners not removed (Node.js, browser)
- Unbounded caches without eviction (all languages)
- Closures capturing large objects (JavaScript, Python)
- Static collections growing indefinitely (Java, .NET)
- Goroutine leaks from missing context cancellation (Go)
