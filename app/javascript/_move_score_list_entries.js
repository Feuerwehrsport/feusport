import Sortable from 'sortablejs/modular/sortable.core.esm.js';

let rebuildTable;

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
};

onVisit(function () {
  bindSortedTable();

  const saveLink = document.querySelector('#save-link');
  if (!saveLink) return;
  saveLink.addEventListener('click', () => {
    rebuildTable(true);
  });
});
