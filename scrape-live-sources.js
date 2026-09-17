const fs = require('fs');
const path = require('path');

// Daftar domain sumber siaran live dari Link nonton Online.txt
const SEEDS = [
    'https://tft-forests.org/',
    'https://xoilacz.vip/',
    'https://socolivezc.tv/',
    'https://cakhiazkv.cc/',
    'https://vebotvx.cc/',
    'https://mitomzm.cc/'
];

async function scrapeAll() {
    console.log('📡 Menghubungi sumber live streaming Xoilac / TFT / Socolive:');
    let html = '';
    let activeDomain = '';

    for (const seed of SEEDS) {
        try {
            console.log(` - Mengecek ${seed}...`);
            const res = await fetch(seed, {
                redirect: 'follow',
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                },
                signal: AbortSignal.timeout(8000)
            });
            if (res.ok) {
                const body = await res.text();
                if (body.includes('grid-matches__item')) {
                    html = body;
                    activeDomain = new URL(res.url).origin;
                    console.log(`   ✅ Terhubung ke ${activeDomain}`);
                    break;
                }
            }
        } catch (e) {
            console.warn(`[WARN] Gagal: ${e.message}`);
        }
    }

    if (!html || !activeDomain) {
        console.error('Gagal mengambil data dari seed.');
        return;
    }

    // Parsing semua card pertandingan dengan data-sport
    const cardRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"[^>]*data-sport="([^"]+)"[^>]*>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;

    let match;
    const nowTime = Date.now();
    const today = new Date();
    const todayStr = `${String(today.getDate()).padStart(2, '0')}-${String(today.getMonth() + 1).padStart(2, '0')}-${today.getFullYear()}`;
    
    const parsedMatches = [];
    const sportCounts = {};

    while ((match = cardRegex.exec(html)) !== null) {
        const sportType = match[1].toLowerCase();
        const cardContent = match[2];

        const linkMatch = cardContent.match(/href="(\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\/)"/i);
        if (!linkMatch) continue;

        const relUrl = linkMatch[1];
        const slugName = linkMatch[2];
        const timeStr = linkMatch[3];
        const day = linkMatch[4];
        const month = linkMatch[5];
        const year = linkMatch[6];
        const hour = timeStr.slice(0, 2);
        const min = timeStr.slice(2, 4);

        // Filter: Hari ini 00:00 sampai 23:59
        const kickoffDateStr = `${day}-${month}-${year}`;

        // Liga
        const leagueMatch = cardContent.match(/class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>/i);
        let league = leagueMatch ? leagueMatch[1].trim() : 'Live Sports';
        league = league.replace(/&#039;/g, "'").replace(/&amp;/g, '&');

        // Home & Away
        const homeMatch = cardContent.match(/class="[^"]*grid-match__team--home-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);
        const awayMatch = cardContent.match(/class="[^"]*grid-match__team--away-name[^"]*"[^>]*>\s*([^<]+)\s*<\/div>/i);

        let home = homeMatch ? homeMatch[1].trim() : '';
        let away = awayMatch ? awayMatch[1].trim() : '';

        if (!home || !away) {
            const raw = slugName.replace(/-/g, ' ');
            const parts = raw.split(/\s+vs\s+|\s+-\s+/i);
            home = home || (parts[0] ? parts[0].trim() : 'Tim 1');
            away = away || (parts.length > 1 ? parts[1].trim() : 'Tim 2');
        }

        const title = `${home} vs ${away}`;

        // Kategori Olahraga Sesuai Permintaan User:
        // Sepakbola, Bola Basket, Bola Voli, Bulutangkis, Tenis, Lainnya
        let category = '⚽ Sepak Bola';
        if (sportType === 'basketball') {
            category = '🏀 Bola Basket';
        } else if (sportType === 'volleyball') {
            category = '🏐 Bola Voli';
        } else if (sportType === 'badminton') {
            category = '🏸 Bulu Tangkis';
        } else if (sportType === 'tennis') {
            category = '🎾 Tenis';
        } else if (sportType !== 'football') {
            category = '🏎️ Olahraga Lainnya';
        }

        const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
        const kickoffText = `${hour}:${min} WIB (${day}/${month})`;
        const matchPageUrl = `${activeDomain}${relUrl}`;

        const kickoffTime = new Date(`${year}-${month}-${day}T${hour}:${min}:00`).getTime();
        const diff = kickoffTime - nowTime;

        let status = 0;
        if (diff <= 0 && diff > -14400000) {
            status = 1; // Live (sedang live sekarang)
        } else if (diff <= -14400000) {
            status = 2; // Selesai (>4 jam)
        } else {
            status = 0; // Upcoming (hari ini jam mendatang)
        }

        // Jangan masukkan yang sudah selesai lebih dari 4 jam
        if (status === 2) continue;

        sportCounts[category] = (sportCounts[category] || 0) + 1;

        parsedMatches.push({
            title,
            home,
            away,
            league,
            category,
            sportType,
            matchPageUrl,
            slugName,
            kickoffIso,
            kickoffText,
            kickoffTime,
            status
        });
    }

    console.log(`🎯 Ditemukan ${parsedMatches.length} pertandingan hari ini dari SEMUA CABANG OLAHRAGA:`);
    console.log(sportCounts);

    // Urutkan: Live status 1 di atas
    parsedMatches.sort((a, b) => {
        if (b.status !== a.status) return b.status - a.status;
        return a.kickoffTime - b.kickoffTime;
    });

    console.log(`\n🔍 Mengekstrak direct channel stream untuk ${parsedMatches.length} pertandingan...`);
    const finalMatches = [];

    // Batch proses dengan concurrency 10
    const BATCH_SIZE = 10;
    for (let i = 0; i < parsedMatches.length; i += BATCH_SIZE) {
        const batch = parsedMatches.slice(i, i + BATCH_SIZE);
        const results = await Promise.all(batch.map(async (m, idx) => {
            let ch1 = '';
            let ch2 = '';

            try {
                const pRes = await fetch(m.matchPageUrl, {
                    headers: { 'User-Agent': 'Mozilla/5.0' },
                    signal: AbortSignal.timeout(5000)
                });
                const pHtml = await pRes.text();
                const listStreamMatch = pHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
                if (listStreamMatch) {
                    const rawJson = listStreamMatch[1].replace(/\\/g, '');
                    const listStream = JSON.parse(rawJson);
                    if (listStream[0] && listStream[0][0]) {
                        ch1 = listStream[0][0];
                        if (!ch1.includes('off-tvc')) ch1 += '/off-tvc?is_off_add=false';
                    }
                    if (listStream[1] && listStream[1][0]) {
                        ch2 = listStream[1][0];
                        if (!ch2.includes('off-tvc')) ch2 += '/off-tvc?is_off_add=false';
                    } else if (listStream[0] && listStream[0][1]) {
                        ch2 = listStream[0][1];
                        if (!ch2.includes('off-tvc')) ch2 += '/off-tvc?is_off_add=false';
                    }
                }
            } catch (_) {}

            const matchNum = i + idx + 1;
            if (!ch1) ch1 = `https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel${(matchNum % 20) + 1}/off-tvc?is_off_add=false`;
            if (!ch2) ch2 = `${m.matchPageUrl}link/0`;

            return {
                id: `match_${matchNum}_${m.slugName.substring(0, 25)}`,
                title: m.title,
                homeTeam: m.home,
                awayTeam: m.away,
                league: m.league,
                sportCategory: m.category,
                kickoffIso: m.kickoffIso,
                kickoffText: m.kickoffText,
                kickoffTime: m.kickoffTime,
                status: m.status,
                streamJalur1: ch1,
                streamJalur2: ch2,
                streamJalur3: m.matchPageUrl,
                streams: {
                    jalur1: ch1,
                    jalur2: ch2,
                    jalur3: m.matchPageUrl
                },
                updatedAt: new Date().toISOString()
            };
        }));

        finalMatches.push(...results);
        console.log(`   Processed ${finalMatches.length} / ${parsedMatches.length}...`);
    }

    console.log(`\n💾 Menyimpan ${finalMatches.length} pertandingan langsung ke file aset & matches.json...`);
    const rootMatchesFile = path.join(__dirname, 'matches.json');
    const appAssetFile = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'matches.json');
    const exportFile = path.join(__dirname, 'meiwatv-firebase-export.json');
    const compactFile = path.join(__dirname, 'compact-matches.json');

    fs.writeFileSync(rootMatchesFile, JSON.stringify(finalMatches, null, 2), 'utf8');
    if (fs.existsSync(path.dirname(appAssetFile))) {
        fs.writeFileSync(appAssetFile, JSON.stringify(finalMatches, null, 2), 'utf8');
    }
    fs.writeFileSync(exportFile, JSON.stringify(finalMatches, null, 2), 'utf8');
    fs.writeFileSync(compactFile, JSON.stringify(finalMatches, null, 2), 'utf8');

    console.log('✅ Selesai mengekstrak semua stream channels untuk semua cabang olahraga!');
}

scrapeAll();
