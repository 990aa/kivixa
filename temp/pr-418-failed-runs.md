# PR Quality Gate Failure Details

## Run

- Workflow: `PR Quality Gate`
- Display title: `Manual Branch main`
- Run ID: `36505040491`
- URL: https://github.com/990aa/kivixa/actions/runs/36505040491
- Branch: `main`
- Event: `workflow_dispatch`

## Failed Jobs

The run reported these nine failed jobs:

- `Flutter Quality Suite` (`109204480141`)
- `Rust Quality Suite (native_math)` (`109204480189`)
- `Rust Security & Policy (native_math)` (`109204480267`)
- `Rust Security & Policy (native)` (`109204480269`)
- `Rust Quality Suite (native)` (`109204480297`)
- `Rust Security & Policy (native_audio)` (`109204480343`)
- `Rust Quality Suite (native_audio)` (`109204480360`)
- `Build Windows EXE` (`109204639152`)
- `Build Android ARM64` (`109204639180`)

## Exact Failure Categories

### Flutter and Rust quality

The changed generated Dart and Rust bridge files failed the workflow's changed-file formatter steps. The generated bridge outputs were manually normalized in the prior change, but the correct fix is regeneration through the repository scripts.

### Rust security policy

The logs reported:

```text
anyhow 1.0.102
RUSTSEC-2026-0190
Solution: Upgrade to >=1.0.103
```

The native_audio audit also reported:

```text
crossbeam-epoch 0.9.18
RUSTSEC-2026-0204
Solution: Upgrade to >=0.9.20
```

### Android

The first attempted workflow fix exported an invalid compiler path because `ANDROID_NDK_HOME` was empty:

```text
CXX_aarch64_linux_android = Some(/aarch64-linux-android-clang++)
error occurred in cc-rs: failed to find tool "/aarch64-linux-android-clang++": No such file or directory (os error 2)
##[error]Process completed with exit code 101.
```

### Windows

The build also contained generated Dart syntax errors in the previous bridge outputs. Those outputs were regenerated through `scripts/run_codegen.ps1`; no platform build was run locally.

## Remediation

- Regenerated core, math, and audio FRB outputs using `scripts/run_codegen.ps1`.
- Added `--no-auto-upgrade-dependency` to both bridge regeneration scripts.
- Confirmed generated bridge files match `HEAD`; no manual generated-file edits remain.
- Updated all affected Cargo lockfiles to `anyhow 1.0.103` and `crossbeam-epoch 0.9.20`.
- Derived Android `NDK_BIN` from the compiler on `PATH` and exported the target C++ compiler for all native Android jobs.

## Validation

- `flutter analyze --fatal-infos --fatal-warnings`: passed, no issues.
- Rustfmt checks: passed for `native`, `native_audio`, and `native_math`.
- `cargo audit`: passed for all three crates.
- `cargo deny check`: passed for all three crates.
- No local platform builds were run.
