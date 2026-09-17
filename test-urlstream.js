async function testUrlStream() {
    const channelUrl = 'https://xlz.domainkqt.cc/ajax/chanel/type/7/link/channel20/off-tvc?is_off_add=false';
    const res = await fetch(channelUrl, {
        headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://tft-forests.org/'
        }
    });
    const html = await res.text();
    const match = html.match(/var urlStream\s*=\s*"([^"]+)";/);
    if (match) {
        const streamUrl = match[1];
        console.log('Stream URL:', streamUrl);
        // Test fetching the stream URL
        try {
            const sRes = await fetch(streamUrl, {
                headers: {
                    'User-Agent': 'Mozilla/5.0',
                    'Referer': 'https://xlz.domainkqt.cc/'
                },
                signal: AbortSignal.timeout(5000)
            });
            console.log('Stream response status:', sRes.status, 'content-type:', sRes.headers.get('content-type'));
            const chunk = await sRes.arrayBuffer();
            console.log('Chunk received bytes:', chunk.byteLength);
            // Check if flv header (0x46, 0x4C, 0x56)
            const u8 = new Uint8Array(chunk.slice(0, 3));
            console.log('Header bytes:', u8[0], u8[1], u8[2], 'isFLV:', u8[0] === 0x46 && u8[1] === 0x4C && u8[2] === 0x56);
        } catch(e) {
            console.log('Stream fetch error:', e.message);
        }
    } else {
        console.log('No urlStream found in channel HTML');
    }
}
testUrlStream();
