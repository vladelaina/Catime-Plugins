import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import sharp from 'sharp';
import { buildPages } from '../scripts/build-pages.mjs';

const fixture = {
  schemaVersion: 1,
  plugins: [{
    id: 'hello_world',
    file: 'plugins/hello_world.bat',
    previewUrl: 'https://github.com/user-attachments/assets/01234567-89ab-cdef-0123-456789abcdef',
  }],
};
const previewBytes = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAADUlEQVQImWOoaOr5DwAFggKGjKIzhwAAAABJRU5ErkJggg==',
  'base64',
);
const animatedPreviewBytes = Buffer.from(
  'R0lGODlhAgACAPcfMQAAACQAAEgAAGwAAJAAALQAANgAAPwAAAAkACQkAEgkAGwkAJAkALQkANgkAPwkAABIACRIAEhIAGxIAJBIALRIANhIAPxIAABsACRsAEhsAGxsAJBsALRsANhsAPxsAACQACSQAEiQAGyQAJCQALSQANiQAPyQAAC0ACS0AEi0AGy0AJC0ALS0ANi0APy0AADYACTYAEjYAGzYAJDYALTYANjYAPzYAAD8ACT8AEj8AGz8AJD8ALT8ANj8APz8AAAAVSQAVUgAVWwAVZAAVbQAVdgAVfwAVQAkVSQkVUgkVWwkVZAkVbQkVdgkVfwkVQBIVSRIVUhIVWxIVZBIVbRIVdhIVfxIVQBsVSRsVUhsVWxsVZBsVbRsVdhsVfxsVQCQVSSQVUiQVWyQVZCQVbSQVdiQVfyQVQC0VSS0VUi0VWy0VZC0VbS0Vdi0Vfy0VQDYVSTYVUjYVWzYVZDYVbTYVdjYVfzYVQD8VST8VUj8VWz8VZD8VbT8Vdj8Vfz8VQAAqiQAqkgAqmwAqpAAqrQAqtgAqvwAqgAkqiQkqkgkqmwkqpAkqrQkqtgkqvwkqgBIqiRIqkhIqmxIqpBIqrRIqthIqvxIqgBsqiRsqkhsqmxsqpBsqrRsqthsqvxsqgCQqiSQqkiQqmyQqpCQqrSQqtiQqvyQqgC0qiS0qki0qmy0qpC0qrS0qti0qvy0qgDYqiTYqkjYqmzYqpDYqrTYqtjYqvzYqgD8qiT8qkj8qmz8qpD8qrT8qtj8qvz8qgAA/yQA/0gA/2wA/5AA/7QA/9gA//wA/wAk/yQk/0gk/2wk/5Ak/7Qk/9gk//wk/wBI/yRI/0hI/2xI/5BI/7RI/9hI//xI/wBs/yRs/0hs/2xs/5Bs/7Rs/9hs//xs/wCQ/ySQ/0iQ/2yQ/5CQ/7SQ/9iQ//yQ/wC0/yS0/0i0/2y0/5C0/7S0/9i0//y0/wDY/yTY/0jY/2zY/5DY/7TY/9jY//zY/wD8/yT8/0j8/2z8/5D8/7T8/9j8//z8/yH/C05FVFNDQVBFMi4wAwEAAAAh+QQEMgAfACwAAAAAAgACAAAIBgAPCDwQEAAh+QQFMgAAACwAAAAAAgACAAAIBgABARsYEAA7',
  'base64',
);
const animatedPreviewFixture = Buffer.concat([animatedPreviewBytes, Buffer.alloc(200)]);

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
    fetchImpl: fetchPreview,
  });

  assert.equal(catalog.count, 1);
  assert.equal(catalog.plugins[0].size, sourceBytes.length);
  assert.equal(catalog.plugins[0].sha256, 'c134b2f85415ba5cfce3e3fe4745688335745a9bb22152ac8f5c77f190d8aee3');
  assert.equal(
    catalog.plugins[0].downloadUrl,
    'https://example.github.io/plugins/files/hello_world.bat?v=c134b2f85415',
  );
  assert.match(
    catalog.plugins[0].posterUrl,
    /^https:\/\/example\.github\.io\/plugins\/posters\/hello_world\.webp\?v=[a-f0-9]{12}$/,
  );
  assert.equal(catalog.plugins[0].previewUrl, catalog.plugins[0].posterUrl);
  assert.deepEqual(await readFile(join(root, '_site/files/hello_world.bat')), sourceBytes);
  assert.equal((await readFile(join(root, '_site/posters/hello_world.webp'))).subarray(8, 12).toString(), 'WEBP');
  assert.deepEqual(JSON.parse(await readFile(join(root, '_site/api/v1/catalog.json'), 'utf8')), catalog);
});

test('converts animated GIF previews to smaller animated WebP files', async t => {
  const root = await createFixture();
  t.after(() => rm(root, { recursive: true, force: true }));
  await writeFile(join(root, 'plugins/hello_world.bat'), '@echo off\r\n');

  const catalog = await buildPages({
    root,
    repository: 'https://github.com/example/plugins',
    pagesUrl: 'https://example.github.io/plugins',
    commit: '0123456789abcdef0123456789abcdef01234567',
    generatedAt: '2026-08-15T00:00:00.000Z',
    fetchImpl: () => previewResponse(animatedPreviewFixture, 'image/gif', 'preview.gif'),
  });

  assert.match(
    catalog.plugins[0].previewUrl,
    /^https:\/\/example\.github\.io\/plugins\/previews\/hello_world\.webp\?v=[a-f0-9]{12}$/,
  );
  assert.notEqual(catalog.plugins[0].previewUrl, catalog.plugins[0].posterUrl);

  const preview = await readFile(join(root, '_site/previews/hello_world.webp'));
  const metadata = await sharp(preview, { animated: true }).metadata();
  assert.equal(preview.subarray(0, 4).toString(), 'RIFF');
  assert.equal(preview.subarray(8, 12).toString(), 'WEBP');
  assert.equal(metadata.pages, 2);
  assert.ok(preview.length < animatedPreviewFixture.length);
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

  await assert.rejects(() => buildPages({ root, commit: 'local', fetchImpl: fetchPreview }), /not registered/);
});

async function fetchPreview() {
  return previewResponse(previewBytes, 'image/png', 'preview.png');
}

function previewResponse(contents, contentType, filename) {
  return {
    ok: true,
    status: 200,
    url: `https://github-production-user-asset-6210df.s3.amazonaws.com/${filename}`,
    headers: new Headers({
      'content-length': String(contents.length),
      'content-type': contentType,
    }),
    arrayBuffer: async () => Uint8Array.from(contents).buffer,
  };
}

async function createFixture() {
  const root = await mkdtemp(join(tmpdir(), 'catime-plugin-pages-'));
  await Promise.all([
    mkdir(join(root, 'data'), { recursive: true }),
    mkdir(join(root, 'plugins'), { recursive: true }),
  ]);
  await writeFile(join(root, 'data/plugins.json'), JSON.stringify(fixture));
  return root;
}
