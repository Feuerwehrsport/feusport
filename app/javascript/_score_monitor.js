import { createConsumer } from '@rails/actioncable';

// Live-Anzeige für Monitore: Inhalt per Fetch nachladen, sobald sich eine angezeigte Startliste ändert.
// Einstellungen (Listenauswahl, Größe) liegen pro Tab im sessionStorage.

const RELOAD_INTERVAL = 60 * 1000;
const IDLE_TIMEOUT = 3000;

let monitor = null;

const readSettings = function (key) {
  try {
    return { listIds: [], fontScale: 1, ...JSON.parse(sessionStorage.getItem(key) || '{}') };
  } catch {
    return { listIds: [], fontScale: 1 };
  }
};

const writeSettings = function (key, settings) {
  try {
    sessionStorage.setItem(key, JSON.stringify(settings));
  } catch {
    // Ohne Speicher gelten die Einstellungen nur bis zum Neuladen
  }
};

const setupMonitor = function (root) {
  const state = {
    root,
    settings: readSettings(root.dataset.storageKey),
    consumer: createConsumer(),
    subscriptions: {},
    timers: [],
    reloadTimeout: null,
    wakeLock: null,
    abort: new AbortController(),
  };
  const content = root.querySelector('.score-monitor-content');
  const connection = root.querySelector('.score-monitor-connection');
  const panel = root.querySelector('.score-monitor-panel');
  const listeners = { signal: state.abort.signal };

  const save = () => writeSettings(root.dataset.storageKey, state.settings);

  const updateConnection = () => {
    const subscriptions = Object.values(state.subscriptions);
    const connected = subscriptions.length > 0 && subscriptions.every((s) => s.connected);
    connection.classList.toggle('connected', connected);
  };

  const subscribe = (listIds) => {
    Object.keys(state.subscriptions).forEach((id) => {
      if (listIds.includes(id)) return;
      state.subscriptions[id].unsubscribe();
      delete state.subscriptions[id];
    });
    listIds.forEach((id) => {
      if (state.subscriptions[id]) return;
      const subscription = state.consumer.subscriptions.create(
        { channel: 'ScoreListChannel', score_list_id: id, editable: false },
        {
          connected() {
            this.connected = true;
            updateConnection();
          },
          disconnected() {
            this.connected = false;
            updateConnection();
          },
          rejected() {
            this.connected = false;
            updateConnection();
          },
          received() {
            scheduleReload();
          },
        }
      );
      state.subscriptions[id] = subscription;
    });
    updateConnection();
  };

  const load = async () => {
    const url = new URL(root.dataset.contentUrl, window.location.href);
    state.settings.listIds.forEach((id) => url.searchParams.append('list_ids[]', id));
    try {
      const response = await fetch(url, { headers: { Accept: 'text/html' }, signal: state.abort.signal });
      if (!response.ok) return;
      content.innerHTML = await response.text();
      const blocks = content.querySelector('.score-monitor-blocks');
      subscribe((blocks?.dataset.listIds || '').split(',').filter(Boolean));
    } catch {
      // Beim nächsten Intervall erneut versuchen
    }
  };

  // Mehrere Änderungen kurz hintereinander nur einmal laden
  const scheduleReload = () => {
    clearTimeout(state.reloadTimeout);
    state.reloadTimeout = setTimeout(load, 300);
  };

  const applyFontScale = () => {
    root.style.setProperty('--monitor-scale', state.settings.fontScale);
    root.querySelector('.score-monitor-size-reset').innerText = `${Math.round(state.settings.fontScale * 100)} %`;
  };

  const changeFontScale = (factor) => {
    state.settings.fontScale = factor ? Math.min(3, Math.max(0.4, state.settings.fontScale * factor)) : 1;
    applyFontScale();
    save();
  };

  const updateListCheckboxes = () => {
    const automatic = state.settings.listIds.length === 0;
    root.querySelector('.score-monitor-automatic').checked = automatic;
    root.querySelectorAll('.score-monitor-list').forEach((checkbox) => {
      checkbox.checked = state.settings.listIds.includes(checkbox.value);
    });
  };

  root.querySelector('.score-monitor-automatic').addEventListener(
    'change',
    () => {
      state.settings.listIds = [];
      updateListCheckboxes();
      save();
      load();
    },
    listeners
  );
  root.querySelectorAll('.score-monitor-list').forEach((checkbox) => {
    checkbox.addEventListener(
      'change',
      () => {
        state.settings.listIds = [...root.querySelectorAll('.score-monitor-list:checked')].map((c) => c.value);
        updateListCheckboxes();
        save();
        load();
      },
      listeners
    );
  });

  root.querySelector('.score-monitor-toggle').addEventListener(
    'click',
    () => panel.classList.toggle('d-none'),
    listeners
  );
  root.querySelector('.score-monitor-smaller').addEventListener('click', () => changeFontScale(1 / 1.1), listeners);
  root.querySelector('.score-monitor-bigger').addEventListener('click', () => changeFontScale(1.1), listeners);
  root.querySelector('.score-monitor-size-reset').addEventListener('click', () => changeFontScale(null), listeners);
  root.querySelector('.score-monitor-fullscreen').addEventListener(
    'click',
    () => {
      if (document.fullscreenElement) {
        document.exitFullscreen();
      } else {
        document.documentElement.requestFullscreen?.();
      }
    },
    listeners
  );

  // Menü nach kurzer Zeit ohne Mausbewegung ausblenden
  let idleTimeout = null;
  const wakeUp = () => {
    root.classList.remove('idle');
    clearTimeout(idleTimeout);
    idleTimeout = setTimeout(() => {
      if (panel.classList.contains('d-none')) root.classList.add('idle');
    }, IDLE_TIMEOUT);
  };
  ['mousemove', 'touchstart', 'keydown'].forEach((event) => document.addEventListener(event, wakeUp, listeners));
  wakeUp();

  // Bildschirm nicht in den Ruhezustand gehen lassen
  const requestWakeLock = async () => {
    try {
      if (navigator.wakeLock && document.visibilityState === 'visible') {
        state.wakeLock = await navigator.wakeLock.request('screen');
      }
    } catch {
      // Nicht unterstützt oder nicht erlaubt
    }
  };
  document.addEventListener('visibilitychange', requestWakeLock, listeners);
  requestWakeLock();

  const clock = root.querySelector('.score-monitor-clock');
  const updateClock = () => {
    clock.innerText = new Date().toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  };
  updateClock();

  state.timers.push(setInterval(updateClock, 1000));
  state.timers.push(setInterval(load, RELOAD_INTERVAL));
  state.timers.push(() => clearTimeout(idleTimeout));

  applyFontScale();
  updateListCheckboxes();
  load();

  return state;
};

const teardownMonitor = function () {
  if (!monitor) return;
  monitor.abort.abort();
  monitor.timers.forEach((timer) => (typeof timer === 'function' ? timer() : clearInterval(timer)));
  clearTimeout(monitor.reloadTimeout);
  monitor.consumer.disconnect();
  monitor.wakeLock?.release();
  monitor = null;
};

onVisit(() => {
  teardownMonitor();
  const root = document.querySelector('.score-monitor[data-content-url]');
  if (root) monitor = setupMonitor(root);
});
