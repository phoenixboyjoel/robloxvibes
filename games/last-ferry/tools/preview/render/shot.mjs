// Screenshots one exported scene.
//
//   node shot.mjs <scene.json> <out.png> [--no-topbar]
//
// Serves this folder (and the scene) over a local HTTP server, renders it in headless
// Chromium with software WebGL (no GPU needed), and saves the screen as a PNG.

import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const here = fileURLToPath(new URL('.', import.meta.url));
const [scenePath, outPath] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const topbar = !process.argv.includes('--no-topbar');
if (!scenePath || !outPath) {
  console.error('usage: node shot.mjs <scene.json> <out.png> [--no-topbar]');
  process.exit(2);
}

const TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.css': 'text/css',
};

const server = createServer(async (request, response) => {
  const url = new URL(request.url, 'http://localhost');
  const file = url.pathname === '/scene.json' ? resolve(scenePath) : join(here, decodeURIComponent(url.pathname));
  if (!file.startsWith(here) && file !== resolve(scenePath)) {
    response.writeHead(403).end();
    return;
  }
  try {
    const body = await readFile(file);
    response.writeHead(200, { 'content-type': TYPES[extname(file)] ?? 'application/octet-stream' });
    response.end(request.method === 'HEAD' ? undefined : body);
  } catch {
    response.writeHead(404).end();
  }
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const port = server.address().port;

const scene = JSON.parse(await readFile(scenePath, 'utf8'));
const [width, height] = scene.screen;
const browser = await chromium.launch({
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
});
try {
  const page = await browser.newPage({ viewport: { width, height } });
  page.on('pageerror', (error) => console.error('page error:', error.message));
  page.on('console', (message) => {
    if (message.type() === 'error' || message.type() === 'warning')
      console.error(`console ${message.type()}:`, message.text());
  });
  await page.goto(`http://127.0.0.1:${port}/index.html?scene=/scene.json&topbar=${topbar ? 1 : 0}`);
  await page.waitForFunction(() => window.__previewDone || window.__previewError, null, { timeout: 180000 });
  const error = await page.evaluate(() => window.__previewError);
  if (error) throw new Error(error);
  await page.screenshot({ path: outPath });
  console.log(`wrote ${outPath} (${width}x${height})`);
} finally {
  await browser.close();
  server.close();
}
