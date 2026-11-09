#!/usr/bin/env node
// Beispiel-Gegenstelle für die Geräte-API von feusport.de: simuliert eine Stoppuhr im Terminal.

import { chmodSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { createInterface } from 'node:readline/promises';

const SERVERS = [
  { label: 'Lokale Entwicklung', url: 'http://localhost:3000' },
  { label: 'Produktion', url: 'https://feusport.de' },
];
const TOKEN_FILE = new URL('.tokens.json', import.meta.url);
const TARGET_KEYS = '123456789abcdefghijkmortuvwxy';

// ---------------------------------------------------------------------------
// API: Das ist der Teil, den auch ein Mikrocontroller umsetzen müsste.
// ---------------------------------------------------------------------------

class ApiError extends Error {
  constructor(status, body) {
    super(`HTTP ${status}: ${JSON.stringify(body)}`);
    this.status = status;
    this.body = body;
  }
}

class Api {
  constructor(baseUrl, token = null) {
    this.baseUrl = baseUrl;
    this.token = token;
  }

  async request(method, path, body) {
    const headers = { Accept: 'application/json' };
    if (this.token) headers.Authorization = `Bearer ${this.token}`;
    if (body) headers['Content-Type'] = 'application/json';

    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await response.json();
    if (!response.ok) throw new ApiError(response.status, data);
    return data;
  }

  // Tauscht den Code von der Zugänge-Seite gegen einen Token
  async pair(code, deviceName) {
    const pairing = await this.request('POST', '/api/v1/pairings', { code, device_name: deviceName });
    this.token = pairing.token;
    return pairing;
  }

  async lists() {
    return (await this.request('GET', '/api/v1/lists')).lists;
  }

  list(id, run) {
    return this.request('GET', `/api/v1/lists/${id}${run ? `?run=${run}` : ''}`);
  }

  // version muss vom zuletzt gelesenen Eintrag stammen, sonst antwortet der Server mit 409
  updateEntry(id, version, result) {
    return this.request('PATCH', `/api/v1/list_entries/${id}`, { version, ...result });
  }
}

// ---------------------------------------------------------------------------
// Terminal
// ---------------------------------------------------------------------------

async function ask(question) {
  const readline = createInterface({ input: process.stdin, output: process.stdout });
  const answer = await readline.question(question);
  readline.close();
  return answer.trim();
}

function quit(code = 0) {
  if (process.stdin.isTTY) process.stdin.setRawMode(false);
  process.exit(code);
}

// Ruft onKey für jede Taste auf, bis onKey true zurückgibt
function readKeys(onKey) {
  return new Promise((resolve) => {
    const listener = (chunk) => {
      for (const key of chunk.toString()) {
        if (key === '\u0003') quit();
        if (onKey(key)) {
          process.stdin.off('data', listener);
          process.stdin.setRawMode(false);
          process.stdin.pause();
          resolve();
          return;
        }
      }
    };
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.on('data', listener);
  });
}

async function readKey(allowed) {
  let result;
  await readKeys((key) => {
    if (!allowed.includes(key)) return false;
    result = key;
    return true;
  });
  return result;
}

async function choose(title, items, labelOf) {
  console.log(`\n${title}`);
  items.forEach((item, index) => console.log(`  ${index + 1}) ${labelOf(item)}`));
  for (;;) {
    const item = items[Number(await ask('Auswahl: ')) - 1];
    if (item) return item;
  }
}

const seconds = (hundredths) => (hundredths / 100).toFixed(2).replace('.', ',');

function describeEntry(entry, list) {
  const times = list.separate_target_times
    ? `L ${entry.time_left_target ? seconds(entry.time_left_target) : '-'} / ` +
      `R ${entry.time_right_target ? seconds(entry.time_right_target) : '-'}`
    : '';
  const states = { waiting: 'wartet', invalid: 'ungültig', no_run: 'nicht angetreten' };
  const state = entry.result_type === 'valid' ? seconds(entry.time) : states[entry.result_type];
  return `Bahn ${entry.track}: ${entry.name} (${entry.band}) - ${state} ${times}`.trimEnd();
}

// ---------------------------------------------------------------------------
// Stoppuhr
// ---------------------------------------------------------------------------

// Ein Ziel pro Bahn, bei getrennten Zielen zwei
function targetsFor(entries, list) {
  const sides = list.separate_target_times
    ? [
        { field: 'time_left_target', label: 'links' },
        { field: 'time_right_target', label: 'rechts' },
      ]
    : [{ field: 'time', label: '' }];
  return entries
    .flatMap((entry) => sides.map((side) => ({ entry, ...side })))
    .map((target, index) => ({ ...target, key: TARGET_KEYS[index] }));
}

// Liefert eine Map von Ziel auf Zeit in Hundertsteln, nicht gestoppte Ziele fehlen
async function measure(targets) {
  console.log('\nLäuft! Stoppen mit:');
  targets.forEach(({ key, entry, label }) => console.log(`  ${key}: Bahn ${entry.track} ${label}`));
  console.log('  Enter: Messung beenden\n');

  const startedAt = performance.now();
  const elapsed = () => Math.max(1, Math.floor((performance.now() - startedAt) / 10));
  const stopped = new Map();

  const clock = setInterval(() => process.stdout.write(`\r  ${seconds(elapsed())} s   `), 47);
  await readKeys((key) => {
    if (key === '\r' || key === '\n') return true;
    const target = targets.find((candidate) => candidate.key === key);
    if (target && !stopped.has(target)) {
      stopped.set(target, elapsed());
      process.stdout.write(`\r  Bahn ${target.entry.track} ${target.label}: ${seconds(stopped.get(target))} s\n`);
    }
    return stopped.size === targets.length;
  });
  clearInterval(clock);
  process.stdout.write('\n');
  return stopped;
}

function randomTimes(targets) {
  const stopped = new Map();
  for (const target of targets) {
    if (Math.random() > 0.1) stopped.set(target, 2000 + Math.floor(Math.random() * 1500));
  }
  return stopped;
}

// Baut pro Eintrag die Felder für das PATCH. Nicht gestoppte Ziele machen die Bahn ungültig.
function resultFor(entry, targets, stopped) {
  const own = targets.filter((target) => target.entry === entry);
  const result = { result_type: own.every((target) => stopped.has(target)) ? 'valid' : 'invalid' };
  for (const target of own) result[target.field] = stopped.get(target) ?? null;
  return result;
}

const isSameResult = (result, entry) => Object.keys(result).every((field) => result[field] === entry[field]);

async function saveEntry(api, entry, list, result) {
  try {
    const saved = await api.updateEntry(entry.id, entry.version, result);
    console.log(`  Gespeichert: ${describeEntry(saved, list)}`);
  } catch (error) {
    if (!(error instanceof ApiError) || error.status !== 409) throw error;
    await resolveConflict(api, error.body.entry, list, result);
  }
}

// 409: Jemand hat den Eintrag geändert, oder die eigene Antwort ging nach dem Speichern verloren
async function resolveConflict(api, current, list, result) {
  if (isSameResult(result, current)) {
    console.log(`  Bereits gespeichert: ${describeEntry(current, list)}`);
    return;
  }

  console.log(`  Konflikt, der Eintrag wurde geändert: ${describeEntry(current, list)}`);
  console.log('  Überschreiben? (j/n)');
  if ((await readKey('jn')) === 'j') await saveEntry(api, current, list, result);
}

async function saveRun(api, entries, list, targets, stopped) {
  for (const entry of entries) {
    try {
      await saveEntry(api, entry, list, resultFor(entry, targets, stopped));
    } catch (error) {
      console.log(`  Fehler bei Bahn ${entry.track}: ${error.message}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Programmablauf
// ---------------------------------------------------------------------------

function loadTokens() {
  return existsSync(TOKEN_FILE) ? JSON.parse(readFileSync(TOKEN_FILE, 'utf8')) : {};
}

function storeToken(baseUrl, token) {
  writeFileSync(TOKEN_FILE, JSON.stringify({ ...loadTokens(), [baseUrl]: token }, null, 2));
  chmodSync(TOKEN_FILE, 0o600);
}

async function chooseServer() {
  if (process.argv[2]) return process.argv[2].replace(/\/$/, '');
  const server = await choose('Mit welchem Server verbinden?', SERVERS, (item) => `${item.label} (${item.url})`);
  return server.url;
}

async function pairDevice(api) {
  console.log('\nLege auf der Zugänge-Seite des Wettkampfs einen Gerätezugang an.');
  for (;;) {
    const code = await ask('Code (8 Ziffern): ');
    try {
      const { competition } = await api.pair(code, 'Beispiel-Stoppuhr');
      storeToken(api.baseUrl, api.token);
      console.log(`Verbunden mit: ${competition.name}`);
      return;
    } catch (error) {
      if (!(error instanceof ApiError)) throw error;
      console.log(error.status === 429 ? 'Zu viele Versuche, bitte eine Minute warten.' : 'Code ungültig.');
    }
  }
}

// Nutzt einen gespeicherten Token weiter, solange der Server ihn akzeptiert
async function connect(baseUrl) {
  const api = new Api(baseUrl, loadTokens()[baseUrl]);
  if (api.token) {
    try {
      await api.lists();
      console.log('Gespeicherter Token ist noch gültig.');
      return api;
    } catch (error) {
      if (!(error instanceof ApiError) || error.status !== 401) throw error;
      api.token = null;
    }
  }
  await pairDevice(api);
  return api;
}

// Gibt false zurück, wenn das Programm enden soll
async function runList(api, listId) {
  const { entries: allEntries, ...list } = await api.list(listId);
  if (allEntries.length === 0) {
    console.log('Diese Startliste hat keine Einträge.');
    return true;
  }

  const runs = [...new Set(allEntries.map((entry) => entry.run))];
  const firstWaiting = allEntries.find((entry) => entry.result_type === 'waiting');
  let index = firstWaiting ? runs.indexOf(firstWaiting.run) : 0;

  for (;;) {
    const { entries } = await api.list(listId, runs[index]);
    const targets = targetsFor(entries, list);

    console.log(`\n${list.name}, Lauf ${runs[index]} von ${runs.at(-1)}`);
    entries.forEach((entry) => console.log(`  ${describeEntry(entry, list)}`));
    console.log('[s] Start  [z] Zufallszeiten  [n] nächster  [p] vorheriger  [l] andere Liste  [q] Ende');

    const key = await readKey('sznplq');
    if (key === 'q') return false;
    if (key === 'l') return true;
    if (key === 'n' || key === 'p') {
      index = Math.min(Math.max(index + (key === 'n' ? 1 : -1), 0), runs.length - 1);
    } else {
      const stopped = key === 's' ? await measure(targets) : randomTimes(targets);
      await saveRun(api, entries, list, targets, stopped);
      index = Math.min(index + 1, runs.length - 1);
    }
  }
}

async function main() {
  if (!process.stdin.isTTY) throw new Error('Das Programm braucht ein interaktives Terminal.');

  const api = await connect(await chooseServer());
  for (;;) {
    const lists = await api.lists();
    if (lists.length === 0) throw new Error('Für dieses Gerät sind keine Startlisten freigegeben.');

    const list = await choose('Startliste wählen:', lists, (item) => item.name);
    if (!(await runList(api, list.id))) quit();
  }
}

main().catch((error) => {
  console.error(`\nAbbruch: ${error.message}${error.cause ? ` (${error.cause.message})` : ''}`);
  quit(1);
});
