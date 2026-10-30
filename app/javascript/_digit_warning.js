onVisit(function () {
  document.querySelectorAll('input[data-digit-warning]').forEach(function (input) {
    const warning = document.createElement('div');
    warning.classList.add('alert', 'alert-warning', 'py-2', 'px-3', 'mt-2', 'mb-0', 'fw-semibold');
    warning.setAttribute('role', 'alert');
    const icon = document.createElement('i');
    icon.classList.add('far', 'fa-warning', 'me-2');
    warning.append(icon, input.dataset.digitWarning);
    input.insertAdjacentElement('afterend', warning);

    const check = function () {
      const hasDigit = /\d/.test(input.value);
      warning.classList.toggle('d-none', !hasDigit);
      input.classList.toggle('border-warning', hasDigit);
    };
    input.addEventListener('input', check);
    input.addEventListener('change', check);
    check();
  });
});
