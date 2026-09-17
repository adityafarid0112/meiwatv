const fs = require('fs');
if (fs.existsSync('source_dump.html')) {
  const html = fs.readFileSync('source_dump.html', 'utf8');
  const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>/gi;
  let m;
  let count = 0;
  while ((m = cardRegex.exec(html)) !== null && count < 3) {
    count++;
    console.log('--- CARD ' + count + ' ---');
    const images = m[1].match(/<img[^>]+>/gi);
    console.log('Images in card:', images);
    console.log('Card snippet:', m[1].substring(0, 400));
  }
}
