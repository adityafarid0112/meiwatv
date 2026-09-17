const fs = require('fs');

async function checkStreams() {
  const matches = [
    'inter-miami-vs-cruz-azul-luc-0700-ngay-17-09-2026',
    'atletico-mineiro-vs-santos-luc-0500-ngay-17-09-2026',
    'ldu-quito-vs-palmeiras-luc-0500-ngay-17-09-2026',
    'columbus-crew-vs-orlando-city-luc-0600-ngay-17-09-2026',
    'montreal-impact-vs-vancouver-whitecaps-luc-0600-ngay-17-09-2026'
  ];

  for (const slug of matches) {
    const url = `https://tft-forests.org/truc-tiep/${slug}/`;
    try {
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      const html = await res.text();
      const listMatch = html.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
      console.log(`\n=== MATCH: ${slug} ===`);
      if (listMatch) {
        const raw = listMatch[1].replace(/\\/g, '');
        const streams = JSON.parse(raw);
        console.log('List streams:', JSON.stringify(streams, null, 2));
      } else {
        console.log('No list_stream found. Checking regex for domainkqt / live2...');
        const matches2 = html.match(/https?:\/\/[^\s"']+(?:domainkqt|zundrix|live2|chanel)[^\s"']*/gi);
        console.log('Other URLs:', matches2);
      }
    } catch (e) {
      console.error('Error for', slug, e.message);
    }
  }
}

checkStreams();
