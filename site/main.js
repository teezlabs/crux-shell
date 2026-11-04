(() => {
  const $$ = s => [...document.querySelectorAll(s)];

  $$("[data-copy]").forEach(b => b.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(b.dataset.copy);
      b.classList.add("done");
      b.setAttribute("aria-label", "Copied");
      setTimeout(() => { b.classList.remove("done"); b.setAttribute("aria-label", "Copy install command"); }, 1500);
    } catch {}
  }));

  // Reveal on scroll; without JS or with reduced motion everything is simply visible.
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  document.documentElement.classList.add("js");
  const io = new IntersectionObserver(entries => entries.forEach(e => {
    if (!e.isIntersecting) return;
    e.target.classList.add("in");
    io.unobserve(e.target);
  }), { rootMargin: "0px 0px -8% 0px" });
  $$(".reveal").forEach(el => io.observe(el));
})();
