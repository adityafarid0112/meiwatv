const https = require('https');
https.get('https://xlz.domainkqt.cc/ajax/chanel/type/7/link/channel76/off-tvc?is_off_add=false', {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
    'Referer': 'https://scoopnashville.com/',
    'Origin': 'https://scoopnashville.com'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    const m3u8Match = data.match(/https?:\/\/[^"'\s]+\.m3u8[^"'\s]*/i);
    if (m3u8Match) console.log('DIRECT M3U8:', m3u8Match[0]);
    console.log('HTML snippet:\n', data.slice(0, 800));
  });
});
