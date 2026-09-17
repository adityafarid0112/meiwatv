async function getXoilacPlayerSrc() {
  const url = 'https://xoilacz.vip/truc-tiep/inter-miami-vs-cruz-azul-luc-0700-ngay-17-09-2026/link/0';
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
  });

  const html = await response.text();
  
  // Search for stream_url or player url
  console.log('Searching for player streams in Xoilac HTML...');
  const playerMatches = html.match(/(https?:\/\/[^\s"'<>]+\.(m3u8|mp4|flv))/gi) || [];
  console.log('Direct video streams:', playerMatches);

  // Search for stream domain
  const streamUrls = html.match(/https?:\/\/[a-zA-Z0-9\-\.]*(stream|player|embed|live)[a-zA-Z0-9\-\.]*\.[a-zA-Z]{2,}[^\s"'<>]*/gi) || [];
  console.log('Stream/Player domains:', [...new Set(streamUrls)]);

  // Let's search inside live.js or inline scripts for stream URL generator
  const liveScripts = html.match(/<script[^>]*>[\s\S]*?<\/script>/gi) || [];
  liveScripts.forEach((s, i) => {
    if (s.includes('iframe-stream') || s.includes('random_stream_url') || s.includes('play') || s.includes('link/0') || s.includes('link/1')) {
      console.log(`Script ${i}:`, s.slice(0, 400));
    }
  });
}

getXoilacPlayerSrc();
