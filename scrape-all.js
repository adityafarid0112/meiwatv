const fs = require('fs');

async function scrapeAllCurrent() {
  const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await res.text();
  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi;
  const slugs = [...new Set(html.match(slugRegex) || [])];

  console.log(`Found ${slugs.length} matches`);
  const results = [];

  // Scrape first 10 matches (the most relevant / live ones)
  for (const slug of slugs.slice(0, 15)) {
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

    // Fetch match page to get direct channels
    let streamUrl = `${matchPageUrl}link/0`;
    let server2Url = `${matchPageUrl}link/1`;
    let directChannel = '';

    try {
      const pageRes = await fetch(matchPageUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      const pageHtml = await pageRes.text();
      const listMatch = pageHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
      if (listMatch) {
        const raw = listMatch[1].replace(/\\/g, '');
        const streams = JSON.parse(raw);
        if (streams[0] && streams[0][0]) streamUrl = streams[0][0];
        if (streams[1] && streams[1][0]) server2Url = streams[1][0];
      }
    } catch (e) {}

    results.push({
      title,
      kickoffIso,
      kickoffText,
      streamUrl,
      server2Url,
      postUrl: matchPageUrl
    });
  }

  console.log(JSON.stringify(results, null, 2));
}

scrapeAllCurrent();
