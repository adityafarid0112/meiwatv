const fs = require('fs');

async function getAllMatches() {
  const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await res.text();
  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi;
  const slugs = [...new Set(html.match(slugRegex) || [])];

  console.log(`Total slugs found: ${slugs.length}`);

  const matches = [];
  const now = new Date().getTime();

  for (const slug of slugs) {
    const parsed = slug.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (!parsed) continue;

    const slugName = parsed[1];
    const rawTitle = slugName.replace(/-/g, ' ');
    const title = rawTitle.replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
    const timeStr = parsed[2];
    const day = parsed[3];
    const month = parsed[4];
    const year = parsed[5];
    const hour = timeStr.slice(0, 2);
    const min = timeStr.slice(2, 4);

    const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
    const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
    const matchPageUrl = `https://tft-forests.org/truc-tiep/${slugName}-luc-${timeStr}-ngay-${day}-${month}-${year}/`;

    const kickoffTime = new Date(kickoffIso).getTime();
    const diff = kickoffTime - now;

    // Deteksi liga
    let league = "Live Match";
    const lower = title.toLowerCase();
    if (lower.includes('milan') || lower.includes('roma') || lower.includes('parma') || lower.includes('como') || lower.includes('juventus') || lower.includes('napoli') || lower.includes('inter')) {
      league = "Italian Serie A";
    } else if (lower.includes('madrid') || lower.includes('barcelona') || lower.includes('atletico') || lower.includes('sevilla') || lower.includes('santos')) {
      league = "La Liga Spain";
    } else if (lower.includes('arsenal') || lower.includes('chelsea') || lower.includes('liverpool') || lower.includes('city') || lower.includes('united') || lower.includes('newcastle')) {
      league = "Premier League";
    } else if (lower.includes('munchen') || lower.includes('dortmund') || lower.includes('leverkusen') || lower.includes('frankfurt')) {
      league = "German Bundesliga";
    } else if (lower.includes('libertadores') || lower.includes('quito') || lower.includes('palmeiras')) {
      league = "Copa Libertadores";
    } else if (lower.includes('champions') || lower.includes('cruz azul') || lower.includes('miami')) {
      league = "CONCACAF Champions Cup";
    } else if (lower.includes('brazil') || lower.includes('bolivia') || lower.includes('argentina') || lower.includes('uruguay') || lower.includes('colombia')) {
      league = "World Cup Qualifiers";
    }

    matches.push({
      title,
      league,
      slug,
      slugName,
      kickoffIso,
      kickoffText,
      kickoffTime,
      diff,
      matchPageUrl
    });
  }

  // Filter out matches older than 2.5 hours (-9000000 ms)
  const activeAndUpcoming = matches.filter(m => m.diff > -9000000);

  // Sort: Live first (diff <= 0), then upcoming by earliest kickoff
  activeAndUpcoming.sort((a, b) => {
    const aLive = (a.diff <= 0 && a.diff > -9000000) ? 0 : 1;
    const bLive = (b.diff <= 0 && b.diff > -9000000) ? 0 : 1;
    if (aLive !== bLive) return aLive - bLive;
    return a.kickoffTime - b.kickoffTime;
  });

  console.log(`Active & Upcoming matches count: ${activeAndUpcoming.length}`);
  console.log('Top 15 sorted matches:');
  activeAndUpcoming.slice(0, 15).forEach((m, i) => {
    const isLive = (m.diff <= 0);
    console.log(`${i+1}. [${isLive ? '🔴 LIVE' : '⏳ UPCOMING'}] ${m.title} (${m.kickoffText}) - ${m.league}`);
  });

  fs.writeFileSync('sorted-scraped-matches.json', JSON.stringify(activeAndUpcoming, null, 2));
}

getAllMatches();
