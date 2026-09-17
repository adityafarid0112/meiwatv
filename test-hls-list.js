const https = require('https');

const list = ['channel13', 'channel18', 'channel23', 'channel12', 'channel17', 'channel89', 'channel26', 'channel27', 'channel16', 'channel3', 'channel4', 'channel2', 'channel5'];

async function testHls(ch) {
  const url = `https://live2.zundrixmediapipeline.com/live/${ch}.m3u8`;
  return new Promise((resolve) => {
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Origin': 'https://meiwaolaharaga.blogspot.com'
      },
      timeout: 3000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          ch,
          status: res.statusCode,
          hasSegments: data.includes('.ts'),
          len: data.length
        });
      });
    });
    req.on('error', (e) => resolve({ ch, error: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ ch, error: 'timeout' }); });
  });
}

async function run() {
  for (const ch of list) {
    const res = await testHls(ch);
    console.log(ch, res.status === 200 ? '✅ 200 LIVE' : '❌ ' + (res.error || res.status));
  }
}

run();
