const suggestions = function (div) {
  const teamName = document.getElementById('team_name');
  const teamShortcut = document.getElementById('team_shortcut');
  let lastValue = teamName.value;
  let shortcutChanged = false;
  let updateTimer = null;

  const setShortcut = function (shortcutValue) {
    teamShortcut.value = shortcutValue.substr(0, 12);
  };

  const updateSuggestions = function () {
    const table = div.querySelector('table');
    const csrfToken = document.head.querySelector('[name~=csrf-token][content]').content;

    fetch('/fire_sport_statistics/suggestions/teams', {
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      method: 'POST',
      credentials: 'same-origin',
      body: JSON.stringify({ name: lastValue }),
    })
      .then((res) => res.json())
      .then((json) => {
        table.innerHTML = '';

        json.forEach(function (result) {
          const tr = document.createElement('tr');
          const td = document.createElement('td');
          td.innerText = result.name;
          td.addEventListener('click', function () {
            table.innerHTML = '';
            teamName.value = result.name;
            setShortcut(result.short);
            shortcutChanged = false;

            const fireSportId = document.getElementById('team_fire_sport_statistics_team_id');
            fireSportId.dataset.name = result.name;
            fireSportId.value = result.id;
            fireSportId.dispatchEvent(new Event('change'));
          });
          tr.append(td);
          table.append(tr);
        });
      });
  };

  teamShortcut.addEventListener('keyup', () => (shortcutChanged = true));
  teamName.addEventListener('keyup', function () {
    var newValue = teamName.value;
    if (lastValue !== newValue) {
      lastValue = newValue;
      if (!shortcutChanged) setShortcut(newValue);
      // erst nach einer kurzen Tipppause anfragen (Server hat ein Rate-Limit)
      clearTimeout(updateTimer);
      updateTimer = setTimeout(updateSuggestions, 200);
    }
  });
};

const connectionInfo = function (fireSportId) {
  const changed = function () {
    const connected = document.getElementById('fire-sport-connected');
    const notConnected = document.getElementById('fire-sport-not-connected');
    if (fireSportId.value.match(/\d+/)) {
      connected.classList.remove('d-none');
      notConnected.classList.add('d-none');
      connected.querySelector('strong').innerText = fireSportId.dataset.name;
      connected.querySelector('a').href = `https://feuerwehrsport-statistik.de/teams/${fireSportId.value}`;
    } else {
      connected.classList.add('d-none');
      notConnected.classList.remove('d-none');
    }
  };
  document.getElementById('fire-sport-remove').addEventListener('click', function () {
    fireSportId.value = '';
    fireSportId.dispatchEvent(new Event('change'));
  });
  fireSportId.addEventListener('change', changed);
  changed();
};

onVisit(function () {
  const div = document.querySelector('.suggestions-entries.for-teams');
  if (div) suggestions(div);

  const fireSportId = document.querySelector('#team_fire_sport_statistics_team_id');
  if (fireSportId) connectionInfo(fireSportId);
});
