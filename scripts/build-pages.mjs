import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import {
  copyFile,
  lstat,
  mkdir,
  readFile,
  readdir,
  rm,
  writeFile,
} from 'node:fs/promises';
import { basename, extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const DEFAULT_REPOSITORY = 'https://github.com/vladelaina/Catime-Plugins';
const DEFAULT_PAGES_URL = 'https://vladelaina.github.io/Catime-Plugins';
const ALLOWED_EXTENSIONS = new Set(['.bat', '.py']);
const MAX_PLUGIN_BYTES = 1024 * 1024;
const MAX_PREVIEW_BYTES = 8 * 1024 * 1024;
const PREVIEW_CONCURRENCY = 6;
const ENTRY_FIELDS = new Set(['id', 'file', 'previewUrl']);
const PREVIEW_TYPES = new Map([
  ['image/gif', 'gif'],
  ['image/jpeg', 'jpg'],
  ['image/png', 'png'],
  ['image/webp', 'webp'],
]);

export async function buildPages({
  root,
  output = resolve(root, '_site'),
  repository = DEFAULT_REPOSITORY,
  pagesUrl = DEFAULT_PAGES_URL,
  commit = resolveCommit(root),
  generatedAt = resolveCommitDate(root, commit),
  fetchImpl = fetch,
} = {}) {
  if (!root) throw new Error('root is required');
  const source = JSON.parse(await readFile(resolve(root, 'data/plugins.json'), 'utf8'));
  validateSource(source);

  const normalizedRepository = normalizeHttpsUrl(repository, 'repository').replace(/\/$/, '');
  const normalizedPagesUrl = normalizeHttpsUrl(pagesUrl, 'pagesUrl').replace(/\/$/, '');
  const seenIds = new Set();
  const seenFiles = new Set();

  await rm(output, { recursive: true, force: true });
  await Promise.all([
    mkdir(resolve(output, 'api/v1'), { recursive: true }),
    mkdir(resolve(output, 'files'), { recursive: true }),
    mkdir(resolve(output, 'previews'), { recursive: true }),
  ]);

  const entries = source.plugins.map((entry, index) => {
    const label = `plugins[${index}]`;
    validateEntry(entry, label);
    if (seenIds.has(entry.id)) throw new Error(`${label} duplicates id ${entry.id}`);
    if (seenFiles.has(entry.file.toLowerCase())) throw new Error(`${label} duplicates file ${entry.file}`);
    seenIds.add(entry.id);
    seenFiles.add(entry.file.toLowerCase());
    return { entry, label };
  });

  const plugins = await mapWithConcurrency(entries, PREVIEW_CONCURRENCY, async ({ entry, label }) => {
    const sourceFile = resolveInsideRoot(root, entry.file, label);
    const stats = await lstat(sourceFile);
    if (!stats.isFile() || stats.isSymbolicLink()) throw new Error(`${label}.file must reference a regular file`);
    if (stats.size === 0 || stats.size > MAX_PLUGIN_BYTES) {
      throw new Error(`${label}.file must be between 1 byte and ${MAX_PLUGIN_BYTES} bytes`);
    }

    const contents = await readFile(sourceFile);
    const sha256 = createHash('sha256').update(contents).digest('hex');
    const filename = basename(entry.file);
    const previewUrl = await publishPreview({
      sourceUrl: entry.previewUrl,
      id: entry.id,
      label: `${label}.previewUrl`,
      output,
      pagesUrl: normalizedPagesUrl,
      fetchImpl,
    });
    await copyFile(sourceFile, resolve(output, 'files', filename));
    const version = sha256.slice(0, 12);

    return {
      id: entry.id,
      previewUrl,
      filename,
      size: contents.byteLength,
      sha256,
      downloadUrl: `${normalizedPagesUrl}/files/${encodeURIComponent(filename)}?v=${version}`,
    };
  });

  const pluginDirectoryEntries = await readdir(resolve(root, 'plugins'), { withFileTypes: true });
  for (const entry of pluginDirectoryEntries) {
    if (!entry.isFile() || entry.isSymbolicLink()) {
      throw new Error(`plugins/${entry.name} must be a regular file`);
    }
    if (!ALLOWED_EXTENSIONS.has(extname(entry.name).toLowerCase())) {
      throw new Error(`plugins/${entry.name} uses an unsupported extension`);
    }
    if (!seenFiles.has(`plugins/${entry.name}`.toLowerCase())) {
      throw new Error(`plugins/${entry.name} is not registered in data/plugins.json`);
    }
  }

  const catalog = {
    schemaVersion: source.schemaVersion,
    generatedAt,
    source: {
      repository: normalizedRepository,
      commit,
    },
    count: plugins.length,
    plugins,
  };

  await Promise.all([
    writeFile(resolve(output, 'api/v1/catalog.json'), `${JSON.stringify(catalog, null, 2)}\n`),
    writeFile(resolve(output, '.nojekyll'), ''),
    writeFile(resolve(output, 'index.html'), apiIndexHtml(catalog)),
  ]);

  return catalog;
}

function validateSource(source) {
  if (!source || typeof source !== 'object' || Array.isArray(source)) {
    throw new Error('data/plugins.json must contain an object');
  }
  if (source.schemaVersion !== 1) throw new Error('schemaVersion must be 1');
  if (!Array.isArray(source.plugins) || source.plugins.length === 0) {
    throw new Error('plugins must contain at least one entry');
  }
}

function validateEntry(entry, label) {
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) throw new Error(`${label} must be an object`);
  if (!/^[a-z0-9]+(?:_[a-z0-9]+)*$/.test(entry.id || '')) throw new Error(`${label}.id is invalid`);
  if (typeof entry.file !== 'string' || !/^plugins\/[A-Za-z0-9][A-Za-z0-9._-]*$/.test(entry.file)) {
    throw new Error(`${label}.file must be a direct child of plugins/`);
  }
  if (!ALLOWED_EXTENSIONS.has(extname(entry.file).toLowerCase())) {
    throw new Error(`${label}.file uses an unsupported extension`);
  }
  normalizePreviewSource(entry.previewUrl, `${label}.previewUrl`);
  for (const field of Object.keys(entry)) {
    if (!ENTRY_FIELDS.has(field)) throw new Error(`${label}.${field} is not supported`);
  }
}

async function publishPreview({ sourceUrl, id, label, output, pagesUrl, fetchImpl }) {
  const normalizedSource = normalizePreviewSource(sourceUrl, label);
  let response;
  try {
    response = await fetchImpl(normalizedSource, {
      redirect: 'follow',
      headers: { accept: 'image/gif,image/png,image/jpeg,image/webp' },
    });
  } catch (error) {
    throw new Error(`${label} could not be downloaded: ${error.message}`);
  }
  if (!response?.ok) throw new Error(`${label} returned HTTP ${response?.status ?? 'unknown'}`);
  validatePreviewResponseUrl(response.url, label);

  const contentType = String(response.headers?.get('content-type') || '').split(';', 1)[0].trim().toLowerCase();
  const extension = PREVIEW_TYPES.get(contentType);
  if (!extension) throw new Error(`${label} returned unsupported content type ${contentType || 'unknown'}`);

  const declaredSize = Number.parseInt(response.headers?.get('content-length') || '0', 10);
  if (declaredSize > MAX_PREVIEW_BYTES) throw new Error(`${label} exceeds ${MAX_PREVIEW_BYTES} bytes`);
  const contents = await readLimitedResponse(response, MAX_PREVIEW_BYTES, label);
  validateImageSignature(contents, contentType, label);

  const sha256 = createHash('sha256').update(contents).digest('hex');
  const filename = `${id}.${extension}`;
  await writeFile(resolve(output, 'previews', filename), contents);
  return `${pagesUrl}/previews/${encodeURIComponent(filename)}?v=${sha256.slice(0, 12)}`;
}

function normalizePreviewSource(value, label) {
  const normalized = normalizeHttpsUrl(value, label);
  const url = new URL(normalized);
  const attachmentPath = /^\/user-attachments\/assets\/[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i;
  if (url.hostname !== 'github.com' || !attachmentPath.test(url.pathname) || url.search || url.hash) {
    throw new Error(`${label} must be a GitHub user attachment URL`);
  }
  return normalized;
}

function validatePreviewResponseUrl(value, label) {
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${label} returned an invalid final URL`);
  }
  const githubAssetHost = /^github-production-user-asset-[a-z0-9-]+\.s3\.amazonaws\.com$/i;
  if (url.protocol !== 'https:' || !githubAssetHost.test(url.hostname)) {
    throw new Error(`${label} redirected to an unsupported host`);
  }
}

async function readLimitedResponse(response, limit, label) {
  if (!response.body?.getReader) {
    const contents = Buffer.from(await response.arrayBuffer());
    if (contents.length === 0 || contents.length > limit) throw new Error(`${label} has an invalid size`);
    return contents;
  }

  const reader = response.body.getReader();
  const chunks = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > limit) {
      await reader.cancel();
      throw new Error(`${label} exceeds ${limit} bytes`);
    }
    chunks.push(Buffer.from(value));
  }
  if (total === 0) throw new Error(`${label} is empty`);
  return Buffer.concat(chunks, total);
}

function validateImageSignature(contents, contentType, label) {
  const valid = {
    'image/gif': () => contents.subarray(0, 6).toString('ascii') === 'GIF87a'
      || contents.subarray(0, 6).toString('ascii') === 'GIF89a',
    'image/jpeg': () => contents[0] === 0xff && contents[1] === 0xd8 && contents[2] === 0xff,
    'image/png': () => contents.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
    'image/webp': () => contents.subarray(0, 4).toString('ascii') === 'RIFF'
      && contents.subarray(8, 12).toString('ascii') === 'WEBP',
  }[contentType]?.();
  if (!valid) throw new Error(`${label} content does not match ${contentType}`);
}

async function mapWithConcurrency(items, concurrency, mapper) {
  const results = new Array(items.length);
  let nextIndex = 0;
  const workers = Array.from({ length: Math.min(concurrency, items.length) }, async () => {
    while (nextIndex < items.length) {
      const index = nextIndex++;
      results[index] = await mapper(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

function resolveInsideRoot(root, relativePath, label) {
  const path = resolve(root, relativePath);
  const rootPrefix = `${resolve(root)}${sep}`;
  if (!path.startsWith(rootPrefix)) throw new Error(`${label}.file escapes the repository root`);
  return path;
}

function normalizeHttpsUrl(value, label) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) throw new Error();
    return url.toString();
  } catch {
    throw new Error(`${label} must be a public HTTPS URL`);
  }
}

function resolveCommit(root) {
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return 'local';
  }
}

function resolveCommitDate(root, commit) {
  try {
    return execFileSync('git', ['show', '-s', '--format=%cI', commit], {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return new Date(0).toISOString();
  }
}

function apiIndexHtml(catalog) {
  const commit = escapeHtml(catalog.source.commit.slice(0, 12));
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Catime Plugin Catalog</title>
</head>
<body>
  <main>
    <h1>Catime Plugin Catalog</h1>
    <p>${catalog.count} published plugins from commit <code>${commit}</code>.</p>
    <p><a href="./api/v1/catalog.json">Open catalog.json</a></p>
  </main>
</body>
</html>\n`;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[character]));
}

const scriptPath = process.argv[1] ? resolve(process.argv[1]) : '';
if (scriptPath === fileURLToPath(import.meta.url)) {
  const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
  const catalog = await buildPages({ root });
  console.log(`Published ${catalog.count} plugins from ${catalog.source.commit.slice(0, 12)}.`);
}
