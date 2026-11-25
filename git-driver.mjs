#!/usr/bin/env node
// Git passes the base, current (%A), and other snapshots as temporary paths.
import { spawnSync } from 'node:child_process'
import { randomUUID } from 'node:crypto'
import { stat, open, rename, unlink } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'

const args = process.argv.slice(2)
if (args.length !== 4) {
  console.error('Usage: node git-driver.mjs KEY %O %A %B')
  process.exitCode = 2
} else {
  const localPath = args[2]
  const result = spawnSync(process.execPath, [fileURLToPath(new URL('./cli.mjs', import.meta.url)), ...args], { maxBuffer: 64 * 1024 * 1024 })
  if (result.error || result.status !== 0) {
    process.stderr.write(result.error ? result.error.message + '\n' : result.stderr)
    process.exitCode = result.status || 2
  } else {
    // Only replace %A after the entire clean merge has been written.
    const temp = localPath + '.' + randomUUID() + '.tmp'
    let owned = false
    try {
      const mode = (await stat(localPath)).mode
      const handle = await open(temp, 'wx', mode)
      owned = true
      try { await handle.writeFile(result.stdout) } finally { await handle.close() }
      await rename(temp, localPath)
      owned = false
    } catch (error) {
      console.error(error.message)
      process.exitCode = 2
    } finally {
      if (owned) await unlink(temp)
    }
  }
}
