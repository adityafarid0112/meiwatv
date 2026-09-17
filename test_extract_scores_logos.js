const fs = require('fs');

if (fs.existsSync('live_source_dump.html')) {
  const html = fs.readFileSync('live_source_dump.html', 'utf8');
  const cardRegex = /<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;
  let m;
  const sports = {};

  while ((m = cardRegex.exec(html)) !== null) {
    const header = m[1];
    const content = m[2];

    const sport = (header.match(/data-sport="([^"]+)"/i)?.[1] || 'football').toLowerCase();
    const homeTeamId = header.match(/data-home-team-id="([^"]+)"/i)?.[1] || '';
    const awayTeamId = header.match(/data-away-team-id="([^"]+)"/i)?.[1] || '';
    const rawStatus = header.match(/data-status="([^"]+)"/i)?.[1] || '';

    const homeName = content.match(/class="[^"]*grid-match__team--home-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i)?.[1]?.trim() || '';
    const awayName = content.match(/class="[^"]*grid-match__team--away-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i)?.[1]?.trim() || '';

    const homeLogoSrc = content.match(/team-logo-group-home-logo['"]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i)?.[1] || '';
    const awayLogoSrc = content.match(/team-logo-group-away-logo['"]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i)?.[1] || '';

    // Skor / Status
    const vsOrScore = content.match(/class="[^"]*grid-match__status[^"]*"[^>]*>([\s\S]*?)<\/div>/i)?.[1] || '';
    const goals = content.match(/class="[^"]*grid-match__goal[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i)?.[1] || '';
    const matchTime = content.match(/class="[^"]*grid-match__date[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i)?.[1] || '';

    // Cari angka skor live seperti 1 - 0, 85 - 90, 6-4 3-6
    const scoreRegex = /(\d+\s*[-:]\s*\d+)/;
    const scoreInVs = vsOrScore.match(scoreRegex)?.[1] || '';
    const scoreInContent = content.match(/class="[^"]*(?:score|result|points|set-score)[^"]*"[^>]*>([\s\S]*?)<\/div>/i)?.[1] || '';

    if (!sports[sport]) sports[sport] = [];
    sports[sport].push({
      homeName,
      awayName,
      homeTeamId,
      awayTeamId,
      homeLogoSrc,
      awayLogoSrc,
      rawStatus,
      matchTime,
      goals,
      scoreInVs,
      scoreInContent: scoreInContent.replace(/<[^>]+>/g, ' ').trim()
    });
  }

  for (const s in sports) {
    console.log(`\n=================== SPORT: ${s} (Total: ${sports[s].length}) ===================`);
    console.log(sports[s].slice(0, 3));
  }
}
