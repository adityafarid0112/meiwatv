async function inspectCard() {
    const res = await fetch('https://tft-forests.org/', { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    const idx = html.indexOf('/truc-tiep/');
    if (idx !== -1) {
        console.log(html.substring(Math.max(0, idx - 400), Math.min(html.length, idx + 600)));
    }
}
inspectCard();
