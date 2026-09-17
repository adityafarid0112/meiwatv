const https = require('https');

function testHlsSegments() {
  const m3u8Url = 'https://live2.zundrixmediapipeline.com/live/channel21.m3u8';
  https.get(m3u8Url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Origin': 'https://meiwaolaharaga.blogspot.com'
    }
  }, (res) => {
    console.log('M3U8 status:', res.statusCode);
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('M3U8 content:\n', data);
      const lines = data.split('\n');
      const tsLine = lines.find(l => l.includes('.ts'));
      if (tsLine) {
        const tsUrl = 'https://live2.zundrixmediapipeline.com/live/' + tsLine.trim();
        console.log('Testing TS segment:', tsUrl);
        https.get(tsUrl, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Origin': 'https://meiwaolaharaga.blogspot.com'
          }
        }, (tsRes) => {
          console.log('TS segment status:', tsRes.statusCode);
          console.log('TS CORS header:', tsRes.headers['access-control-allow-origin']);
          let bytes = 0;
          tsRes.on('data', c => bytes += c.length);
          tsRes.on('end', () => console.log('TS segment downloaded bytes:', bytes));
        });
      }
    });
  });
}

testHlsSegments();
