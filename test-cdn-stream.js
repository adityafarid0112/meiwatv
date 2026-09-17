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

async function test() {
  const m3u8Url = 'https://live2.zundrixmediapipeline.com/live/channel21.m3u8';
  console.log('Testing m3u8:', m3u8Url);
  try {
    const resM3u8 = await fetch(m3u8Url, { 'Origin': 'https://meiwaolaharaga.blogspot.com' });
    console.log('M3U8 status:', resM3u8.statusCode);
    console.log('M3U8 cors header:', resM3u8.headers['access-control-allow-origin']);
    console.log('M3U8 body:\n', resM3u8.body);
  } catch (e) {
    console.log('M3U8 err:', e.message);
  }

  const flvUrl = 'https://live2.zundrixmediapipeline.com/live/channel21.flv';
  console.log('\nTesting FLV head/chunk:', flvUrl);
  try {
    const resFlv = await new Promise((resolve, reject) => {
      https.get(flvUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Origin': 'https://meiwaolaharaga.blogspot.com'
        }
      }, (res) => {
        console.log('FLV status:', res.statusCode);
        console.log('FLV cors header:', res.headers['access-control-allow-origin']);
        console.log('FLV content-type:', res.headers['content-type']);
        let chunks = 0;
        res.on('data', chunk => {
          chunks += chunk.length;
          if (chunks > 1000) {
            res.destroy();
            resolve({ chunks, status: res.statusCode });
          }
        });
        res.on('end', () => resolve({ chunks, status: res.statusCode }));
      }).on('error', reject);
    });
    console.log('FLV received bytes:', resFlv.chunks);
  } catch (e) {
    console.log('FLV err:', e.message);
  }
}

test();
