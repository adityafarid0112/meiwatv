const fs = require('fs');

async function inspectLiveHtml() {
  const SEEDS = [
    'https://xoilacz.vip/',
    'https://tft-forests.org/',
    'https://socolivezc.tv/',
    'https://xoilackl.tv/',
    'https://90phutcn.tv/',
    'https://cakhiazkv.cc/',
    'https://xoilaccu.tv/'
  ];

  let html = '';
  let domain = '';
  for (const seed of SEEDS) {
    try {
      console.log('Fetching', seed);
      const res = await fetch(seed, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' },
        signal: AbortSignal.timeout(8000)
      });
      if (res.ok) {
        const text = await res.text();
        if (text.includes('grid-matches__item') || text.includes('match-item')) {
          html = text;
          domain = new URL(res.url).origin;
          console.log('✅ Found HTML from', domain);
          break;
        }
      }
    } catch(e) {
      console.log('Error', seed, e.message);
    }
  }

  if (!html) {
    console.log('No HTML fetched');
    return;
  }

  fs.writeFileSync('live_source_dump.html', html, 'utf8');

  // Find all cards
  const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/gi;
  let m;
  let count = 0;
  while ((m = cardRegex.exec(html)) !== null && count < 5) {
    count++;
    console.log(`\n================ CARD ${count} ================\n`);
    console.log(m[0]);
  }
}

inspectLiveHtml();
