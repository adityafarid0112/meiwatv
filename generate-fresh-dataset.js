const fs = require('fs');

async function buildFreshDataset() {
  const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await res.text();
  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi;
  const slugs = [...new Set(html.match(slugRegex) || [])];

  const now = new Date().getTime();
  console.log('Now:', new Date(now).toISOString());

  const validMatches = [];
  const seenKeys = new Set();

  for (const s of slugs) {
    const match = s.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (!match) continue;
    const slugName = match[1];
    const timeStr = match[2];
    const day = match[3];
    const month = match[4];
    const year = match[5];
    const hour = timeStr.slice(0, 2);
    const min = timeStr.slice(2, 4);

    const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
    const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
    const matchPageUrl = `https://tft-forests.org/truc-tiep/${slugName}-luc-${timeStr}-ngay-${day}-${month}-${year}/`;

    const rawTitle = slugName.replace(/-/g, ' ');
    const title = rawTitle.replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
    const cleanKey = title.toLowerCase().replace(/[^a-z0-9]/g, '');

    if (seenKeys.has(cleanKey)) continue;
    seenKeys.add(cleanKey);

    const kickoffTime = new Date(kickoffIso).getTime();
    const diff = kickoffTime - now;

    // Filter out matches that started more than 2 hours ago (-7200000 ms)
    if (diff < -7200000) continue;

    let league = "Live Match";
    const lower = title.toLowerCase();
    if (lower.includes('milan') || lower.includes('roma') || lower.includes('parma') || lower.includes('como') || lower.includes('juventus') || lower.includes('napoli') || lower.includes('inter')) {
      league = "Italian Serie A";
    } else if (lower.includes('madrid') || lower.includes('barcelona') || lower.includes('atletico') || lower.includes('sevilla')) {
      league = "La Liga Spain";
    } else if (lower.includes('arsenal') || lower.includes('chelsea') || lower.includes('liverpool') || lower.includes('city') || lower.includes('united') || lower.includes('newcastle')) {
      league = "Premier League";
    } else if (lower.includes('munchen') || lower.includes('dortmund') || lower.includes('leverkusen') || lower.includes('frankfurt')) {
      league = "German Bundesliga";
    } else if (lower.includes('libertadores') || lower.includes('quito') || lower.includes('palmeiras')) {
      league = "Copa Libertadores";
    } else if (lower.includes('champions') || lower.includes('cruz azul') || lower.includes('miami')) {
      league = "CONCACAF Champions Cup";
    } else if (lower.includes('brazil') || lower.includes('bolivia') || lower.includes('argentina') || lower.includes('uruguay')) {
      league = "World Cup Qualifiers";
    }

    const isLive = (diff <= 0 && diff >= -7200000);

    validMatches.push({
      title,
      league,
      streamUrl: `${matchPageUrl}link/0`,
      server2Url: `${matchPageUrl}link/1`,
      postUrl: matchPageUrl,
      kickoffIso,
      kickoffText,
      kickoffTime,
      diff,
      status: isLive ? 0 : 1
    });
  }

  // Sort: Live (0) on top, then upcoming (1) sorted chronologically
  validMatches.sort((a, b) => {
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  console.log(`Total active matches after filtering: ${validMatches.length}`);
  console.log(`Live matches: ${validMatches.filter(m => m.status === 0).length}`);
  console.log(`Upcoming matches: ${validMatches.filter(m => m.status === 1).length}`);

  // Fetch direct channels for top 6 live matches
  for (let i = 0; i < Math.min(8, validMatches.length); i++) {
    const m = validMatches[i];
    try {
      const pageRes = await fetch(m.postUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      const pageHtml = await pageRes.text();
      const listMatch = pageHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
      if (listMatch) {
        const raw = listMatch[1].replace(/\\/g, '');
        const streams = JSON.parse(raw);
        if (streams[0] && streams[0][0]) m.streamUrl = streams[0][0];
        if (streams[1] && streams[1][0]) m.server2Url = streams[1][0];
        else if (streams[0] && streams[0][1]) m.server2Url = streams[0][1];
      }
    } catch (e) {}
  }

  fs.writeFileSync('fresh-active-dataset.json', JSON.stringify(validMatches, null, 2));
  console.log('Saved to fresh-active-dataset.json');
}

buildFreshDataset();
