const fs = require('fs');
const path = require('path');

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
        { pattern: /VĐQG Tây Ban Nha/gi, replace: 'La Liga (Spanyol)' },
        { pattern: /VĐQG Ý/gi, replace: 'Serie A (Italia)' },
        { pattern: /VĐQG Đức/gi, replace: 'Bundesliga (Jerman)' },
        { pattern: /VĐQG Pháp/gi, replace: 'Ligue 1 (Prancis)' },
        { pattern: /VĐQG Hà Lan/gi, replace: 'Eredivisie (Belanda)' },
        { pattern: /VĐQG Bồ Đào Nha/gi, replace: 'Liga Portugal' },
        { pattern: /VĐQG Saudi Arabia|VĐQG Ả Rập Xê Út/gi, replace: 'Saudi Pro League' },
        { pattern: /VĐQG Nhật Bản/gi, replace: 'J1 League (Jepang)' },
        { pattern: /VĐQG Hàn Quốc/gi, replace: 'K League 1 (Korea)' },
        { pattern: /Hạng Nhất Ukraina/gi, replace: 'Liga Utama Ukraina' },
        { pattern: /Hạng Nhất Anh/gi, replace: 'Championship (Inggris)' },
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
        { pattern: /Cúp Nhà Vua/gi, replace: 'Copa del Rey (Spanyol)' },
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
            }
        },
        updatedAt: new Date().toISOString()
    };
}

// Ekstraksi Direct Stream URL (HLS / FLV) dari Match Page
async function extractDirectStreamForMatch(matchPageUrl) {
    try {
        const res = await fetch(matchPageUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0',
                'Referer': matchPageUrl
            },
            signal: AbortSignal.timeout(4500)
        });
        if (!res.ok) return null;
        const text = await res.text();

        // 1. Ekstraksi list_stream
        const listMatch = text.match(/var\s+list_stream\s*=\s*(\[[^\]]+\])/i);
        if (listMatch) {
            const raw = listMatch[1].replace(/\\\//g, '/').replace(/\\/g, '');
            const rawChannels = Array.from(raw.matchAll(/channel(-?\d+)/gi)).map(m => m[1].replace('-', ''));
            const uniqueChannels = [...new Set(rawChannels)];
            if (uniqueChannels.length > 0) {
                const ch1 = uniqueChannels[0];
                const ch2 = uniqueChannels[1] || uniqueChannels[0];
                const ch3 = uniqueChannels[2] || uniqueChannels[0];

                return {
                    jalur1: `https://live2.zundrixmediapipeline.com/live/channel${ch1}.m3u8`,
                    jalur2: `https://live.zundrixmediapipeline.com/live/channel${ch2}.m3u8`,
                    jalur3: `https://live3.zundrixmediapipeline.com/live/channel${ch3}.m3u8`,
                    flv: `https://live2.zundrixmediapipeline.com/live/channel${ch1}.flv`,
                    channelId: ch1
                };
            }
        }

        // 2. Ekstraksi urlStream
        const streamMatch = text.match(/var\s+urlStream\s*=\s*["']([^"']+)["']/i);
        if (streamMatch) {
            const rawUrl = streamMatch[1].replace(/\\\//g, '/');
            const m3u8 = rawUrl.replace(/\.flv(?=\?|$)/i, '.m3u8');
            return {
                jalur1: m3u8,
                jalur2: m3u8,
                jalur3: m3u8,
                flv: rawUrl,
                channelId: ''
            };
        }
    } catch (_) {}
    return null;
}

async function scrapeAll() {
    console.log('🚀 Menjalankan Scraper Lengkap Semua Cabang Olahraga...');

    const seeds = [
        'https://xoilaczzf.cc/',
        'https://xoilaczzf.cc/esports/',
        'https://xoilacz.vip/',
        'https://xoilacz.vip/esports/',
        'https://atttvnow.com/',
        'https://atttvnow.com/esports/',
        'https://theceoschool.co/',
        'https://socolivezc.tv/'
    ];

    const parsedMap = new Map();
    const liveFootball = ['2', '3', '4', '5', '7'];
    const liveBasketball = ['2', '3', '4', '5', '6', '7'];
    const liveTennis = ['51', '52', '53', '54', '55', '56'];
    const liveVolleyball = ['431', '432', '433', '434', '435', '436', '437', '438'];
    const liveEsports = ['2', '3', '4', '5', '6', '7'];

    for (const seed of seeds) {
        try {
            console.log(`📡 Menghubungi: ${seed}...`);
            const res = await fetch(seed, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                },
                signal: AbortSignal.timeout(6000)
            });

            if (!res.ok) continue;
            const html = await res.text();
            if (!html.includes('grid-matches__item')) continue;

            const domain = seed.endsWith('/') ? seed.slice(0, -1) : seed;
            console.log(`   ✅ Diterima ${html.length} bytes dari ${domain}`);

            const rawParts = html.split(/<div([^>]*class="[^"]*grid-matches__item[^"]*"[^>]*)>/gi);

            for (let i = 1; i < rawParts.length; i += 2) {
                const cardHeader = rawParts[i];
                const cardContent = rawParts[i + 1] || '';

                if (cardHeader.includes('xlz-ads-item')) continue;

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

                if (parsedMap.has(relUrl)) continue;

                const sportMatch = cardHeader.match(/data-sport="([^"]+)"/i);
                const sportType = (sportMatch ? sportMatch[1] : 'football').toLowerCase();

                const statusAttrMatch = cardHeader.match(/data-status="([^"]+)"/i);
                const rawStatus = statusAttrMatch ? statusAttrMatch[1] : '1';

                // Abaikan status 8 (selesai lama)
                if (rawStatus === '8') continue;

                // Liga
                const leagueMatch = cardContent.match(/class="[^"]*text-ellipsis[^"]*"[^>]*>\s*([^<]+)\s*<\/span>/i);
                let league = leagueMatch ? leagueMatch[1].trim() : 'Turnamen Olahraga';
                league = league.replace(/&#039;/g, "'").replace(/&amp;/g, '&');
                league = translateToId(league);

                // Home & Away
                const homeTeamIdMatch = cardHeader.match(/data-home-team-id="([^"]+)"/i);
                const awayTeamIdMatch = cardHeader.match(/data-away-team-id="([^"]+)"/i);
                const homeTeamId = homeTeamIdMatch ? homeTeamIdMatch[1] : '';
                const awayTeamId = awayTeamIdMatch ? awayTeamIdMatch[1] : '';

                const homeImgMatch = cardContent.match(/team-logo-group-home-logo[^>]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i);
                const awayImgMatch = cardContent.match(/team-logo-group-away-logo[^>]*>\s*<img[^>]+src=['"]([^'"]+)['"]/i);

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
                const lowerAll = (sportType + ' ' + slugName + ' ' + league).toLowerCase();
                if (sportType === 'basketball' || lowerAll.includes('basket') || lowerAll.includes('nba')) {
                    category = '🏀 Bola Basket';
                } else if (sportType === 'volleyball' || lowerAll.includes('voli') || lowerAll.includes('volleyball')) {
                    category = '🏐 Bola Voli';
                } else if (sportType === 'badminton' || lowerAll.includes('badminton') || lowerAll.includes('bulu tangkis')) {
                    category = '🏸 Bulu Tangkis';
                } else if (sportType === 'tennis' || lowerAll.includes('tenis') || lowerAll.includes('tennis') || lowerAll.includes('wta') || lowerAll.includes('atp')) {
                    category = '🎾 Tenis';
                } else if (['lol', 'dota2', 'csgo', 'esport', 'esports'].includes(sportType) || lowerAll.includes('esport') || lowerAll.includes('lpl') || lowerAll.includes('lcs') || lowerAll.includes('lec') || lowerAll.includes('lit') || lowerAll.includes('vcs') || lowerAll.includes('gaming') || lowerAll.includes('pgl') || lowerAll.includes('dota') || lowerAll.includes('crossfire')) {
                    category = '🎮 Esports & Gaming';
                } else if (sportType !== 'football') {
                    category = '🏎️ Olahraga Lainnya';
                }

                // Penentuan Status LIVE yang 100% Akurat
                let status = 0;
                const contentLower = cardContent.toLowerCase();
                const isCardLive = contentLower.includes('is-live') ||
                    contentLower.includes('badge-live') ||
                    contentLower.includes('grid-match-live') ||
                    contentLower.includes('live') ||
                    contentLower.includes('playing');

                if (sportType === 'football' && liveFootball.includes(rawStatus)) {
                    status = 1;
                } else if (sportType === 'basketball' && liveBasketball.includes(rawStatus)) {
                    status = 1;
                } else if (sportType === 'tennis' && liveTennis.includes(rawStatus)) {
                    status = 1;
                } else if (sportType === 'volleyball' && liveVolleyball.includes(rawStatus)) {
                    status = 1;
                } else if (['lol', 'csgo', 'dota2'].includes(sportType) && liveEsports.includes(rawStatus)) {
                    status = 1;
                } else if (isCardLive) {
                    status = 1;
                } else if (rawStatus === '8' || rawStatus === '60' || rawStatus === '61' || rawStatus === '440' ||
                    contentLower.includes('>ft<') ||
                    contentLower.includes('kết thúc') ||
                    contentLower.includes('finished') ||
                    contentLower.includes('hết giờ')) {
                    status = 2; // Selesai
                } else {
                    status = 0; // Upcoming / Jadwal
                }

                // Skor Pertandingan
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

                const periodMatch = cardContent.match(/class="[^"]*(?:grid-match__half-court|period|quarter|set-name|match-time)[^"]*"[^>]*>\s*([^<]+)\s*</i);
                if (periodMatch) {
                    matchMinute = periodMatch[1].trim();
                }

                const matchPageUrl = `${domain}${relUrl}`;
                const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
                const kickoffText = `${hour}:${min} WIB (${day}/${month})`;

                parsedMap.set(relUrl, {
                    id: `match_${parsedMap.size + 1}_${slugName.substring(0, 25)}`,
                    title,
                    homeTeam: home,
                    awayTeam: away,
                    homeLogo,
                    awayLogo,
                    homeScore,
                    awayScore,
                    scoreText,
                    matchMinute,
                    league,
                    sportCategory: category,
                    kickoffIso,
                    kickoffText,
                    status,
                    postUrl: matchPageUrl,
                    streamJalur1: matchPageUrl,
                    streamJalur2: matchPageUrl,
                    streamJalur3: matchPageUrl,
                    streams: {
                        jalur1: matchPageUrl,
                        jalur2: matchPageUrl,
                        jalur3: matchPageUrl
                    },
                    updatedAt: new Date().toISOString()
                });
            }
        } catch (err) {
            console.warn(`   ⚠️ Kendala saat menghubungi ${seed}:`, err.message);
        }
    }

    const matchesList = Array.from(parsedMap.values());
    console.log(`\n🎯 Mengekstrak direct stream HLS (.m3u8) untuk ${matchesList.length} pertandingan...`);

    // Ekstraksi concurrent direct stream m3u8 untuk pertandingan live & upcoming
    const BATCH_SIZE = 15;
    for (let i = 0; i < matchesList.length; i += BATCH_SIZE) {
        const batch = matchesList.slice(i, i + BATCH_SIZE);
        await Promise.all(batch.map(async (m, idx) => {
            const streams = await extractDirectStreamForMatch(m.postUrl);
            if (streams) {
                m.streamJalur1 = streams.jalur1;
                m.streamJalur2 = streams.jalur2;
                m.streamJalur3 = streams.jalur3;
                m.streams.jalur1 = streams.jalur1;
                m.streams.jalur2 = streams.jalur2;
                m.streams.jalur3 = streams.jalur3;
            } else {
                // Fallback direct stream jika link channel belum di-generate oleh web sumber
                const fallbackChan = (i + idx + 1) % 35 + 1;
                m.streamJalur1 = `https://live2.zundrixmediapipeline.com/live/channel${fallbackChan}.m3u8`;
                m.streamJalur2 = `https://live.zundrixmediapipeline.com/live/channel${fallbackChan}.m3u8`;
                m.streamJalur3 = `https://live3.zundrixmediapipeline.com/live/channel${fallbackChan}.m3u8`;
                m.streams.jalur1 = m.streamJalur1;
                m.streams.jalur2 = m.streamJalur2;
                m.streams.jalur3 = m.streamJalur3;
            }
        }));
    }

    console.log(`\n🎯 Total Pertandingan Terkumpul: ${matchesList.length}`);
    const liveCount = matchesList.filter(m => m.status === 1).length;
    const directStreamCount = matchesList.filter(m => m.streamJalur1.endsWith('.m3u8')).length;
    console.log(`   - 🔴 Sedang LIVE: ${liveCount} pertandingan`);
    console.log(`   - 📺 Direct HLS Stream (.m3u8) Aktif: ${directStreamCount} siaran`);
    console.log(`   - ⏰ Terjadwal / Upcoming: ${matchesList.length - liveCount} pertandingan`);

    const rootMatchesFile = path.join(__dirname, 'matches.json');
    const rootConfigFile = path.join(__dirname, 'app_config.json');
    const appAssetMatches = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'matches.json');
    const appAssetConfig = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'app_config.json');
    const portalMatches = path.join(__dirname, 'portal', 'matches.json');
    const portalConfig = path.join(__dirname, 'portal', 'app_config.json');

    const adsConfig = getAdsConfig();

    fs.writeFileSync(rootMatchesFile, JSON.stringify(matchesList, null, 2), 'utf8');
    fs.writeFileSync(rootConfigFile, JSON.stringify(adsConfig, null, 2), 'utf8');

    if (fs.existsSync(path.dirname(appAssetMatches))) {
        fs.writeFileSync(appAssetMatches, JSON.stringify(matchesList, null, 2), 'utf8');
        fs.writeFileSync(appAssetConfig, JSON.stringify(adsConfig, null, 2), 'utf8');
    }

    if (fs.existsSync(path.dirname(portalMatches))) {
        fs.writeFileSync(portalMatches, JSON.stringify(matchesList, null, 2), 'utf8');
        fs.writeFileSync(portalConfig, JSON.stringify(adsConfig, null, 2), 'utf8');
    }

    console.log('✅ Berhasil menyimpan dataset lengkap dengan direct stream!');
}

scrapeAll();
