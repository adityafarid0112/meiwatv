async function checkSoco() {
  try {
    const res = await fetch('https://socolivezc.tv/', {
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
    });
    console.log('Socolive status:', res.status, res.url);
    const html = await res.text();
    console.log('HTML length:', html.length);
    const slugs = html.match(/\/truc-tiep\/([a-z0-9\-]+)/gi) || [];
    console.log('Total Slugs on Socolive:', slugs.length);
    console.log('Sample Slugs:', slugs.slice(0, 10));
  } catch(e) {
    console.log('Error:', e.message);
  }
}
checkSoco();
