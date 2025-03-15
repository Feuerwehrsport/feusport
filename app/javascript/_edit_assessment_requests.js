const resetHandler = function () {
  document.querySelectorAll('.assessment-request').forEach(function (context) {
    const checkbox = context.querySelector('input[type=checkbox]');
    checkbox.addEventListener('change', (event) => {
      const opacity = checkbox.checked ? 1 : 0.3;
      context.querySelector('.edit-assesment-type').style.opacity = opacity;
    });
    checkbox.dispatchEvent(new Event('change'));

    const select = context.querySelector('select.assessment-types');
    if (select) {
      select.addEventListener('change', function () {
        if (select.value === 'group_competitor') {
          context.querySelector('.group-competitor-order').classList.remove('d-none');
          context.querySelector('.single-competitor-order').classList.add('d-none');
          context.querySelector('.competitor-order').classList.add('d-none');
        } else if (select.value === 'single_competitor') {
          context.querySelector('.single-competitor-order').classList.remove('d-none');
          context.querySelector('.group-competitor-order').classList.add('d-none');
          context.querySelector('.competitor-order').classList.add('d-none');
        } else if (select.value === 'competitor') {
          context.querySelector('.competitor-order').classList.remove('d-none');
          context.querySelector('.group-competitor-order').classList.add('d-none');
          context.querySelector('.single-competitor-order').classList.add('d-none');
        } else {
          context.querySelector('.single-competitor-order').classList.add('d-none');
          context.querySelector('.group-competitor-order').classList.add('d-none');
          context.querySelector('.competitor-order').classList.add('d-none');
        }
      });
      select.dispatchEvent(new Event('change'));
    }
  });
};

onVisit(resetHandler);

const quickAssessmentChange = function () {
  document.querySelectorAll('.quick-assessment-change-link').forEach(function (btn) {
    btn.addEventListener('click', () => {
      const [modal, modalContent] = feusportModal();

      const csrfToken = document.head.querySelector('[name~=csrf-token][content]').content;
      fetch(btn.dataset.url, {
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        method: 'GET',
        credentials: 'same-origin',
      })
        .then((res) => res.json())
        .then((json) => {
          modalContent.innerHTML = json.content;
          resetHandler();
        });
    });
  });
};

onVisit(quickAssessmentChange);
