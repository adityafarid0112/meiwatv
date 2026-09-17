async function parseSoco() {
    const res = await fetch('https://socolivezc.tv/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    const matches = html.match(/\/truc-tiep\/[^\s"'<>]+/gi) || [];
    console.log('Unique soco matches:', [...new Set(matches)]);
}
parseSoco();
