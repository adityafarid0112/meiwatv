const SEED_DOMAINS = [
  'https://xoilacz.vip/',
  'https://tft-forests.org/',
  'https://xoilaczbj.tv/',
  'https://xoilac.org/'
];

async function testAllMatches() {
  console.log('Fetching homepage with dynamic redirect detection...');
  let res;
  let activeDomain = '';
  for (const seed of SEED_DOMAINS) {
    try {
      console.log(`Checking seed: ${seed}`);
      res = await fetch(seed, {
        redirect: 'follow',
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
      });
      if (res.ok) {
        activeDomain = new URL(res.url).origin;
        console.log(`✅ Connected! Dynamic Domain Resolved: ${activeDomain}`);
        break;
      }
    } catch (e) {
      console.warn(`Seed failed: ${seed}`);
    }
  }

  const html = await res.text();
  const allSlugs = html.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi) || [];
  const uniqueSlugs = [...new Set(allSlugs)];
  console.log(`Found ${uniqueSlugs.length} unique match slugs.`);

  for (const slug of uniqueSlugs.slice(0, 3)) {
    const matchUrl = activeDomain + slug;
    console.log('\n--- Checking:', matchUrl);
    const mRes = await fetch(matchUrl, {
      redirect: 'follow',
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
    });
    const mHtml = await mRes.text();

    const listStreamMatch = mHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
    if (listStreamMatch) {
      try {
        const rawJson = listStreamMatch[1].replace(/\\/g, '');
        const listStream = JSON.parse(rawJson);
        console.log('List stream extracted:', listStream);
        const server1 = listStream[0] && listStream[0][0] ? listStream[0][0] + '/off-tvc?is_off_add=false' : '';
        const server2 = listStream[1] && listStream[1][0] ? listStream[1][0] + '/off-tvc?is_off_add=false' : (listStream[0] && listStream[0][1] ? listStream[0][1] + '/off-tvc?is_off_add=false' : '');
        console.log('Server 1 Embed:', server1);
        console.log('Server 2 Embed:', server2);
      } catch (e) {
        console.error('JSON parse error:', e.message);
      }
    } else {
      console.log('No list_stream found on this match page.');
    }
  }
}

testAllMatches();
