const https = require('https');

const channels = ['channel18', 'channel22', 'channel27', 'channel28', 'channel33', 'channel21', 'channel25'];

function checkChannel(ch) {
  return new Promise((resolve) => {
    const url = `https://live2.zundrixmediapipeline.com/live/${ch}.m3u8`;
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Origin': 'https://meiwaolaharaga.blogspot.com'
      },
      timeout: 5000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const hasSegments = data.includes('.ts');
        resolve({ channel: ch, status: res.statusCode, hasSegments, lines: data.split('\n').length });
      });
    });
    req.on('error', (e) => resolve({ channel: ch, error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ channel: ch, error: 'Timeout' }); });
  });
}

async function main() {
  console.log('--- CHECKING LIVE CHANNELS ---');
  for (const ch of channels) {
    const res = await checkChannel(ch);
    console.log(`Channel ${ch}:`, res);
  }
}

main();
