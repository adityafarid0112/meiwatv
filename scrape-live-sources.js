const fs = require('fs');
const path = require('path');

// Bersihkan karakter diakritik khusus Vietnam dan terjemahkan kata negara/gender
function cleanVietnameseDiacritics(str) {
    if (!str) return '';
    let text = str.trim();

    const teamWordMap = [
        { pattern: /\bNữ\s+/gi, replace: '' },
        { pattern: /\bNam\s+/gi, replace: '' },
        { pattern: /\bBa Lan\b/gi, replace: 'Polandia' },
        { pattern: /\bĐức\b/gi, replace: 'Jerman' },
        { pattern: /\bTây Ban Nha\b/gi, replace: 'Spanyol' },
        { pattern: /\bÝ\b/g, replace: 'Italia' },
        { pattern: /\bPháp\b/gi, replace: 'Prancis' },
        { pattern: /\bAnh\b/g, replace: 'Inggris' },
        { pattern: /\bHà Lan\b/gi, replace: 'Belanda' },
        { pattern: /\bBồ Đào Nha\b/gi, replace: 'Portugal' },
        { pattern: /\bThái Lan\b/gi, replace: 'Thailand' },
        { pattern: /\bNhật Bản\b/gi, replace: 'Jepang' },
        { pattern: /\bHàn Quốc\b/gi, replace: 'Korea Selatan' },
        { pattern: /\bTrung Quốc\b/gi, replace: 'China' },
        { pattern: /\bMỹ\b|\bHoa Kỳ\b/gi, replace: 'Amerika Serikat' },
        { pattern: /\bÚc\b/gi, replace: 'Australia' },
        { pattern: /\bHy Lạp\b/gi, replace: 'Yunani' },
        { pattern: /\bThụy Sĩ\b/gi, replace: 'Swiss' },
        { pattern: /\bThụy Điển\b/gi, replace: 'Swedia' },
        { pattern: /\bThổ Nhĩ Kỳ\b/gi, replace: 'Turki' },
        { pattern: /\bNga\b/g, replace: 'Rusia' },
        { pattern: /\bẢ Rập Xê Út\b|\bẢ Rập Saudi\b/gi, replace: 'Arab Saudi' },
        { pattern: /\bViệt Nam\b/gi, replace: 'Vietnam' }
    ];

    teamWordMap.forEach(item => { text = text.replace(item.pattern, item.replace); });

    return text
        .replace(/[àáạảãâầấậẩẫăằắặẳẵ]/g, 'a')
        .replace(/[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]/g, 'A')
        .replace(/[èéẹẻẽêềếệểễ]/g, 'e')
        .replace(/[ÈÉẸẺẼÊỀẾỆỂỄ]/g, 'E')
        .replace(/[ìíịỉĩ]/g, 'i')
        .replace(/[ÌÍỊỈĨ]/g, 'I')
        .replace(/[òóọỏõôồốộổỗơờớợởỡ]/g, 'o')
        .replace(/[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]/g, 'O')
        .replace(/[ùúụủũưừứựửữ]/g, 'u')
        .replace(/[ÙÚỤỦŨƯỪỨỰỬỮ]/g, 'U')
        .replace(/[ỳýỵỷỹ]/g, 'y')
        .replace(/[ỲÝỴỶỸ]/g, 'Y')
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'D')
        .replace(/\s+/g, ' ')
        .trim();
}

// Pemetaan Channel HD DaddyLive untuk Multi-Link Redundancy
function getDaddyLiveMapping(sportCategory, league, title, slugName) {
    const text = (sportCategory + ' ' + league + ' ' + title + ' ' + slugName).toLowerCase();

    // 1. Motorsport & MotoGP (TNT Sports 2 UK, Sky Sports F1)
    if (text.includes('motogp') || text.includes('moto2') || text.includes('moto3') || text.includes('balap') || text.includes('motor') || text.includes('wsbk')) {
        return {
            name: 'TNT Sports 2 HD / SPOTV',
            url: 'https://daddylive.app/player/embed.php?id=32'
        };
    }
    if (text.includes('formula 1') || text.includes('f1') || text.includes('grand prix')) {
        return {
            name: 'Sky Sports F1 HD',
            url: 'https://daddylive.app/player/embed.php?id=38'
        };
    }

    // 2. Bulu Tangkis (BWF Badminton - Astro SuperSport & SPOTV)
    if (text.includes('badminton') || text.includes('bulu tangkis') || text.includes('bwf') || text.includes('all england') || text.includes('indonesia open') || text.includes('thomas') || text.includes('uber')) {
        return {
            name: 'Astro SuperSport 1 HD',
            url: 'https://daddylive.app/player/embed.php?id=123'
        };
    }

    // 3. Bola Voli (KOVO V-League Korea & Proliga - Astro SuperSport & Eurosport)
    if (text.includes('voli') || text.includes('volleyball') || text.includes('v-league') || text.includes('kovo') || text.includes('proliga') || text.includes('vnl')) {
        return {
            name: 'Astro SuperSport 3 HD / Eurosport',
            url: 'https://daddylive.app/player/embed.php?id=125'
        };
    }

    // 4. Sepak Bola Populer (Sky Sports Premier League, TNT Sports, beIN Sports HD)
    if (text.includes('inggris') || text.includes('premier league') || text.includes('championship')) {
        return {
            name: 'Sky Sports Premier League / TNT 1 HD',
            url: 'https://daddylive.app/player/embed.php?id=39'
        };
    }
    if (text.includes('champions') || text.includes('ucl') || text.includes('europa') || text.includes('uefa')) {
        return {
            name: 'TNT Sports 1 HD / beIN HD',
            url: 'https://daddylive.app/player/embed.php?id=31'
        };
    }
    if (text.includes('spanyol') || text.includes('la liga') || text.includes('italia') || text.includes('serie a')) {
        return {
            name: 'beIN Sports 1 HD / DAZN Spain',
            url: 'https://daddylive.app/player/embed.php?id=91'
        };
    }
    if (text.includes('jerman') || text.includes('bundesliga') || text.includes('prancis') || text.includes('ligue 1')) {
        return {
            name: 'Sky Bundesliga HD / DAZN DE',
            url: 'https://daddylive.app/player/embed.php?id=240'
        };
    }

    // 5. Bola Basket (NBA TV HD & NBA League Pass)
    if (text.includes('basket') || text.includes('nba')) {
        return {
            name: 'NBA TV USA HD',
            url: 'https://daddylive.app/player/embed.php?id=404'
        };
    }

    // 6. Tenis (Sky Sport Tennis & Court Tennis)
    if (text.includes('tenis') || text.includes('tennis') || text.includes('wta') || text.includes('atp') || text.includes('grand slam')) {
        return {
            name: 'Sky Sport Tennis HD',
            url: 'https://daddylive.app/player/embed.php?id=576'
        };
    }

    return null;
}

// Terjemahkan nama liga, turnamen, dan tim ke Bahasa Indonesia Resmi
function translateToId(str) {
    if (!str) return '';
    let text = str.trim();

    const directList = [
        // Bangladesh & negara lain yang memakai nama 'Premier League'
        { pattern: /Bangladesh\s*Premier\s*League/gi, replace: 'Liga Utama Bangladesh' },
        { pattern: /Czech\s*3\s*liga/gi, replace: 'Liga 3 Ceko' },
        { pattern: /Ngoại Hạng Darwin/gi, replace: 'Liga Darwin Australia' },

        // Liga Inggris
        { pattern: /Ngoại Hạng Anh|Premier League(\s*\(Inggris\))?/gi, replace: 'Liga Inggris' },
        { pattern: /Hạng Nhất Anh|Championship(\s*\(Inggris\))?/gi, replace: 'Liga Championship Inggris' },
        { pattern: /Cúp FA|FA Cup(\s*\(Inggris\))?/gi, replace: 'Piala FA Inggris' },
        { pattern: /Cúp Liên Đoàn Anh|EFL Cup|Carabao Cup/gi, replace: 'Piala Carabao Inggris' },

        // Indonesia
        { pattern: /VĐQG Indonesia|Liga\s*1\s*Indonesia|BRI Liga 1(\s*Indonesia)?/gi, replace: 'BRI Liga 1 Indonesia' },
        { pattern: /Hạng 2 Indonesia|Liga\s*2\s*Indonesia/gi, replace: 'Liga 2 Indonesia' },
        { pattern: /Hạng 3 Indonesia|Liga\s*3\s*Indonesia/gi, replace: 'Liga 3 Indonesia' },

        // Vietnam
        { pattern: /Cúp Quốc Gia Việt Nam|Cúp Quốc Gia/gi, replace: 'Piala Nasional Vietnam' },
        { pattern: /VĐQG Việt Nam|V\.League\s*1(\s*\(Vietnam\))?/gi, replace: 'Liga Vietnam (V.League 1)' },
        { pattern: /Hạng Nhất Việt Nam|V\.League\s*2(\s*\(Vietnam\))?/gi, replace: 'Liga Vietnam 2 (V.League 2)' },

        // Spanyol
        { pattern: /VĐQG Tây Ban Nha|La\s*Liga(\s*\(Spanyol\))?(?!\s*2)/gi, replace: 'La Liga Spanyol' },
        { pattern: /Hạng 2 Tây Ban Nha|La\s*Liga\s*2(\s*\(Spanyol\))?|Segunda\s*División/gi, replace: 'La Liga 2 Spanyol' },
        { pattern: /Cúp Nhà Vua|Copa del Rey(?! de Baloncesto)/gi, replace: 'Piala Raja Spanyol (Copa del Rey)' },
        { pattern: /Copa del Rey de Baloncesto/gi, replace: 'Piala Raja Basket Spanyol' },
        { pattern: /Spain Basketball Supercopa/gi, replace: 'Piala Super Basket Spanyol' },

        // Italia
        { pattern: /VĐQG Ý|Serie\s*A(\s*\(Italia\))?/gi, replace: 'Serie A Italia' },
        { pattern: /Hạng 2 Ý|Serie\s*B(\s*\(Italia\))?/gi, replace: 'Serie B Italia' },
        { pattern: /Cúp Quốc Gia Ý|Coppa Italia/gi, replace: 'Piala Italia (Coppa Italia)' },
        { pattern: /Italy Super Cup/gi, replace: 'Piala Super Italia' },

        // Jerman
        { pattern: /VĐQG Đức|Bundesliga(\s*\(Jerman\))?(?!\s*2)(?! Basket)/gi, replace: 'Bundesliga Jerman' },
        { pattern: /Hạng 2 Đức|2\.\s*Bundesliga(\s*\(Jerman\))?|Bundesliga\s*2(\s*\(Jerman\))?/gi, replace: '2. Bundesliga Jerman' },
        { pattern: /Cúp Quốc Gia Đức|DFB[- ]Pokal/gi, replace: 'Piala DFB Jerman' },
        { pattern: /Basketball Bundesliga/gi, replace: 'Bundesliga Basket Jerman' },

        // Prancis
        { pattern: /VĐQG Pháp|Ligue\s*1(\s*\(Prancis\))?/gi, replace: 'Ligue 1 Prancis' },
        { pattern: /Hạng 2 Pháp|Ligue\s*2(\s*\(Prancis\))?/gi, replace: 'Ligue 2 Prancis' },

        // Belanda & Portugal
        { pattern: /VĐQG Hà Lan|Eredivisie(\s*\(Belanda\))?/gi, replace: 'Eredivisie Belanda' },
        { pattern: /VĐQG Bồ Đào Nha|Liga\s*Portugal|Primeira\s*Liga/gi, replace: 'Liga Portugal' },

        // Arab Saudi
        { pattern: /VĐQG Saudi Arabia|VĐQG Ả Rập Xê Út|Saudi\s*Pro\s*League/gi, replace: 'Saudi Pro League (Arab Saudi)' },

        // Jepang
        { pattern: /VĐQG Nhật Bản|J1\s*League(\s*\(Jepang\))?/gi, replace: 'J1 League Jepang' },
        { pattern: /Hạng 2 Nhật Bản|J2\s*League(\s*\(Jepang\))?/gi, replace: 'J2 League Jepang' },
        { pattern: /Hạng 3 Nhật Bản|J3\s*League(\s*\(Jepang\))?/gi, replace: 'J3 League Jepang' },
        { pattern: /Japan Football League|\bJFL\b/gi, replace: 'Liga Sepak Bola Jepang (JFL)' },

        // Korea Selatan
        { pattern: /VĐQG Hàn Quốc|K\s*League\s*1(\s*\(Korea Selatan\))?/gi, replace: 'K League 1 Korea Selatan' },
        { pattern: /Hạng 2 Hàn Quốc|K\s*League\s*2(\s*\(Korea Selatan\))?/gi, replace: 'K League 2 Korea Selatan' },

        // Lainnya
        { pattern: /Hạng Nhất Ukraina/gi, replace: 'Liga Utama Ukraina' },
        { pattern: /Hạng 2 Trung Quốc|China\s*League\s*One/gi, replace: 'Liga 2 China' },
        { pattern: /Hạng 2 Romania/gi, replace: 'Liga 2 Rumania' },
        { pattern: /National Basketball League|^NBL$/gi, replace: 'Liga Basket Australia (NBL)' },
        { pattern: /Philippines University Athletic Association|^UAAP$/gi, replace: 'Liga Kampus Filipina (UAAP)' },
        { pattern: /Turkish Basketball First League/gi, replace: 'Liga Basket Turki (TBL)' },
        { pattern: /Vietnam VBA|^VBA$/gi, replace: 'Liga Basket Vietnam (VBA)' },
        { pattern: /VTB United League Supercup/gi, replace: 'Piala Super VTB Liga' },
        { pattern: /Women National Basketball Association|^WNBA$/gi, replace: 'Liga Basket Wanita Amerika (WNBA)' },
        { pattern: /Liga Nacional de Baloncesto Profesional|^LNBP$/gi, replace: 'Liga Basket Meksiko (LNBP)' },
        { pattern: /Asian Games - Women'?s Basketball/gi, replace: 'Asian Games - Bola Basket Putri' },
        { pattern: /WTA Seoul.*/gi, replace: 'WTA Seoul Tenis Putri' },
        { pattern: /Davis Cup/gi, replace: 'Piala Davis Tenis' },
        { pattern: /European Championships/gi, replace: 'Kejuaraan Eropa' },

        // Esports
        { pattern: /LPL Regional Finals 2026/gi, replace: 'Final Regional LPL 2026 (LoL)' },
        { pattern: /VCS Finals 2026/gi, replace: 'Final VCS 2026 (LoL)' },
        { pattern: /Rift Legends Summer 2026/gi, replace: 'Rift Legends Musim Panas 2026' },
        { pattern: /LEC Summer 2026/gi, replace: 'LEC Musim Panas 2026 (LoL)' },
        { pattern: /LIT Summer 2026/gi, replace: 'LIT Musim Panas 2026' },
        { pattern: /LCS Summer 2026/gi, replace: 'LCS Musim Panas 2026 (LoL)' },
        { pattern: /PGL Wallachia Season 9/gi, replace: 'PGL Wallachia Musim 9 (Dota 2)' },
        { pattern: /European Pro League Season 40/gi, replace: 'Liga Pro Eropa Musim 40' },
        { pattern: /CCT 2026 Europe Series 9/gi, replace: 'CCT 2026 Seri Eropa 9 (CS2)' },
        { pattern: /StarLadder StarSeries Season 22/gi, replace: 'StarLadder StarSeries Musim 22 (CS2)' },
        { pattern: /NODWIN Clutch Series 12/gi, replace: 'NODWIN Clutch Seri 12' },
        { pattern: /HyperX Retake Season 12/gi, replace: 'HyperX Retake Musim 12' },
        { pattern: /CROSSFIRE Season 6/gi, replace: 'CROSSFIRE Musim 6' },

        // Turnamen & Piala Internasional
        { pattern: /Cúp C1|Champions League/gi, replace: 'Liga Champions' },
        { pattern: /Cúp C2|Europa League/gi, replace: 'Liga Europa' },
        { pattern: /Cúp C3|Conference League/gi, replace: 'Liga Konferensi Eropa' },
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
        { pattern: /Hạng 2/gi, replace: 'Divisi 2' },
        { pattern: /Hạng 3/gi, replace: 'Divisi 3' },
        { pattern: /Hạng 4/gi, replace: 'Divisi 4' },
        { pattern: /Hạng Nhất/gi, replace: 'Divisi Utama' },
        { pattern: /Ngoại Hạng/gi, replace: 'Liga Utama' },
        { pattern: /VĐQG/gi, replace: 'Liga Utama' },
        { pattern: /Cúp/gi, replace: 'Piala' }
    ];

    for (const item of directList) {
        if (item.pattern.test(text)) {
            return text.replace(item.pattern, item.replace).trim();
        }
    }

    const wordMap = [
        { pattern: /\bSeason\b/gi, replace: 'Musim' },
        { pattern: /\bSeries\b/gi, replace: 'Seri' },
        { pattern: /\bSummer\b/gi, replace: 'Musim Panas' },
        { pattern: /\bSpring\b/gi, replace: 'Musim Semi' },
        { pattern: /\bAutumn\b|\bFall\b/gi, replace: 'Musim Gugur' },
        { pattern: /\bWinter\b/gi, replace: 'Musim Dingin' },
        { pattern: /\bFinals\b/gi, replace: 'Final' },
        { pattern: /\bSemifinals\b/gi, replace: 'Semifinal' },
        { pattern: /\bQuarterfinals\b/gi, replace: 'Perempat Final' },
        { pattern: /\bSingles\b/gi, replace: 'Tunggal' },
        { pattern: /\bDoubles\b/gi, replace: 'Ganda' },
        { pattern: /\bViệt Nam\b|\bViet Nam\b/gi, replace: 'Vietnam' },
        { pattern: /\bWomen\b|\bNữ\b/gi, replace: 'Wanita' },
        { pattern: /\bMen\b|(?<!Việt\s|Viet\s)\bNam\b/gi, replace: 'Pria' },
        { pattern: /\bTrẻ\b/gi, replace: 'Muda' },
        { pattern: /\bCLB\s+/gi, replace: 'Klub ' },
        { pattern: /\bNhật Bản\b/gi, replace: 'Jepang' },
        { pattern: /\bHàn Quốc\b/gi, replace: 'Korea Selatan' },
        { pattern: /\bTrung Quốc\b/gi, replace: 'China' },
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
        { pattern: /\bẢ Rập Xê Út\b|\bẢ Rập Saudi\b/gi, replace: 'Arab Saudi' }
    ];

    wordMap.forEach(item => { text = text.replace(item.pattern, item.replace); });

    text = text
        .replace(/\s*\(\s*Jepang\s*\)\s*\(\s*Jepang\s*\)/gi, ' Jepang')
        .replace(/Jepang\s*\(\s*Jepang\s*\)/gi, 'Jepang')
        .replace(/Inggris\s*\(\s*Inggris\s*\)/gi, 'Inggris')
        .replace(/Spanyol\s*\(\s*Spanyol\s*\)/gi, 'Spanyol')
        .replace(/Italia\s*\(\s*Italia\s*\)/gi, 'Italia')
        .replace(/Jerman\s*\(\s*Jerman\s*\)/gi, 'Jerman')
        .replace(/Prancis\s*\(\s*Prancis\s*\)/gi, 'Prancis')
        .replace(/Vietnam\s*\(\s*Vietnam\s*\)/gi, 'Vietnam')
        .replace(/Indonesia\s*\(\s*Indonesia\s*\)/gi, 'Indonesia');

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

async function extractDaddyDirectStream(embedUrl) {
    if (!embedUrl || !embedUrl.startsWith('http')) return null;
    try {
        const res1 = await fetch(embedUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
                'Referer': 'https://daddylive.app/'
            },
            signal: AbortSignal.timeout(6000)
        });
        if (!res1.ok) return null;
        const html1 = await res1.text();

        // 1. Direct .m3u8 in html1
        let directMatch = html1.match(/var\s+playbackURL\s*=\s*["'](https?:[^"']+\.m3u8[^"']*)["']/i) ||
                          html1.match(/["'](https?:[^\s"'<>]+\.m3u8[^\s"'<>]*)["']/i);
        if (directMatch) return directMatch[1].replace(/\\\//g, '/');

        // 2. Find player URL / iframe (supports StreamTP, FlyEmbed, EpiEmbeds, etc.)
        let playerUrl = null;
        const iframeMatch = html1.match(/src=["'](https?:\/\/[^"']*flyembed[^\s"'<>]+)["']/i) ||
                            html1.match(/src=["'](https?:\/\/[^"']*stream[^\s"'<>]+)["']/i) ||
                            html1.match(/src=["'](https?:\/\/[^"']+\.php\?stream=[^"']+)["']/i) ||
                            html1.match(/src=["'](https?:\/\/[^"']*embed[^\s"'<>]+)["']/i);
        if (iframeMatch) {
            playerUrl = iframeMatch[1];
        } else {
            const jsonMatch = html1.match(/const\s+PLAYERS\s*=\s*(\[[^\]]+\])/i);
            if (jsonMatch) {
                try {
                    const players = JSON.parse(jsonMatch[1]);
                    if (players[0] && players[0].src) playerUrl = players[0].src;
                } catch (_) {}
            }
        }

        if (!playerUrl) return null;

        const res2 = await fetch(playerUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': embedUrl
            },
            signal: AbortSignal.timeout(6000)
        });
        if (!res2.ok) return null;
        const html2 = await res2.text();

        // Check if html2 has direct m3u8
        directMatch = html2.match(/var\s+playbackURL\s*=\s*["'](https?:[^"']+\.m3u8[^"']*)["']/i) ||
                      html2.match(/["'](https?:[^\s"'<>]+\.m3u8[^\s"'<>]*)["']/i);
        if (directMatch) return directMatch[1].replace(/\\\//g, '/');

        // Check if html2 embeds another iframe (like epiembeds, rockystream)
        const nestedIframe = html2.match(/src=["'](https?:\/\/[^"']*epiembeds[^\s"'<>]+)["']/i) ||
                             html2.match(/src=["'](https?:\/\/[^"']*rockystream[^\s"'<>]+)["']/i) ||
                             html2.match(/<iframe[^>]+src=["'](https?:\/\/[^"']+)["']/i);
        if (nestedIframe) {
            let nextUrl = nestedIframe[1];
            const res3 = await fetch(nextUrl, {
                headers: { 'User-Agent': 'Mozilla/5.0', 'Referer': playerUrl },
                signal: AbortSignal.timeout(6000)
            });
            if (!res3.ok) return null;
            const html3 = await res3.text();

            // Check if html3 has deobfuscation script (epiembeds pattern)
            const deobMatch = html3.match(/var\s+(_[a-z0-9]+)=\[([0-9,]+)\][\s\S]*?(_[a-z0-9]+)=([0-9]+)[\s\S]*?(_[a-z0-9]+)=([0-9]+)[\s\S]*?String\.fromCharCode/i);
            if (deobMatch) {
                const arr = deobMatch[2].split(',').map(Number);
                const vk = Number(deobMatch[4]);
                const ko = Number(deobMatch[6]);
                let decoded = '';
                for (let i = 0; i < arr.length; i++) {
                    decoded += String.fromCharCode(((arr[i] ^ vk) - ko + 256) & 255);
                }
                const urlMatch = decoded.match(/url\s*=\s*["'](https?:[^"']+\.m3u8[^"']*)["']/i);
                if (urlMatch) return urlMatch[1];
            }

            directMatch = html3.match(/var\s+playbackURL\s*=\s*["'](https?:[^"']+\.m3u8[^"']*)["']/i) ||
                          html3.match(/["'](https?:[^\s"'<>]+\.m3u8[^\s"'<>]*)["']/i);
            if (directMatch) return directMatch[1].replace(/\\\//g, '/');
        }

        return null;
    } catch (_) {
        return null;
    }
}

async function fetchDaddyLiveEvents() {
    console.log('📡 Mengambil jadwal siaran resmi DaddyLive (https://daddylive.app/api/events)...');
    try {
        const res = await fetch('https://daddylive.app/api/events', {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
                'Accept': 'application/json'
            },
            signal: AbortSignal.timeout(8000)
        });
        if (!res.ok) {
            console.warn(`   ⚠️ DaddyLive API response code: ${res.status}`);
            return [];
        }
        const data = await res.json();
        const categories = data.categories || {};
        const events = [];

        for (const [catName, list] of Object.entries(categories)) {
            if (!Array.isArray(list)) continue;
            for (const item of list) {
                if (!item || !item.event) continue;
                events.push({
                    rawCategory: catName,
                    time: item.time || 'Live',
                    event: item.event,
                    channels: Array.isArray(item.channels) ? item.channels : [],
                    source: item.source || 'tv1'
                });
            }
        }
        console.log(`   ✅ Diterima ${events.length} event siaran HD dari DaddyLive API!`);
        return events;
    } catch (err) {
        console.warn('   ⚠️ Gagal mengambil DaddyLive API:', err.message);
        return [];
    }
}

async function scrapeAll() {
    console.log('🚀 Menjalankan Scraper Lengkap Semua Cabang Olahraga (DaddyLive + Xoilac)...');

    // 1. Ambil seluruh event dari DaddyLive API
    const daddyEvents = await fetchDaddyLiveEvents();

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

                home = cleanVietnameseDiacritics(translateToId(home));
                away = cleanVietnameseDiacritics(translateToId(away));
                const title = `${home} vs ${away}`;

                // Kategori Olahraga
                let category = '⚽ Sepak Bola';
                const lowerAll = (sportType + ' ' + slugName + ' ' + league).toLowerCase();
                if (lowerAll.includes('motogp') || lowerAll.includes('moto2') || lowerAll.includes('moto3') || lowerAll.includes('f1') || lowerAll.includes('formula 1') || lowerAll.includes('wsbk') || lowerAll.includes('superbike') || sportType === 'motorsport' || lowerAll.includes('motorsport') || lowerAll.includes('balap') || lowerAll.includes('dua xe')) {
                    category = '🏎️ Balap & Motorsport';
                } else if (sportType === 'volleyball' || lowerAll.includes('voli') || lowerAll.includes('volleyball') || lowerAll.includes('bong chuyen') || lowerAll.includes('bóng chuyền') || lowerAll.includes('v-league') || lowerAll.includes('kovo') || lowerAll.includes('proliga') || lowerAll.includes('vnl')) {
                    category = '🏐 Bola Voli';
                } else if (sportType === 'badminton' || lowerAll.includes('badminton') || lowerAll.includes('bulu tangkis') || lowerAll.includes('cau long') || lowerAll.includes('cầu lông') || lowerAll.includes('bwf') || lowerAll.includes('all england') || lowerAll.includes('indonesia open')) {
                    category = '🏸 Bulu Tangkis';
                } else if (sportType === 'basketball' || lowerAll.includes('basket') || lowerAll.includes('nba') || lowerAll.includes('bong ro') || lowerAll.includes('bóng rổ')) {
                    category = '🏀 Bola Basket';
                } else if (sportType === 'tennis' || lowerAll.includes('tenis') || lowerAll.includes('tennis') || lowerAll.includes('wta') || lowerAll.includes('atp') || lowerAll.includes('quan vot') || lowerAll.includes('quần vợt')) {
                    category = '🎾 Tenis';
                } else if (['lol', 'dota2', 'csgo', 'esport', 'esports'].includes(sportType) || lowerAll.includes('esport') || lowerAll.includes('lpl') || lowerAll.includes('lcs') || lowerAll.includes('lec') || lowerAll.includes('lit') || lowerAll.includes('vcs') || lowerAll.includes('gaming') || lowerAll.includes('pgl') || lowerAll.includes('dota') || lowerAll.includes('crossfire')) {
                    category = '🎮 Esports & Gaming';
                } else if (sportType !== 'football') {
                    category = '🏎️ Olahraga Lainnya';
                }

                const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
                const kickoffText = `${hour}:${min} WIB (${day}/${month})`;
                const matchDate = new Date(kickoffIso);
                const now = new Date();
                const diffMinutes = (now.getTime() - matchDate.getTime()) / (1000 * 60);

                // Penentuan Status LIVE yang 100% Akurat berdasarkan Waktu & Tag
                let status = 0;
                if (diffMinutes < -5) {
                    status = 0; // Terjadwal / Belum Mulai
                } else if (diffMinutes >= -5 && diffMinutes <= 150) {
                    status = 1; // Sedang LIVE
                } else {
                    status = 2; // Selesai
                }

                const contentLower = cardContent.toLowerCase();
                if (contentLower.includes('>ft<') || contentLower.includes('kết thúc') || contentLower.includes('hết giờ') || contentLower.includes('finished')) {
                    status = 2; // Selesai
                }

                // Skor Pertandingan: Hanya untuk pertandingan yang benar-benar ada data skor resmi
                let homeScore = '';
                let awayScore = '';
                let scoreText = '';
                let matchMinute = '';

                if (status === 1 || status === 2) {
                    const hpuScore = cardContent.match(/class="[^"]*hpu-score-home[^"]*"[^>]*>\s*(\d+)\s*<\/span>[\s\S]*?class="[^"]*hpu-score-away[^"]*"[^>]*>\s*(\d+)\s*<\/span>/i);
                    const realScoreMatch = cardContent.match(/class="[^"]*score-(?:live|real|current)[^"]*"[^>]*>\s*(\d+)\s*[-:]\s*(\d+)/i);

                    if (hpuScore) {
                        homeScore = hpuScore[1].trim();
                        awayScore = hpuScore[2].trim();
                        scoreText = `${homeScore} - ${awayScore}`;
                    } else if (realScoreMatch) {
                        homeScore = realScoreMatch[1].trim();
                        awayScore = realScoreMatch[2].trim();
                        scoreText = `${homeScore} - ${awayScore}`;
                    }

                    const periodMatch = cardContent.match(/class="[^"]*(?:period|quarter|set-name|match-time)[^"]*"[^>]*>\s*([^<]+)\s*</i);
                    if (periodMatch) {
                        let pm = periodMatch[1].trim();
                        // Jangan masukkan jika hanya angka odds (seperti 0 - 0)
                        if (!/^\d+\s*[-:]\s*\d+$/.test(pm)) {
                            pm = pm.replace(/Hiệp 1/gi, 'Babak 1')
                                   .replace(/Hiệp 2/gi, 'Babak 2')
                                   .replace(/Nghỉ giữa hiệp/gi, 'Turun Minum')
                                   .replace(/Hết giờ/gi, 'Selesai');
                            matchMinute = pm;
                        }
                    }
                }

                const matchPageUrl = `${domain}${relUrl}`;
                const dlMapping = getDaddyLiveMapping(category, league, title, slugName);
                const dlUrl = dlMapping ? dlMapping.url : '';

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
                    daddyliveUrl: dlUrl,
                    daddyliveName: dlMapping ? dlMapping.name : 'DaddyLive HD',
                    streamJalur1: dlUrl || matchPageUrl,
                    streamJalur2: matchPageUrl,
                    streamJalur3: dlUrl || matchPageUrl,
                    streams: {
                        jalur1: dlUrl || matchPageUrl,
                        jalur2: matchPageUrl,
                        jalur3: dlUrl || matchPageUrl,
                        daddylive: dlUrl
                    },
                    updatedAt: new Date().toISOString()
                });
            }
        } catch (err) {
            console.warn(`   ⚠️ Kendala saat menghubungi ${seed}:`, err.message);
        }
    }

    // 2. Integrasikan event resmi dari DaddyLive API ke dalam parsedMap
    if (Array.isArray(daddyEvents) && daddyEvents.length > 0) {
        let daddyAddedCount = 0;
        let daddyMergedCount = 0;

        for (let idx = 0; idx < daddyEvents.length; idx++) {
            const dev = daddyEvents[idx];
            if (!dev.event) continue;

            const rawEvent = dev.event.trim();
            const channels = dev.channels || [];
            if (channels.length === 0) continue;

            // Bersihkan icon emoji dari teks event
            const cleanEvent = rawEvent.replace(/^[⚽🏎️🏐🏀🎾🥊🎮🏆🏸]\s*/u, '').trim();

            let league = 'Turnamen Internasional';
            let title = cleanEvent;
            let home = '';
            let away = '';

            if (cleanEvent.includes(':')) {
                const parts = cleanEvent.split(':');
                league = parts[0].trim();
                title = parts.slice(1).join(':').trim();
            }

            league = translateToId(league);

            if (title.includes(' vs ') || title.includes(' - ') || title.includes(' vs. ')) {
                const teamParts = title.split(/\s+vs\.?\s+|\s+-\s+/i);
                home = cleanVietnameseDiacritics(translateToId(teamParts[0] ? teamParts[0].trim() : 'Tim 1'));
                away = cleanVietnameseDiacritics(translateToId(teamParts.length > 1 ? teamParts[1].trim() : 'Tim 2'));
            } else {
                home = cleanVietnameseDiacritics(translateToId(title));
                away = '';
            }

            title = away ? `${home} vs ${away}` : home;

            // Klasifikasi Kategori Olahraga
            let category = '⚽ Sepak Bola';
            const lowerAll = (dev.rawCategory + ' ' + league + ' ' + title).toLowerCase();
            if (lowerAll.includes('motogp') || lowerAll.includes('moto2') || lowerAll.includes('moto3') || lowerAll.includes('formula 1') || lowerAll.includes('f1') || lowerAll.includes('motorsport') || lowerAll.includes('sprint race') || lowerAll.includes('gt world')) {
                category = '🏎️ Balap & Motorsport';
            } else if (lowerAll.includes('volleyball') || lowerAll.includes('voli') || lowerAll.includes('v-league') || lowerAll.includes('kovo') || lowerAll.includes('proliga') || lowerAll.includes('iberian cup')) {
                category = '🏐 Bola Voli';
            } else if (lowerAll.includes('badminton') || lowerAll.includes('bulu tangkis') || lowerAll.includes('bwf')) {
                category = '🏸 Bulu Tangkis';
            } else if (lowerAll.includes('basketball') || lowerAll.includes('basket') || lowerAll.includes('nba') || lowerAll.includes('euroleague')) {
                category = '🏀 Bola Basket';
            } else if (lowerAll.includes('tennis') || lowerAll.includes('tenis') || lowerAll.includes('wta') || lowerAll.includes('atp')) {
                category = '🎾 Tenis';
            } else if (lowerAll.includes('ufc') || lowerAll.includes('boxing') || lowerAll.includes('tinju') || lowerAll.includes('mma')) {
                category = '🥊 Combat Sports';
            } else if (!lowerAll.includes('football') && !lowerAll.includes('soccer')) {
                category = '🏆 Olahraga Lainnya';
            }

            // Link DaddyLive dinamis (Link 1, 2, 3, 4)
            const link1 = channels[0] ? channels[0].url : '';
            const link2 = channels[1] ? channels[1].url : '';
            const link3 = channels[2] ? channels[2].url : '';
            const link4 = channels[3] ? channels[3].url : '';

            // Helper normalisasi tim untuk fuzzy matching akurat
            function normTeam(str) {
                if (!str) return '';
                return str.toLowerCase()
                    .replace(/\b(fc|cf|sc|ac|as|united|city|club|cd|afc|ssc|rb|deportivo|sporting|real|atletico|borussia|spvgg|sv|vfb|tsg|bsc|fsv|wolverhampton|wolves)\b/gi, '')
                    .replace(/[^a-z0-9]/g, '')
                    .trim();
            }

            // Cek apakah pertandingan ini sudah ada di parsedMap (dari Xoilac)
            let matchedKey = null;
            const normTitle = title.toLowerCase().replace(/[^a-z0-9]/g, '');
            const nHome = normTeam(home);
            const nAway = normTeam(away);

            for (const [key, item] of parsedMap.entries()) {
                const normItem = item.title.toLowerCase().replace(/[^a-z0-9]/g, '');
                if (normTitle && normItem && (normTitle.includes(normItem) || normItem.includes(normTitle))) {
                    matchedKey = key;
                    break;
                }
                const nItemH = normTeam(item.homeTeam);
                const nItemA = normTeam(item.awayTeam);
                if (nHome && nAway && nItemH && nItemA) {
                    const homeMatch = nHome.includes(nItemH) || nItemH.includes(nHome);
                    const awayMatch = nAway.includes(nItemA) || nItemA.includes(nAway);
                    if (homeMatch && awayMatch) {
                        matchedKey = key;
                        break;
                    }
                }
            }

            if (matchedKey) {
                // Merge dengan Xoilac:
                // Jalur 1: DaddyLive HD Link 1 (UTAMA)
                // Jalur 2: DaddyLive HD Link 2 (atau Xoilac jika hanya 1 link di Daddy)
                // Jalur 3: DaddyLive HD Link 3 (atau Xoilac)
                // Jalur 4: Xoilac HD (Komentator Indonesia / Cadangan di paling akhir)
                const existing = parsedMap.get(matchedKey);
                const xoilacBackup = existing.postUrl;

                existing.daddyliveUrl = link1;
                existing.streamJalur1 = link1; // Utamakan DaddyLive HD sebagai Jalur 1

                if (link3) {
                    existing.streamJalur2 = link2;
                    existing.streamJalur3 = link3;
                    existing.streamJalur4 = xoilacBackup;
                } else if (link2) {
                    existing.streamJalur2 = link2;
                    existing.streamJalur3 = xoilacBackup;
                    existing.streamJalur4 = '';
                } else {
                    existing.streamJalur2 = xoilacBackup;
                    existing.streamJalur3 = link1;
                    existing.streamJalur4 = '';
                }

                existing.streams.jalur1 = existing.streamJalur1;
                existing.streams.jalur2 = existing.streamJalur2;
                existing.streams.jalur3 = existing.streamJalur3;
                existing.streams.jalur4 = existing.streamJalur4;
                existing.streams.daddylive = link1;
                existing.streams.daddylive2 = link2;
                existing.streams.daddylive3 = link3;
                existing.streams.xoilac = xoilacBackup;
                daddyMergedCount++;
            } else {
                // Event baru dari DaddyLive (MotoGP, Balap, Voli Korea, Badminton, Basket NBA, dll)
                const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '').substring(0, 30);
                const uniqueKey = `daddy_${idx + 1}_${slug}`;

                parsedMap.set(uniqueKey, {
                    id: uniqueKey,
                    title,
                    homeTeam: home || title,
                    awayTeam: away || '',
                    homeLogo: '',
                    awayLogo: '',
                    homeScore: '',
                    awayScore: '',
                    scoreText: '',
                    matchMinute: '',
                    league,
                    sportCategory: category,
                    kickoffIso: new Date().toISOString(),
                    kickoffText: dev.time === 'Live' ? 'LIVE Sekarang' : `${dev.time} WIB`,
                    status: dev.time.toLowerCase().includes('live') ? 1 : 0,
                    postUrl: link1,
                    daddyliveUrl: link1,
                    daddyliveName: 'DaddyLive HD',
                    streamJalur1: link1,
                    streamJalur2: link2 || link1,
                    streamJalur3: link3 || link2 || link1,
                    streamJalur4: link4 || '',
                    streams: {
                        jalur1: link1,
                        jalur2: link2 || link1,
                        jalur3: link3 || link2 || link1,
                        jalur4: link4 || '',
                        daddylive: link1,
                        daddylive2: link2,
                        daddylive3: link3
                    },
                    updatedAt: new Date().toISOString()
                });
                daddyAddedCount++;
            }
        }
        console.log(`   ✅ Selesai Menggabungkan: ${daddyMergedCount} pertandingan sinkron Xoilac + DaddyLive, ${daddyAddedCount} event baru dari DaddyLive!`);
    }

    const matchesList = Array.from(parsedMap.values());
    console.log(`\n🎯 Mengekstrak direct stream HLS (.m3u8) & multi-link untuk ${matchesList.length} pertandingan...`);

    // Ekstraksi concurrent direct stream m3u8 untuk pertandingan live & upcoming
    const BATCH_SIZE = 12;
    for (let i = 0; i < matchesList.length; i += BATCH_SIZE) {
        const batch = matchesList.slice(i, i + BATCH_SIZE);
        await Promise.all(batch.map(async (m) => {
            // 1. Ekstraksi Direct M3U8 DaddyLive untuk Jalur 1 (UTAMA HD 1080p)
            const daddySource1 = m.daddyliveUrl || (m.streamJalur1 && m.streamJalur1.includes('daddylive.app') ? m.streamJalur1 : null);
            if (daddySource1) {
                const dlDirect1 = await extractDaddyDirectStream(daddySource1);
                if (dlDirect1) {
                    m.streamJalur1 = dlDirect1;
                    m.streams.jalur1 = dlDirect1;
                    m.streams.daddylive_direct = dlDirect1;
                }
            }

            // 2. Ekstraksi Direct M3U8 DaddyLive untuk Jalur 2 (jika Jalur 2 adalah embed DaddyLive)
            if (m.streamJalur2 && m.streamJalur2.includes('daddylive.app')) {
                const dlDirect2 = await extractDaddyDirectStream(m.streamJalur2);
                if (dlDirect2) {
                    m.streamJalur2 = dlDirect2;
                    m.streams.jalur2 = dlDirect2;
                }
            }

            // 3. Ekstraksi Direct M3U8 Xoilac untuk Jalur Cadangan / Paling Akhir (Komentator Indonesia)
            if (m.postUrl && m.postUrl.includes('/truc-tiep/')) {
                const streams = await extractDirectStreamForMatch(m.postUrl);
                if (streams) {
                    m.streams.xoilac = streams.jalur1;
                    // Pastikan Xoilac berada di jalur terakhir pertandingan
                    if (m.streamJalur4) {
                        m.streamJalur4 = streams.jalur1;
                        m.streams.jalur4 = streams.jalur1;
                    } else if (m.streamJalur3 && m.streamJalur3.includes('/truc-tiep/')) {
                        m.streamJalur3 = streams.jalur1;
                        m.streams.jalur3 = streams.jalur1;
                    } else if (m.streamJalur2 && m.streamJalur2.includes('/truc-tiep/')) {
                        m.streamJalur2 = streams.jalur1;
                        m.streams.jalur2 = streams.jalur1;
                    }

                    // Hanya jika pertandingan ini TIDAK memiliki sumber DaddyLive, gunakan Xoilac untuk Jalur 1
                    if (!daddySource1 && (!m.streamJalur1 || m.streamJalur1.includes('/truc-tiep/'))) {
                        m.streamJalur1 = streams.jalur1;
                        m.streams.jalur1 = streams.jalur1;
                    }
                }
            }
        }));
    }

    // Hitung Skor Prioritas Pertandingan Populer (Bundesliga, Liga 1, EPL, UCL, MotoGP, Voli, Badminton, NBA)
    function getMatchPriority(m) {
        let score = 0;
        // Status LIVE mendapatkan prioritas utama di atas layar
        if (m.status === 1) score += 1000;
        else if (m.status === 0) score += 500;

        const text = (m.league + ' ' + m.title + ' ' + m.sportCategory).toLowerCase();

        // 1. Sepak Bola Populer
        if (text.includes('indonesia') || text.includes('bri liga 1') || text.includes('timnas') || text.includes('liga 1')) score += 300;
        if (text.includes('champions') || text.includes('ucl')) score += 280;
        if (text.includes('inggris') || text.includes('premier league')) score += 270;
        if (text.includes('bundesliga') || text.includes('jerman') || text.includes('dfb')) score += 260; // 🇩🇪 Bundesliga Jerman
        if (text.includes('spanyol') || text.includes('la liga')) score += 250;
        if (text.includes('italia') || text.includes('serie a')) score += 240;
        if (text.includes('europa') || text.includes('conference')) score += 200;
        if (text.includes('saudi') || text.includes('al nassr') || text.includes('al hilal') || text.includes('afc')) score += 180;

        // 2. MotoGP & Motorsport
        if (text.includes('motogp') || text.includes('moto2') || text.includes('moto3') || text.includes('formula 1') || text.includes('f1') || text.includes('balap')) score += 290;

        // 3. Bola Voli (KOVO V-League Korea & Proliga)
        if (text.includes('v-league') || text.includes('kovo') || text.includes('proliga') || text.includes('red sparks') || text.includes('vnl') || text.includes('voli')) score += 280;

        // 4. Bulu Tangkis (BWF Badminton)
        if (text.includes('badminton') || text.includes('bulu tangkis') || text.includes('bwf') || text.includes('all england') || text.includes('indonesia open') || text.includes('thomas') || text.includes('uber')) score += 280;

        // 5. Bola Basket (NBA & IBL)
        if (text.includes('nba') || text.includes('ibl') || text.includes('euroleague') || text.includes('basket')) score += 220;

        // 6. UFC & Combat Sports
        if (text.includes('ufc') || text.includes('one championship') || text.includes('tinju') || text.includes('boxing')) score += 210;

        // 7. Tenis Grand Slam
        if (text.includes('wimbledon') || text.includes('us open') || text.includes('australian open') || text.includes('roland garros')) score += 200;

        return score;
    }

    // Urutkan pertandingan berdasarkan prioritas kepopuleran & status LIVE
    matchesList.sort((a, b) => getMatchPriority(b) - getMatchPriority(a));

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
