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

