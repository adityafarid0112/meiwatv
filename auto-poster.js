const fs = require('fs');
const path = require('path');

const BLOG_ID = '8531123332112355973'; // ID Blog Blogger meiwaolaharaga.blogspot.com
const credentialsPath = path.join(__dirname, 'client_secrets.json');
const tokenPath = path.join(__dirname, 'token.json');

// 1. Dapatkan Access Token yang Valid
async function getValidAccessToken() {
  if (!fs.existsSync(tokenPath)) {
    console.error('❌ File token.json belum ditemukan!');
    console.log('👉 Silakan jalankan otentikasi terlebih dahulu dengan perintah: node auth.js');
    process.exit(1);
  }

  const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8')).installed;
  const tokenData = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

  // Refresh token jika ada
  if (tokenData.refresh_token) {
    try {
      const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          client_id: credentials.client_id,
          client_secret: credentials.client_secret,
          refresh_token: tokenData.refresh_token,
          grant_type: 'refresh_token'
        })
      });

      const refreshed = await res.json();
      if (refreshed.access_token) {
        tokenData.access_token = refreshed.access_token;
        fs.writeFileSync(tokenPath, JSON.stringify(tokenData, null, 2), 'utf8');
        return refreshed.access_token;
      }
    } catch (e) {
      console.warn('⚠️ Gagal me-refresh token, mencoba token lama:', e.message);
    }
  }

  return tokenData.access_token;
}

// 2. Ambil Daftar Postingan yang Sudah Ada di Blog (Mencegah Duplikasi)
async function getExistingPostTitles(accessToken) {
  const existing = new Set();
  try {
    const url = `https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts?maxResults=50`;
    const res = await fetch(url, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const data = await res.json();
    if (data.items) {
      data.items.forEach(p => {
        if (p.title) existing.add(p.title.trim().toLowerCase());
      });
    }
  } catch (e) {
    console.warn('⚠️ Gagal mengambil daftar postingan lama via API:', e.message);
  }
  return existing;
}

// 3. Scraper Pintar Xoilac dengan Dynamic Redirect Follower
// Daftar mirror seed jika ada domain yang diblokir ISP / berubah
const SEED_DOMAINS = [
  'https://xoilacz.vip/',
  'https://tft-forests.org/',
  'https://xoilaczbj.tv/',
  'https://xoilac.org/'
];

async function scrapeXoilacMatches() {
  let html = '';
  let activeDomain = '';

  for (const seed of SEED_DOMAINS) {
    try {
      console.log(`📡 Menghubungi seed domain: ${seed}...`);
      const response = await fetch(seed, {
        redirect: 'follow',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
      });

      if (response.ok) {
        html = await response.text();
        // Dapatkan domain tujuan akhir setelah redirect secara dinamis
        activeDomain = new URL(response.url).origin;
        console.log(`✅ Berhasil terhubung! Domain aktif saat ini (setelah direct/redirect): ${activeDomain}`);
        break;
      }
    } catch (e) {
      console.warn(`⚠️ Gagal menghubungi ${seed}: ${e.message}`);
    }
  }

  if (!html || !activeDomain) {
    throw new Error('Gagal mengambil data dari semua seed domain Xoilac yang tersedia.');
  }

  const allSlugs = html.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi) || [];
  const uniqueSlugs = [...new Set(allSlugs)];

  const matches = [];

  for (const slug of uniqueSlugs) {
    const parsed = slug.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//i);
    if (parsed) {
      const slugName = parsed[1];
      const rawTitle = slugName.replace(/-/g, ' ');
      const title = rawTitle.replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
      const timeStr = parsed[2];
      const day = parsed[3];
      const month = parsed[4];
      const year = parsed[5];
      const hour = timeStr.slice(0, 2);
      const min = timeStr.slice(2, 4);

      // Vietnam UTC+7 sama dengan WIB (UTC+7)
      const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
      const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
      // Buat URL halaman pertandingan menggunakan activeDomain yang didapat dinamis
      const matchPageUrl = `${activeDomain}/truc-tiep/${slugName}-luc-${timeStr}-ngay-${day}-${month}-${year}/`;

      // Deteksi liga / turnamen dari nama tim
      let league = "Live Match";
      if (title.includes('Milan') || title.includes('Roma') || title.includes('Parma') || title.includes('Como') || title.includes('Juventus') || title.includes('Napoli') || title.includes('Inter')) {
        league = "Italian Serie A";
      } else if (title.includes('Madrid') || title.includes('Barcelona') || title.includes('Atletico') || title.includes('Sevilla')) {
        league = "La Liga Spain";
      } else if (title.includes('Arsenal') || title.includes('Chelsea') || title.includes('Liverpool') || title.includes('Newcastle') || title.includes('City') || title.includes('United')) {
        league = "Premier League";
      } else if (title.includes('Munchen') || title.includes('Dortmund') || title.includes('Leverkusen')) {
        league = "German Bundesliga";
      }

      matches.push({
        title,
        matchPageUrl,
        kickoffIso,
        kickoffText,
        league
      });
    }
  }

  return matches;
}

// 4. Ekstraksi Link Stream Embed Langsung dari Halaman Pertandingan Xoilac (Auto Follow Redirect)
async function extractDirectEmbedStreams(matchPageUrl) {
  let server1Url = '';
  let server2Url = '';

  try {
    const res = await fetch(matchPageUrl, {
      redirect: 'follow',
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
    });
    const pageHtml = await res.text();
    const listStreamMatch = pageHtml.match(/var list_stream\s*=\s*(\[[\s\S]*?\]);/);
    if (listStreamMatch) {
      const rawJson = listStreamMatch[1].replace(/\\/g, '');
      const listStream = JSON.parse(rawJson);
      if (listStream[0] && listStream[0][0]) {
        server1Url = listStream[0][0] + '/off-tvc?is_off_add=false';
      }
      if (listStream[1] && listStream[1][0]) {
        server2Url = listStream[1][0] + '/off-tvc?is_off_add=false';
      } else if (listStream[0] && listStream[0][1]) {
        server2Url = listStream[0][1] + '/off-tvc?is_off_add=false';
      }
    }
  } catch (err) {
    console.warn(`   ⚠️ Tidak dapat mengekstrak stream embed langsung untuk ${matchPageUrl}:`, err.message);
  }

  return { server1Url, server2Url };
}

// 5. Buat Konten HTML Postingan Blogger
function generatePostHtml(match) {
  const primaryStream = match.server1Url || `${match.matchPageUrl}link/0`;
  const secondaryStream = match.server2Url || `${match.matchPageUrl}link/1`;

  return `<!-- FORMAT POSTINGAN PERTANDINGAN OTOMATIS (SPORTSTREAM BOT) -->
<!-- 1. DATA KONTROL STREAM & JADWAL -->
<div id="stream-meta" 
     data-streamurl="${primaryStream}" 
     data-server2="${secondaryStream}"
     data-sourceurl="${match.matchPageUrl}"
     data-kickoff="${match.kickoffIso}" 
     data-kickoff-text="${match.kickoffText}" 
     data-league="${match.league}">
</div>

<!-- 2. KARTU INFORMASI PERTANDINGAN -->
<div style="background: #111826; border-radius: 12px; padding: 20px; border: 1px solid rgba(255,255,255,0.08); margin: 15px 0; color: #fff; text-align: center;">
  <span style="background: rgba(16, 185, 129, 0.15); color: #10b981; font-weight: 700; padding: 4px 14px; border-radius: 50px; font-size: 13px;">
    📌 ${match.league}
  </span>
  <h2 style="font-size: 20px; margin: 15px 0;">${match.title}</h2>
  <p style="color: #94a3b8; font-size: 14px;">⏰ Kickoff: ${match.kickoffText}</p>
</div>

<!-- 3. TOMBOL CEPAT SIARAN -->
<div style="text-align: center; margin-top: 15px;">
  <a href="${primaryStream}" target="_blank" style="background: #10b981; color: #000; padding: 10px 22px; border-radius: 8px; font-weight: 800; text-decoration: none; font-size: 14px; display: inline-block;">
    ▶ Putar Siaran Langsung (Player HD)
  </a>
</div>`;
}

// 6. Eksekusi Bot Utama
async function runBot() {
  console.log('==================================================');
  console.log('🤖 SPORTSTREAM AUTO-POSTER BOT BERJALAN');
  console.log('==================================================\n');

  const accessToken = await getValidAccessToken();
  const existingTitles = await getExistingPostTitles(accessToken);
  console.log(`ℹ️ Ditemukan ${existingTitles.size} postingan yang sudah ada di blog.\n`);

  const matches = await scrapeXoilacMatches();
  console.log(`🎯 Berhasil mendapatkan ${matches.length} jadwal pertandingan dari Xoilac.\n`);

  let postedCount = 0;
  let skippedCount = 0;

  const nowTime = new Date().getTime();
  matches.forEach(m => {
    const kickoffTime = new Date(m.kickoffIso).getTime();
    const diff = kickoffTime - nowTime;
    if (diff <= 0 && diff > -10800000) {
      m.status = 0; // Live Now
      m.statusLabel = '🔴 SEDANG LIVE';
    } else if (diff <= -10800000) {
      m.status = 2; // Selesai
      m.statusLabel = 'SELESAI';
    } else {
      m.status = 1; // Menunggu
      m.statusLabel = 'MENUNGGU';
    }
    m.kickoffTime = kickoffTime;

    let priorityScore = 0;
    const lowerTitle = m.title.toLowerCase();
    if (lowerTitle.includes('milan') || lowerTitle.includes('roma') || lowerTitle.includes('parma') || lowerTitle.includes('como') || lowerTitle.includes('juventus') || lowerTitle.includes('napoli') || lowerTitle.includes('inter') || lowerTitle.includes('torino') || lowerTitle.includes('udinese') || lowerTitle.includes('lazio') || lowerTitle.includes('atalanta') || lowerTitle.includes('fiorentina')) {
      m.league = "Italian Serie A";
      priorityScore += 100;
    } else if (lowerTitle.includes('madrid') || lowerTitle.includes('barcelona') || lowerTitle.includes('atletico') || lowerTitle.includes('sevilla') || lowerTitle.includes('valencia')) {
      m.league = "La Liga Spain";
      priorityScore += 100;
    } else if (lowerTitle.includes('arsenal') || lowerTitle.includes('chelsea') || lowerTitle.includes('liverpool') || lowerTitle.includes('newcastle') || lowerTitle.includes('city') || lowerTitle.includes('united') || lowerTitle.includes('tottenham') || lowerTitle.includes('leeds')) {
      m.league = "Premier League";
      priorityScore += 100;
    } else if (lowerTitle.includes('munchen') || lowerTitle.includes('dortmund') || lowerTitle.includes('leverkusen')) {
      m.league = "German Bundesliga";
      priorityScore += 80;
    }

    if (lowerTitle.includes('como') || lowerTitle.includes('parma') || lowerTitle.includes('torino') || lowerTitle.includes('roma') || lowerTitle.includes('inter') || lowerTitle.includes('udinese') || lowerTitle.includes('leeds') || lowerTitle.includes('newcastle')) {
      priorityScore += 300;
    }
    m.priorityScore = priorityScore;
  });

  // Prioritaskan: 1. Priority Score Tertinggi, 2. Live Now, 3. Upcoming Terdekat
  const validMatches = matches.filter(m => m.status !== 2);
  validMatches.sort((a, b) => {
    if (a.priorityScore !== b.priorityScore) return b.priorityScore - a.priorityScore;
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  // Batasi maksimal 15 pertandingan per run
  const maxToProcess = validMatches.slice(0, 15);

  for (const match of maxToProcess) {
    const postTitle = `${match.title} - ${match.league}`;
    const simpleTitle = match.title.toLowerCase();

    // Cek apakah sudah pernah diposting
    let alreadyExists = false;
    for (const ext of existingTitles) {
      if (ext.includes(simpleTitle)) {
        alreadyExists = true;
        break;
      }
    }

    if (alreadyExists) {
      console.log(`⏭️ Dilewati (Sudah Ada): ${postTitle}`);
      skippedCount++;
      continue;
    }

    console.log(`🔍 Mengekstrak stream embed: ${match.title}...`);
    const streams = await extractDirectEmbedStreams(match.matchPageUrl);
    match.server1Url = streams.server1Url;
    match.server2Url = streams.server2Url;

    console.log(`📤 Memposting: ${postTitle} (${match.kickoffText})...`);

    const postBody = {
      kind: 'blogger#post',
      title: postTitle,
      content: generatePostHtml(match),
      labels: [match.league, match.status === 0 ? 'Live Now' : 'Upcoming', 'Xoilac']
    };

    try {
      const res = await fetch(`https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts/`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(postBody)
      });

      const result = await res.json();
      if (result.id) {
        console.log(`   ✅ SUKSES DITERBITKAN: ${result.url}`);
        existingTitles.add(simpleTitle);
        postedCount++;
      } else if (result.error && result.error.status === 'PERMISSION_DENIED') {
        console.error(`\n❌ ERROR IZIN AKSES GOOGLE BLOGGER (PERMISSION DENIED):`);
        console.error(`1. Pastikan "Blogger API v3" sudah AKTIF di Google Cloud Console:`);
        console.error(`   👉 https://console.cloud.google.com/apis/library/blogger.googleapis.com?project=sportstream-bot`);
        console.error(`2. Jalankan ulang LOGIN_GOOGLE.bat dan pilih akun Google pemilik blog ini.\n`);
        break;
      } else {
        console.warn(`   ⚠️ Status: ${result.message || JSON.stringify(result.error || result)}`);
      }
    } catch (err) {
      console.error(`   ❌ Error: ${err.message}`);
    }

    // Jeda 2 detik antar postingan agar aman dari rate limit
    await new Promise(r => setTimeout(r, 2000));
  }

  console.log('\n==================================================');
  console.log(`🎉 SIKLUS SELESAI (${new Date().toLocaleTimeString()} WIB):`);
  console.log(`   - Berhasil diposting baru: ${postedCount} pertandingan`);
  console.log(`   - Dilewati (karena sudah ada): ${skippedCount} pertandingan`);
  console.log('==================================================');
}

// 7. Kontrol Eksekusi: Mode Sekali Jalan vs Mode Loop Otomatis
async function main() {
  const args = process.argv.slice(2);
  const isLoop = args.includes('--loop') || args.includes('-l') || args.includes('--watch');
  
  let intervalMinutes = 15;
  const intervalIdx = args.indexOf('--interval');
  if (intervalIdx !== -1 && args[intervalIdx + 1]) {
    const parsed = parseInt(args[intervalIdx + 1], 10);
    if (!isNaN(parsed) && parsed > 0) intervalMinutes = parsed;
  }

  if (!isLoop) {
    // Mode Sekali Jalan
    await runBot();
  } else {
    // Mode Loop Otomatis Terus Menerus
    console.log(`🔁 BOT BERJALAN DALAM MODE OTOMATIS (UPDATE SETIAP ${intervalMinutes} MENIT)`);
    console.log(`Tekan Ctrl+C di terminal ini kapan saja untuk menghentikan bot.\n`);

    while (true) {
      try {
        await runBot();
      } catch (err) {
        console.error('⚠️ Terjadi kendala pada siklus ini:', err.message);
      }

      console.log(`\n⏳ Menunggu ${intervalMinutes} menit untuk pembaruan berikutnya...`);
      await new Promise(r => setTimeout(r, intervalMinutes * 60 * 1000));
    }
  }
}

main().catch(err => console.error('Fatal Bot Error:', err));
