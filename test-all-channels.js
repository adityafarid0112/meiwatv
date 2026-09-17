const https = require('https');

function fetch(url, headers = {}) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        ...headers
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    }).on('error', reject);
  });
}

async function testAllCurrentChannels() {
  const home = await fetch('https://tft-forests.org/');
  const allSlugs = home.body.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi) || [];
  const uniqueSlugs = [...new Set(allSlugs)];
  console.log(`Found ${uniqueSlugs.length} slugs on tft-forests.org`);

  const results = [];

  for (let i = 0; i < Math.min(uniqueSlugs.length, 5); i++) {
    const slug = uniqueSlugs[i];
    const matchUrl = `https://tft-forests.org${slug}`;
    const mPage = await fetch(matchUrl);

    // Extract list_stream
    const listStreamMatch = mPage.body.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
    let channels = [];
    if (listStreamMatch) {
      const raw = listStreamMatch[1].replace(/\\/g, '');
      const parsed = JSON.parse(raw);
      parsed.forEach(group => {
        group.forEach(u => {
          const chMatch = u.match(/link\/(channel[\-_]?[0-9a-zA-Z]+)/i);
          if (chMatch) channels.push(chMatch[1].replace(/[^a-zA-Z0-9]/g, ''));
        });
      });
    }

    console.log(`\nMatch [${i+1}]: ${slug}`);
    console.log(`  Extracted channels:`, channels);

    for (const ch of channels) {
      const flv = `https://live2.zundrixmediapipeline.com/live/${ch}.flv`;
      const m3u8 = `https://live2.zundrixmediapipeline.com/live/${ch}.m3u8`;

      // Test M3U8 status
      const resM = await fetch(m3u8, { 'Origin': 'https://meiwaolaharaga.blogspot.com' });
      console.log(`  Channel ${ch} M3U8 status: ${resM.statusCode}, lines: ${resM.body.split('\n').length}`);
    }
  }
}

testAllCurrentChannels().catch(console.error);
