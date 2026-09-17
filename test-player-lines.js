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
  const matchUrl = 'https://tft-forests.org/truc-tiep/inter-miami-vs-cruz-azul-luc-0700-ngay-17-09-2026/';
  const res = await fetch(matchUrl);

  // Search for lines mentioning player, stream, channel, play_main, iframe, embed
  const lines = res.body.split('\n');
  console.log('Total lines:', lines.length);

  lines.forEach((line, idx) => {
    if (line.includes('channel') || line.includes('play_main') || line.includes('stream') || line.includes('iframe') || line.includes('embed') || line.includes('m3u8') || line.includes('flv') || line.includes('live2') || line.includes('zundrix')) {
      console.log(`Line ${idx+1}: ${line.trim().slice(0, 300)}`);
    }
  });
}

main().catch(console.error);
