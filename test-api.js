const fs = require('fs');

async function testApiEndpoints() {
  const base = 'https://tft-forests.org';
  const paths = [
    '/',
    '/api/matches',
    '/ajax/matches',
    '/api/live',
    '/api/schedule',
    '/feed',
    '/wp-json/wp/v2/posts?per_page=50'
  ];

  for (const p of paths) {
    try {
      const url = base + p;
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      console.log(url, 'Status:', res.status, 'Type:', res.headers.get('content-type'));
    } catch (e) {
      console.log(p, 'Error:', e.message);
    }
  }
}

testApiEndpoints();
