onVisit(function () {
  document.querySelectorAll('input[data-name-preview]').forEach(function (input) {
    const takeOverBtn = document.createElement('i');
    takeOverBtn.classList.add('far', 'fa-square-pen');
    takeOverBtn.title = 'Automatischen Text übernehmen und bearbeiten';
    const label = input.parentElement.querySelector('label');
    label.appendChild(document.createTextNode('\u00A0'));
    label.appendChild(takeOverBtn);
    takeOverBtn.addEventListener('click', function (event) {
      event.preventDefault();
      input.value = input.placeholder;
      input.focus();
    });

    const form = input.closest('form');
    const change = function () {
      const data = new URLSearchParams();
      data.append('name_preview', '1');
      for (const pair of new FormData(form)) {
        data.append(pair[0], pair[1]);
      }
      const csrfToken = document.head.querySelector('[name~=csrf-token][content]').content;
      fetch(form.action, {
        headers: {
          'X-CSRF-Token': csrfToken,
        },
        method: 'POST',
        credentials: 'same-origin',
        body: data,
      })
        .then((res) => res.json())
        .then((json) => {
          input.placeholder = json.name;
        });
    };
    form.addEventListener('change', change);
    change();
  });
});
