const https = require('https');

function fetch(url, headers = {}) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...headers
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    }).on('error', reject);
  });
}

async function testProxy() {
  console.log('--- TESTING ALLORIGINS PROXY ---');
  try {
    const res = await fetch('https://api.allorigins.win/raw?url=https%3A%2F%2Ftft-forests.org%2F');
    console.log('AllOrigins status:', res.statusCode, 'bytes:', res.body.length);

    // Let's parse all matches from the homepage HTML!
    // Let's find how matches are structured in tft-forests.org HTML
    const matchHrefs = [...new Set([...res.body.matchAll(/href=["'](https?:\/\/tft-forests\.org\/truc-tiep\/[^"'\/\s]+(?:\/)?)(?:link\/[0-9]+)?["']/gi)].map(x => x[1]))];
    console.log('AllOrigins found unique match links:', matchHrefs.length);
    console.log('First 5 match links:', matchHrefs.slice(0, 5));
  } catch (e) {
    console.log('Allorigins error:', e.message);
  }
}

testProxy();
