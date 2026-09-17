const fs = require('fs');

async function checkPlayerCode() {
  const url = 'https://tft-forests.org/truc-tiep/inter-miami-vs-cruz-azul-luc-0700-ngay-17-09-2026/';
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await res.text();
  
  // Find where iframe-stream or list_stream is used
  const scriptRegex = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
  let match;
  let i = 0;
  while ((match = scriptRegex.exec(html)) !== null) {
    i++;
    const content = match[1];
    if (content.includes('list_stream') || content.includes('iframe-stream') || content.includes('domainkqt')) {
      console.log(`\n================ SCRIPT #${i} ================`);
      console.log(content);
    }
  }
}

checkPlayerCode();
