const fs = require('fs');
const path = require('path');

function extractChannelUrl(item) {
    if (!item) return '';
    if (typeof item === 'string') return item.replace(/\\\//g, '/').replace(/\\/g, '');
    if (Array.isArray(item) && item.length > 0) return extractChannelUrl(item[0]);
    if (typeof item === 'object') return extractChannelUrl(item.play_url || item.m3u8 || item.url || '');
    return '';
}

// 1. Baca semua domain live streaming dari "Link nonton Online.txt"
function getSeeds() {
    return [
        'https://xoilaczbi.tv/',
        'https://theceoschool.co/',
        'https://xoilacz.vip/',
        'https://socolivezc.tv/',
        'https://tft-forests.org/'
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
    const primarySeeds = [
        { name: 'Xoilac', url: 'https://xoilaczbi.tv/' },
        { name: 'Socolive', url: 'https://theceoschool.co/' }
    ];

    console.log(`📡 Menghubungi sumber live streaming utama (Xoilac & Socolive)...`);
    const sourceHtmls = [];

    for (const source of primarySeeds) {
        try {
            console.log(` - Mengambil data dari ${source.name} (${source.url})...`);
            const res = await fetch(source.url, {
                redirect: 'follow',
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                },
                signal: AbortSignal.timeout(10000)
            });
            if (res.ok) {
                const body = await res.text();
                if (body.includes('grid-matches__item')) {
                    const finalDomain = new URL(res.url).origin;
                    sourceHtmls.push({ domain: finalDomain, html: body, name: source.name });
                    console.log(`   ✅ Berhasil memuat ${source.name} (${finalDomain}, ${body.length} bytes)`);
                }
            }
        } catch (e) {
            console.warn(`[WARN] Gagal menghubungi ${source.name}: ${e.message}`);
        }
    }

    if (sourceHtmls.length === 0) {
        console.error('Gagal mengambil data dari semua sumber utama.');
        return;
    }

    const cardRegex = /<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>([\s\S]*?)(?=(?:<div[^>]*class="[^"]*grid-matches__item|<div[^>]*class="sport-content-tab|<\/body|$))/gi;

    const parsedMap = new Map();
    const sportCounts = {};
    let rawIndex = 0;

    for (const src of sourceHtmls) {
        let match;
        cardRegex.lastIndex = 0;

        while ((match = cardRegex.exec(src.html)) !== null) {
            const cardHeader = match[1];
            const cardContent = match[2];

            // Abaikan elemen iklan dalam grid
            if (cardHeader.includes('xlz-ads-item')) continue;

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

            rawIndex++;

            // Cek duplikasi (jangan timpa data Xoilac yang sudah ada, tapi lengkapi data yang baru dari Socolive)
            if (parsedMap.has(relUrl)) continue;

            // Jangan masukkan yang berstatus selesai lama jika sudah ada status 8
            if (rawStatus === '8') {
                continue;
            }

            // Liga
            const leagueMatch = cardContent.match(/class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>/i);
            let league = leagueMatch ? leagueMatch[1].trim() : 'Live Sports';
            league = league.replace(/&#039;/g, "'").replace(/&amp;/g, '&');

            // Home & Away IDs & Logos
            const homeTeamIdMatch = cardHeader.match(/data-home-team-id="([^"]+)"/i);
            const awayTeamIdMatch = cardHeader.match(/data-away-team-id="([^"]+)"/i);
            const homeTeamId = homeTeamIdMatch ? homeTeamIdMatch[1] : '';
            const awayTeamId = awayTeamIdMatch ? awayTeamIdMatch[1] : '';

            const homeImgMatch = cardContent.match(/team-logo-group-home-logo['"]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i);
            const awayImgMatch = cardContent.match(/team-logo-group-away-logo['"]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i);

            let homeLogo = (homeImgMatch && homeImgMatch[1].startsWith('http'))
                ? homeImgMatch[1]
                : (homeTeamId ? `https://imgts.sportpulseapiz.com/${sportType}/team/${homeTeamId}/image/small` : '');
            let awayLogo = (awayImgMatch && awayImgMatch[1].startsWith('http'))
                ? awayImgMatch[1]
                : (awayTeamId ? `https://imgts.sportpulseapiz.com/${sportType}/team/${awayTeamId}/image/small` : '');

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

            // Kategori Olahraga
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
            const matchPageUrl = `${src.domain}${relUrl}`;

            // Penentuan Status LIVE yang akurat langsung dari sumbernya:
            // 1 = Upcoming, 2 = 1st Half / Quarter, 3 = 2nd Half / Late, 4 = FT, 51/52 = Tennis Live, 438 = Live
            let status = 0;
            if (['2', '3', '51', '52', '438'].includes(rawStatus) || cardContent.includes('is-live') || cardContent.includes('badge-live')) {
                status = 1; // 🔴 LIVE SEKARANG
            } else if (rawStatus === '4') {
                status = 2; // Selesai (Full Time)
            } else {
                status = 0; // 📅 Jadwal Hari Ini / Upcoming
            }

            // Ekstraksi Skor Pertandingan Real-Time
            let homeScore = '';
            let awayScore = '';
            let scoreText = '';
            let matchMinute = '';

            const goalMatch = cardContent.match(/class="[^"]*grid-match__goal[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)\s*<\/div>/i);
            const liveScoreEl = cardContent.match(/class="[^"]*grid-match__score[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)/i);
            const hpuScore = cardContent.match(/class="[^"]*hpu-score-home[^"]*"[^>]*>\s*(\d+)\s*<\/span>[\s\S]*?class="[^"]*hpu-score-away[^"]*"[^>]*>\s*(\d+)\s*<\/span>/i);

            if (hpuScore) {
                homeScore = hpuScore[1].trim();
                awayScore = hpuScore[2].trim();
                scoreText = `${homeScore} - ${awayScore}`;
            } else if (goalMatch) {
                homeScore = goalMatch[1].trim();
                awayScore = goalMatch[2].trim();
                scoreText = `${homeScore} - ${awayScore}`;
            } else if (liveScoreEl) {
                homeScore = liveScoreEl[1].trim();
                awayScore = liveScoreEl[2].trim();
                scoreText = `${homeScore} - ${awayScore}`;
            }

            const periodMatch = cardContent.match(/class="[^"]*(?:grid-match__half-court|period|quarter|set-name)[^"]*"[^>]*>\s*([^<]+)\s*</i);
            if (periodMatch) {
                matchMinute = periodMatch[1].trim();
            }

            sportCounts[category] = (sportCounts[category] || 0) + 1;

            parsedMap.set(relUrl, {
                originalIndex: rawIndex,
                title,
                home,
                away,
                homeLogo,
                awayLogo,
                homeScore,
                awayScore,
                scoreText,
                matchMinute,
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
    }

    const parsedMatches = Array.from(parsedMap.values());
    const liveTotal = parsedMatches.filter(m => m.status === 1).length;
    console.log(`🎯 Ditemukan ${parsedMatches.length} total pertandingan unik (${liveTotal} sedang LIVE SEKARANG):`);
    console.log(sportCounts);

    // Urutan 100% PERSIS seperti tampilan web sumber aslinya tanpa diacak!
    parsedMatches.sort((a, b) => a.originalIndex - b.originalIndex);

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
                        ch1 = extractChannelUrl(listStream[0]);
                        if (ch1 && !ch1.includes('off-tvc')) ch1 += '/off-tvc?is_off_add=false';
                    }
                    if (listStream.length > 1) {
                        ch2 = extractChannelUrl(listStream[1]);
                        if (ch2 && !ch2.includes('off-tvc')) ch2 += '/off-tvc?is_off_add=false';
                    }
                }
            } catch (_) {}

            const matchNum = i + idx + 1;
            if (!ch1) ch1 = `${m.matchPageUrl}`;
            if (!ch2) ch2 = `${m.matchPageUrl}`;

            return {
                id: `match_${matchNum}_${m.slugName.substring(0, 25)}`,
                title: m.title,
                homeTeam: m.home,
                awayTeam: m.away,
                homeLogo: m.homeLogo || '',
                awayLogo: m.awayLogo || '',
                homeScore: m.homeScore || '',
                awayScore: m.awayScore || '',
                scoreText: m.scoreText || '',
                matchMinute: m.matchMinute || '',
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

    const portalMatches = path.join(__dirname, 'portal', 'matches.json');
    const portalConfig = path.join(__dirname, 'portal', 'app_config.json');
    if (fs.existsSync(path.dirname(portalMatches))) {
        fs.writeFileSync(portalMatches, JSON.stringify(finalMatches, null, 2), 'utf8');
        fs.writeFileSync(portalConfig, JSON.stringify(adsConfig, null, 2), 'utf8');
    }

    console.log('✅ Selesai mengekstrak semua siaran dan iklan!');
}

scrapeAll();
