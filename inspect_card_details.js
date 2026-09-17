const fs = require('fs');

if (fs.existsSync('live_source_dump.html')) {
  const html = fs.readFileSync('live_source_dump.html', 'utf8');
  // Match the cards
  const idx = html.indexOf('class="grid-matches__item');
  if (idx !== -1) {
    const snippet = html.substring(idx, idx + 4000);
    console.log(snippet);
  }
}
