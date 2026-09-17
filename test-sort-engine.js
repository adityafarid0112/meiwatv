const fs = require('fs');

// Test data simulating raw matches from Blogger + live scraper
const sampleMatches = [
  { title: "Eintracht Frankfurt vs All For One", kickoffIso: "2026-09-17T23:00:00+07:00", kickoffText: "17/09/2026, 23:00 WIB", league: "German Bundesliga" },
  { title: "Inter Miami vs Cruz Azul", kickoffIso: "2026-09-17T07:00:00+07:00", kickoffText: "17/09/2026, 07:00 WIB", league: "CONCACAF Champions Cup" },
  { title: "Old Match Yesterday", kickoffIso: "2026-09-16T02:00:00+07:00", kickoffText: "16/09/2026, 02:00 WIB", league: "Premier League" },
  { title: "Atletico Mineiro vs Santos", kickoffIso: "2026-09-17T05:00:00+07:00", kickoffText: "17/09/2026, 05:00 WIB", league: "La Liga Spain" },
  { title: "Montreal Impact vs Vancouver Whitecaps", kickoffIso: "2026-09-17T06:00:00+07:00", kickoffText: "17/09/2026, 06:00 WIB", league: "Live Match" },
  { title: "Liverpool vs Arsenal (Tomorrow)", kickoffIso: "2026-09-18T20:00:00+07:00", kickoffText: "18/09/2026, 20:00 WIB", league: "Premier League" }
];

function testProcessAndSort(rawMatches) {
  const now = new Date().getTime();
  const validMatches = [];
  const seenTitles = new Set();

  rawMatches.forEach(m => {
    if (!m) return;
    const title = (m.title || "Live Match").trim();
    const cleanKey = title.toLowerCase().replace(/[^a-z0-9]/g, '');
    if (seenTitles.has(cleanKey)) return;
    seenTitles.add(cleanKey);

    const kickoffIso = m.kickoffIso || "";
    const kickoffText = m.kickoffText || "";
    const league = m.league || "Live Match";

    let kickoffTime = 0;
    if (kickoffIso) {
      const parsed = new Date(kickoffIso).getTime();
      if (!isNaN(parsed)) kickoffTime = parsed;
    }

    const diff = kickoffTime ? (kickoffTime - now) : 0;

    let status = 1;
    if (kickoffTime) {
      if (diff <= 0 && diff >= -9000000) {
        status = 0; // 🔴 SEDANG LIVE
      } else if (diff < -9000000) {
        status = 2; // 🏁 SELESAI
      } else {
        status = 1; // ⏳ MENUNGGU
      }
    } else {
      status = 0;
    }

    if (status !== 2) {
      validMatches.push({
        title,
        league,
        kickoffIso,
        kickoffText,
        kickoffTime: kickoffTime || now,
        diff,
        status,
        statusLabel: status === 0 ? '🔴 LIVE NOW' : '⏳ MENUNGGU'
      });
    }
  });

  validMatches.sort((a, b) => {
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  return validMatches;
}

const sorted = testProcessAndSort(sampleMatches);
console.log('=== HASIL SORTING & FILTERING ===');
sorted.forEach((m, idx) => {
  console.log(`${idx + 1}. [${m.statusLabel}] ${m.title} (${m.kickoffText})`);
});
