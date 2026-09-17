const fs = require('fs');

async function testDomains() {
    const rawSeeds = fs.readFileSync('Link nonton Online.txt', 'utf8')
        .split('\n')
        .map(s => s.trim())
        .filter(s => s.startsWith('http'));

    console.log('Seeds found:', rawSeeds);

    for (const seed of rawSeeds) {
        try {
            console.log(`\n--- Testing ${seed} ---`);
            const res = await fetch(seed, {
                headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
                signal: AbortSignal.timeout(6000),
                redirect: 'follow'
            });
            const finalUrl = res.url;
            console.log('Status:', res.status, 'Final URL:', finalUrl);
            const html = await res.text();
            
            // Check for match links
            const trucTiep = html.match(/\/truc-tiep\/[^"' >]+/gi) || [];
            console.log('Match links count:', trucTiep.length);
            
            // Check for categories/nav items
            const navMatches = html.match(/<nav[\s\S]*?<\/nav>|<ul[\s\S]*?class="[^"]*menu[^"]*"[\s\S]*?<\/ul>/gi) || [];
            if (navMatches.length > 0) {
                console.log('Nav sample:', navMatches[0].substring(0, 300).replace(/\s+/g, ' '));
            }

            // Check if there are other sport keywords in the html
            const sports = ['bóng rổ', 'bong-ro', 'bóng chuyền', 'bong-chuyen', 'cầu lông', 'cau-long', 'quần vợt', 'tennis', 'basket'];
            for (const sp of sports) {
                if (html.toLowerCase().includes(sp)) {
                    console.log(`Found keyword "${sp}" in ${seed}`);
                }
            }
        } catch (e) {
            console.log('Error:', e.message);
        }
    }
}

testDomains();
