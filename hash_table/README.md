# Hash table optimization

Initial performance:
```
Benchmark 1: build/hash_table
  Time (mean ± σ):     207.9 ms ±  20.5 ms    [User: 204.8 ms, System: 2.7 ms]
  Range (min … max):   181.1 ms … 240.5 ms    12 runs

```

Most of the time is consumed by `table_insert_key`, memory reads take up 86% of its CPU time.
```
  86.55 │61:   mov    rdi,QWORD PTR [rbx]
```

