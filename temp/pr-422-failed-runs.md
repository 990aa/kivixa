# PR Quality Gate Failure Details

## Run

- Workflow: `PR Quality Gate`
- Display title: `Manual Branch fix/android-handwritten-notes`
- Run ID: `36512678759`
- URL: https://github.com/990aa/Kivixa/actions/runs/36512678759
- Branch: `fix/android-handwritten-notes`
- Event: `workflow_dispatch`

## Failed Jobs

- `Flutter Quality Suite` (`109228101332`)
- `Build Windows EXE` (`109228269567`)
- `Build Android ARM64` (`109228269610`)

## Flutter Test Failures

The log ended with `34` failures, but most were cascades from one leaked five-minute timer:

```text
A Timer is still pending even after the widget tree was disposed.
Failed assertion: line 2543 pos 12: '!timersPending'
Timer (duration: 0:05:00.000000, periodic: false)
AppLifecycleManager._resetIdleTimer
SleepWakeController.attach
_MediaVideoPlayerState.initState
```

The two independent assertion failures were:

```text
Expected: contains 'SettingsSubtitle(subtitle: \'Handwritten Note\')'
Actual: 'import \'dart:io\'; ...'
```

This was an outdated source-text test: the current settings UI uses `category: 'Handwritten Note'`.

```text
TermsAndConditionsService terms text contains required sections [E]
Expected: <true>
Actual: <false>
```

This was an outdated test expecting headings no longer present in the current terms document.

## Windows Failure

The Windows job failed in the WebView plugin with MSVC error `STL1011`:

```text
error C2338: static assertion failed: 'error STL1011: The /await compiler option,
<experimental/coroutine>, <experimental/generator>, and <experimental/resumable>
are deprecated by Microsoft and will be REMOVED SOON. They are superseded by the
C++20 <coroutine> and C++23 <generator> headers. You can define
_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS to suppress this error for now.'
```

The runner also emitted a non-fatal path warning from `s.ps1` for
`C:\Users\runneradmin\AppData`.

## Android Failure

The Android job failed while compiling the C++ dependency:

```text
CXX_aarch64_linux_android = Some(./aarch64-linux-android23-clang++)
error occurred in cc-rs: failed to find tool "./aarch64-linux-android23-clang++":
No such file or directory (os error 2)
##[error]Process completed with exit code 101.
```

## Fixes

- Prevented uninitialized `SleepWakeController` instances from registering global idle timers.
- Updated the stale settings and terms tests to match current production content.
- Added the MSVC coroutine deprecation suppression definition to Windows CMake and CI.
- Made Android NDK compiler discovery absolute with `realpath` before exporting CC/CXX/linker variables.

## Validation

- Focused Flutter tests: `48` passed.
- No local Windows or Android platform builds were run.
