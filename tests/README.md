# Filter tests

## Quick run

From the **apex-filters** repo root:

```bash
./tests/run_filter_tests.sh
```

Requirements:

- **apex** in `PATH`
- **git**, **jq**
- For Lua filters (e.g. unwrap, uppercase): **lua**, **luarocks**, and `luarocks install dkjson`

## Adding a test for a new filter

1. **Add your filter** to `apex-filters.json` (id, repo, description, etc.).

2. **Add a fixture** in `tests/fixtures/<id>.md`: a small Markdown file that demonstrates the filter (e.g. input that the filter changes in a visible way).

3. **Add one or more tests** in `tests/run_filter_tests.sh`:
   - The script already runs every filter listed in `apex-filters.json` against `tests/fixtures/<id>.md` if that file exists (exit code and run are checked).
   - Add a **filter-specific assertion** by defining a shell function `test_<id>()` that receives the HTML output and returns 0 on success, non-zero on failure. Example:

     ```bash
     test_myfilter() {
       local out="$1"
       echo "$out" | grep -q 'expected substring' || return 1
     }
     ```

4. Open a pull request with a short description of the filter and how you tested it (e.g. “Ran `./tests/run_filter_tests.sh` and manual `apex --filter myfilter sample.md`”).
