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
const RUNTIMES = new Set(['windows', 'python']);

export async function buildPages({
  root,
  output = resolve(root, '_site'),
  repository = DEFAULT_REPOSITORY,
  pagesUrl = DEFAULT_PAGES_URL,
  commit = resolveCommit(root),
  generatedAt = resolveCommitDate(root, commit),
} = {}) {
  if (!root) throw new Error('root is required');
  const source = JSON.parse(await readFile(resolve(root, 'data/plugins.json'), 'utf8'));
  validateSource(source);

  const normalizedRepository = normalizeHttpsUrl(repository, 'repository').replace(/\/$/, '');
  const normalizedPagesUrl = normalizeHttpsUrl(pagesUrl, 'pagesUrl').replace(/\/$/, '');
  const seenIds = new Set();
  const seenFiles = new Set();
  const plugins = [];

  await rm(output, { recursive: true, force: true });
  await Promise.all([
    mkdir(resolve(output, 'api/v1'), { recursive: true }),
    mkdir(resolve(output, 'files'), { recursive: true }),
  ]);

  for (const [index, entry] of source.plugins.entries()) {
    const label = `plugins[${index}]`;
    validateEntry(entry, label);
    if (seenIds.has(entry.id)) throw new Error(`${label} duplicates id ${entry.id}`);
    if (seenFiles.has(entry.file.toLowerCase())) throw new Error(`${label} duplicates file ${entry.file}`);
    seenIds.add(entry.id);
    seenFiles.add(entry.file.toLowerCase());

    const sourceFile = resolveInsideRoot(root, entry.file, label);
    const stats = await lstat(sourceFile);
    if (!stats.isFile() || stats.isSymbolicLink()) throw new Error(`${label}.file must reference a regular file`);
    if (stats.size === 0 || stats.size > MAX_PLUGIN_BYTES) {
      throw new Error(`${label}.file must be between 1 byte and ${MAX_PLUGIN_BYTES} bytes`);
    }

    const contents = await readFile(sourceFile);
    const sha256 = createHash('sha256').update(contents).digest('hex');
    const filename = basename(entry.file);
    await copyFile(sourceFile, resolve(output, 'files', filename));
    const version = sha256.slice(0, 12);

    plugins.push({
      id: entry.id,
      name: entry.name,
      description: entry.description,
      category: entry.category,
      runtime: entry.runtime,
      requiresNetwork: entry.requiresNetwork,
      configurable: entry.configurable,
      ...(entry.note ? { note: entry.note } : {}),
      previewUrl: normalizeHttpsUrl(entry.previewUrl, `${label}.previewUrl`),
      filename,
      size: contents.byteLength,
      sha256,
      downloadUrl: `${normalizedPagesUrl}/files/${encodeURIComponent(filename)}?v=${version}`,
      sourceUrl: `${normalizedRepository}/blob/${encodeURIComponent(commit)}/${encodePath(entry.file)}`,
    });
  }

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
      guideUrl: normalizeHttpsUrl(source.guideUrl, 'guideUrl'),
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
  validateLocalizedText(entry.name, `${label}.name`);
  validateLocalizedText(entry.description, `${label}.description`);
  if (entry.note !== undefined) validateLocalizedText(entry.note, `${label}.note`);
  if (typeof entry.category !== 'string' || !/^[a-z][a-z0-9-]*$/.test(entry.category)) {
    throw new Error(`${label}.category is invalid`);
  }
  if (!RUNTIMES.has(entry.runtime)) throw new Error(`${label}.runtime is invalid`);
  for (const field of ['requiresNetwork', 'configurable']) {
    if (typeof entry[field] !== 'boolean') throw new Error(`${label}.${field} must be boolean`);
  }
}

function validateLocalizedText(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error(`${label} must be an object`);
  for (const locale of ['en', 'zh']) {
    if (typeof value[locale] !== 'string' || !value[locale].trim()) {
      throw new Error(`${label}.${locale} must be a non-empty string`);
    }
  }
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

function encodePath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
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
