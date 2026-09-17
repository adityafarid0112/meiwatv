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
  console.log('--- FETCHING EMBED URL ---', url);

  // Test 1: with Referer: https://tft-forests.org/
  const resWithRef = await fetch(url, { 'Referer': 'https://tft-forests.org/' });
  console.log('With tft-forests referer - status:', resWithRef.statusCode, 'bytes:', resWithRef.body.length);
  console.log('Body snippet:\n', resWithRef.body.slice(0, 1500));

  // Test 2: without referer or with blog referer
  const resWithBlog = await fetch(url, { 'Referer': 'https://meiwaolaharaga.blogspot.com/' });
  console.log('\nWith blogspot referer - status:', resWithBlog.statusCode, 'bytes:', resWithBlog.body.length);
  console.log('Body snippet:\n', resWithBlog.body.slice(0, 500));
}

main().catch(console.error);
