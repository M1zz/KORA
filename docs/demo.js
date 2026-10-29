// KORA 웹 체험: 공항철도에서 홍대입구 출발, 내릴 역을 고르면 타는 방향과 하차 알림을 앱과 같은 규칙으로 보여 준다.
// 역 순서는 SubwayLineData.line10, 역 이름 표기는 SubwayStationLocale · SubwayStationChinese(Traditional)Names,
// 알림 단계는 AlightWarningLevel.from(stopsRemaining:) 과 같다: 0 지금 내리세요 · 1 다음 정거장 · 2~3 준비 · 그 밖 내릴 역.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang;

  // [한글, 영문(역 표지판), 가타카나, 简体, 繁體]
  const LINE = [
    ["서울역", "Seoul Station", "ソウルヨク", "首尔站", "首爾站"],
    ["공덕", "Gongdeok", "コンドク", "孔德", "孔德"],
    ["홍대입구", "Hongik Univ.", "ホンデイック", "弘大入口", "弘大入口"],
    ["디지털미디어시티", "Digital Media City", "デジタルメディアシティ", "数码媒体城", "數碼媒體城"],
    ["마곡나루", "Magok Naru", "マゴクナル", "麻谷渡口", "麻谷渡口"],
    ["김포공항", "Gimpo Int'l Airport", "キンポゴンハン", "金浦机场", "金浦機場"],
    ["계양", "Gyeyang", "ケヤン", "桂阳", "桂陽"],
    ["검암", "Geomam", "コマム", "黔岩", "黔岩"],
    ["청라국제도시", "Cheongna Int'l City", "チョンナクッチェドシ", "青罗国际城", "青羅國際城"],
    ["영종", "Yeongjong", "ヨンジョン", "永宗", "永宗"],
    ["운서", "Unseo", "ウンソ", "云西", "雲西"],
    ["공항화물청사", "Airport Cargo Terminal", "コンハンファムルチョンサ", "机场货物厅舍", "機場貨物廳捨"],
    ["인천공항1터미널", "Incheon Int'l Airport T1", "インチョンコンハンT1", "仁川机场T1", "仁川機場T1"],
    ["인천공항2터미널", "Incheon Int'l Airport T2", "インチョンコンハンT2", "仁川机场T2", "仁川機場T2"],
  ];
  const START = 2, DESTS = [0, 5, 12];
  const col = { ko: -1, ja: 2, "zh-Hans": 3, "zh-Hant": 4 }[lang] ?? 1;
  const local = i => (col < 0 ? "" : LINE[i][col]);   // 한국어 페이지는 한글만
  const plain = i => local(i) || LINE[i][0];
  const label = i => `<b>${LINE[i][0]}</b>${local(i) ? `<small>${local(i)}</small>` : ""}`;
  const fmt = (s, v) => s.replace("{0}", v);
  // 남은 정거장 문구: 언어마다 복수형이 달라서 left 에 {one, few, many, other} 로 둔다.
  const plural = new Intl.PluralRules(lang);
  const leftText = n => fmt(T.left[plural.select(n)] || T.left.other, n);

  const LEVELS = ["now", "imminent", "prepare", "prepare"];
  const level = left => LEVELS[left] || "calm";

  const state = { dest: 12, cur: START, riding: false, used: false };
  let timer;

  root.innerHTML = `
    <div class="kd-stage">
      <p class="kd-status"><span class="kd-badge">AR</span><span class="kd-state"></span></p>
      <div class="kd-track" aria-hidden="true"></div>
      <p class="kd-here"></p>
      <div class="kd-alert" aria-live="polite">
        <span class="kd-head"></span>
        <span class="kd-dest"></span>
        <span class="kd-left"></span>
      </div>
    </div>
    <div class="kd-controls">
      <p class="kd-from">${T.from}: ${label(START)}</p>
      <p class="kd-ask">${T.pick}</p>
      <div class="kd-chips">
        ${DESTS.map(i => `<button type="button" class="chip" data-dest="${i}" aria-pressed="false">${plain(i)}</button>`).join("")}
      </div>
      <div class="kd-sign" hidden><span class="muted small">${T.take}</span><strong></strong></div>
      <button type="button" class="kd-go">${T.go}</button>
      <p class="muted small kd-note">${T.note}</p>
    </div>`;

  const $ = s => root.querySelector(s);
  const track = $(".kd-track"), here = $(".kd-here"), alertEl = $(".kd-alert"), go = $(".kd-go");

  function render() {
    const d = state.dest;
    $(".kd-state").textContent = state.riding || state.cur !== START ? T.onBoard : T.before;
    root.querySelectorAll("[data-dest]").forEach(b => {
      const on = +b.dataset.dest === d;
      b.setAttribute("aria-pressed", on);
      b.disabled = state.riding;
    });
    go.disabled = d === null || state.riding;
    go.classList.toggle("hint", !state.used);
    go.textContent = d !== null && state.cur === d ? T.again : T.go;
    if (d === null) { track.innerHTML = ""; here.innerHTML = ""; alertEl.hidden = true; return; }

    const step = d < START ? -1 : 1, seg = [];
    for (let i = START; i !== d + step; i += step) seg.push(i);
    track.innerHTML = seg.map(i => `<i class="${i === state.cur ? "on" : ""}${i === d ? " end" : ""}${
      (i - state.cur) * step < 0 ? " past" : ""}"></i>`).join("");
    here.innerHTML = `<span class="muted small">${T.current}</span> ${label(state.cur)}`;

    const sign = $(".kd-sign");
    sign.hidden = false;
    sign.querySelector("strong").textContent = fmt(T.bound, plain(d < START ? 0 : LINE.length - 1));

    const left = Math.abs(d - state.cur), lv = level(left);
    alertEl.hidden = false;
    alertEl.dataset.level = lv;
    $(".kd-head").textContent = T[lv];
    $(".kd-dest").innerHTML = label(d);
    $(".kd-left").textContent = left ? leftText(left) : "";
  }

  function ride() {
    clearInterval(timer);
    state.used = true;
    state.cur = START; state.riding = true; render();
    timer = setInterval(() => {
      state.cur += state.dest < START ? -1 : 1;
      if (state.cur === state.dest) { state.riding = false; clearInterval(timer); go.focus(); }
      render();
    }, 1300);
  }

  root.addEventListener("click", e => {
    const chip = e.target.closest("[data-dest]");
    if (chip) { state.dest = +chip.dataset.dest; state.cur = START; render(); }
    if (e.target.closest(".kd-go")) ride();
  });

  render();
})();
