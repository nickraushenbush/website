(function () {
  var btn = document.getElementById("theme-toggle");
  if (!btn) return;

  function getTheme() {
    return document.documentElement.dataset.theme === "dark" ? "dark" : "light";
  }

  function applyTheme(theme, persist) {
    document.documentElement.dataset.theme = theme;
    if (persist) {
      try {
        localStorage.setItem("theme", theme);
      } catch (e) {}
    }

    var isDark = theme === "dark";
    btn.setAttribute("aria-checked", isDark ? "true" : "false");
    btn.setAttribute(
      "aria-label",
      isDark ? "Switch to light mode" : "Switch to dark mode"
    );
  }

  applyTheme(getTheme(), false);

  btn.addEventListener("click", function () {
    var next = getTheme() === "dark" ? "light" : "dark";
    applyTheme(next, true);
  });
})();
