const fs = require('fs');

async function testMatchStreams() {
    const raw = fs.readFileSync('meiwatv_app/assets/data/matches.json', 'utf8');
    const matches = JSON.parse(raw);

    // Pick 5 matches (some live, some upcoming, some non-football)
    const samples = [
        matches.find(m => m.status === 1), // Live
        matches.find(m => m.sportCategory.includes('Basket')),
        matches.find(m => m.sportCategory.includes('Voli')),
        matches.find(m => m.sportCategory.includes('Tenis')),
        matches[matches.length - 1]
    ].filter(Boolean);

    for (const m of samples) {
        console.log(`\nTesting Match: ${m.title} (${m.sportCategory}, status: ${m.status})`);
        console.log(` - Jalur 1: ${m.streamJalur1}`);
        console.log(` - Jalur 2: ${m.streamJalur2}`);
        console.log(` - Jalur 3: ${m.streamJalur3}`);

        // Fetch match page
        try {
            const res = await fetch(m.streamJalur3, {
                headers: { 'User-Agent': 'Mozilla/5.0' },
                signal: AbortSignal.timeout(5000)
            });
            const html = await res.text();
            const ls = html.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
            if (ls) {
                console.log(' - Match Page list_stream:', ls[1].replace(/\\/g, '').substring(0, 150));
            } else {
                console.log(' - No list_stream found on match page! Check iframe or video:');
                const iframes = html.match(/<iframe[^>]+src="([^"]+)"/gi) || [];
                console.log('   iframes:', iframes);
            }
        } catch(e) {
            console.log(' - Error fetching match page:', e.message);
        }

        // Test Jalur 1
        try {
            const j1Res = await fetch(m.streamJalur1, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                    'Referer': 'https://tft-forests.org/'
                },
                signal: AbortSignal.timeout(5000)
            });
            const j1Html = await j1Res.text();
            console.log(` - Jalur 1 HTTP: ${j1Res.status}, Length: ${j1Html.length}`);
            // Check if there is an error message or offline message in j1Html
            if (j1Html.includes('chưa diễn ra') || j1Html.includes('offline') || j1Html.includes('kết thúc') || j1Html.includes('error')) {
                console.log('   Jalur 1 notice:', j1Html.substring(0, 300).replace(/\s+/g, ' '));
            }
        } catch(e) {
            console.log(' - Jalur 1 error:', e.message);
        }
    }
}

testMatchStreams();
