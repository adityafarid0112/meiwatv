fetch('https://xoilaczbj.tv/wp-content/themes/bongda/dist/scripts/live.js?ver=1786312862')
  .then(r => r.text())
  .then(code => {
    console.log('live.js length:', code.length);
    // Find player setup
    const streamCode = code.match(/.{0,100}(iframe-stream|random_stream_url|m3u8|hls|player|play|stream).{0,100}/gi) || [];
    console.log('Found matches:', streamCode.length);
    streamCode.slice(0, 10).forEach((m, i) => console.log(i, m));
  });
