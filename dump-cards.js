async function dumpCards() {
    const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    
    for (const sport of ['basketball', 'tennis', 'volleyball', 'badminton']) {
        const needle = `data-sport="${sport}"`;
        const idx = html.indexOf(needle);
        if (idx !== -1) {
            const start = html.lastIndexOf('<div class="grid-matches__item', idx);
            const end = html.indexOf('</div>\n    </div>\n</div>', idx) !== -1 
                ? html.indexOf('</div>\n    </div>\n</div>', idx) + 25 
                : idx + 800;
            console.log(`\n================ SPORT: ${sport} ================`);
            console.log(html.substring(start, end));
        } else {
            console.log(`No match for ${sport}`);
        }
    }
}
dumpCards();
