async function testParser() {
    const res = await fetch('https://tft-forests.org/', {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
    });
    const html = await res.text();

    // Regex to extract all cards
    // Look for <div class="grid-matches__item ... data-sport="..." ...
    const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*data-sport="([^"]+)"[^>]*>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;

    let match;
    const items = [];
    const sportCounts = {};

    while ((match = cardRegex.exec(html)) !== null) {
        const sportType = match[1];
        const cardContent = match[2];

        const linkMatch = cardContent.match(/href="(\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\/)"/i);
        if (!linkMatch) continue;

        const relUrl = linkMatch[1];
        const slugName = linkMatch[2];
        const timeStr = linkMatch[3];
        const day = linkMatch[4];
        const month = linkMatch[5];
        const year = linkMatch[6];

        // League
        const leagueMatch = cardContent.match(/class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>/i);
        const league = leagueMatch ? leagueMatch[1].trim() : 'Live Sports';

        // Home & Away team
        const homeMatch = cardContent.match(/class="[^"]*grid-match__team--home-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);
        const awayMatch = cardContent.match(/class="[^"]*grid-match__team--away-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);

        let home = homeMatch ? homeMatch[1].trim() : '';
        let away = awayMatch ? awayMatch[1].trim() : '';

        if (!home || !away) {
            const raw = slugName.replace(/-/g, ' ');
            const parts = raw.split(/\s+vs\s+|\s+-\s+/i);
            home = home || (parts[0] ? parts[0].trim() : 'Tim 1');
            away = away || (parts[1] ? parts[1].trim() : 'Tim 2');
        }

        // Title
        const title = `${home} vs ${away}`;

        // Category mapping
        let category = '⚽ Sepak Bola';
        if (sportType === 'basketball') category = '🏀 Bola Basket';
        else if (sportType === 'volleyball') category = '🏐 Bola Voli';
        else if (sportType === 'badminton') category = '🏸 Bulu Tangkis';
        else if (sportType === 'tennis') category = '🎾 Tenis';
        else if (sportType !== 'football') category = '🏎️ Olahraga Lainnya';

        sportCounts[category] = (sportCounts[category] || 0) + 1;
        items.push({
            category,
            sportType,
            title,
            home,
            away,
            league,
            kickoffIso: `${year}-${month}-${day}T${timeStr.slice(0, 2)}:${timeStr.slice(2, 4)}:00+07:00`,
            dateText: `${day}/${month}/${year}`,
            timeText: `${timeStr.slice(0, 2)}:${timeStr.slice(2, 4)} WIB`,
            relUrl
        });
    }

    console.log(`Total parsed items: ${items.length}`);
    console.log('Sport counts:', sportCounts);
    console.log('\nSample badminton/tennis/basketball items:');
    const nonFootball = items.filter(i => i.category !== '⚽ Sepak Bola');
    console.log(nonFootball.slice(0, 5));
}

testParser();
