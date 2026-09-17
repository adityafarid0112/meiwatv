const https = require('https');
const http = require('http');

function fetch(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...headers
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    });
    req.on('error', reject);
    req.setTimeout(8000, () => {
      req.destroy();
      reject(new Error('Timeout ' + url));
    });
  });
}

const proxies = [
  'https://corsproxy.io/?url=https%3A%2F%2Ftft-forests.org%2F',
  'https://api.codetabs.com/v1/proxy?quest=https%3A%2F%2Ftft-forests.org%2F',
  'https://thingproxy.freeboard.io/fetch/https://tft-forests.org/',
  'https://api.allorigins.win/get?url=' + encodeURIComponent('https://tft-forests.org/'),
  'https://api.allorigins.win/raw?url=' + encodeURIComponent('https://tft-forests.org/')
];

async function testProxies() {
  for (const p of proxies) {
    console.log('Testing proxy:', p.slice(0, 60));
    try {
      const res = await fetch(p);
      console.log('  Status:', res.statusCode, 'Body length:', res.body.length);
      if (res.body.includes('truc-tiep')) {
        const slugs = res.body.match(/\/truc-tiep\/[a-z0-9\-]+-luc-\d{4}-ngay-\d{2}-\d{2}-\d{4}\//gi) || [];
        console.log('  ✅ SUCCESS! Found match slugs:', slugs.length);
      } else {
        console.log('  ⚠️ Response snippet:', res.body.slice(0, 150));
      }
    } catch (e) {
      console.log('  ❌ Error:', e.message);
    }
  }
}

testProxies();
