const slides = Array.from(document.querySelectorAll('.slide'));
const progress = document.getElementById('progress');
const counter = document.getElementById('counter');
const toc = document.getElementById('toc');
const prevBtn = document.getElementById('prev');
const nextBtn = document.getElementById('next');
const navLabel = document.getElementById('nav-label');
const orLabel = document.getElementById('or-label');
const langBtns = Array.from(document.querySelectorAll('.lang-toggle .lang'));
let i = 0;

// ---------- language ----------
// Korean copy travels with the markup in data-ko attributes. The first swap
// stashes the English original in data-en, so toggling back is lossless and
// nothing has to be duplicated slide-for-slide.
const LANG_KEY = 'agents-deck-lang';
const UI = {
  en: { title: 'Agents in the Terminal', slide: 'slide ', nav: 'navigate with', or: 'or', prev: 'prev', next: 'next' },
  ko: { title: 'Terminal 속의 Agent', slide: '슬라이드 ', nav: '이동', or: '또는', prev: '이전', next: '다음' },
};
let lang = 'en';
try { if (localStorage.getItem(LANG_KEY) === 'ko') lang = 'ko'; } catch (e) { /* file:// with storage off */ }

function setLang(next) {
  lang = next === 'ko' ? 'ko' : 'en';
  document.documentElement.lang = lang;
  document.title = UI[lang].title;

  document.querySelectorAll('[data-ko]').forEach(el => {
    if (el.dataset.en === undefined) el.dataset.en = el.innerHTML;
    el.innerHTML = lang === 'ko' ? el.dataset.ko : el.dataset.en;
  });

  navLabel.textContent = UI[lang].nav;
  orLabel.textContent = UI[lang].or;
  prevBtn.textContent = UI[lang].prev;
  nextBtn.textContent = UI[lang].next;
  langBtns.forEach(b => {
    const on = b.dataset.lang === lang;
    b.classList.toggle('on', on);
    b.setAttribute('aria-pressed', String(on));
  });

  buildToc();
  show(i);
  try { localStorage.setItem(LANG_KEY, lang); } catch (e) { /* ignore */ }
}

function show(n) {
  i = Math.max(0, Math.min(slides.length - 1, n));
  slides.forEach((s, j) => s.classList.toggle('active', j === i));
  progress.style.width = ((i + 1) / slides.length * 100) + '%';
  const pad = x => String(x).padStart(2, '0');
  counter.textContent = UI[lang].slide + pad(i + 1) + '/' + pad(slides.length);
  location.hash = i + 1;
}

document.addEventListener('keydown', e => {
  if (['ArrowRight', ' ', 'PageDown'].includes(e.key)) { e.preventDefault(); show(i + 1); }
  if (['ArrowLeft', 'PageUp'].includes(e.key)) { e.preventDefault(); show(i - 1); }
  if (e.key === 'Home') show(0);
  if (e.key === 'End') show(slides.length - 1);
  if (e.key === 'l' || e.key === 'L') setLang(lang === 'ko' ? 'en' : 'ko');
});
nextBtn.addEventListener('click', () => show(i + 1));
prevBtn.addEventListener('click', () => show(i - 1));
langBtns.forEach(b => b.addEventListener('click', () => setLang(b.dataset.lang)));

// The table of contents is built from the slides that carry a data-section
// label, so reordering slides never means hand-patching indices here.
function buildToc() {
  if (!toc) return;
  toc.textContent = '';
  slides.forEach((slide, j) => {
    const label = lang === 'ko' && slide.dataset.sectionKo ? slide.dataset.sectionKo : slide.dataset.section;
    if (!label) return;
    const item = document.createElement('button');
    item.className = 'toc-item';
    item.innerHTML = '<span class="toc-n"></span><span class="toc-title"></span>';
    item.querySelector('.toc-n').textContent = String(toc.children.length + 1).padStart(2, '0');
    item.querySelector('.toc-title').textContent = label;
    item.addEventListener('click', () => show(j));
    toc.appendChild(item);
  });
}

const fromHash = parseInt(location.hash.slice(1), 10);
i = isNaN(fromHash) ? 0 : Math.max(0, Math.min(slides.length - 1, fromHash - 1));
setLang(lang);

window.addEventListener('hashchange', () => {
  const n = parseInt(location.hash.slice(1), 10);
  if (!isNaN(n)) show(n - 1);
});
