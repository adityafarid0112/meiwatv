const fs = require('fs');
const matches = JSON.parse(fs.readFileSync('matches.json', 'utf8'));
const sampleMatches = matches.slice(0, 10);

async function resolve(url, referer) {
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        'Referer': referer,
        'Origin': new URL(referer).origin
      },
      signal: AbortSignal.timeout(5000)
    });
    if (res.ok) {
      const text = await res.text();
      const m = text.match(/var\s+urlStream\s*=\s*["'](https?:\/\/[^"'\s]+)["']/i) ||
                text.match(/(https?:\/\/[^"'\s<>]+\.m3u8[^"'\s<>]*)/i);
      if (m) return m[1];
    }
  } catch (e) {
    return 'Error: ' + e.message;
  }
  return 'Not found';
}

(async () => {
  for (const m of sampleMatches) {
    const url = m.streamJalur1 || m.streamUrl;
    const ref = m.streamJalur2 || 'https://scoopnashville.com/';
    const stream = await resolve(url, ref);
    console.log(`${m.title} [Status: ${m.status}] -> ${stream ? stream.slice(0, 70) : 'NONE'}`);
  }
})();
