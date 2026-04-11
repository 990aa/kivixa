## 2024-11-20 - Fix N+1 Filesystem Traversal Query
**Learning:** Calling recursive file listing functions like `getAllFiles()` repeatedly inside loops or batch operations creates severe N+1 query bottlenecks, heavily degrading app performance.
**Action:** When performing operations on multiple file types, pre-fetch the directory contents once and share the cached list among functions, or use a short-lived memory cache to prevent redundant disk I/O.
