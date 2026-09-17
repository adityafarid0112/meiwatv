const fs = require('fs');
if (fs.existsSync('source_dump.html')) {
  const html = fs.readFileSync('source_dump.html', 'utf8');
  const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/gi;
  const m = cardRegex.exec(html);
  if (m) {
    console.log(m[0]);
  }
}
