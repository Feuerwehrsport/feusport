import Draggable from './draggable';

let config;
let formElementTemplate;
let currentDraggableForPrintDocument = null;

onVisit(function () {
  const modalForm = document.getElementById('new-positions-form');
  const boundary = document.getElementById('certificates-template-position');
  if (boundary === null) return;

  setTimeout(function () {
    config = JSON.parse(boundary.dataset.config);

    const backgroundSrc = boundary.dataset.background;
    if (backgroundSrc) boundary.style.backgroundImage = 'url("' + backgroundSrc + '")';

    document.querySelectorAll('.certificates_template_text_fields_key').forEach(function (textField) {
      const id = textField.querySelector('input').id;
      const number = id.replace(/^certificates_template_text_fields_attributes_(\d+)_key/, '$1');
      new FormElement(number, boundary);
    });

    const formKeySelect = modalForm.querySelector('#certificates_text_field_key');
    const selectChanged = function () {
      const textGroup = modalForm.querySelector('#certificates_text_field_text').closest('.form-group');
      const value = formKeySelect.value;
      if (value === 'text') {
        textGroup.style.display = 'block';
      } else {
        textGroup.style.display = 'none';
      }
    };
    formKeySelect.addEventListener('change', selectChanged);

    document.getElementById('add-new-field').addEventListener('click', function () {
      modalForm.style.display = 'block';
      selectChanged();
    });

    window.addEventListener('click', function (event) {
      if (event.target == modalForm) {
        modalForm.style.display = 'none';
      }
    });

    modalForm.querySelector('a[href=""]').addEventListener('click', function (event) {
      event.stopPropagation();
      event.preventDefault();
      modalForm.style.display = 'none';
    });

    modalForm.querySelector('form').addEventListener('submit', function (event) {
      event.stopPropagation();
      event.preventDefault();
      modalForm.style.display = 'none';

      const key = formKeySelect.value;
      const text = modalForm.querySelector('#certificates_text_field_text').value;
      formElementTemplate.newElement(key, text);
    });
  }, 300);
});

class FormElement {
  constructor(number, boundary) {
    this.number = number;
    this.boundary = boundary;
    this.formInputs = {
      left: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_left`),
      top: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_top`),
      width: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_width`),
      height: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_height`),
      size: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_size`),
      key: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_key`),
      align: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_align`),
      text: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_text`),
      font: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_font`),
      color: document.getElementById(`certificates_template_text_fields_attributes_${this.number}_color`),
      destroy: document.getElementById(`certificates_template_text_fields_attributes_${this.number}__destroy`),
    };

    if (this.get('key') !== 'template') {
      this.textElement = new TextElement(this, this.boundary);
    } else {
      this.nextNumber = parseInt(this.number, 10) + 1;
      formElementTemplate = this;
    }
  }

  set(input, value) {
    this.formInputs[input].value = value;
  }

  get(input) {
    return this.formInputs[input].value;
  }

  newElement(newKey, newText) {
    var input, key;
    for (key in this.formInputs) {
      input = this.formInputs[key].cloneNode();
      input.id = input.id.replace(RegExp(`_${this.number}_`), `_${this.nextNumber}_`);
      input.name = input.name.replace(RegExp(`\\[${this.number}\\]`), `[${this.nextNumber}]`);
      this.formInputs[key].after(input);
    }
    document.getElementById(`certificates_template_text_fields_attributes_${this.nextNumber}_key`).value = newKey;
    document.getElementById(`certificates_template_text_fields_attributes_${this.nextNumber}_text`).value = newText;
    document.getElementById(`certificates_template_text_fields_attributes_${this.nextNumber}__destroy`).value = 'false';

    new FormElement(this.nextNumber, this.boundary).focus();
    this.nextNumber = this.nextNumber + 1;
  }

  focus() {
    this.textElement.element.click();
  }
}

class TextElement {
  constructor(formElement, boundary) {
    this.formElement = formElement;
    this.boundary = boundary;

    this.description = config[formElement.get('key')].description;
    this.example = config[formElement.get('key')].example;
    if (formElement.get('key') === 'text') {
      this.example = formElement.get('text');
    }

    const buttonLine = document.createElement('div');
    buttonLine.classList.add('button-line');

    this.removeButton = document.createElement('div');
    this.removeButton.classList.add('btn', 'btn-info', 'btn-sm', 'fa-regular', 'fa-trash');
    buttonLine.append(this.removeButton);

    this.moveButton = document.createElement('div');
    this.moveButton.classList.add('btn', 'btn-info', 'btn-sm', 'fa-regular', 'fa-up-down-left-right');
    buttonLine.append(this.moveButton);

    this.textLine = document.createElement('div');
    this.textLine.classList.add('text-line');
    this.element = document.createElement('div');
    this.element.classList.add('text-element');
    this.element.append(this.textLine);
    this.element.append(buttonLine);

    if (this.formElement.get('destroy') === 'false') {
      this.show();
    }

    this.element.addEventListener('click', (event) => {
      event.stopPropagation();
      if (currentDraggableForPrintDocument != null) {
        currentDraggableForPrintDocument.blur();
      }
      currentDraggableForPrintDocument = this;
      this.focus();
      this.registerBlur();
    });

    this.createTable();
  }

  registerBlur() {
    const outsideClickListener = (event) => {
      if (currentDraggableForPrintDocument == null) {
        return removeClickListener();
      }
      if (event.target.tagName === 'INPUT' && event.target.type === 'color') {
        return;
      } else {
        if (!this.element.contains(event.target)) {
          currentDraggableForPrintDocument.blur();
          currentDraggableForPrintDocument = null;
          removeClickListener();
        }
      }
    };

    const removeClickListener = () => {
      document.removeEventListener('click', outsideClickListener);
    };

    document.addEventListener('click', outsideClickListener);
  }

  setFontSize() {
    var textSize;
    textSize = 16;
    if (this.formElement.get('size') !== '') {
      textSize = parseInt(this.formElement.get('size'), 10);
    }
    this.textLine.style.fontSize = `${textSize}px`;
    this.formElement.set('size', textSize);
  }

  show() {
    this.removeButton.addEventListener('click', (event) => {
      event.stopPropagation();
      if (window.confirm('Element entfernen?')) this.hide();
    });

    this.formElement.set('destroy', 'false');
    this.setFontSize();
    this.setSize();
    this.setPosition();
    this.setAlign();
    this.setFont();

    this.textLine.textContent = this.example;
    this.textLine.title = this.description;
    this.boundary.append(this.element);

    this.draggable = new Draggable(this.element, {
      handle: this.moveButton,
      limit: this.boundary,
      setPosition: false,
      onDrag: (element, x, y, event) => {
        this.movedTo(x, y);
      },
    });
    this.draggable.set(this.realLeft, this.realTop);
    this.savePosition();
  }

  focus() {
    this.element.classList.add('is-focused');
    this.regenerateTable();
    this.table.style.display = 'table';
    document.title = this.formElement.get('key');
  }

  changeValue(key, distance) {
    if (key === 'width' || key === 'height') {
      let width = this.formElement.get('width');
      let height = this.formElement.get('height');
      if (key === 'width') {
        width = parseInt(width, 10) + distance;
        if (width < 1) width = 1;
      }
      if (key === 'height') {
        height = parseInt(height, 10) + distance;
        if (height < 1) height = 1;
      }
      this.resizeTo(width, height);
      this.setSize();
      this.draggable.destroy();

      this.draggable = new Draggable(this.element, {
        handle: this.moveButton,
        limit: this.boundary,
        setPosition: false,
        onDrag: (element, x, y, event) => {
          this.movedTo(x, y);
        },
      });
    }

    if (key === 'left' || key === 'top') {
      const position = this.draggable.get();
      if (key === 'left') {
        position.x = position.x + distance;
      }
      if (key === 'top') {
        position.y = position.y + distance;
      }
      this.draggable.set(position.x, position.y);
      this.movedTo(position.x, position.y);
    }

    if (key === 'size') {
      let size = parseInt(this.formElement.get('size'), 10) + distance;
      if (size < 1) size = 1;
      this.formElement.set('size', size);
      this.setFontSize();
      this.regenerateTable();
    }
  }

  createTable() {
    this.table = document.getElementById('information-table-template').cloneNode(true);
    document.getElementById('field-tables').append(this.table);

    const keys = ['size', 'left', 'top', 'width', 'height'];
    keys.forEach((key) => {
      this.table.querySelector(`.${key}-value .less-less`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.changeValue(key, -10);
      });
      this.table.querySelector(`.${key}-value .less`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.changeValue(key, -1);
      });
      this.table.querySelector(`.${key}-value .more`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.changeValue(key, +1);
      });
      this.table.querySelector(`.${key}-value .more-more`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.changeValue(key, +10);
      });
    });

    const aligns = ['left', 'center', 'right'];
    aligns.forEach((align) => {
      this.table.querySelector(`.fa-align-${align}`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.formElement.set('align', align);
        this.setAlign();
        this.regenerateTable();
      });
    });

    const fonts = ['regular', 'bold'];
    fonts.forEach((font) => {
      this.table.querySelector(`.font-${font}`).addEventListener('click', (event) => {
        event.stopPropagation();
        this.formElement.set('font', font);
        this.setFont();
        this.regenerateTable();
      });
    });

    const colorInput = this.table.querySelector('input[type=color]');
    colorInput.value = `#${this.formElement.get('color')}`;
    colorInput.addEventListener('change', (event) => {
      this.formElement.set('color', colorInput.value.replace(/[^0-9A-F]/, '').toUpperCase());
      this.formElement.focus();
    });

    this.table.querySelector('.centering').addEventListener('click', (event) => {
      event.stopPropagation();
      this.adjustCenter();
    });
  }

  regenerateTable() {
    var alignLine, btn, colorInput, colorLine, fontLine;

    this.table.querySelector('th.key').textContent = config[this.formElement.get('key')].description;

    const keys = ['size', 'left', 'top', 'width', 'height'];
    keys.forEach((key) => {
      this.table.querySelector(`.${key}-value .value`).textContent = this.formElement.get(key);
    });

    const aligns = ['left', 'center', 'right'];
    aligns.forEach((align) => {
      if (this.formElement.get('align') === align) {
        this.table.querySelector(`.fa-align-${align}`).classList.add('btn-primary');
        this.table.querySelector(`.fa-align-${align}`).classList.remove('btn-light');
      } else {
        this.table.querySelector(`.fa-align-${align}`).classList.add('btn-light');
        this.table.querySelector(`.fa-align-${align}`).classList.remove('btn-primary');
      }
    });

    const fonts = ['regular', 'bold'];
    fonts.forEach((font) => {
      if (this.formElement.get('font') === font) {
        this.table.querySelector(`.font-${font}`).classList.add('btn-primary');
        this.table.querySelector(`.font-${font}`).classList.remove('btn-light');
      } else {
        this.table.querySelector(`.font-${font}`).classList.add('btn-light');
        this.table.querySelector(`.font-${font}`).classList.remove('btn-primary');
      }
    });
  }

  blur() {
    this.element.classList.remove('is-focused');
    this.table.style.display = null;
  }

  hide() {
    this.element.remove();
    this.formElement.set('destroy', 'true');
  }

  movedTo(left, top) {
    this.realLeft = left;
    this.realTop = top;
    this.savePosition();
    this.regenerateTable();
  }

  adjustCenter() {
    const position = this.draggable.get();
    position.x = 595 / 2 - parseInt(this.formElement.get('width'), 10) / 2;
    this.draggable.set(position.x, position.y);
    this.movedTo(position.x, position.y);
  }

  resizeTo(width, height) {
    this.width = Math.round(width * 2) / 2;
    this.height = Math.round(height * 2) / 2;
    this.formElement.set('width', this.width);
    this.formElement.set('height', this.height);
    this.regenerateTable();
  }

  setFont() {
    if (this.formElement.get('font') === 'regular') {
      if (this.formElement.boundary.dataset.fontFamilyRegular !== '') {
        this.textLine.style.fontFamily = this.formElement.boundary.dataset.fontFamilyRegular;
        this.textLine.style.fontWeight = 'normal';
      } else {
        this.textLine.style.fontFamily = this.formElement.boundary.dataset.initial;
        this.textLine.style.fontWeight = 'normal';
      }
    } else {
      if (this.formElement.boundary.dataset.fontFamilyBold !== '') {
        this.textLine.style.fontFamily = this.formElement.boundary.dataset.fontFamilyBold;
        this.textLine.style.fontWeight = 'normal';
      } else {
        this.textLine.style.fontFamily = this.formElement.boundary.dataset.initial;
        this.textLine.style.fontWeight = 'bold';
      }
    }
  }

  setSize() {
    if (this.formElement.get('width') !== '') {
      this.width = parseInt(this.formElement.get('width'), 10);
    } else {
      this.width = 400;
    }
    if (this.formElement.get('height') !== '') {
      this.height = parseInt(this.formElement.get('height'), 10);
    } else {
      this.height = 50;
    }
    this.formElement.set('width', this.width);
    this.formElement.set('height', this.height);

    this.textLine.style.width = `${this.width}px`;
    this.textLine.style.height = `${this.height}px`;
    this.textLine.style.lineHeight = `${this.height}px`;
  }

  setAlign() {
    this.textLine.style.textAlign = this.formElement.get('align');
  }

  setPosition() {
    let left, top;
    if (this.formElement.get('left') !== '') {
      left = parseInt(this.formElement.get('left'), 10);
    } else {
      left = 97;
    }
    if (this.formElement.get('top') !== '') {
      top = (parseInt(this.formElement.get('top'), 10) - 842) * -1;
    } else {
      top = 400;
    }
    this.realTop = top;
    this.realLeft = left;
  }

  savePosition() {
    this.formElement.set('left', this.realLeft);
    return this.formElement.set('top', 842 - this.realTop);
  }
}
