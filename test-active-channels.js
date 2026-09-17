const https = require('https');

const channels = ['channel13', 'channel18', 'channel22', 'channel16', 'channel23', 'channel28'];

async function testHls(ch) {
  const url = `https://live2.zundrixmediapipeline.com/live/${ch}.m3u8`;
  return new Promise((resolve) => {
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Origin': 'https://meiwaolaharaga.blogspot.com'
      },
      timeout: 5000
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
  for (const ch of channels) {
    const res = await testHls(ch);
    console.log(ch, res);
  }
}

run();
