# Issue #137 – G1 vs ZGC (generational) vs Shenandoah for Kaui

Draft results (not yet posted). Raw data: `results/` (JFR + gc.log + Gatling report per run, `summary.csv`).

## Setup
- Kaui: m6i.large (2 vCPU, 8 GiB), OpenJDK 21.0.13, JRuby 10, Tomcat 11, `-Xmx2G`, `-Djruby.compile.invokedynamic=false`,
  `-Djruby.jit.exclude=Rails::Engine#call`. Kill Bill 0.25.5 + MySQL on a separate t2.medium (CPU credits never exhausted:
  balance 105-110, host CPU ~22 % during the matrix, so not the bottleneck).
- Load: Gatling (separate EC2 in the same VPC), 10 users, 30 s ramp + 600 s, 180 s warm-up (not recorded) after every JVM restart,
  485 accounts. Scenarios: `mix`; `account_show` and `timeline` = single page, 100 % large accounts, no think time (stress: they
  saturate both vCPUs).
- JFR (`settings=profile`) + unified gc.log per run. One run per cell (no repetitions), order g1 -> zgc -> shenandoah.

## Results (10 users, 600 s, -Xmx2G)
| scenario | GC | p50 | p75 | p95 | p99 | max | rps | JVM CPU | STW pauses (JFR) total / max |
|---|---|---|---|---|---|---|---|---|---|
| mix | G1 | 91 | 145 | 293 | 704 | 3227 | 7.35 | 87 % | 9.0 s / 174 ms |
| mix | ZGC gen | 76 | 134 | 265 | 712 | 4275 | 7.42 | 71 % | 6 ms / 0.4 ms |
| mix | Shenandoah | 118 | 227 | 600 | 1536 | 11095 | 6.98 | 116 % | 29 ms / 1.2 ms |
| account_show | G1 | 1132 | 1247 | 1362 | 1438 | 1559 | 10.21 | 194 % | 16.5 s / 152 ms |
| account_show | ZGC gen | 1247 | 1361 | 1528 | 1657 | 1905 | 9.13 | 194 % | 59 ms / 0.2 ms |
| account_show | Shenandoah | 1675 | 1872 | 2073 | 2254 | 2744 | 6.90 | 187 % | 93 ms / 2.1 ms |
| timeline | G1 | 5436 | 5737 | 6147 | 6418 | 6796 | 2.22 | 195 % | 24.5 s / 87 ms |
| timeline | ZGC gen | 5881 | 6149 | 6662 | 6988 | 7237 | 2.05 | 195 % | 64 ms / 0.1 ms |
| timeline | Shenandoah | 8114 | 9147 | 11343 | 12438 | 14066 | 1.42 | 186 % | 14.8 s / 1160 ms (allocation failure -> degenerated/full GC) |

Latencies in ms. 0 KO in all runs.

## Working set (G1, `mix`, 300 s per heap size, class histogram = full GC at the end)
- Live set after a full GC: ~280-295 MB of heap (+ ~157 MB metaspace, outside the heap). Biggest: `byte[]` 48-53 MB, CHM nodes, Object[].
- Minimum heap after GC during load (JFR): 267-286 MB for every `-Xmx`; median ~320-360 MB.

| -Xmx | p99 | GC pause total (300 s) | Full GCs under load |
|---|---|---|---|
| 2G | 690 | ~2.5 s (~0.8 %) | 0 |
| 1G | 805 | ~4.2 s (~1.4 %) | 0 |
| 768m | 745 | ~5.1 s (~1.7 %) | 0 |
| 512m | 978 | ~7.1 s (~2.4 %) | 3 |
(each run also has 1 deliberate full GC from the histogram.)

## Reading
- Kaui is CPU-bound on the 2 vCPU box for the heavy pages. Concurrent collectors (ZGC, Shenandoah) take CPU from the app:
  ZGC -11 % / -8 % throughput on account_show / timeline, Shenandoah -32 % / -36 %. Shenandoah fell over on `timeline`
  (allocation outpaces concurrent GC -> degenerated GC, 1.16 s pause).
- ZGC removes STW pauses (max 0.4 ms vs 174 ms) but that doesn't show in p99 for `mix` (704 vs 712 ms), p50/p75/p95 are slightly better,
  and it uses the whole heap (after-GC values are not a live set).
- G1 pauses are ~1.5 % (mix) to ~4 % (timeline) of wall time with max ~170 ms.

## Recommendation (draft)
- Keep G1 as the default. ZGC generational is a viable alternative if pause max matters (mix), but with only 2 vCPUs
  it costs throughput on heavy pages; Shenandoah is not recommended here.
- `-Xmx`: live set ~0.3 GB. 1G works for `mix` (no Full GC) but p99 is worse than 2G within the noise of one run; 512m is clearly too small.
  `timeline` was not tested below 2G and its heap after GC reaches 1.1-1.4 GB under G1 (promoted garbage), so keep `-Xmx2G` default
  (~6x live set). 1G is a floor for small deployments, not a recommendation.

## Caveats
- Single run per cell, fixed order; max latency outliers (e.g. Shenandoah mix 11 s) are not GC (Shenandoah pauses only 29 ms there).
- `account_show` / `timeline` parameters are my assumption (100 % large accounts, no think time).
- Not measured: indy on/off (#349), after allocation reductions in killbill-client-ruby#125/#126/#136, `timeline` with smaller heap.
- JFR files contain request data from a test system; not uploaded anywhere.
