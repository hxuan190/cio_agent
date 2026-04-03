# Token Economy & Extreme I/O Rules

This system prioritizes absolute token zero-waste.

## 1. Zero-Fat File Reads
- **NEVER** read an entire file if it exceeds 200 lines. 
- ALWAYS use `grep` (or code search tools) to find the exact line numbers of target functions first.
- ALWAYS use `view_file` (or `sed`) with explicit `StartLine` and `EndLine` to read ONLY the 30-50 lines representing the function body.

## 2. Prompt Caching Awareness
- Read static project architecture documentation sparingly.
- When referencing a large master file, assume it is implicitly cached. Do not continuously output content from the file into the conversation log.

## 3. Sandboxed Terminal Output
- Console logs and stack traces are massive token burners.
- For commands that build, test, or lint full projects, **must use** `./core/scripts/safe-exec.sh "command"` to truncate outputs to only the Head and Tail. No exceptions.
