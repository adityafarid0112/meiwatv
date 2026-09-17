async function testChannels() {
    // Check what happens when loading channel1 vs channel18 vs match page
    const channels = [1, 2, 3, 4, 5, 8, 10, 18, 20];
    for (const c of channels) {
        const url = `https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel${c}/off-tvc?is_off_add=false`;
        try {
            const res = await fetch(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                    'Referer': 'https://tft-forests.org/'
                },
                signal: AbortSignal.timeout(5000)
            });
            const text = await res.text();
            console.log(`Channel ${c}: status ${res.status}, length ${text.length}, hasVideo: ${text.includes('<video') || text.includes('.m3u8') || text.includes('.flv') || text.includes('dplayer')}`);
            if (text.length < 500) {
                console.log(`Channel ${c} content:`, text.trim());
            }
        } catch(e) {
            console.log(`Channel ${c} error:`, e.message);
        }
    }
}
testChannels();
