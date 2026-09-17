const https = require('https');

function fetch(url, headers = {}) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...headers
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    }).on('error', reject);
  });
}

async function main() {
  const url = 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel21/off-tvc?is_off_add=false';
  const res = await fetch(url, { 'Referer': 'https://tft-forests.org/' });
  console.log('--- EMBED PAGE CODE ---');
  console.log(res.body);
}

main().catch(console.error);
