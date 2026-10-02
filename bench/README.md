# Stage 1 benchmarks

Micro-benchmarks used to characterize the Ripes simulator before porting
the solver. Analysis lives in the HackMD note; this file only indexes the
raw data.

## Programs

All three loops retire exactly `4N + 6` instructions
(`la` 2 + `li` 2 + `4N` + `li a7` 1 + `ecall` 1), so their times are
directly comparable.

| Variant | File | Loop body | Guest memory behavior |
| :--- | :--- | :--- | :--- |
| A | `rate_alu.s` | `addi`, `addi`, `addi`, `bne` | none |
| B | `rate.s` | `sw`, `lw` (same address), `addi`, `bne` | 4 bytes, rewritten |
| C | `rate_sweep.s` | `sw`, `addi t0,4`, `addi`, `bne` | 4 new bytes per iteration |

`measure.ps1` runs Ripes several times and samples the process's peak
working set every 50 ms.

Result file names use `alu` = A, `iss` = B (historical name, refers to
`rate.s`, not the ISS model), `sweep` = C.

## How the results were produced

Rate (one run each):

```
Ripes.exe --mode cli --proc <MODEL> --src <file>.s -t asm --iret --exectime --timeout 600000 --output results/<name>.txt
```

Memory (3 runs each, `RV32_ISS`):

```
.\measure.ps1 -Runs 3 -Ripes C:\Ripes\Ripes.exe -ArgLine "--mode cli --proc RV32_ISS --src <file>.s -t asm --iret --exectime --timeout 600000" | Tee-Object results\mem-<name>.txt
```

## Raw numbers

### 1. Simulation rate: how fast does each Ripes model run?

Question: how many instructions per second does each processor model
retire, and does that depend on what the program does with memory?

Columns:

* **Retired**: instructions retired, from `--iret`; must equal `4N + 6`.
* **Time**: `--exectime`, the model's execution time only (excludes
  Ripes startup and assembly).
* **Rate** = Retired / Time.

How to read it: compare rows **within one model** (A vs B vs C) to see the
cost of memory behavior; compare **the same variant across models** to see
how much slower the pipeline model is. Compare rates, not times, since N
differs between some rows.

| Model | Variant | N | Retired | Time (ms) | Rate (instr/s) | File |
| :--- | :--- | ---: | ---: | ---: | ---: | :--- |
| RV32_ISS | A | 1,000,000 | 4,000,006 | 399 | 10.03 M | `rate-alu-1M.txt` |
| RV32_ISS | B | 1,000,000 | 4,000,006 | 433 | 9.24 M | `rate-iss-1M.txt` |
| RV32_ISS | C | 1,000,000 | 4,000,006 | 2277 | 1.76 M | `rate-sweep-1M.txt` |
| RV32_5S | A | 100,000 | 400,006 | 3278 | 122.0 k | `rate-5s-alu-100k.txt` |
| RV32_5S | B | 100,000 | 400,006 | 3676 | 108.8 k | `rate-5s-iss-100k.txt` |
| RV32_5S | C | 100,000 | 400,006 | 3632 | 110.1 k | `rate-5s-sweep-100k.txt` |
| RV32_5S | A | 1,000,000 | 4,000,006 | 35174 | 113.7 k | `rate-5s-alu-1M.txt` |
| RV32_5S | B | 1,000,000 | 4,000,006 | 36057 | 110.9 k | `rate-5s-iss-1M.txt` |
| RV32_5S | C | 1,000,000 | 4,000,006 | 35579 | 112.4 k | `rate-5s-sweep-1M.txt` |

### 2. RV32_ISS rate of variant C as the swept region grows

Question: does the cost of writing new guest memory depend on how much has
already been written? Taken from the `--exectime` lines of the memory runs
below (median of 3). Variant C at N = 1M appears in both tables from
separate runs (2277 ms here vs 2326 ms below).

| N | Guest bytes written | Retired | Time (ms, median) | Rate (instr/s) | File |
| ---: | ---: | ---: | ---: | ---: | :--- |
| 250,000 | 1,000,000 | 1,000,006 | 460 | 2.17 M | `mem-sweep-250k.txt` |
| 500,000 | 2,000,000 | 2,000,006 | 1078 | 1.86 M | `mem-sweep-500k.txt` |
| 1,000,000 | 4,000,000 | 4,000,006 | 2326 | 1.72 M | `mem-sweep-1M.txt` |
| 2,000,000 | 8,000,000 | 8,000,006 | 5302 | 1.51 M | `mem-sweep-2M.txt` |

### 3. Host memory per guest byte (RV32_ISS, median of 3)

Question: how many bytes of host (PC) memory does Ripes use for each byte
of guest memory the program writes?

Columns:

* **Guest bytes written** = 4N for variant C (one new word per iteration);
  4 for the control, which rewrites one word.
* **Peak**: the Ripes process's peak working set in each of 3 runs, as
  sampled by `measure.ps1`.

How to read it: the control is Ripes' own footprint with almost no guest
memory. Subtracting it from each C row leaves the memory caused by the
written guest bytes; dividing by the guest bytes gives host bytes per
guest byte. The fit below uses all four C rows.

| Program | N | Guest bytes written | Peak (MiB) | Median | File |
| :--- | ---: | ---: | :--- | ---: | :--- |
| B (control) | 1,000,000 | 4 | 23.9 / 23.4 / 23.4 | 23.4 | `mem-control.txt` |
| C | 250,000 | 1,000,000 | 80.2 / 80.9 / 87.2 | 80.9 | `mem-sweep-250k.txt` |
| C | 500,000 | 2,000,000 | 147.8 / 145.3 / 146.2 | 146.2 | `mem-sweep-500k.txt` |
| C | 1,000,000 | 4,000,000 | 269.4 / 267.7 / 271.8 | 269.4 | `mem-sweep-1M.txt` |
| C | 2,000,000 | 8,000,000 | 517.4 / 520.0 / 519.4 | 519.4 | `mem-sweep-2M.txt` |

Least-squares fit over the four C points: slope 65.5 host bytes per guest
byte, intercept 19.7 MiB (1 MiB = 1,048,576 bytes).
