const fs = require('fs');

const raw = fs.readFileSync('meiwatv_app/assets/data/matches.json', 'utf8');
const matches = JSON.parse(raw);
console.log('Total matches in assets:', matches.length);

let withRealChannel = 0;
let withFallbackChannel = 0;

for (const m of matches) {
    if (m.streamJalur1.includes('/ajax/chanel/type/')) {
        // check if it's from list_stream or fallback
        // fallback in scrape-live-sources was:
        // if (!ch1) ch1 = `https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel${(matchNum % 20) + 1}...`
        // or let's inspect sample
    }
}
console.log('Sample 10 stream URLs:');
matches.slice(0, 10).forEach(m => {
    console.log(`${m.title} (${m.sportCategory}, status: ${m.status}): ${m.streamJalur1}`);
});
