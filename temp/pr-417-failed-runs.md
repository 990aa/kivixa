# Failed Run Details

## Source

- Repository: `990aa/kivixa`
- Requested reference: `PR #417`, `Manual Branch fix/android-handwritten-notes`
- GitHub PR lookup result: `GraphQL: Could not resolve to a PullRequest with the number of 417. (repository.pullRequest)`
- Matching workflow run: `36500777420`
- Run URL: https://github.com/990aa/kivixa/actions/runs/36500777420
- Event: `workflow_dispatch`
- Head branch: `fix/android-handwritten-notes`
- Created: `2026-09-28T23:58:49Z`
- Updated: `2026-09-29T00:14:21Z`

## Failure Cases

### 1. Flutter Quality Suite

- Job ID: `109190857717`
- Failed step: `Enforce Dart formatting (changed files)`
- Exact terminal result:

```text
##[error]Process completed with exit code 123.
```

The failure is the Dart formatter check for changed files.

### 2. Rust Quality Suite (native_math)

- Job ID: `109190857793`
- Failed step: `Cargo fmt check (changed Rust files)`
- Exact terminal result:

```text
##[error]Process completed with exit code 123.
```

The log contains rustfmt diffs in generated `native_math/src/frb_generated.rs`, including changes such as:

```diff
-                pub  fn wire__crate__api__...
+    pub fn wire__crate__api__...
```

and generated C-struct decoder layout changes such as:

```diff
- crate::statistics::StatisticsResult{success: self_.get(0).cst_decode(),values: self_.get(1).cst_decode(),error: self_.get(2).cst_decode()}
+ crate::statistics::StatisticsResult {
+     success: self_.get(0).cst_decode(),
+     values: self_.get(1).cst_decode(),
+     error: self_.get(2).cst_decode(),
+ }
```

### 3. Build Windows EXE

- Job ID: `109191029194`
- Failed step: `Build Windows app`
- Exact runner-side PowerShell error:

```text
s.ps1:25 char:17
+             $item = Get-Item $realPath
+                     ~~~~~~~~~~~~~~~~~~
CategoryInfo          : ObjectNotFound: (C:\Users\runneradmin\AppData:String) [Get-Item], IOException
FullyQualifiedErrorId : ItemNotFound,Microsoft.PowerShell.Commands.GetItemCommand
```

The subsequent Dart compiler errors were:

```text
lib/src/rust_math/frb_generated.io.dart(2676,1): error G85CCD27E: Expected a declaration, but got ')'.
lib/src/rust_math/frb_generated.io.dart(2676,3): error G85CCD27E: Expected a declaration, but got '=>'.
lib/src/rust_math/frb_generated.io.dart(2677,5): error G67247B7E: Expected '{' before this.
lib/src/rust_math/frb_generated.io.dart(2677,5): error G85CCD27E: Expected a declaration, but got '..'.
lib/src/rust_math/frb_generated.io.dart(2677,7): error G3763787C: A function declaration needs an explicit list of parameters.
lib/src/rust_math/frb_generated.io.dart(2677,10): error G67247B7E: Expected '{' before this.
lib/src/rust_math/frb_generated.io.dart(2677,10): error G85CCD27E: Expected a declaration, but got '.'.
lib/src/rust_math/frb_generated.io.dart(2677,11): error G077942FA: Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
lib/src/rust_math/frb_generated.io.dart(2679,1): error G85CCD27E: Expected a declaration, but got '}'.
lib/src/rust/frb_generated.io.dart(2370,1): error G85CCD27E: Expected a declaration, but got ')'.
lib/src/rust/frb_generated.io.dart(2370,3): error G85CCD27E: Expected a declaration, but got '=>'.
lib/src/rust/frb_generated.io.dart(2371,5): error G67247B7E: Expected '{' before this.
lib/src/rust/frb_generated.io.dart(2371,5): error G85CCD27E: Expected a declaration, but got '..'.
lib/src/rust/frb_generated.io.dart(2371,7): error G3763787C: A function declaration needs an explicit list of parameters.
lib/src/rust/frb_generated.io.dart(2371,10): error G67247B7E: Expected '{' before this.
lib/src/rust/frb_generated.io.dart(2371,10): error G85CCD27E: Expected a declaration, but got '.'.
lib/src/rust/frb_generated.io.dart(2371,11): error G077942FA: Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
lib/src/rust/frb_generated.io.dart(2373,1): error G85CCD27E: Expected a declaration, but got '}'.
lib/src/rust_math/frb_generated.io.dart(2678,17): error GC9768DF9: Undefined name 'len'.
lib/src/rust_math/frb_generated.io.dart(2677,11): error G297C951C: Can't infer the type of 'ptr': circularity found during type inference.
lib/src/rust/frb_generated.io.dart(2372,17): error GC9768DF9: Undefined name 'len'.
lib/src/rust/frb_generated.io.dart(2371,11): error G297C951C: Can't infer the type of 'ptr': circularity found during type inference.
```

Final exact build failure:

```text
error MSB8066: Custom build ... exited with code 1.
Build process failed.
##[error]Process completed with exit code 1.
```

### 4. Build Android ARM64

- Job ID: `109191029282`
- Failed step: `Build native (Android)`
- Exact compiler discovery failure:

```text
warning: llama-cpp-sys-2@0.1.157: Compiler family detection failed due to error: ToolNotFound: failed to find tool "aarch64-linux-android-clang++": No such file or directory (os error 2)
```

Exact final error:

```text
error occurred in cc-rs: failed to find tool "aarch64-linux-android-clang++": No such file or directory (os error 2)
warning: build failed, waiting for other jobs to finish...
##[error]Process completed with exit code 101.
```

## Scope Note

No local Android, Windows, or other platform build is run. The requested local validation is limited to `flutter analyze` and source-level fixes.
