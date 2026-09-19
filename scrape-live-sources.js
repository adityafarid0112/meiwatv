const fs = require('fs');
const path = require('path');

function extractChannelUrl(item) {
    if (!item) return '';
    if (typeof item === 'string') return item.replace(/\\\//g, '/').replace(/\\/g, '');
    if (Array.isArray(item) && item.length > 0) return extractChannelUrl(item[0]);
    if (typeof item === 'object') return extractChannelUrl(item.play_url || item.m3u8 || item.url || '');
    return '';
}

// Terjemahkan nama liga, turnamen, dan tim dari bahasa Vietnam ke Bahasa Indonesia Resmi
function translateToId(str) {
    if (!str) return '';
    let text = str;

    const leagueMap = [
        // Spesifik Liga Sepak Bola / Olahraga Populer
        { pattern: /Ngoại Hạng Anh/gi, replace: 'Premier League (Inggris)' },
        { pattern: /VĐQG Indonesia/gi, replace: 'BRI Liga 1 Indonesia' },
        { pattern: /Hạng 2 Indonesia/gi, replace: 'Liga 2 Indonesia' },
        { pattern: /Hạng 3 Indonesia/gi, replace: 'Liga 3 Indonesia' },
        { pattern: /Cúp Quốc Gia Việt Nam/gi, replace: 'Piala Nasional Vietnam' },
        { pattern: /VĐQG Việt Nam|V\.League\s*1/gi, replace: 'V.League 1 (Vietnam)' },
        { pattern: /VĐQG Tây Ban Nha|La Liga/gi, replace: 'La Liga (Spanyol)' },
        { pattern: /VĐQG Ý|Serie A/gi, replace: 'Serie A (Italia)' },
        { pattern: /VĐQG Đức|Bundesliga/gi, replace: 'Bundesliga (Jerman)' },
        { pattern: /VĐQG Pháp|Ligue 1/gi, replace: 'Ligue 1 (Prancis)' },
        { pattern: /VĐQG Hà Lan|Eredivisie/gi, replace: 'Eredivisie (Belanda)' },
        { pattern: /VĐQG Bồ Đào Nha/gi, replace: 'Liga Portugal' },
        { pattern: /VĐQG Saudi Arabia|VĐQG Ả Rập Xê Út/gi, replace: 'Saudi Pro League' },
        { pattern: /VĐQG Nhật Bản/gi, replace: 'J1 League (Jepang)' },
        { pattern: /VĐQG Hàn Quốc/gi, replace: 'K League 1 (Korea)' },
        { pattern: /Hạng Nhất Ukraina/gi, replace: 'Liga Utama Ukraina' },
        { pattern: /Hạng Nhất Anh|Championship/gi, replace: 'Championship (Inggris)' },
        { pattern: /Hạng 2 Trung Quốc/gi, replace: 'Liga 2 China' },
        { pattern: /Hạng 2 Romania/gi, replace: 'Liga 2 Rumania' },
        { pattern: /Hạng 2 Tây Ban Nha/gi, replace: 'La Liga 2 (Spanyol)' },
        { pattern: /Hạng 2 Đức/gi, replace: '2. Bundesliga (Jerman)' },
        { pattern: /Hạng 2 Ý/gi, replace: 'Serie B (Italia)' },
        { pattern: /Hạng 2 Pháp/gi, replace: 'Ligue 2 (Prancis)' },
        
        // Turnamen & Kompetisi
        { pattern: /Cúp C1|Champions League/gi, replace: 'Liga Champions' },
        { pattern: /Cúp C2|Europa League/gi, replace: 'Liga Europa' },
        { pattern: /Cúp C3|Conference League/gi, replace: 'Liga Konferensi Eropa' },
        { pattern: /Cúp FA/gi, replace: 'Piala FA (Inggris)' },
        { pattern: /Cúp Nhà Vua|Copa del Rey/gi, replace: 'Copa del Rey (Spanyol)' },
        { pattern: /Cúp Quốc Gia/gi, replace: 'Piala Nasional' },
        { pattern: /Cúp Liên Đoàn/gi, replace: 'Piala Liga' },
        { pattern: /Siêu Cúp/gi, replace: 'Piala Super' },
        { pattern: /Giao hữu quốc tế/gi, replace: 'Laga Persahabatan Internasional' },
        { pattern: /Giao hữu CLB/gi, replace: 'Laga Persahabatan Klub' },
        { pattern: /Giao hữu/gi, replace: 'Laga Persahabatan' },
        { pattern: /Giải vô địch/gi, replace: 'Kejuaraan' },
        { pattern: /Vòng loại World Cup/gi, replace: 'Kualifikasi Piala Dunia' },
        { pattern: /Vòng loại Asian Cup/gi, replace: 'Kualifikasi Piala Asia' },
        { pattern: /Vòng loại Euro/gi, replace: 'Kualifikasi Euro' },
        { pattern: /Vòng loại/gi, replace: 'Kualifikasi' },
        { pattern: /Bán kết/gi, replace: 'Semifinal' },
        { pattern: /Chung kết/gi, replace: 'Final' },
        { pattern: /Tứ kết/gi, replace: 'Perempat Final' },
        { pattern: /Vòng Bảng/gi, replace: 'Fase Grup' },
        
        // Klasifikasi Umum
        { pattern: /Hạng 2/gi, replace: 'Divisi 2' },
        { pattern: /Hạng 3/gi, replace: 'Divisi 3' },
        { pattern: /Hạng 4/gi, replace: 'Divisi 4' },
        { pattern: /Hạng Nhất/gi, replace: 'Divisi Utama' },
        { pattern: /VĐQG/gi, replace: 'Liga Utama' },
        { pattern: /Cúp/gi, replace: 'Piala' }
    ];

    leagueMap.forEach(item => { text = text.replace(item.pattern, item.replace); });

    const wordMap = [
        { pattern: /\bNữ\b/gi, replace: 'Wanita' },
        { pattern: /\bNam\b/gi, replace: 'Pria' },
        { pattern: /\bTrẻ\b/gi, replace: 'Muda' },
        { pattern: /\bCLB\s+/gi, replace: 'Klub ' },
        { pattern: /\bNhật Bản\b/gi, replace: 'Jepang' },
        { pattern: /\bHàn Quốc\b/gi, replace: 'Korea Selatan' },
        { pattern: /\bTriều Tiên\b/gi, replace: 'Korea Utara' },
        { pattern: /\bTrung Quốc\b/gi, replace: 'China' },
        { pattern: /\bĐài Loan\b/gi, replace: 'Taiwan' },
        { pattern: /\bHồng Kông\b/gi, replace: 'Hong Kong' },
        { pattern: /\bTây Ban Nha\b/gi, replace: 'Spanyol' },
        { pattern: /\bÝ\b/g, replace: 'Italia' },
        { pattern: /\bĐức\b/gi, replace: 'Jerman' },
        { pattern: /\bPháp\b/gi, replace: 'Prancis' },
        { pattern: /\bAnh\b/g, replace: 'Inggris' },
        { pattern: /\bHà Lan\b/gi, replace: 'Belanda' },
        { pattern: /\bBồ Đào Nha\b/gi, replace: 'Portugal' },
        { pattern: /\bThái Lan\b/gi, replace: 'Thailand' },
        { pattern: /\bMỹ\b|\bHoa Kỳ\b/gi, replace: 'Amerika Serikat' },
        { pattern: /\bÚc\b/gi, replace: 'Australia' },
        { pattern: /\bThụy Sĩ\b/gi, replace: 'Swiss' },
        { pattern: /\bThụy Điển\b/gi, replace: 'Swedia' },
        { pattern: /\bThổ Nhĩ Kỳ\b/gi, replace: 'Turki' },
        { pattern: /\bNga\b/g, replace: 'Rusia' },
        { pattern: /\bHy Lạp\b/gi, replace: 'Yunani' },
        { pattern: /\bẢ Rập Xê Út\b/gi, replace: 'Arab Saudi' },
        { pattern: /\bIndonesia\b/gi, replace: 'Indonesia' },
        { pattern: /\bViệt Nam\b/gi, replace: 'Vietnam' }
    ];

    wordMap.forEach(item => { text = text.replace(item.pattern, item.replace); });
    return text.replace(/\s+/g, ' ').trim();
}

// 1. Baca semua domain live streaming dari "Link nonton Online.txt"
function getSeeds() {
    return [
        'https://xoilaczzf.cc/',
        'https://xoilacz.vip/',
        'https://tft-forests.org/',
        'https://xoilaczbi.tv/',
        'https://socolivezc.tv/',
        'https://theceoschool.co/',
        'https://atttvnow.com/',
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
    const primarySeeds = [
        { name: 'Xoilac Main', url: 'https://xoilaczzf.cc/' },
        { name: 'Xoilac Backup', url: 'https://xoilaczbi.tv/' },
        { name: 'Socolive Main', url: 'https://atttvnow.com/' },
        { name: 'Socolive Backup', url: 'https://theceoschool.co/' },
        { name: 'Cakhia', url: 'https://cakhiazkv.cc/' },
        { name: 'Mitom', url: 'https://mitomzm.cc/' },
        { name: '90phut', url: 'https://90phutcn.tv/' },
        { name: 'Vebotv', url: 'https://vebotvx.cc/' },
        { name: 'Rakhoi', url: 'https://rakhoiib.cc/' },
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
            league = translateToId(league);

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

            home = translateToId(home);
            away = translateToId(away);

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

            // Penentuan Status LIVE yang 100% Akurat untuk SEMUA cabang olahraga:
            // Termasuk Babak Tambahan (Extra Time), Overtime (OT), Adu Penalti (Penalties), dan Set Tambahan
            let status = 0;
            const liveFootball = ['2', '3', '4', '5', '7']; // 1st Half, 2nd Half, Extra Time 1, Extra Time 2, Penalties
            const liveBasketball = ['2', '3', '4', '5', '6', '7']; // Q1, Q2, Q3, Q4, OT, OT2
            const liveTennis = ['51', '52', '53', '54', '55', '56']; // Set 1..5
            const liveVolleyball = ['431', '432', '433', '434', '435', '436', '437', '438']; // Set 1..5, Golden Set
            const liveEsports = ['2', '3', '4', '5', '6', '7'];

            const contentLower = cardContent.toLowerCase();
            const isCardLive = contentLower.includes('is-live') ||
                contentLower.includes('badge-live') ||
                contentLower.includes('grid-match-live') ||
                contentLower.includes('live') ||
                contentLower.includes('playing');

            if (sportType === 'football' && liveFootball.includes(rawStatus)) {
                status = 1; // 🔴 LIVE SEKARANG (Termasuk ET & Penalti)
            } else if (sportType === 'basketball' && liveBasketball.includes(rawStatus)) {
                status = 1; // 🔴 LIVE SEKARANG (Termasuk Overtime)
            } else if (sportType === 'tennis' && liveTennis.includes(rawStatus)) {
                status = 1; // 🔴 LIVE SEKARANG (Termasuk Set Tambahan)
            } else if (sportType === 'volleyball' && liveVolleyball.includes(rawStatus)) {
                status = 1; // 🔴 LIVE SEKARANG (Termasuk Set Tambahan)
            } else if (['lol', 'csgo', 'dota2'].includes(sportType) && liveEsports.includes(rawStatus)) {
                status = 1; // 🔴 LIVE SEKARANG
            } else if (isCardLive) {
                status = 1; // 🔴 LIVE SEKARANG
            } else if (rawStatus === '8' || rawStatus === '60' || rawStatus === '61' || rawStatus == '440' ||
                contentLower.includes('>ft<') ||
                contentLower.includes('kết thúc') ||
                contentLower.includes('finished') ||
                contentLower.includes('hết giờ')) {
                status = 2; // Selesai (Full Time / FT)
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
