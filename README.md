# keyed-csv-merge

Merge two UTF-8 CSV exports against their common base. Identify rows by one unique key column and columns by their header names. This preserves independent edits even when one contributor reorders the rows or columns.

## Run locally

Install [MoonBit](https://www.moonbitlang.com/download/) and Node.js 20 or later. Build the JavaScript target and merge the three sample files from the repository root.

```sh
moon build --target js --release
node cli.mjs sku examples/catalog/base.csv examples/catalog/count.csv examples/catalog/move.csv
```

The command writes the complete table to stdout only when it can resolve every change. To save it, redirect stdout to a **new** file. Shell redirection truncates an existing file before the program runs. Keep all three inputs intact.

## Decisions

| Situation | Result |
| --- | --- |
| Both versions give a cell the same value | Keep that value |
| Only one version changes the cell | Keep the changed value |
| Different columns of one row change | Merge both edits |
| Both versions change a cell differently | Report its key, column and three values |
| One side removes an unchanged row | Remove the row |
| One side removes a row the other edited | Report a delete/edit conflict |
| Both sides introduce the same new key | Accept identical rows, otherwise report an add/add conflict |

Output keeps the base header order and surviving base rows first, then new left rows and new right rows in their original order. Key and cell comparisons are exact strings. Leading zeros and spaces are significant. A key change appears as a deletion and addition. Files need the same set of headers. The tool rejects duplicate or blank keys, duplicate or blank header names, malformed quoting and unexpected field counts.

The parser accepts UTF-8 BOM, LF, CRLF, CR, escaped double quotes, and quoted multi-line fields. Output records use CRLF. All three files must fit in memory.

## Exit codes

| Code | stdout | stderr |
| --- | --- | --- |
| 0 | Merged CSV | Empty |
| 1 | Empty | JSON conflict report |
| 2 | Empty | Input, usage, or file error |

## Use as a Git merge driver

After building, point a **local** Git driver at the absolute path to `git-driver.mjs`, using the key column for that dataset. For a catalog keyed by `sku`, add this to the consuming repository’s Git configuration, replacing the example path:

```ini
[merge "catalog"]
    name = Merge catalog rows by SKU
    driver = node "/absolute/path/to/keyed-csv-merge/git-driver.mjs" sku "%O" "%A" "%B"
```

Then add `catalog.csv merge=catalog` to that repository’s `.gitattributes`. The driver replaces the current snapshot only on a clean merge. On conflict, Git marks the file unresolved and the driver prints details on stderr. Inspect the three Git stages before resolving the file.

## Tests

```sh
moon test --target js
moon build --target js --release
node --test cli.test.mjs
```

MIT licensed. The MoonBit implementation uses the core library. The Node.js wrappers use built-in modules.
