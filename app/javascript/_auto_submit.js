const KEEP_OPEN_KEY = 'autoSubmitKeepOpen';

onVisit(function () {
  const keepOpenId = sessionStorage.getItem(KEEP_OPEN_KEY);
  sessionStorage.removeItem(KEEP_OPEN_KEY);

  document.querySelectorAll('form[data-auto-submit]').forEach(function (form) {
    // Eingeklappte Formulare bleiben nach dem Absenden geöffnet
    if (form.id && form.id === keepOpenId && form.classList.contains('collapse')) {
      form.classList.add('show');
      document.querySelectorAll(`[data-bs-target="#${form.id}"]`).forEach(function (toggle) {
        toggle.setAttribute('aria-expanded', 'true');
      });
    }

    form.addEventListener('change', function () {
      if (form.id && form.classList.contains('show')) sessionStorage.setItem(KEEP_OPEN_KEY, form.id);
      form.requestSubmit();
    });
  });
});
