const https = require('https');

function testCors() {
  const options = {
    hostname: 'live2.zundrixmediapipeline.com',
    port: 443,
    path: '/live/channel21.flv',
    method: 'OPTIONS',
    headers: {
      'Origin': 'https://meiwaolaharaga.blogspot.com',
      'Access-Control-Request-Method': 'GET',
      'Access-Control-Request-Headers': 'range'
    }
  };

  const req = https.request(options, (res) => {
    console.log('OPTIONS status:', res.statusCode);
    console.log('OPTIONS headers:', res.headers);
  });
  req.on('error', console.error);
  req.end();
}

testCors();
