const fs = require('fs');

async function inspectSchedule() {
  const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await res.text();
  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi;
  const slugs = [...new Set(html.match(slugRegex) || [])];

  const now = new Date().getTime();
  console.log('Current local time:', new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' }));
  console.log('Total slugs found on source:', slugs.length);

  const parsed = [];
  slugs.forEach(s => {
    const match = s.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (!match) return;
    const name = match[1];
    const timeStr = match[2];
    const day = match[3];
    const month = match[4];
    const year = match[5];
    const hour = timeStr.slice(0, 2);
    const min = timeStr.slice(2, 4);

    const iso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
    const t = new Date(iso).getTime();
    const diff = t - now;
    const diffHours = (diff / 3600000).toFixed(2);

    parsed.push({
      slug: s,
      slugName: name,
      title: name.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs '),
      time: `${day}/${month}/${year}, ${hour}:${min} WIB`,
      iso,
      diff,
      diffHours: Number(diffHours),
      // 0 = LIVE (kickoff <= now and within 2.5 hours)
      // 1 = UPCOMING (kickoff in future)
      // 2 = SELESAI (kickoff > 2.5 hours ago or earlier today/yesterday)
      status: (diff <= 0 && diff >= -9000000) ? 0 : (diff > 0 ? 1 : 2)
    });
  });

  console.log('\n--- 🏁 SUDAH SELESAI (Status 2 - Dihilangkan) ---');
  const finished = parsed.filter(p => p.status === 2);
  console.log(`Total selesai: ${finished.length}`);
  finished.slice(0, 10).forEach(p => console.log(`[SELESAI ${p.diffHours}h] ${p.title} (${p.time})`));

  console.log('\n--- 🔴 SEDANG LIVE (Status 0 - Paling Atas) ---');
  const live = parsed.filter(p => p.status === 0);
  console.log(`Total live: ${live.length}`);
  live.forEach(p => console.log(`[🔴 LIVE NOW ${p.diffHours}h] ${p.title} (${p.time})`));

  console.log('\n--- ⏳ AKAN DATANG / MENUNGGU (Status 1 - Di bawah Live, urut jam terdekat) ---');
  const upcoming = parsed.filter(p => p.status === 1).sort((a, b) => a.diff - b.diff);
  console.log(`Total upcoming: ${upcoming.length}`);
  upcoming.slice(0, 15).forEach(p => console.log(`[⏳ UPCOMING +${p.diffHours}h] ${p.title} (${p.time})`));
}

inspectSchedule();
