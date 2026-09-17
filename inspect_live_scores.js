const fs = require('fs');

if (fs.existsSync('live_source_dump.html')) {
  const html = fs.readFileSync('live_source_dump.html', 'utf8');

  // Let's find matches with scores or live status
  const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;
  let m;
  let count = 0;
  while ((m = cardRegex.exec(html)) !== null) {
    const cardContent = m[1];
    // Check if contains score or status
    const statusMatch = cardContent.match(/class="[^"]*grid-match__status[^"]*"[^>]*>([\s\S]*?)<\/div>/i);
    const scoreMatch = cardContent.match(/class="[^"]*(?:score|goal|point)[^"]*"[^>]*>([\s\S]*?)<\/div>/i);
    const sportMatch = m[0].match(/data-sport="([^"]+)"/i);
    const sport = sportMatch ? sportMatch[1] : '';

    if (cardContent.includes('score') || cardContent.includes('is-live') || (statusMatch && !statusMatch[1].includes('vs'))) {
      count++;
      console.log(`\n=== LIVE / SCORE CARD ${count} (${sport}) ===`);
      console.log('Status snippet:', statusMatch ? statusMatch[0] : 'no status div');
      console.log('Score snippet:', scoreMatch ? scoreMatch[0] : 'no score div');
      console.log('Full body snippet:\n', cardContent.match(/<div class="grid-match__body">[\s\S]*?<\/div>\s*<\/div>/i)?.[0]);
    }
  }
}
