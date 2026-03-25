(function () {
  var storageKey = "archive-of-missing-log-progress";
  var progress = loadProgress();

  document.addEventListener("DOMContentLoaded", function () {
    markPageVisit();
    bindPuzzleForms();
    bindHintButtons();
    bindSecretInput();
    renderProgress();
  });

  function loadProgress() {
    try {
      var raw = window.localStorage.getItem(storageKey);
      return raw ? JSON.parse(raw) : {};
    } catch (error) {
      return {};
    }
  }

  function saveProgress() {
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(progress));
    } catch (error) {
      return;
    }
  }

  function normalize(value) {
    return String(value || "")
      .trim()
      .toUpperCase()
      .replace(/\s+/g, "")
      .replace(/[^\u30A0-\u30FF\u3040-\u309FA-Z0-9]/g, "");
  }

  function markPageVisit() {
    var body = document.body;
    if (!body || !body.dataset.page) {
      return;
    }

    progress["visited:" + body.dataset.page] = true;
    saveProgress();
  }

  function bindPuzzleForms() {
    var forms = document.querySelectorAll("[data-puzzle-form]");
    forms.forEach(function (form) {
      var input = form.querySelector("input");
      var feedback = form.querySelector(".feedback");
      var revealSelector = form.dataset.reveal;
      var successKey = form.dataset.successKey;
      var accepted = (form.dataset.answer || "").split("|").map(normalize);

      if (successKey && progress[successKey]) {
        revealSolvedState(feedback, revealSelector, form.dataset.successMessage || "記録を確認しました。");
      }

      form.addEventListener("submit", function (event) {
        event.preventDefault();
        var value = normalize(input.value);

        if (accepted.indexOf(value) !== -1) {
          if (successKey) {
            progress[successKey] = true;
            saveProgress();
          }
          revealSolvedState(feedback, revealSelector, form.dataset.successMessage || "正解です。");
          return;
        }

        if (feedback) {
          feedback.textContent = form.dataset.errorMessage || "一致しません。別の見方を試してください。";
          feedback.className = "feedback error";
        }
      });
    });
  }

  function revealSolvedState(feedback, revealSelector, message) {
    if (feedback) {
      feedback.textContent = message;
      feedback.className = "feedback success";
    }

    if (revealSelector) {
      var revealed = document.querySelector(revealSelector);
      if (revealed) {
        revealed.classList.remove("hidden");
      }
    }
  }

  function bindHintButtons() {
    var groups = document.querySelectorAll("[data-hints]");
    groups.forEach(function (group) {
      var button = group.querySelector("[data-show-hint]");
      var hints = group.querySelectorAll("[data-hint-step]");
      var shown = 0;

      if (!button || !hints.length) {
        return;
      }

      button.addEventListener("click", function () {
        if (shown < hints.length) {
          hints[shown].classList.remove("hidden");
          shown += 1;
        }

        if (shown >= hints.length) {
          button.disabled = true;
          button.textContent = "これ以上ヒントはありません";
        }
      });
    });
  }

  function bindSecretInput() {
    var form = document.querySelector("[data-secret-form]");
    if (!form) {
      return;
    }

    var input = form.querySelector("input");
    var output = document.querySelector(form.dataset.output);
    var accepted = normalize(form.dataset.answer);

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!output) {
        return;
      }

      if (normalize(input.value) === accepted) {
        output.classList.remove("hidden");
      } else {
        output.classList.add("hidden");
      }
    });
  }

  function renderProgress() {
    var mount = document.querySelector("[data-progress]");
    if (!mount) {
      return;
    }

    var labels = [
      ["puzzle1-solved", "導入復元"],
      ["puzzle2-solved", "記録整理"],
      ["visited:hidden-log", "深層ログ到達"],
      ["puzzle4-solved", "復元完了"]
    ];

    labels.forEach(function (item) {
      var key = item[0];
      var label = item[1];
      var tag = document.createElement("span");
      tag.className = "progress-tag";
      tag.textContent = progress[key] ? "済: " + label : "未: " + label;
      mount.appendChild(tag);
    });
  }
})();
