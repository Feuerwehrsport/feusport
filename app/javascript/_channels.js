import { createConsumer } from '@rails/actioncable';

let lastScoreListId = null;
let currentScoreListChannel = null;

const subscribeScoreListChannel = function (id, editable) {
  currentScoreListChannel = createConsumer().subscriptions.create(
    { channel: 'ScoreListChannel', score_list_id: id, editable: editable == '1' },
    {
      received(data) {
        if (data.run != null) {
          for (var entryId in data.tracks) {
            const tr = document.querySelector(`tr[data-id="${entryId}"]`);
            const newTrHtml = data.tracks[entryId];
            if (tr) {
              tr.classList.add('animate-fade-out');
              setTimeout(() => {
                const template = document.createElement('template');
                template.innerHTML = newTrHtml.trim();
                const newRow = template.content.firstChild;
                newRow.classList.add('highlight-updated-run');
                setTimeout(() => {
                  newRow.classList.add('highlight-updated-run-fade-out');
                }, 4000);

                tr.replaceWith(newRow);
              }, 500);
            }
          }
        } else {
          window.location.reload();
        }
      },
    }
  );
};
const unsubscribeScoreListChannel = function () {
  if (currentScoreListChannel) {
    currentScoreListChannel.unsubscribe();
    currentScoreListChannel = null;
    lastScoreListId = null;
  }
};

onVisit(function () {
  const table = document.querySelector('.score-list-channel[data-score-list-id]');
  if (!table) {
    unsubscribeScoreListChannel();
  } else if (table.dataset.scoreListId != lastScoreListId) {
    unsubscribeScoreListChannel();

    lastScoreListId = table.dataset.scoreListId;
    subscribeScoreListChannel(lastScoreListId, table.dataset.scoreListEditable);
  }
});
