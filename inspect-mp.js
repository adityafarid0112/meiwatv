async function inspectMatchPage() {
    const url = 'https://tft-forests.org/truc-tiep/nu-solomon-islands-vs-nu-vanuatu-luc-1100-ngay-17-09-2026/';
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const html = await res.text();
    console.log('Match page length:', html.length);
    const iframe = html.match(/<iframe[^>]+>/gi) || [];
    console.log('Iframes:', iframe);
    const listStream = html.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
    if (listStream) console.log('list_stream:', listStream[1]);
    const dplayer = html.match(/<div[^>]+id="player"[^>]*>/gi) || [];
    console.log('Player div:', dplayer);
}
inspectMatchPage();
