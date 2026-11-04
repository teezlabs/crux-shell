(() => {
  // name, surface, surfaceLow, surfaceCt, outline, outlineV, primary, primaryCt, tertiary, error, text, muted
  // Presets come from Assets/ColorSchemes/*.json (dark variants).
  const PALETTES = [
  ["Default", "#0a0a0b", "#111113", "#18181b", "#34343a", "#232327", "#e6a866", "#4a3115", "#c9d9a2", "#ffb4ab", "#ededef", "#8f8f98"],
  ["Ayu", "#0b0e14", "#13161d", "#1e222a", "#565b66", "#2d3139", "#e6b450", "#53411d", "#39bae6", "#d95757", "#d1d1c7", "#8e959e"],
  ["Catppuccin", "#1e1e2e", "#262637", "#313244", "#4c4f69", "#333449", "#cba6f7", "#493c59", "#94e2d5", "#f38ba8", "#cdd6f4", "#a3b4eb"],
  ["Crux", "#070722", "#0b0b26", "#11112d", "#21215f", "#13133d", "#fff59b", "#5c5838", "#9bfece", "#fd4663", "#f3edf7", "#7c80b4"],
  ["Dracula", "#282a36", "#2d2f3d", "#44475a", "#6272a4", "#464a63", "#bd93f9", "#453465", "#ff79c6", "#ff5555", "#f8f8f2", "#e2e2f7"],
  ["Eldritch", "#212337", "#24273b", "#292e42", "#3b4261", "#2d314a", "#37f499", "#145837", "#a48cf2", "#f16c75", "#ebfafa", "#abb4da"],
  ["Everforest", "#2b3339", "#303a40", "#3a454a", "#4a555b", "#384247", "#a7c080", "#3d4a30", "#e67e80", "#e67e80", "#d3c6aa", "#c6d1c1"],
  ["Gruvbox", "#282828", "#2d2c2a", "#3c3836", "#504945", "#3a3532", "#fabd2f", "#5a4310", "#fb4934", "#fb4934", "#ebdbb2", "#d5c4a1"],
  ["Kanagawa", "#1f1f28", "#23232e", "#2a2a37", "#363646", "#292936", "#76946a", "#2a3526", "#7e9cd8", "#c34043", "#c8c093", "#717c7c"],
  ["Mocha", "#1e1e2e", "#232334", "#313244", "#45475a", "#33344a", "#89b4fa", "#2c3e5c", "#f38ba8", "#f38ba8", "#cdd6f4", "#a6adc8"],
  ["Nord", "#2e3440", "#333a48", "#3b4252", "#4c566a", "#3a4152", "#88c0d0", "#2e4650", "#bf616a", "#bf616a", "#eceff4", "#d8dee9"],
  ["Rosé Pine", "#191724", "#1e1c2d", "#26233a", "#403d52", "#2b2839", "#ebbcba", "#554443", "#31748f", "#eb6f92", "#e0def4", "#908caa"],
  ["Tokyo Night", "#1a1b26", "#1e202e", "#24283b", "#353d57", "#262a3c", "#7aa2f7", "#2c3a59", "#9ece6a", "#f7768e", "#c0caf5", "#9aa5ce"],
  ];

  // Page var for each palette column above, by index; error isn't used on the page.
  const VARS = [null, "--bg", "--surface", "--raised", "--line-strong", "--line", "--accent", "--accent-ct", "--tertiary", null, "--text", "--muted"];
  const root = document.documentElement;
  const $ = s => document.querySelector(s);
  const $$ = s => [...document.querySelectorAll(s)];

  // Presets
  const presets = $("[data-presets]");
  let current = 0;
  PALETTES.forEach((p, i) => {
    const b = document.createElement("button");
    b.type = "button";
    b.className = "preset";
    b.setAttribute("role", "radio");
    const sw = [p[6], p[8], p[7], p[3]].map(c => `<i style="background:${c}"></i>`).join("");
    b.innerHTML = `<span class="sw" aria-hidden="true">${sw}</span>${p[0]}`;
    b.addEventListener("click", () => apply(i));
    presets.append(b);
  });
  presets.addEventListener("keydown", e => {
    const d = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    if (!d) return;
    e.preventDefault();
    const n = (current + d + PALETTES.length) % PALETTES.length;
    apply(n);
    presets.children[n].focus();
  });
  function apply(i) {
    current = i;
    const p = PALETTES[i];
    VARS.forEach((v, k) => v && root.style.setProperty(v, p[k]));
    $('meta[name="theme-color"]').content = p[1];
    [...presets.children].forEach((b, k) => {
      b.setAttribute("aria-checked", String(k === i));
      b.tabIndex = k === i ? 0 : -1;
    });
  }
  apply(0);

  // Copy buttons
  $$("[data-copy]").forEach(b => b.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(b.dataset.copy);
      b.classList.add("done");
      b.setAttribute("aria-label", "Copied");
      setTimeout(() => { b.classList.remove("done"); b.setAttribute("aria-label", "Copy"); }, 1500);
    } catch {}
  }));

  // Install tabs
  const tabs = $$('[role="tab"]');
  function select(t) {
    tabs.forEach(x => {
      const on = x === t;
      x.setAttribute("aria-selected", String(on));
      x.tabIndex = on ? 0 : -1;
      document.getElementById(x.getAttribute("aria-controls")).hidden = !on;
    });
  }
  tabs.forEach((t, i) => {
    t.addEventListener("click", () => select(t));
    t.addEventListener("keydown", e => {
      const d = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
      if (!d) return;
      const n = tabs[(i + d + tabs.length) % tabs.length];
      select(n);
      n.focus();
    });
  });
})();
