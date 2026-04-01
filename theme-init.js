(function () {
  try {
    var stored = localStorage.getItem("theme");
    var prefersDark =
      window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    var theme =
      stored === "light" || stored === "dark" ? stored : prefersDark ? "dark" : "light";
    document.documentElement.dataset.theme = theme;
  } catch (e) {}
})();
