import test from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

function run(entry, ...args) {
  return spawnSync(process.execPath, [fileURLToPath(new URL(entry, import.meta.url)), ...args], { encoding: 'utf8' })
}

test('CLI merges the published inventory example with CRLF record endings', async () => {
  const example = fileURLToPath(new URL('./examples/catalog/', import.meta.url))
  const res = run('./cli.mjs', 'sku', ...['base','count','move'].map(name => join(example,name+'.csv')))
  assert.equal(res.status, 0, res.stderr)
  assert.equal(res.stderr, '')
  const expected = await readFile(join(example, 'expected.csv'), 'utf8')
  assert.equal(res.stdout, expected.replace(/\r?\n/g, '\r\n'))
})

test('Git driver leaves the current file intact on conflict and replaces it on success', async t => {
  const dir = await mkdtemp(join(tmpdir(), 'keyed-merge-test-'))
  t.after(() => rm(dir, { recursive: true, force: true }))
  const files = ['base', 'ours', 'theirs'].map(n => join(dir, n))
  const prefix = 'id,x,y\na,'
  await Promise.all(files.map((p,i) => writeFile(p, prefix + ['0,0','1,0','2,0'][i])))
  const conflict = run('./git-driver.mjs', 'id', ...files)
  assert.equal(conflict.status, 1, conflict.stderr)
  assert.equal(JSON.parse(conflict.stderr).conflicts[0].column,'x')
  assert.equal(await readFile(files[1], 'utf8'),prefix+'1,0')
  await writeFile(files[2],prefix+'0,2')
  const ok = run('./git-driver.mjs', 'id', ...files)
  assert.equal(ok.status, 0, ok.stderr)
  assert.equal(await readFile(files[1], 'utf8'),'id,x,y\r\na,1,2\r\n')
})

test('bad UTF-8 is rejected without CSV output', async t => {
  const dir = await mkdtemp(join(tmpdir(),'keyed-merge-encoding-'))
  t.after(() => rm(dir, { recursive: true, force: true }))
  const f = join(dir,'input.csv')
  await writeFile(f,Buffer.from([0xff]))
  const res = run('./cli.mjs','id',f,f,f)
  assert.equal(res.status,2,res.stderr)
  assert.equal(res.stdout,'')
})
