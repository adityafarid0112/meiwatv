async function checkDataSport() {
    const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    const sports = html.match(/data-sport="([^"]+)"/g) || [];
    const sportTypes = sports.map(s => s.replace(/data-sport="|"/g, ''));
    const counts = {};
    for (const st of sportTypes) {
        counts[st] = (counts[st] || 0) + 1;
    }
    console.log('data-sport counts in tft-forests.org:', counts);

    // Also check other seeds like socolive
    const sRes = await fetch('https://socolivezc.tv/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const sHtml = await sRes.text();
    const sSports = sHtml.match(/data-sport="([^"]+)"/g) || [];
    const sCounts = {};
    for (const st of sSports.map(s => s.replace(/data-sport="|"/g, ''))) {
        sCounts[st] = (sCounts[st] || 0) + 1;
    }
    console.log('data-sport counts in socolivezc.tv:', sCounts);
}
checkDataSport();
