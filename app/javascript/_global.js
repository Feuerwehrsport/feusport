window.onVisit = function (callback) {
  document.addEventListener('turbo:render', (event) => {
    if (!event.isPreview) callback();
  });
  document.addEventListener('DOMContentLoaded', callback);
};

window.feusportModal = function (spinning = true) {
  const modal = document.createElement('div');
  modal.classList.add('feusport-modal');
  modal.style.display = 'block';
  const modalContent = document.createElement('div');
  modalContent.classList.add('feusport-modal-content');
  modal.appendChild(modalContent);

  if (spinning) modalContent.innerText = 'spinning';

  document.querySelector('body').appendChild(modal);

  return [modal, modalContent];
};

window.div = function (htmlClasses, innerText = null) {
  const element = document.createElement('div');
  htmlClasses.split(/\s+/).forEach((htmlClass) => element.classList.add(htmlClass));
  if (innerText) element.innerText = innerText;
  return element;
};
