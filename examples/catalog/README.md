# Inventory count and warehouse move

Two people use the same SKU export. The stock counter changes P-01 from 12 to 18 and adds P-03. The warehouse planner changes the zone of P-01 to B1 and exports columns in a different order. A line merge treats these as competing edits. A primary-key merge preserves both.

After building from the repository root, run:

```sh
node cli.mjs sku examples/catalog/base.csv examples/catalog/count.csv examples/catalog/move.csv
```

Compare the output to `expected.csv`. Output uses CRLF record separators. To exercise a conflict, copy the planner's file and change P-01's stock from 12 to 15. The command reports the base value of 12 and both counts on stderr and exits with code 1.
