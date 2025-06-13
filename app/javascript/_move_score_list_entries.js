import Sortable from 'sortablejs/modular/sortable.core.esm.js';

let rebuildTable;
let modus;

const bindSortedTable = function () {
  const table = document.querySelector('table.sorted-table');
  if (!table) return;

  const tbody = table.querySelector('tbody');

  const animationEndCallback = function () {
    table.removeEventListener('animationend', animationEndCallback);
    table.classList.remove('animate-fade-out');
    table.classList.remove('animate-fade-in');
    window.setTimeout(bindSortedTable, 1);
  };

  rebuildTable = function (save = false) {
    if (save) {
      document.getElementById('pending-changes').classList.add('d-none');
      document.getElementById('back-link').classList.remove('d-none');
    } else {
      document.getElementById('pending-changes').classList.remove('d-none');
      document.getElementById('back-link').classList.add('d-none');
    }
    table.classList.add('animate-fade-out');

    const tableData = {};
    tbody.querySelectorAll('tr').forEach((tr, i) => {
      tableData[i] = tr.dataset.id || null;
    });

    const csrfToken = document.head.querySelector('[name~=csrf-token][content]').content;

    fetch(window.location, {
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      method: 'POST',
      credentials: 'same-origin',
      body: JSON.stringify({ new_order: tableData, save: save, tab_session_id: tabSessionId() }),
    })
      .then((res) => res.text())
      .then((html) => {
        var parser = new DOMParser();
        var doc = parser.parseFromString(html, 'text/html');
        var newTbody = doc.querySelector('table.sorted-table tbody');
        tbody.replaceWith(newTbody);

        table.classList.remove('animate-fade-out');
        table.classList.add('animate-fade-in');
        table.addEventListener('animationend', animationEndCallback);

        var newRestrictionCheck = doc.querySelector('.restriction-check');
        document.querySelector('.restriction-check').replaceWith(newRestrictionCheck);
      });
  };

  if (modus == 'move') {
    table.classList.add('move');
    document.querySelectorAll('.move-up, .move-down').forEach((e) => e.classList.remove('d-none'));

    tbody.querySelectorAll('.move-up').forEach((btn) => {
      btn.addEventListener('click', () => {
        const tr = btn.closest('tr');
        tbody.prepend(tr);
        rebuildTable();
      });
    });

    tbody.querySelectorAll('.move-down').forEach((btn) => {
      btn.addEventListener('click', () => {
        const tr = btn.closest('tr');
        const nodes = tbody.querySelectorAll('tr[data-id]');
        if (nodes.length > 0) {
          const lastWithData = nodes[nodes.length - 1];
          lastWithData.parentNode.insertBefore(tr, lastWithData.nextSibling);
          rebuildTable();
        }
      });
    });

    new Sortable(tbody, {
      animation: 150,
      ghostClass: 'sortable-ghost',
      chosenClass: 'sortable-chosen',
      dragClass: 'sortable-drag',
      filter: '.btn',
      onEnd: () => {
        rebuildTable();
      },
    });
  } else if (modus == 'swap') {
    swapCheck(table, tbody, '.swap-checkbox');
  } else if (modus == 'swap-run') {
    swapCheck(table, tbody, '.swap-run-checkbox');
  }
};

const swapCheck = function (table, tbody, query) {
  table.classList.remove('move');

  // Für alle checkboxen
  tbody.querySelectorAll(query).forEach((c) => {
    // sichtbar machen
    c.classList.remove('d-none');

    // bei Änderung überpüfen
    c.addEventListener('input', () => {
      let c1 = null;
      let c2 = null;
      document.querySelectorAll(query).forEach((c) => {
        if (c.checked) {
          if (c1 == null) c1 = c;
          else c2 = c;
        }
      });

      if (c1 && c2) {
        const tr1 = c1.closest('tr');
        const tr2 = c2.closest('tr');
        swapRowsWithFollowing(tbody, tr1, tr2, c1.dataset.trackCount || 1);

        rebuildTable();
      }
    });
  });
};

const swapRowsWithFollowing = function (tbody, tr1, tr2, count) {
  count = parseInt(count, 10);

  // Alle <tr> in ein Array
  const rows = Array.from(tbody.children);

  const index1 = rows.indexOf(tr1);
  const index2 = rows.indexOf(tr2);

  if (index1 === -1 || index2 === -1) return;

  // Bereich extrahieren
  const group1 = rows.slice(index1, index1 + count);
  const group2 = rows.slice(index2, index2 + count);

  // Sicherstellen, dass beide Gruppen vollständig vorhanden sind
  if (group1.length !== count || group2.length !== count) return;

  // Platzhalter: ein leeres Kommentar-Node
  const marker1 = document.createComment('swap-marker1');
  tbody.insertBefore(marker1, group1[0]);

  const marker2 = document.createComment('swap-marker2');
  tbody.insertBefore(marker2, group2[0]);

  // Entfernen (aber in Variablen behalten)
  group1.forEach((row) => tbody.removeChild(row));
  group2.forEach((row) => tbody.removeChild(row));

  // Zuerst group2 einfügen, wo group1 war
  group2.forEach((row) => tbody.insertBefore(row, marker1));

  // Dann group1 einfügen, an die Stelle von group2
  group1.forEach((row) => tbody.insertBefore(row, marker2));

  tbody.removeChild(marker1);
  tbody.removeChild(marker2);
};

const changeModus = function () {
  modus = document.querySelector('input[name=modus]:checked').value;

  document.querySelector('.move-hint').classList.toggle('d-none', modus != 'move');
  document.querySelector('.swap-hint').classList.toggle('d-none', modus != 'swap');
  document.querySelector('.swap-run-hint').classList.toggle('d-none', modus != 'swap-run');
};

onVisit(function () {
  const saveLink = document.querySelector('#save-link');
  if (!saveLink) return;

  changeModus();

  for (let elem of document.querySelectorAll('input[type="radio"][name="modus"]')) {
    elem.addEventListener('input', (event) => {
      changeModus();
      rebuildTable();
    });
  }

  bindSortedTable();

  saveLink.addEventListener('click', () => {
    rebuildTable(true);
  });
});
