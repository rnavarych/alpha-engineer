# Concurrency Patterns

## Goroutine with Context Cancellation

```go
// Every goroutine must have a way to stop
func startWorker(ctx context.Context, workChan <-chan Work) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return // Stop when context cancelled
            case work, ok := <-workChan:
                if !ok {
                    return // Stop when channel closed
                }
                process(work)
            }
        }
    }()
}
```

## errgroup — Parallel with Error Handling

```go
import "golang.org/x/sync/errgroup"

func fetchDashboard(ctx context.Context, userID string) (*Dashboard, error) {
    g, ctx := errgroup.WithContext(ctx)

    var user *User
    var orders []Order
    var stats *Stats

    g.Go(func() error {
        var err error
        user, err = getUser(ctx, userID)
        return err
    })

    g.Go(func() error {
        var err error
        orders, err = getOrders(ctx, userID)
        return err
    })

    g.Go(func() error {
        var err error
        stats, err = getStats(ctx, userID)
        return err
    })

    // Wait for all — if any fails, ctx is cancelled, others abort
    if err := g.Wait(); err != nil {
        return nil, fmt.Errorf("fetchDashboard: %w", err)
    }

    return &Dashboard{User: user, Orders: orders, Stats: stats}, nil
}
```

## Worker Pool

```go
func workerPool(ctx context.Context, jobs <-chan Job, results chan<- Result, numWorkers int) {
    var wg sync.WaitGroup

    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for {
                select {
                case <-ctx.Done():
                    return
                case job, ok := <-jobs:
                    if !ok {
                        return
                    }
                    result := processJob(ctx, job)
                    select {
                    case results <- result:
                    case <-ctx.Done():
                        return
                    }
                }
            }
        }(i)
    }

    go func() {
        wg.Wait()
        close(results)
    }()
}

// Usage
jobs := make(chan Job, 100)
results := make(chan Result, 100)
workerPool(ctx, jobs, results, runtime.NumCPU())
```

## Fan-Out / Fan-In

```go
// Fan-out: distribute work to multiple goroutines
func fanOut(ctx context.Context, input <-chan int, numWorkers int) []<-chan int {
    channels := make([]<-chan int, numWorkers)
    for i := 0; i < numWorkers; i++ {
        channels[i] = worker(ctx, input)
    }
    return channels
}

func worker(ctx context.Context, input <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range input {
            select {
            case out <- n * n:
            case <-ctx.Done():
                return
            }
        }
    }()
    return out
}

// Fan-in: merge multiple channels into one
func fanIn(ctx context.Context, channels ...<-chan int) <-chan int {
    merged := make(chan int)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for val := range c {
                select {
                case merged <- val:
                case <-ctx.Done():
                    return
                }
            }
        }(ch)
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

## Semaphore — Concurrency Limiting

```go
import "golang.org/x/sync/semaphore"

var sem = semaphore.NewWeighted(10) // Max 10 concurrent

func rateLimitedProcess(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item
        g.Go(func() error {
            if err := sem.Acquire(ctx, 1); err != nil {
                return err
            }
            defer sem.Release(1)
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}
```

## Anti-Patterns
- Goroutine without exit path — leaks memory forever
- Unbuffered channel with no reader — goroutine blocks forever
- Missing `sync.WaitGroup` — main exits before goroutines finish
- Shared mutable state without mutex — data race (use `-race` flag)
- Ignoring `ctx.Done()` in select — goroutine ignores cancellation

## Quick Reference
```
errgroup: parallel with shared error handling + context cancellation
Worker pool: bounded goroutines, channel-based job distribution
Fan-out/fan-in: distribute work, merge results
Semaphore: limit concurrent access to resources
WaitGroup: wait for goroutines to complete
Context: always check ctx.Done() in select — enable cancellation
Race detector: go run -race ./... — catches data races
Workers count: runtime.NumCPU() for CPU-bound, 10-100 for I/O-bound
```
