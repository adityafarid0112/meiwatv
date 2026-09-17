const proxies = [
  url => `https://thingproxy.freeboard.io/fetch/${url}`,
  url => `https://api.allorigins.win/get?url=${encodeURIComponent(url)}`,
  url => `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}`,
  url => `https://cors.eu.org/${url}`,
  url => `https://cors-anywhere.herokuapp.com/${url}`,
  url => `https://api.scraperapi.com?api_key=free&url=${encodeURIComponent(url)}`,
  url => `https://proxy.cors.sh/${url}`,
  url => `https://corsproxy.org/?${encodeURIComponent(url)}`,
  url => `https://test.cors.workers.dev/?${encodeURIComponent(url)}`
];

async function testAll() {
  const target = 'https://tft-forests.org/';
  for (let i = 0; i < proxies.length; i++) {
    const fn = proxies[i];
    const pUrl = fn(target);
    try {
      const start = Date.now();
      const res = await fetch(pUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      const text = await res.text();
      console.log(`Proxy ${i}: ${pUrl.slice(0, 40)} -> Status: ${res.status}, Len: ${text.length}, Time: ${Date.now() - start}ms`);
      if (text.includes('truc-tiep')) {
        console.log(`✅ Proxy ${i} SUCCESS with truc-tiep matches!`);
      }
    } catch (e) {
      console.log(`Proxy ${i} Error:`, e.message);
    }
  }
}

testAll();
