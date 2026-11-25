#!/usr/bin/env node
import { readFile } from 'node:fs/promises'
import { TextDecoder } from 'node:util'
import { merge_csv } from './_build/js/release/build/keyed-csv-merge.js'

const args = process.argv.slice(2)
const help = 'Usage: node cli.mjs KEY BASE.csv LEFT.csv RIGHT.csv\nWrites CSV to stdout on success. Diagnostics go to stderr.\n'
if (args.length === 1 && args[0] === '--help') {
  process.stdout.write(help)
} else if (args.length !== 4 || !args[0]) {
  process.stderr.write(help)
  process.exitCode = 2
} else {
  try {
    const documents = await Promise.all(args.slice(1).map(async file => {
      const bytes = await readFile(file)
      return new TextDecoder('utf-8', { fatal: true }).decode(bytes)
    }))
    const result = JSON.parse(merge_csv(...documents, args[0]))
    if (result.status === 'merged') {
      process.stdout.write(result.csv)
    } else {
      process.stderr.write(JSON.stringify(result, null, 2) + '\n')
      process.exitCode = result.status === 'conflict' ? 1 : 2
    }
  } catch (error) {
    process.stderr.write(error.message + '\n')
    process.exitCode = 2
  }
}
