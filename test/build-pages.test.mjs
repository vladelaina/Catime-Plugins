import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { buildPages } from '../scripts/build-pages.mjs';

const fixture = {
  schemaVersion: 1,
  guideUrl: 'https://github.com/example/plugins/blob/main/GUIDE.md',
  plugins: [{
    id: 'hello_world',
    file: 'plugins/hello_world.bat',
    name: { en: 'Hello', zh: '你好' },
    description: { en: 'A test plugin.', zh: '测试插件。' },
    category: 'test',
    runtime: 'windows',
    requiresNetwork: false,
    configurable: false,
    previewUrl: 'https://example.com/preview.webp',
  }],
};

test('builds a versioned catalog and preserves plugin bytes', async t => {
  const root = await createFixture();
  t.after(() => rm(root, { recursive: true, force: true }));
  const sourceBytes = Buffer.from([0x40, 0x65, 0x63, 0x68, 0x6f, 0x20, 0x6f, 0x66, 0x66, 0x0d, 0x0a]);
  await writeFile(join(root, 'plugins/hello_world.bat'), sourceBytes);

  const catalog = await buildPages({
    root,
    repository: 'https://github.com/example/plugins',
    pagesUrl: 'https://example.github.io/plugins',
    commit: '0123456789abcdef0123456789abcdef01234567',
    generatedAt: '2026-08-15T00:00:00.000Z',
  });

  assert.equal(catalog.count, 1);
  assert.equal(catalog.plugins[0].size, sourceBytes.length);
  assert.equal(catalog.plugins[0].sha256, 'c134b2f85415ba5cfce3e3fe4745688335745a9bb22152ac8f5c77f190d8aee3');
  assert.equal(
    catalog.plugins[0].downloadUrl,
    'https://example.github.io/plugins/files/hello_world.bat?v=c134b2f85415',
  );
  assert.deepEqual(await readFile(join(root, '_site/files/hello_world.bat')), sourceBytes);
  assert.deepEqual(JSON.parse(await readFile(join(root, '_site/api/v1/catalog.json'), 'utf8')), catalog);
});

test('rejects traversal and unsupported plugin files', async t => {
  const root = await createFixture();
  t.after(() => rm(root, { recursive: true, force: true }));
  const invalid = structuredClone(fixture);
  invalid.plugins[0].file = 'plugins/nested/hello.exe';
  await writeFile(join(root, 'data/plugins.json'), JSON.stringify(invalid));

  await assert.rejects(() => buildPages({ root, commit: 'local' }), /direct child/);
});

test('rejects plugin scripts missing from the catalog', async t => {
  const root = await createFixture();
  t.after(() => rm(root, { recursive: true, force: true }));
  await Promise.all([
    writeFile(join(root, 'plugins/hello_world.bat'), '@echo off\r\n'),
    writeFile(join(root, 'plugins/unregistered.py'), 'print("hello")\n'),
  ]);

  await assert.rejects(() => buildPages({ root, commit: 'local' }), /not registered/);
});

async function createFixture() {
  const root = await mkdtemp(join(tmpdir(), 'catime-plugin-pages-'));
  await Promise.all([
    mkdir(join(root, 'data'), { recursive: true }),
    mkdir(join(root, 'plugins'), { recursive: true }),
  ]);
  await writeFile(join(root, 'data/plugins.json'), JSON.stringify(fixture));
  return root;
}
