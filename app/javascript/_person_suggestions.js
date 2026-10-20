const suggestions = function (div) {
  const firstName = document.querySelector('#person_first_name');
  const lastName = document.querySelector('#person_last_name');

  const personSuggestion = document.querySelector('#person_suggestion');

  let lastValue = personSuggestion.value;
  let updateTimer = null;

  const updateSuggestions = function () {
    const table = div.querySelector('table');
    const csrfToken = document.head.querySelector('[name~=csrf-token][content]').content;

    fetch('/fire_sport_statistics/suggestions/people', {
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      method: 'POST',
      credentials: 'same-origin',
      body: JSON.stringify({ name: lastValue, team_name: personSuggestion.dataset.teamName }),
    })
      .then((res) => res.json())
      .then((json) => {
        table.innerHTML = '';

        json.forEach(function (result) {
          const tr = document.createElement('tr');
          const tdFirstName = document.createElement('td');
          tdFirstName.innerText = result.first_name;
          const tdLastName = document.createElement('td');
          tdLastName.innerText = result.last_name;
          const tdTeam = document.createElement('td');
          tdTeam.innerText = result.teams.map((t) => t.short).join(', ');
          tr.addEventListener('click', function () {
            table.innerHTML = '';
            firstName.value = result.first_name;
            lastName.value = result.last_name;

            const fireSportId = document.querySelector('#person_fire_sport_statistics_person_id');
            fireSportId.dataset.firstName = result.first_name;
            fireSportId.dataset.lastName = result.last_name;
            fireSportId.dataset.gender = result.gender;
            fireSportId.value = result.id;
            fireSportId.dispatchEvent(new Event('change'));
          });
          tr.append(tdFirstName);
          tr.append(tdLastName);
          tr.append(tdTeam);
          table.append(tr);
        });
      });
  };

  personSuggestion.addEventListener('keyup', function () {
    const newValue = personSuggestion.value;
    if (lastValue !== newValue) {
      lastValue = newValue;
      if (newValue !== '') {
        const nameParts = newValue.split(/\s+/);
        lastName.value = '';
        for (var i = 0; i < nameParts.length; i++) {
          if (i == 0) firstName.value = nameParts[i];
          else lastName.value += nameParts[i] + ' ';
        }

        // erst nach einer kurzen Tipppause anfragen (Server hat ein Rate-Limit)
        clearTimeout(updateTimer);
        updateTimer = setTimeout(updateSuggestions, 200);
      }
    }
  });
};

const connectionInfo = function (fireSportId) {
  const changed = function () {
    const connected = document.querySelector('#fire-sport-connected');
    const notConnected = document.querySelector('#fire-sport-not-connected');
    if (fireSportId.value.match(/\d+/)) {
      const genderWarning = document.getElementById('gender-warning');
      if (genderWarning) {
        if (genderWarning.dataset.gender == fireSportId.dataset.gender) {
          genderWarning.classList.add('d-none');
        } else {
          genderWarning.classList.remove('d-none');
        }
      }

      connected.classList.remove('d-none');
      notConnected.classList.add('d-none');
      connected.querySelector('strong.first-name').innerText = fireSportId.dataset.firstName;
      connected.querySelector('strong.last-name').innerText = fireSportId.dataset.lastName;
      connected.querySelector('a').href = `https://feuerwehrsport-statistik.de/people/${fireSportId.value}`;
    } else {
      connected.classList.add('d-none');
      notConnected.classList.remove('d-none');
    }
  };
  document.querySelector('#fire-sport-remove').addEventListener('click', function () {
    fireSportId.value = '';
    fireSportId.dispatchEvent(new Event('change'));
  });
  fireSportId.addEventListener('change', changed);
  changed();
};

onVisit(function () {
  const div = document.querySelector('.suggestions-entries.for-people');
  if (div) suggestions(div);

  const fireSportId = document.querySelector('#person_fire_sport_statistics_person_id');
  if (fireSportId) connectionInfo(fireSportId);
});
