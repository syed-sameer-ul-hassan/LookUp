<p align="center">
  <img src="assets/logo.bmp" alt="Zenith-Sentry Logo" width="600"/>
</p>


# LookUp

**Professional Storage Intelligence & Directory Analysis Platform**

Version `1.0.0` — License: [Apache 2.0](LICENSE)

---

## What is LookUp?

LookUp is a Bash-based terminal tool that scans your filesystem and produces a full intelligence report on your storage. It finds duplicate files, forgotten large files, empty directories, suspicious permissions, and more — all from a single command, with a clean TUI interface and exportable reports.

---

## Architecture Overview

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#222222', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#444444', 'lineColor': '#888888', 'secondaryColor': '#333333', 'tertiaryColor': '#222222', 'background': '#222222', 'mainBkg': '#222222', 'nodeBorder': '#555555', 'clusterBkg': '#2a2a2a', 'titleColor': '#ffffff', 'edgeLabelBackground': '#222222', 'attributeBackgroundColorEven': '#222222', 'attributeBackgroundColorOdd': '#2d2d2d'}}} %%
graph TD
    A([CLI Entry Point]) --> B[init_all]
    B --> C[init_directories]
    B --> D[init_config]
    B --> E[load_config]
    B --> F[load_theme]
    B --> G[init_history_db]
    B --> H[check_dependencies]

    A --> I{Mode?}
    I -->|scan| J[run_scan]
    I -->|report| K[generate_reports]
    I -->|interactive| L[interactive_menu]
    I -->|history| M[show_history]

    J --> N[Phase 1: _scan_phase_stat]
    J --> O[Phase 2: _scan_phase_hashes]
    J --> P[Phase 3: _scan_phase_analysis]

    N --> Q[File stat collection]
    N --> R[Empty file/dir detection]
    N --> S[Old file detection]

    O --> T[SHA-256 hashing]
    O --> U[Duplicate detection]

    P --> V[Extension stats]
    P --> W[Age stats]
    P --> X[Permission audit]
    P --> Y[Health score calc]

    K --> Z[HTML report]
    K --> AA[JSON report]
    K --> AB[CSV report]
    K --> AC[TXT report]

    style A fill:#222222,color:#ffffff,stroke:#555555
    style B fill:#222222,color:#ffffff,stroke:#555555
    style J fill:#222222,color:#ffffff,stroke:#555555
    style K fill:#222222,color:#ffffff,stroke:#555555
    style L fill:#222222,color:#ffffff,stroke:#555555
    style N fill:#222222,color:#ffffff,stroke:#555555
    style O fill:#222222,color:#ffffff,stroke:#555555
    style P fill:#222222,color:#ffffff,stroke:#555555
```

---

## Scan Pipeline

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#222222', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#444444', 'lineColor': '#888888', 'secondaryColor': '#2d2d2d', 'tertiaryColor': '#222222', 'background': '#222222', 'mainBkg': '#222222', 'nodeBorder': '#555555', 'edgeLabelBackground': '#222222'}}} %%
sequenceDiagram
    participant U as User
    participant S as run_scan
    participant P1 as Phase 1: Stat
    participant P2 as Phase 2: Hash
    participant P3 as Phase 3: Analysis
    participant R as Reports

    U->>S: lookup scan /path
    S->>S: resolve realpath, generate SCAN_ID
    S->>P1: find all files & dirs
    P1->>P1: stat each file (size, mtime, perms, owner)
    P1->>P1: detect empty files & dirs
    P1->>P1: flag files older than 6 months
    P1-->>S: TMP_SIZES_LIST, TMP_EMPTY_*, TMP_OLD_FILES

    S->>P2: iterate files
    P2->>P2: sha256sum each file < 500 MB
    P2->>P2: group by hash = duplicates
    P2-->>S: TMP_HASHES_FILE, TMP_DUPLICATES_FILE

    S->>P3: compute statistics
    P3->>P3: extension frequency
    P3->>P3: age distribution
    P3->>P3: permission anomalies
    P3->>P3: health score 0–100
    P3-->>S: TMP_EXT_STATS, TMP_AGE_STATS, SCAN_HEALTH_SCORE

    S->>R: write history DB entry
    S->>R: generate HTML/JSON/CSV/TXT
    R-->>U: reports in ~/.lookup/reports/
```

---

## Health Score Calculation

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#222222', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#444444', 'lineColor': '#888888', 'background': '#222222', 'mainBkg': '#222222', 'nodeBorder': '#555555', 'edgeLabelBackground': '#222222', 'pie1': '#3a3a3a', 'pie2': '#2a2a2a', 'pie3': '#444444', 'pie4': '#333333'}}} %%
pie title Health Score Components
    "Duplicate penalty" : 25
    "Large file penalty" : 20
    "Old/forgotten files" : 20
    "Empty dirs/files" : 15
    "Permission anomalies" : 10
    "Extension diversity" : 10
```

| Score | Label | Color |
|-------|-------|-------|
| 90–100 | Excellent | Bright Green |
| 70–89 | Good | Green |
| 50–69 | Average | Yellow |
| 0–49 | Poor | Red |

---

## Directory & File Layout

```mermaid
%%{init': {'theme': 'base', 'themeVariables': {'primaryColor': '#222222', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#444444', 'lineColor': '#888888', 'background': '#222222', 'mainBkg': '#222222', 'nodeBorder': '#555555', 'edgeLabelBackground': '#222222'}}} %%
graph LR
    H["~/.lookup/"] --> C["config/"]
    H --> HI["history/"]
    H --> SN["snapshots/"]
    H --> RP["reports/"]
    H --> CA["cache/"]
    H --> PL["plugins/"]
    H --> LK["locks/"]

    C --> CF["lookup.conf"]
    C --> FA["favorites.lst"]
    C --> BK["bookmarks.lst"]
    C --> PR["profile.conf"]
    C --> TH["theme.conf"]

    HI --> HD["history.db"]

    RP --> RH["*.html"]
    RP --> RJ["*.json"]
    RP --> RC["*.csv"]
    RP --> RT["*.txt"]

    style H fill:#222222,color:#ffffff,stroke:#555555
    style C fill:#222222,color:#ffffff,stroke:#555555
    style HI fill:#222222,color:#ffffff,stroke:#555555
    style SN fill:#222222,color:#ffffff,stroke:#555555
    style RP fill:#222222,color:#ffffff,stroke:#555555
    style CA fill:#222222,color:#ffffff,stroke:#555555
    style PL fill:#222222,color:#ffffff,stroke:#555555
    style LK fill:#222222,color:#ffffff,stroke:#555555
```

---

## Configuration & Initialization Flow

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#222222', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#444444', 'lineColor': '#888888', 'background': '#222222', 'mainBkg': '#222222', 'nodeBorder': '#555555', 'edgeLabelBackground': '#222222'}}} %%
flowchart TD
    START([Script launches]) --> CHECK{Config exists?}
    CHECK -- No --> WIZARD[first_run_wizard\nPrompt user for defaults]
    CHECK -- Yes --> LOAD[load_config\nSource lookup.conf]
    WIZARD --> SAVE[Write lookup.conf]
    SAVE --> LOAD
    LOAD --> THEME{Theme setting?}
    THEME -- dark --> DARK[apply_theme_dark\nBright ANSI palette]
    THEME -- light --> LIGHT[apply_theme_light\nMuted ANSI palette]
    DARK --> DEPS[check_dependencies\nwkhtmltopdf pandoc bc ...]
    LIGHT --> DEPS
    DEPS --> TMP[mktemp /tmp/lookup_XXXX\nSet LOOKUP_TMP_DIR]
    TMP --> READY([Ready to run])

    style START fill:#222222,color:#ffffff,stroke:#555555
    style READY fill:#222222,color:#ffffff,stroke:#555555
    style WIZARD fill:#222222,color:#ffffff,stroke:#555555
    style CHECK fill:#222222,color:#ffffff,stroke:#555555
    style THEME fill:#222222,color:#ffffff,stroke:#555555
```

---

## Installation

**Requirements:** Bash 5+, standard Linux utilities (`find`, `stat`, `awk`, `sed`, `grep`, `sha256sum`, `du`, `df`, `tput`, `bc`)

**Optional:** `wkhtmltopdf` (PDF export), `pandoc` (document conversion), `notify-send` (desktop notifications)

```bash
# Clone or download
git clone https://github.com/your-username/lookup.git
cd lookup

# Make executable
chmod +x lookup.sh

# Run for the first time (launches setup wizard)
./lookup.sh
```

---

## Usage

```bash
# Scan a directory
./lookup.sh scan /home/user

# Scan with verbose output
./lookup.sh --verbose scan /path/to/dir

# Launch interactive TUI menu
./lookup.sh interactive

# View scan history
./lookup.sh history

# Generate report from last scan
./lookup.sh report
```

---

## Key Functions Reference

| Function | Description |
|----------|-------------|
| `init_all` | Bootstrap: directories, config, theme, deps, tmp dir |
| `run_scan <path>` | Entry point for a full directory scan |
| `_scan_phase_stat` | Phase 1 — file stat, sizes, empty/old detection |
| `_scan_phase_hashes` | Phase 2 — SHA-256 hashing for duplicate detection |
| `_scan_phase_analysis` | Phase 3 — extension stats, age distribution, health score |
| `print_banner` | Renders the ASCII art header with system info |
| `draw_progress_bar` | Animated progress bar during scan phases |
| `human_size <bytes>` | Converts bytes to KB/MB/GB/TB string |
| `human_duration <secs>` | Converts seconds to h/m/s string |
| `score_color <n>` | Returns ANSI color code for a health score |
| `first_run_wizard` | Interactive setup on first launch |
| `load_config` | Sources `~/.lookup/config/lookup.conf` |
| `load_theme` | Applies dark or light ANSI color theme |
| `cleanup_tmp` | Removes `/tmp/lookup_*` on exit or signal |

---

## Configuration Reference

All settings live in `~/.lookup/config/lookup.conf`:

| Key | Default | Description |
|-----|---------|-------------|
| `LOOKUP_THEME` | `dark` | `dark` or `light` terminal theme |
| `LOOKUP_DEFAULT_SCAN_DIR` | `$HOME` | Directory scanned when none is specified |
| `LOOKUP_REPORT_DIR` | `~/.lookup/reports` | Output directory for reports |
| `LOOKUP_MAX_HISTORY` | `50` | Number of scan history entries to keep |
| `LOOKUP_LARGE_FILE_MB` | `100` | Files above this size are flagged as large |
| `LOOKUP_FORGOTTEN_MONTHS` | `6` | Months since access before a file is "old" |
| `LOOKUP_HASH_ENABLED` | `true` | Enable SHA-256 hashing for duplicate detection |
| `LOOKUP_SECURITY_ENABLED` | `true` | Enable permission anomaly scanning |
| `LOOKUP_AUTO_REPORT` | `true` | Auto-generate reports after each scan |
| `LOOKUP_NOTIFY_ENABLED` | `false` | Desktop notifications via `notify-send` |
| `LOOKUP_MAX_THREADS` | `4` | Parallel worker threads |
| `LOOKUP_SHOW_HIDDEN` | `false` | Include hidden files (dot-files) in scan |

---

## Output Reports

After every scan LookUp writes a report bundle to `~/.lookup/reports/<SCAN_ID>/`:

- `report.html` — full interactive HTML report
- `report.json` — machine-readable scan data
- `report.csv` — file listing with metadata
- `report.txt` — plain-text summary

The history database at `~/.lookup/history/history.db` records:

```
ID | DATE | PATH | FILES | DIRS | SIZE_BYTES | DUPLICATES | HEALTH_SCORE | REPORT_DIR
```

---

## Signal Handling & Cleanup

LookUp traps `INT` and `TERM` signals:

```bash
trap 'show_cursor; cleanup_tmp; exit 130' INT TERM
```

The temp directory under `/tmp/lookup_*` is always removed on exit, even if the scan is interrupted with `Ctrl+C`.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-improvement`
3. Commit your changes: `git commit -m "Add feature"`
4. Push and open a pull request

Please keep functions focused and follow the existing style: `snake_case` names, `readonly` for constants, `local` for all function-scoped variables, and `[[ ]]` for conditionals.

---

## License

Copyright 2024 Syed Sameer Ul Hassan

Licensed under the **Apache License, Version 2.0** — see [LICENSE](LICENSE) for the full text.

You may use, distribute, and modify this software under the terms of that license. You may not use it in violation of applicable law.
