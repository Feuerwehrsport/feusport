const handleBadInput = function (input) {
  const group = input.parentNode;
  const tr = group.closest('tr');
  const label = group.querySelector('label');
  const text = label.innerText;

  const handleInput = function () {
    const value = input.value;

    const goodInput = !input.validity.badInput;
    const goodValue = value.match(/^\d+([.,]\d{1,2})?$/) || value.match(/^\s*$/);
    if (goodInput && goodValue) {
      label.innerText = text;
      tr.classList.remove('danger');
      group.closest('form').querySelector('button[type=submit]').disabled = false;
    } else {
      label.innerText = 'Format: SS,MM';
      tr.classList.add('danger');
      group.closest('form').querySelector('button[type=submit]').disabled = true;
    }
  };
  input.addEventListener('change', handleInput);
  input.addEventListener('keydown', handleInput);
  input.addEventListener('paste', handleInput);
  input.addEventListener('input', handleInput);
};

const editTimes = function () {
  document.querySelectorAll('.edit-time').forEach(function (context, i) {
    const disableHandler = function () {
      const checked = context.querySelector('input[type=radio]:checked');
      if (checked && (checked.value === 'invalid' || checked.value === 'no_run')) {
        context.querySelector('.time-entries').classList.add('disabled-time-entries');
      } else {
        context.querySelector('.time-entries').classList.remove('disabled-time-entries');
      }
    };
    context.querySelectorAll('input[type=radio]').forEach(function (radio) {
      radio.addEventListener('change', disableHandler);
    });
    disableHandler();

    context.querySelectorAll('.time-entries input.numeric.second_time').forEach(function (timeInput, tindex) {
      handleBadInput(timeInput);
      const selectRadioButton = function () {
        if (timeInput.value !== '') {
          context.querySelector('input[type=radio][value=valid]').checked = true;
          disableHandler();
        }
      };
      timeInput.addEventListener('change', selectRadioButton);
      timeInput.addEventListener('keydown', selectRadioButton);
      timeInput.addEventListener('paste', selectRadioButton);
      if (i == 0 && tindex == 0) timeInput.focus();
    });
  });
};

onVisit(editTimes);
