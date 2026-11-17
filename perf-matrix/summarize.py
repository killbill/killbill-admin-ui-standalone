#!/usr/bin/env python3
"""Append one summary row for a finished run.

usage: summarize.py --header
       summarize.py <rundir> <gc-label> <indy> <scenario> <users> <jvm_cpu_pct>

<rundir> holds report.tgz (Gatling HTML report) and gclog.tgz (gc.log* written during the run).
GC pause numbers are parsed from the unified gc log (lines containing "Pause ... <n>ms"); they are
approximate and meant for a first look. The JFR recording is the authoritative source.
"""
import csv
import json
import os
import re
import sys
import tarfile

FIELDS = ["run", "gc", "indy", "scenario", "users", "requests", "ko", "p50_ms", "p75_ms",
          "p95_ms", "p99_ms", "max_ms", "rps", "jvm_cpu_pct", "gc_pauses", "gc_pause_total_ms",
          "gc_pause_max_ms"]

PAUSE_RE = re.compile(r"Pause\b.*?\s([0-9]+(?:\.[0-9]+)?)ms\s*$")


def gatling_stats(rundir):
    path = os.path.join(rundir, "report.tgz")
    with tarfile.open(path) as t:
        members = {m.name: m for m in t.getmembers()}
        for suffix in ("js/global_stats.json", "js/stats.json"):
            for name, m in members.items():
                if name.endswith(suffix):
                    d = json.load(t.extractfile(m))
                    return d.get("stats", d)
    raise RuntimeError("no stats.json in report.tgz")


def num(text):
    """'1,058' -> 1058.0, '-' -> 0.0"""
    text = text.strip().replace(",", "")
    try:
        return float(text)
    except ValueError:
        return 0.0


def console_stats(rundir):
    """Parse the 'Global Information' table Gatling prints at the end of the run (gatling.log).
    Gatling >= 3.10 no longer writes js/stats.json, but this table is stable across versions."""
    out = {}
    in_table = False
    with open(os.path.join(rundir, "gatling.log"), encoding="utf-8", errors="replace") as f:
        for line in f:
            if "Global Information" in line:
                in_table = True
                continue
            if not in_table:
                continue
            if line.startswith("---- Response Time Distribution") or line.startswith("===="):
                break
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < 4 or not parts[0].startswith(">"):
                continue
            label = parts[0].lstrip("> ").strip().lower()
            total_v, ko_v = num(parts[1]), num(parts[3])
            m = re.search(r"(\d+)(?:st|nd|rd|th) percentile", label)
            if label == "request count":
                out["requests"], out["ko"] = int(total_v), int(ko_v)
            elif m:
                out["p" + m.group(1) + "_ms"] = int(total_v)
            elif label.startswith("max response time"):
                out["max_ms"] = int(total_v)
            elif label.startswith("mean throughput"):
                out["rps"] = total_v
    if "requests" not in out:
        raise RuntimeError("no 'Global Information' table in gatling.log")
    return out


def total(d, key):
    v = d.get(key, {})
    return v.get("total", "") if isinstance(v, dict) else v


def gc_pauses(rundir):
    path = os.path.join(rundir, "gclog.tgz")
    pauses = []
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return pauses
    with tarfile.open(path) as t:
        for m in t.getmembers():
            if not m.isfile() or "gc.log" not in m.name:
                continue
            for raw in t.extractfile(m):
                match = PAUSE_RE.search(raw.decode("utf-8", "replace").rstrip())
                if match:
                    pauses.append(float(match.group(1)))
    return pauses


def main():
    w = csv.writer(sys.stdout, lineterminator="\n")
    if sys.argv[1:] == ["--header"]:
        w.writerow(FIELDS)
        return
    rundir, gc, indy, scenario, users, cpu = sys.argv[1:7]
    row = {"run": os.path.basename(rundir.rstrip("/")), "gc": gc, "indy": indy,
           "scenario": scenario, "users": users, "jvm_cpu_pct": cpu}
    try:
        try:  # older Gatling: js/stats.json inside the report
            s = gatling_stats(rundir)
            n = s.get("numberOfRequests", {})
            row.update(requests=n.get("total", ""), ko=n.get("ko", ""),
                       p50_ms=total(s, "percentiles1"), p75_ms=total(s, "percentiles2"),
                       p95_ms=total(s, "percentiles3"), p99_ms=total(s, "percentiles4"),
                       max_ms=total(s, "maxResponseTime"),
                       rps=total(s, "meanNumberOfRequestsPerSecond"))
        except Exception:
            row.update(console_stats(rundir))
    except Exception as e:  # keep going, the raw files are still on disk
        print(f"warning: Gatling stats unreadable for {rundir}: {e}", file=sys.stderr)
    try:
        p = gc_pauses(rundir)
        row.update(gc_pauses=len(p), gc_pause_total_ms=round(sum(p), 1),
                   gc_pause_max_ms=max(p) if p else 0)
    except Exception as e:
        print(f"warning: gc.log unreadable for {rundir}: {e}", file=sys.stderr)
    w.writerow([row.get(f, "") for f in FIELDS])


if __name__ == "__main__":
    main()
