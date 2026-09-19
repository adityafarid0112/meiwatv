const https = require('https');
const http = require('http');

function fetchUrl(url, headers = {}, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    if (maxRedirects < 0) return reject(new Error('Too many redirects'));
    const parsed = new URL(url);
    const lib = parsed.protocol === 'https:' ? https : http;
    const req = lib.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        ...headers
      },
      timeout: 10000
    }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let nextUrl = res.headers.location;
        if (nextUrl.startsWith('/')) {
          nextUrl = `${parsed.protocol}//${parsed.host}${nextUrl}`;
        }
        console.log(`Redirect [${res.statusCode}] -> ${nextUrl}`);
        return fetchUrl(nextUrl, headers, maxRedirects - 1).then(resolve).catch(reject);
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: data, finalUrl: url }));
    });
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('Timeout')));
  });
}

(async () => {
  const seeds = ['https://xoilaczbi.tv/', 'https://theceoschool.co/', 'https://socolivezc.tv/'];
  for (const seed of seeds) {
    try {
      console.log('\n--- Fetching seed:', seed);
      const res = await fetchUrl(seed);
      console.log('Final URL:', res.finalUrl);
      console.log('Status:', res.status, 'Body len:', res.body.length);
      const matchRegex = /href="(\/truc-tiep\/[^"]+)"/g;
      const matches = [];
      let m;
      while ((m = matchRegex.exec(res.body)) !== null) {
        matches.push(m[1]);
      }
      console.log('Found match links count:', matches.length);
      if (matches.length > 0) {
        console.log('Sample links:', matches.slice(0, 5));
        const firstLink = matches[0];
        const parsedFinal = new URL(res.finalUrl);
        const matchPageUrl = `${parsedFinal.protocol}//${parsedFinal.host}${firstLink}`;
        console.log('\nFetching match page:', matchPageUrl);
        const matchRes = await fetchUrl(matchPageUrl);
        console.log('Match page status:', matchRes.status, 'Body len:', matchRes.body.length);
        
        // Find streams
        const urlStreamMatches = matchRes.body.match(/var\s+urlStream\s*=\s*["'][^"']+["']/g);
        console.log('var urlStream:', urlStreamMatches);
        
        const listStreamMatches = matchRes.body.match(/var\s+list_stream\s*=\s*\[[^\]]+\]/g);
        console.log('list_stream:', listStreamMatches);

        const iframeMatches = matchRes.body.match(/<iframe[^>]+src=["'][^"']+["']/g);
        console.log('iframe:', iframeMatches);

        const m3u8Matches = matchRes.body.match(/https?:\/\/[^\s"<>]+?\.m3u8[^\s"<>]*/g);
        console.log('m3u8:', m3u8Matches);

        const scripts = matchRes.body.match(/<script[\s\S]*?<\/script>/gi) || [];
        console.log('Total scripts found:', scripts.length);
        for (const s of scripts) {
          if (s.includes('player') || s.includes('m3u8') || s.includes('stream') || s.includes('chanel') || s.includes('channel') || s.includes('ajax')) {
            console.log('\nRelevant script snippet:\n', s.slice(0, 500));
          }
        }
        break;
      }
    } catch (e) {
      console.error('Error on seed', seed, e.message);
    }
  }
})();
