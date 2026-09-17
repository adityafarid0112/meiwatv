const https = require('https');

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

async function testClientSideScraper() {
  console.log('--- TESTING CLIENT-SIDE SCRAPER ---');
  const rawHtml = await fetch('https://api.allorigins.win/raw?url=https%3A%2F%2Ftft-forests.org%2F');
  console.log('Received HTML bytes:', rawHtml.length);

  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi;
  const allSlugs = rawHtml.match(slugRegex) || [];
  const uniqueSlugs = [...new Set(allSlugs)];
  console.log('Unique slugs found:', uniqueSlugs.length);

  const now = new Date().getTime();
  const parsedMatches = [];

  uniqueSlugs.forEach(slug => {
    const parsed = slug.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (!parsed) return;

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

    let status = 1; // 0 = LIVE NOW, 1 = UPCOMING, 2 = FINISHED
    if (diff <= 0 && diff > -10800000) {
      status = 0; // SEDANG LIVE
    } else if (diff <= -10800000) {
      status = 2; // SELESAI
    }

    if (status !== 2) {
      let league = "Live Match";
      const lower = title.toLowerCase();
      if (lower.includes('milan') || lower.includes('roma') || lower.includes('parma') || lower.includes('como') || lower.includes('juventus') || lower.includes('napoli') || lower.includes('inter')) {
        league = "Italian Serie A";
      } else if (lower.includes('madrid') || lower.includes('barcelona') || lower.includes('atletico') || lower.includes('sevilla')) {
        league = "La Liga Spain";
      } else if (lower.includes('arsenal') || lower.includes('chelsea') || lower.includes('liverpool') || lower.includes('city') || lower.includes('united') || lower.includes('newcastle')) {
        league = "Premier League";
      } else if (lower.includes('munchen') || lower.includes('dortmund') || lower.includes('leverkusen')) {
        league = "German Bundesliga";
      } else if (lower.includes('libertadores') || lower.includes('quito') || lower.includes('palmeiras')) {
        league = "Copa Libertadores";
      } else if (lower.includes('champions') || lower.includes('cruz azul') || lower.includes('miami')) {
        league = "CONCACAF Champions Cup";
      }

      parsedMatches.push({
        title,
        postUrl: matchPageUrl,
        streamUrl: `${matchPageUrl}link/0`,
        server2Url: `${matchPageUrl}link/1`,
        kickoffIso,
        kickoffText,
        kickoffTime,
        status,
        league
      });
    }
  });

  parsedMatches.sort((a, b) => {
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  console.log(`\nParsed ${parsedMatches.length} active matches!`);
  console.log('Top 5 matches:');
  parsedMatches.slice(0, 5).forEach((m, idx) => {
    console.log(` ${idx+1}. [${m.status === 0 ? 'LIVE NOW' : 'UPCOMING'}] ${m.title} (${m.kickoffText}) - ${m.league}`);
  });
}

testClientSideScraper().catch(console.error);
