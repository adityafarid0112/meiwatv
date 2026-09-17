const fs = require('fs');
const path = require('path');

const SEED_DOMAINS = [
  'https://xoilacz.vip/',
  'https://tft-forests.org/',
  'https://xoilaczbj.tv/',
  'https://xoilac.org/'
];

async function scrapeAllMatches() {
  console.log('--- SCRAPING ALL LIVE MATCHES FROM XOILAC ---');
  let html = '';
  let activeDomain = '';

  for (const seed of SEED_DOMAINS) {
    try {
      console.log(`Menghubungi seed: ${seed}...`);
      const res = await fetch(seed, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
        redirect: 'follow'
      });
      if (res.ok) {
        html = await res.text();
        activeDomain = new URL(res.url).origin;
        console.log(`✅ Berhasil! Domain aktif: ${activeDomain}`);
        break;
      }
    } catch (e) {
      console.warn(`Gagal: ${seed}`);
    }
  }

  if (!html) throw new Error('Semua seed domain gagal dihubungi');

  const allSlugs = html.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi) || [];
  const uniqueSlugs = [...new Set(allSlugs)];
  console.log(`Ditemukan ${uniqueSlugs.length} jadwal pertandingan.`);

  const matches = [];
  const nowTime = new Date().getTime();

  for (let i = 0; i < uniqueSlugs.length; i++) {
    const slug = uniqueSlugs[i];
    const parsed = slug.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (!parsed) continue;

    const slugName = parsed[1];
    const rawTitle = slugName.replace(/-/g, ' ');
    const title = rawTitle.replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
    const timeStr = parsed[2];
    const day = parsed[3];
    const month = parsed[4];
    const year = parsed[5];
    const hour = timeStr.slice(0, 2);
    const min = timeStr.slice(2, 4);

    const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
    const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
    const matchPageUrl = `${activeDomain}/truc-tiep/${slugName}-luc-${timeStr}-ngay-${day}-${month}-${year}/`;

    const kickoffTime = new Date(kickoffIso).getTime();
    const diff = kickoffTime - nowTime;

    let status = 1;
    let statusLabel = 'MENUNGGU';
    if (diff <= 0 && diff > -10800000) {
      status = 0; // Live Now
      statusLabel = '🔴 SEDANG LIVE';
    } else if (diff <= -10800000) {
      status = 2; // Finished
      statusLabel = 'SELESAI';
    }

    // Filter out old finished matches
    if (status === 2) continue;

    let league = "Live Match";
    const lower = title.toLowerCase();
    if (lower.includes('milan') || lower.includes('roma') || lower.includes('parma') || lower.includes('como') || lower.includes('juventus') || lower.includes('napoli') || lower.includes('inter')) {
      league = "Italian Serie A";
    } else if (lower.includes('madrid') || lower.includes('barcelona') || lower.includes('atletico') || lower.includes('sevilla')) {
      league = "La Liga Spain";
    } else if (lower.includes('arsenal') || lower.includes('chelsea') || lower.includes('liverpool') || lower.includes('city') || lower.includes('united') || lower.includes('newcastle')) {
      league = "Premier League";
    } else if (lower.includes('munchen') || lower.includes('dortmund') || lower.includes('leverkusen')) {
      league = "German Bundesliga";
    } else if (lower.includes('libertadores') || lower.includes('quito') || lower.includes('palmeiras')) {
      league = "Copa Libertadores";
    } else if (lower.includes('champions') || lower.includes('cruz azul') || lower.includes('miami')) {
      league = "CONCACAF Champions Cup";
    }

    matches.push({
      title,
      slugName,
      matchPageUrl,
      kickoffIso,
      kickoffText,
      kickoffTime,
      status,
      statusLabel,
      league
    });
  }

  // Sort: Live now first, then upcoming
  matches.sort((a, b) => {
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  console.log(`\nBerhasil memproses ${matches.length} jadwal aktif!`);

  // Now extract embed channels for the top matches
  for (let i = 0; i < Math.min(matches.length, 25); i++) {
    const m = matches[i];
    console.log(`[${i+1}/${Math.min(matches.length, 25)}] Mengambil stream: ${m.title}...`);
    try {
      const pageRes = await fetch(m.matchPageUrl, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
        redirect: 'follow'
      });
      const pageHtml = await pageRes.text();
      const listStreamMatch = pageHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
      if (listStreamMatch) {
        const rawJson = listStreamMatch[1].replace(/\\/g, '');
        const listStream = JSON.parse(rawJson);
        if (listStream[0] && listStream[0][0]) {
          m.streamUrl = listStream[0][0] + '/off-tvc?is_off_add=false';
        }
        if (listStream[1] && listStream[1][0]) {
          m.server2Url = listStream[1][0] + '/off-tvc?is_off_add=false';
        } else if (listStream[0] && listStream[0][1]) {
          m.server2Url = listStream[0][1] + '/off-tvc?is_off_add=false';
        }
      }
    } catch (e) {
      console.warn(`   ⚠️ Stream err for ${m.title}: ${e.message}`);
    }

    if (!m.streamUrl) m.streamUrl = `${m.matchPageUrl}link/0`;
    if (!m.server2Url) m.server2Url = `${m.matchPageUrl}link/1`;
  }

  const outputPath = path.join(__dirname, 'live-matches.json');
  fs.writeFileSync(outputPath, JSON.stringify(matches, null, 2), 'utf8');
  console.log(`\n✅ SUKSES: Jadwal pertandingan lengkap tersimpan di ${outputPath}`);
}

scrapeAllMatches().catch(console.error);
