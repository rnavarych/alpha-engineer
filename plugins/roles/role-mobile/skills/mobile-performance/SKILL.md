---
name: mobile-performance
description: Expert guidance on mobile performance optimization — achieving 60fps rendering, memory management (leak detection, large image handling), battery optimization, startup time reduction (cold/warm/hot), image loading strategies (Glide, SDWebImage, cached_network_image), and profiling tools (Instruments, Android Profiler, Flipper). Use when diagnosing or improving mobile app performance.
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile Performance

## When to use
- Diagnosing frame drops, jank, or ANR issues on iOS or Android
- Detecting and fixing memory leaks (closures, listeners, retained bitmaps)
- Reducing cold start time to meet the 2-second-to-interactive target
- Choosing image loading libraries (Glide, Coil, SDWebImage, Kingfisher, Nuke)
- Selecting the right profiling tool for the symptom: CPU, memory, battery, or frames
- Optimizing React Native FlatList/FlashList rendering or Flutter widget rebuilds
- Setting up Firebase Performance Monitoring or Macrobenchmark for field data

## Core principles
1. **Measure before optimizing** — a frame drop without a profile is a guess; a guess is a waste of time
2. **Frame budget is physics** — 60fps means 16.67ms; every millisecond over budget is visible
3. **Leaks are deferred crashes** — a leak that takes 10 minutes to OOM-kill is still a crash
4. **Cold start under 2 seconds** — on a mid-range device; not your M2 MacBook running the simulator
5. **Battery complaints mean background work** — excessive wake-ups, GPS polling, or timer abuse

## Reference Files

- `references/rendering-memory.md` — 60fps frame budget, iOS CoreAnimation pitfalls, Android overdraw and Compose recomposition, React Native list tuning, Flutter RepaintBoundary and const usage, memory leak detection tools (Instruments, LeakCanary, Flipper, DevTools), common leak patterns, large image downsampling strategies
- `references/startup-images-profiling.md` — battery optimization strategies, cold/warm/hot start definitions and targets, startup measurement tools (os_signpost, MetricKit, Macrobenchmark, Perfetto), iOS image libraries (SDWebImage, Kingfisher, Nuke), Android image libraries (Glide, Coil), cross-platform image caching, Xcode Instruments suite, Android Studio Profiler, Flipper, Flutter DevTools
