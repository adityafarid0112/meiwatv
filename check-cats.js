async function checkCategories() {
    const res = await fetch('https://tft-forests.org/', {
        headers: { 'User-Agent': 'Mozilla/5.0' }
    });
    const html = await res.text();
    const links = html.match(/href="([^"]+)"/g) || [];
    const unique = [...new Set(links.map(l => l.replace(/href="|"/g, '')))];
    console.log('All links on tft-forests.org:');
    unique.forEach(l => {
        if (!l.includes('/truc-tiep/') && !l.includes('.css') && !l.includes('.js') && !l.includes('.png')) {
            console.log(l);
        }
    });

    console.log('\nAll links on socolivezc.tv:');
    try {
        const sRes = await fetch('https://socolivezc.tv/', {
            headers: { 'User-Agent': 'Mozilla/5.0' }
        });
        const sHtml = await sRes.text();
        const sLinks = sHtml.match(/href="([^"]+)"/g) || [];
        const sUnique = [...new Set(sLinks.map(l => l.replace(/href="|"/g, '')))];
        sUnique.forEach(l => {
            if (!l.includes('/truc-tiep/') && !l.includes('.css') && !l.includes('.js') && !l.includes('.png')) {
                console.log(l);
            }
        });
    } catch(e) {
        console.log('Socolive error:', e.message);
    }
}
checkCategories();
