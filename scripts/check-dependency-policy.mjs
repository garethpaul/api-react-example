import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(
  process.argv[2] ?? path.join(import.meta.dirname, '..'),
);
const packageJson = JSON.parse(
  fs.readFileSync(path.join(root, 'package.json'), 'utf8'),
);
const lockfile = fs.readFileSync(path.join(root, 'yarn.lock'), 'utf8');
const jsdomSpecifier = packageJson.devDependencies?.jsdom;

if (typeof jsdomSpecifier !== 'string' || jsdomSpecifier.length === 0) {
  throw new Error(
    'package.json must declare jsdom as a development dependency',
  );
}

const stanzaFor = (selector) => {
  for (const stanza of lockfile.trimEnd().split(/\n{2,}/)) {
    const [header, ...body] = stanza.split('\n');
    if (!header.endsWith(':')) continue;

    const selectors = header
      .slice(0, -1)
      .match(/"(?:\\.|[^"\\])*"|[^,]+/g)
      ?.map((entry) => entry.trim())
      .map((entry) => (entry.startsWith('"') ? JSON.parse(entry) : entry));

    if (selectors?.includes(selector)) return `${body.join('\n')}\n`;
  }

  return undefined;
};

const jsdomStanza = stanzaFor(`jsdom@${jsdomSpecifier}`);
if (!jsdomStanza) {
  throw new Error(`yarn.lock must resolve jsdom@${jsdomSpecifier}`);
}

const undiciRange = jsdomStanza.match(/^    undici "([^"]+)"$/m)?.[1];
if (!undiciRange) {
  throw new Error(
    'the locked jsdom package must declare its undici dependency',
  );
}

const undiciStanza = stanzaFor(`undici@${undiciRange}`);
const lockedVersion = undiciStanza?.match(/^  version "([^"]+)"$/m)?.[1];
const versionMatch = lockedVersion?.match(/^(\d+)\.(\d+)\.(\d+)$/);

if (!versionMatch) {
  throw new Error(
    "yarn.lock must contain a stable semantic version for jsdom's undici dependency",
  );
}

const [, major, minor] = versionMatch.map(Number);
if (major !== 7 || minor < 28) {
  throw new Error(
    `jsdom resolves vulnerable undici ${lockedVersion}; require 7.28.0 or newer within major 7`,
  );
}

console.log(`dependency policy passed: jsdom resolves undici ${lockedVersion}`);
