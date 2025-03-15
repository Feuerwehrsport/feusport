import EasyMDE from 'easymde';

const insertFileLink = function (editor, files) {
  const [modal, modalContent] = feusportModal(false);

  const card = div('card');
  card.append(div('card-header', 'Auswahl des Dokuments'));

  const cardBody = div('card-body');
  card.append(cardBody);

  const cardFooter = div('card-footer');
  const hint = document.createElement('p');
  hint.classList.add('small', 'text-muted');
  hint.innerText = 'Sie müssen zuerst Dokumente zu diesem Wettkampf hinzufügen. Danach können Sie diese hier Auswählen und somit direkt in der Beschreibung einen Link setzen.';

  cardFooter.append(hint);
  const cancel = div('btn btn-light btn-sm', 'Abbrechen');
  cancel.addEventListener('click', () => modal.remove());
  cardFooter.append(cancel);
  card.append(cardFooter);

  const table = document.createElement('table');
  table.classList.add('table');

  const headline = document.createElement('tr');
  let col = document.createElement('th');
  col.innerText = 'Vorschau';
  headline.append(col);
  col = document.createElement('th');
  col.innerText = 'Einfügen als Link';
  headline.append(col);
  col = document.createElement('th');
  col.innerText = 'Einfügen als Bild';
  headline.append(col);
  table.append(headline);

  files.forEach((file) => {
    const tr = document.createElement('tr');
    let td = document.createElement('td');
    if (file.preview) {
      const img = document.createElement('img');
      img.src = file.preview;
      td.append(img);
    }
    tr.append(td);

    td = document.createElement('td');
    let btn = div('btn btn-link btn-sm', file.title);
    btn.addEventListener('click', () => {
      let selection = editor.codemirror.getSelection();
      if (!selection) selection = file.title;
      editor.codemirror.replaceSelection(`[${selection}](${file.url})`);
      modal.remove();
    });
    td.append(btn);
    tr.append(td);

    td = document.createElement('td');
    if (file.preview) {
      btn = div('btn btn-link btn-sm', file.title);
      btn.addEventListener('click', () => {
        let selection = editor.codemirror.getSelection();
        if (!selection) selection = file.title;
        editor.codemirror.replaceSelection(`![${selection}](${file.image})`);
        modal.remove();
      });
      td.append(btn);
    }
    tr.append(td);

    table.append(tr);
  });

  cardBody.append(table);

  modalContent.append(card);
};

onVisit(function () {
  document.querySelectorAll('textarea.easymde-required').forEach((textarea) => {
    var editor = new EasyMDE({
      element: textarea,
      autoDownloadFontAwesome: false,
      spellChecker: false,
      status: false,
      toolbar: [
        'bold',
        'italic',
        'heading-3',
        '|',
        'unordered-list',
        'ordered-list',
        'link',
        '|',
        {
          name: 'tabelle',
          action: EasyMDE.drawTable,
          className: 'fa fa-table',
          title: 'Tabelle einfügen',
        },
        'horizontal-rule',
        '|',
        'preview',
        'side-by-side',
        'fullscreen',
        'guide',
        '|',
        {
          name: 'insertFile',
          action: (editor) => insertFileLink(editor, JSON.parse(textarea.dataset.files || [])),
          className: 'fa fa-file',
          title: 'Dokument einfügen',
        },
      ],
    });
  });
});
