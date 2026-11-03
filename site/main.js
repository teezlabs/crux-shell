(() => {
  // name, surface, surfaceLow, surfaceCt, outline, outlineV, primary, primaryCt, tertiary, error, text, muted
  // Taken from Assets/ColorSchemes/*.json (dark); "Wallpaper" is matugen's output for the README wallpaper.
  const PALETTES = [
  ["Wallpaper", "#0d0a07", "#15100a", "#1d1710", "#8a6a45", "#3a2d1e", "#e6a866", "#6b4310", "#c9d9a2", "#ffb4ab", "#efe0cf", "#a8957c"],
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
  const VARS = ["--surface", "--surface-low", "--surface-ct", "--outline", "--outline-v", "--primary", "--primary-ct", "--tertiary", "--error", "--text", "--muted"];
  const root = document.documentElement;
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const $ = (s, el = document) => el.querySelector(s);
  const $$ = (s, el = document) => [...el.querySelectorAll(s)];

  // Theme
  const presets = $("[data-presets]");
  const toast = $("[data-toast]");
  let current = 0;
  let toastTimer;

  PALETTES.forEach((p, i) => {
    const b = document.createElement("button");
    b.type = "button";
    b.className = "preset cham";
    b.setAttribute("role", "radio");
    b.dataset.i = i;
    const sw = [p[6], p[7], p[8], p[3], p[9]].map(c => `<i style="background:${c}"></i>`).join("");
    b.innerHTML = `<span class="swatches">${sw}</span><span class="preset-name">${p[0]}</span>`;
    b.addEventListener("click", () => apply(i, true));
    presets.append(b);
  });

  presets.addEventListener("keydown", e => {
    const d = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    if (!d) return;
    e.preventDefault();
    const n = (current + d + PALETTES.length) % PALETTES.length;
    apply(n, true);
    presets.children[n].focus();
  });

  function apply(i, announce) {
    current = i;
    const p = PALETTES[i];
    VARS.forEach((v, k) => root.style.setProperty(v, p[k + 1]));
    $('meta[name="theme-color"]').content = p[1];
    $$(".preset").forEach((b, k) => {
      b.setAttribute("aria-checked", String(k === i));
      b.tabIndex = k === i ? 0 : -1;
    });
    $$("[data-theme-name]").forEach(el => (el.textContent = p[0]));
    try { localStorage.setItem("crux-theme", p[0]); } catch {}
    if (!announce) return;
    $("[data-toast-name]").textContent = p[0];
    toast.classList.remove("show");
    void toast.offsetWidth;
    toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("show"), 2600);
  }

  let saved = 0;
  try { saved = Math.max(0, PALETTES.findIndex(p => p[0] === localStorage.getItem("crux-theme"))); } catch {}
  apply(saved, false);
  $("[data-cycle]").addEventListener("click", () => apply((current + 1) % PALETTES.length, true));

  // Clock and calendar
  const pad = n => String(n).padStart(2, "0");
  let calDay = -1;
  function tick() {
    const d = new Date();
    const h = pad(d.getHours()), m = pad(d.getMinutes()), s = pad(d.getSeconds());
    const set = (k, v) => $$(`[data-clock="${k}"]`).forEach(el => (el.textContent = v));
    set("hm", `${h}:${m}`);
    set("h", h);
    set("m", m);
    set("hms", `${h}:${m}:${s}`);
    set("date", `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`);
    if (d.getDate() !== calDay) { calDay = d.getDate(); calendar(d); }
  }
  function calendar(d) {
    const y = d.getFullYear(), mo = d.getMonth();
    $("[data-cal-title]").textContent = d.toLocaleString("en", { month: "long" }) + " " + y;
    const first = (new Date(y, mo, 1).getDay() + 6) % 7;
    const days = new Date(y, mo + 1, 0).getDate();
    const prev = new Date(y, mo, 0).getDate();
    let html = ["M", "T", "W", "T", "F", "S", "S"].map(x => `<span class="dow">${x}</span>`).join("");
    for (let k = 0; k < 42; k++) {
      const n = k - first + 1;
      if (n < 1) html += `<span class="out">${prev + n}</span>`;
      else if (n > days) html += `<span class="out">${n - days}</span>`;
      else html += `<span${n === d.getDate() ? ' class="today"' : ""}>${n}</span>`;
    }
    $("[data-cal]").innerHTML = html;
  }
  tick();
  setInterval(tick, 1000);

  // Fireflies
  const sky = $("[data-fireflies]");
  for (let k = 0; k < 34; k++) {
    const f = document.createElement("i");
    f.className = "fly";
    const r = () => Math.random();
    f.style.cssText = `left:${8 + r() * 90}%;top:${10 + r() * 85}%;--o:${(.35 + r() * .6).toFixed(2)};` +
      `--x:${(r() * 40 - 20).toFixed(0)}px;--y:${(r() * -40).toFixed(0)}px;` +
      `--t:${(5 + r() * 7).toFixed(1)}s;--d:${(-r() * 10).toFixed(1)}s;` +
      (r() < .3 ? "width:2px;height:2px;" : "");
    sky.append(f);
  }

  // Copy buttons
  $$("[data-copy]").forEach(b => b.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(b.dataset.copy);
      b.textContent = "Copied";
      b.classList.add("done");
    } catch {
      b.textContent = "Select it";
    }
    setTimeout(() => { b.textContent = "Copy"; b.classList.remove("done"); }, 1600);
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

  // Workspaces follow the section in view
  const links = new Map($$("[data-ws]").map(a => [a.dataset.ws, a]));
  const io = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (!e.isIntersecting) return;
      links.forEach(a => { a.classList.remove("on"); a.removeAttribute("aria-current"); });
      const a = links.get(e.target.id);
      if (a) { a.classList.add("on"); a.setAttribute("aria-current", "true"); }
    });
  }, { rootMargin: "-45% 0px -50% 0px" });
  $$("[data-section]").forEach(s => io.observe(s));

  if (reduced) $$(".fly").forEach(f => (f.style.animation = "none"));
})();
