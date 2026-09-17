async function check() {
  const res = await fetch('https://tft-forests.org/truc-tiep/alianza-salvador-vs-cd-motagua-luc-1015-ngay-17-09-2026/', {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
  });
  const html = await res.text();
  const listStream = html.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
  console.log('list_stream:', listStream ? listStream[1] : 'none');
  
  if (listStream) {
    const raw = JSON.parse(listStream[1].replace(/\\/g, ''));
    console.log('Parsed stream channels:', JSON.stringify(raw, null, 2));
    
    // Check channel 1
    const ch1 = raw[0][0];
    console.log('Channel 1 URL:', ch1);
    const chRes = await fetch(ch1, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://tft-forests.org/'
      }
    });
    const chHtml = await chRes.text();
    const urlStreamMatch = chHtml.match(/var urlStream\s*=\s*["']([^"']+)["']/);
    console.log('Direct urlStream extracted:', urlStreamMatch ? urlStreamMatch[1] : 'not found');
  }
}

check();
