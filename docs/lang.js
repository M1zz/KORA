// Language toggle for KORA support / privacy pages
(function () {
  const KEY = 'kora-pages-lang';
  const buttons = document.querySelectorAll('nav.langs button');
  const sections = document.querySelectorAll('.lang-section');

  function applyLang(code) {
    buttons.forEach(b => b.classList.toggle('active', b.dataset.lang === code));
    sections.forEach(s => {
      const match = s.dataset.lang === code;
      s.classList.toggle('active', match);
      // Toggle the [hidden] attribute too so screen readers + Search bypass it
      if (match) s.removeAttribute('hidden');
      else s.setAttribute('hidden', '');
    });
    document.documentElement.lang = code;
    try { localStorage.setItem(KEY, code); } catch (_) {}
  }

  buttons.forEach(b => {
    b.addEventListener('click', () => applyLang(b.dataset.lang));
  });

  // Restore last choice, else infer from browser
  let initial = null;
  try { initial = localStorage.getItem(KEY); } catch (_) {}
  if (!initial) {
    const nav = (navigator.language || 'ko').slice(0, 2).toLowerCase();
    initial = ['ko', 'ja', 'en'].includes(nav) ? nav : 'ko';
  }
  applyLang(initial);
})();
