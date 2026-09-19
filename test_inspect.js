async function testScrape() {
  try {
    const res = await fetch('https://xoilaczzf.cc/', {
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
    });
    const html = await res.text();
    const rawParts = html.split(/<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>/gi);
    console.log('Total items on xoilac:', Math.floor(rawParts.length / 2));
    const sample = [];
    for (let i = 1; i < rawParts.length; i += 2) {
      const cardContent = rawParts[i+1] || '';
      const leagueMatch = cardContent.match(/class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>/i);
      const homeMatch = cardContent.match(/class="[^"]*grid-match__team--home-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);
      const awayMatch = cardContent.match(/class="[^"]*grid-match__team--away-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);
      if (leagueMatch) {
        sample.push({
          rawLeague: leagueMatch[1].trim(),
          home: homeMatch ? homeMatch[1].trim() : '',
          away: awayMatch ? awayMatch[1].trim() : ''
        });
      }
    }
    console.log('RAW SCRAPED LEAGUES & TEAMS SAMPLE (first 30):');
    console.log(JSON.stringify(sample.slice(0, 30), null, 2));
  } catch (err) {
    console.error('Scrape error:', err);
  }
}
testScrape();
