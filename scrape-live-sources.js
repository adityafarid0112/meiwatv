const fs = require('fs');
const path = require('path');

// 1. Baca semua domain live streaming dari "Link nonton Online.txt"
function getSeeds() {
    const linkFile = path.join(__dirname, 'Link nonton Online.txt');
    if (fs.existsSync(linkFile)) {
        const lines = fs.readFileSync(linkFile, 'utf8').split(/\r?\n/);
        const seeds = lines
            .map(l => l.trim())
            .filter(l => l.startsWith('http') && !l.includes('profitablerate') && !l.includes('saweria'));
        if (seeds.length > 0) return seeds;
    }
    return [
        'https://xoilacz.vip/',
        'https://tft-forests.org/',
        'https://socolivezc.tv/',
        'https://xoilackl.tv/',
        'https://90phutcn.tv/',
        'https://cakhiazkv.cc/',
        'https://xoilaccu.tv/',
        'https://vebotvx.cc/',
        'https://rakhoiib.cc/',
        'https://mitomzm.cc/',
        'https://vaoroig.cc/',
        'https://malaysiandigest.com/'
    ];
}

// 2. Baca konfigurasi Iklan & Saweria dari "Link nonton Online.txt"
function getAdsConfig() {
    return {
        saweriaUrl: "https://saweria.co/meiwatv",
        popunderUrls: [
            "https://www.profitableratecpmnetwork.com/r1x7jbv2ys?key=c06365de807e3e8605b4e7e665953775",
            "https://www.profitableratecpmnetwork.com/nhgf41xe?key=c1f7258bb9659ab225647c310b68619e"
        ],
        banners: {
            banner_728x90: {
                key: "0b453dca166b5389587addc2ba0a053a",
                width: 728,
                height: 90,
                script: "https://www.highrevenueformat.com/0b453dca166b5389587addc2ba0a053a/invoke.js"
            },
            banner_300x250: {
                key: "dc4ffb491cd457659d1c3eea5b5db6ca",
                width: 300,
                height: 250,
                script: "https://www.highrevenueformat.com/dc4ffb491cd457659d1c3eea5b5db6ca/invoke.js"
            },
            banner_468x60: {
                key: "b3ebfb84dfe7f276ec8ca6b0601afc33",
                width: 468,
                height: 60,
                script: "https://www.highrevenueformat.com/b3ebfb84dfe7f276ec8ca6b0601afc33/invoke.js"
            }
        },
        updatedAt: new Date().toISOString()
    };
}

async function scrapeAll() {
    const SEEDS = getSeeds();
    console.log(`📡 Menghubungi ${SEEDS.length} sumber live streaming dari Link nonton Online.txt...`);
    let html = '';
    let activeDomain = '';

    for (const seed of SEEDS) {
        try {
            console.log(` - Mengecek ${seed}...`);
            const res = await fetch(seed, {
                redirect: 'follow',
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
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

    // Parsing semua card pertandingan
    const cardRegex = /<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;

    let match;
    const parsedMatches = [];
    const sportCounts = {};

    while ((match = cardRegex.exec(html)) !== null) {
        const cardHeader = match[1];
        const cardContent = match[2];

        // Ekstrak atribut cardHeader
        const sportMatch = cardHeader.match(/data-sport="([^"]+)"/i);
        const sportType = (sportMatch ? sportMatch[1] : 'football').toLowerCase();

        const statusAttrMatch = cardHeader.match(/data-status="([^"]+)"/i);
        const rawStatus = statusAttrMatch ? statusAttrMatch[1] : '1';

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

        // Jangan masukkan yang berstatus selesai lama (4 = FT, 8 = selesai)
        if (rawStatus === '4' || rawStatus === '8') {
            continue;
        }

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

        // Kategori Olahraga:
        // Sepak Bola, Bola Basket, Bola Voli, Bulu Tangkis, Tenis, Olahraga Lainnya
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

        // Penentuan Status LIVE yang akurat langsung dari sumbernya:
        // rawStatus '2', '3', '51', '52', '438' = Sedang Live Bertanding Saat Ini!
        let status = 0;
        if (['2', '3', '51', '52', '438'].includes(rawStatus) || cardContent.includes('is-live') || cardContent.includes('badge-live')) {
            status = 1; // 🔴 LIVE SEKARANG
        } else {
            status = 0; // 📅 Jadwal Hari Ini
        }

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
            status,
            rawStatus
        });
    }

    const liveTotal = parsedMatches.filter(m => m.status === 1).length;
    console.log(`🎯 Ditemukan ${parsedMatches.length} pertandingan (${liveTotal} sedang LIVE SEKARANG):`);
    console.log(sportCounts);

    // Urutkan: Pertandingan yang sedang LIVE (status 1) SELALU paling atas!
    parsedMatches.sort((a, b) => {
        if (b.status !== a.status) return b.status - a.status;
        return a.kickoffIso.localeCompare(b.kickoffIso);
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
                    if (Array.isArray(listStream) && listStream.length > 0) {
                        const s1 = listStream[0];
                        ch1 = s1.play_url || s1.m3u8 || '';
                        if (!ch1.includes('off-tvc')) ch1 += '/off-tvc?is_off_add=false';
                    }
                    if (listStream.length > 1) {
                        const s2 = listStream[1];
                        ch2 = s2.play_url || s2.m3u8 || '';
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

    console.log(`\n💾 Menyimpan ${finalMatches.length} pertandingan & konfigurasi iklan ke GitHub...`);
    const rootMatchesFile = path.join(__dirname, 'matches.json');
    const rootConfigFile = path.join(__dirname, 'app_config.json');
    const appAssetMatches = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'matches.json');
    const appAssetConfig = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'app_config.json');

    const adsConfig = getAdsConfig();

    fs.writeFileSync(rootMatchesFile, JSON.stringify(finalMatches, null, 2), 'utf8');
    fs.writeFileSync(rootConfigFile, JSON.stringify(adsConfig, null, 2), 'utf8');

    if (fs.existsSync(path.dirname(appAssetMatches))) {
        fs.writeFileSync(appAssetMatches, JSON.stringify(finalMatches, null, 2), 'utf8');
        fs.writeFileSync(appAssetConfig, JSON.stringify(adsConfig, null, 2), 'utf8');
    }

    console.log('✅ Selesai mengekstrak semua siaran dan iklan!');
}

scrapeAll();
