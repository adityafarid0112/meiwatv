async function testStream() {
  const embedUrl = 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel11/off-tvc?is_off_add=false';
  console.log('Fetching embed URL:', embedUrl);
  const res = await fetch(embedUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Referer': 'https://xoilaczbj.tv/'
    }
  });
  console.log('Status:', res.status);
  const text = await res.text();
  console.log('Body length:', text.length);
  console.log('\n--- BODY PREVIEW ---\n', text.slice(0, 1500));

  const m3u8Matches = text.match(/https?:\/\/[^"'\s<>]+\.m3u8[^"'\s<>]*/gi);
  console.log('\nM3U8 Matches:', m3u8Matches);

  const scripts = text.match(/<script[\s\S]*?<\/script>/gi) || [];
  console.log('\nScripts found:', scripts.length);
  scripts.forEach((s, idx) => {
    console.log(`\n=== SCRIPT ${idx} ===\n`, s);
  });
}

testStream().catch(console.error);
