import { createConsumer } from '@rails/actioncable';

let lastScoreListId = null;
let currentScoreListChannel = null;

const highlightUpdatedRow = function (tr) {
  tr.classList.add('highlight-updated-row');
  setTimeout(() => {
    tr.classList.add('highlight-updated-row-fade-out');
  }, 4000);
};

const subscribeScoreListChannel = function (id, editable) {
  currentScoreListChannel = createConsumer().subscriptions.create(
    { channel: 'ScoreListChannel', score_list_id: id, editable: editable == '1' },
    {
      received(data) {
        if (data.tab_session_id == tabSessionId()) return;
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
                highlightUpdatedRow(newRow);

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

let lastScoreResultId = null;
let currentScoreResultChannel = null;

const subscribeScoreResultChannel = function (id) {
  currentScoreResultChannel = createConsumer().subscriptions.create(
    { channel: 'ScoreResultChannel', score_result_id: id },
    {
      received(data) {
        const template = document.createElement('template');
        template.innerHTML = data.html.trim();
        const tables = template.content.querySelectorAll('.score-result-rows-table');
        if (tables.length === 0) {
          if (document.querySelectorAll('.score-result-rows-table').length !== 0) {
            window.location.reload();
            return;
          }
        } else {
          tables.forEach((newTable) => {
            const contentId = newTable.dataset.content;
            const currentTable = document.querySelector(`.score-result-rows-table[data-content=${contentId}]`);
            if (!currentTable) {
              window.location.reload();
              return;
            } else {
              const currentTrs = currentTable.querySelectorAll('tr');
              const newTrs = newTable.querySelectorAll('tr');

              const changedIndexes = getDiffIndexes(currentTrs, newTrs);

              currentTable.replaceWith(newTable);

              newTable.querySelectorAll('tr').forEach((tr, index) => {
                if (changedIndexes.includes(index)) {
                  highlightUpdatedRow(tr);
                }
              });
            }
          });
        }
      },
    }
  );
};
const unsubscribeScoreResultChannel = function () {
  if (currentScoreResultChannel) {
    currentScoreResultChannel.unsubscribe();
    currentScoreResultChannel = null;
    lastScoreResultId = null;
  }
};

onVisit(function () {
  const resultPart = document.querySelector('.score-result-channel[data-score-result-id]');
  if (!resultPart) {
    unsubscribeScoreResultChannel();
  } else if (resultPart.dataset.scoreResultId != lastScoreResultId) {
    unsubscribeScoreResultChannel();

    lastScoreResultId = resultPart.dataset.scoreResultId;
    subscribeScoreResultChannel(lastScoreResultId);
  }
});

function getDiffIndexes(oldRows, newRows) {
  const lcs = [];
  const dp = Array(oldRows.length + 1)
    .fill(null)
    .map(() => Array(newRows.length + 1).fill(0));

  for (let i = 1; i <= oldRows.length; i++) {
    for (let j = 1; j <= newRows.length; j++) {
      if (oldRows[i - 1].innerHTML === newRows[j - 1].innerHTML) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
  }

  let i = oldRows.length,
    j = newRows.length;
  while (i > 0 && j > 0) {
    if (oldRows[i - 1].innerHTML === newRows[j - 1].innerHTML) {
      lcs.unshift({ oldIndex: i - 1, newIndex: j - 1 });
      i--;
      j--;
    } else if (dp[i - 1][j] > dp[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }

  const unchangedNewIndexes = new Set(lcs.map((pair) => pair.newIndex));
  const changedIndexes = [];
  for (let k = 0; k < newRows.length; k++) {
    if (!unchangedNewIndexes.has(k)) {
      changedIndexes.push(k);
    }
  }

  return changedIndexes;
}
