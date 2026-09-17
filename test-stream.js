const https = require('https');
const http = require('http');

function fetch(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...headers
      }
    }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirectUrl = res.headers.location;
        if (!redirectUrl.startsWith('http')) {
          const u = new URL(url);
          redirectUrl = u.origin + redirectUrl;
        }
        return resolve(fetch(redirectUrl, headers));
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    });
    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Timeout ' + url));
    });
  });
}

async function main() {
  console.log('--- FETCHING TFT-FORESTS HOMEPAGE ---');
  const home = await fetch('https://tft-forests.org/');
  console.log('Homepage status:', home.statusCode, 'bytes:', home.body.length);

  // Look for any /truc-tiep/ links
  const trucTiepMatches = [...home.body.matchAll(/href=["']([^"']*truc-tiep[^"']*)["']/gi)].map(x => x[1]);
  console.log('Found /truc-tiep/ hrefs:', trucTiepMatches.length);
  console.log('Sample truc-tiep hrefs:', trucTiepMatches.slice(0, 5));

  // Also look for match titles, team names, or match item elements
  const matchCards = [...home.body.matchAll(/class=["'][^"']*(match|item|event|league)[^"']*["']/gi)].slice(0, 10);
  console.log('Sample classes:', matchCards.map(x => x[0]));

  if (trucTiepMatches.length > 0) {
    let firstUrl = trucTiepMatches[0];
    if (!firstUrl.startsWith('http')) firstUrl = 'https://tft-forests.org' + (firstUrl.startsWith('/') ? '' : '/') + firstUrl;
    console.log('\n--- FETCHING FIRST MATCH PAGE:', firstUrl, '---');
    const matchPage = await fetch(firstUrl);
    console.log('Match page size:', matchPage.body.length);

    // Look for video, iframe, embed, scripts, streams
    const iframes = [...matchPage.body.matchAll(/<iframe[^>]+src=["']([^"']+)["']/gi)].map(x => x[1]);
    console.log('Iframes on match page:', iframes);

    const scriptUrls = [...matchPage.body.matchAll(/<script[^>]+src=["']([^"']+)["']/gi)].map(x => x[1]);
    console.log('Scripts on match page:', scriptUrls.slice(0, 10));

    const domainkqt = [...matchPage.body.matchAll(/https?:\/\/[^"'\s<>]+domainkqt[^"'\s<>]*/gi)].map(x => x[0]);
    console.log('domainkqt matches:', domainkqt);

    const channels = [...matchPage.body.matchAll(/(channel[\-_]?[0-9a-zA-Z]+)/gi)].map(x => x[0]);
    console.log('channels:', [...new Set(channels)]);

    // Check inline scripts for stream links
    const scripts = [...matchPage.body.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)].map(x => x[1]);
    for (const sc of scripts) {
      if (sc.includes('flv') || sc.includes('m3u8') || sc.includes('channel') || sc.includes('player') || sc.includes('source') || sc.includes('stream')) {
        console.log('\nFound interesting script snippet:');
        console.log(sc.slice(0, 500));
      }
    }
  }
}

main().catch(console.error);
