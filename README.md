# Apex Filters Directory

This repository defines the **public filter directory** for the Apex Markdown
processor. It is consumed by the Apex CLI when you use:

- `--install-plugin ID` (for plugins)
- `--filter ID` / `--filters` (for AST filters)

The file `apex-filters.json` describes available **AST filters** that can be
installed into `~/.config/apex/filters` and then enabled at runtime.

## Filters

Currently defined filters:

- **title**
  - **Description**: Adds a level‑1 header at the top of the document based on
    the document title (`meta.title`) if one is not already present.
  - **Repo**: `https://github.com/ApexMarkdown/apex-filter-title`
  - **Language**: Ruby

- **delink**
  - **Description**: Converts links to plain text by stripping the hyperlink
    target but preserving the link text.
  - **Repo**: `https://github.com/ApexMarkdown/apex-filter-delink`
  - **Language**: Python

- **uppercase**
  - **Description**: Converts all plain text in the document to uppercase.
  - **Repo**: `https://github.com/ApexMarkdown/apex-filter-uppercase`
  - **Language**: Lua

- **unwrap**
  - **Description**: Unwraps elements starting with `< ` (e.g. paragraphs into raw HTML blocks); also unwraps single-image paragraphs to bare `<img>`.
  - **Repo**: `https://github.com/ApexMarkdown/apex-filter-unwrap`
  - **Language**: Lua (requires `dkjson`)

## Using filters with Apex

### Installing via CLI

You can install filters directly from the central directory using:

```bash
apex --install-filter title
apex --install-filter delink
```

This clones the corresponding repositories under:

- `$XDG_CONFIG_HOME/apex/filters` (if set), or
- `~/.config/apex/filters`

### Manual installation

You can also install a filter manually by placing its executable into:

- macOS/Linux:
  - `$XDG_CONFIG_HOME/apex/filters` (if set), or
  - `~/.config/apex/filters`

For example:

```bash
mkdir -p ~/.config/apex/filters
cp path/to/title.rb ~/.config/apex/filters/title
chmod +x ~/.config/apex/filters/title
```

Then run Apex with:

```bash
apex --filter title input.md > output.html
apex --filter delink input.md > output.html
apex --filters input.md > output.html   # run all installed filters
```

## Tests

Filter tests live in `tests/`. From the repo root, run:

```bash
./tests/run_filter_tests.sh
```

See [tests/README.md](tests/README.md) for requirements and how to add tests for new filters.

## How to request adding a filter

To propose a new filter for this directory:

1. **Fork this repository** (apex-filters).

2. **Update `apex-filters.json`** with your filter’s entry: `id`, `title`, `description`, `author`, `homepage`, and `repo` (and `requires` if it has dependencies, e.g. Lua rocks).

3. **Add tests:**
   - Add a **fixture** under `tests/fixtures/<id>.md`: a small Markdown file that demonstrates the filter (input that the filter changes in a visible way).
   - Add **one or more tests** in `tests/run_filter_tests.sh`: define a `test_<id>()` function that asserts the filter’s HTML output (see existing filters for examples).

4. **Open a pull request** with:
   - A short description of **what the filter does**.
   - A note on **how you tested it** (e.g. “Ran `./tests/run_filter_tests.sh` and `apex --filter <id> sample.md`”).

Maintainers will review the JSON entry, fixture, and tests before merging.

