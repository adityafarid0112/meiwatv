const fs = require('fs');
const path = require('path');

const BLOG_ID = '8531123332112355973'; // ID Blog Blogger meiwaolaharaga.blogspot.com

// Cari file kredensial di folder saat ini atau folder blogger/
let credentialsPath = path.join(__dirname, 'client_secrets.json');
if (!fs.existsSync(credentialsPath)) {
  credentialsPath = path.join(__dirname, 'blogger', 'client_secrets.json');
}

let tokenPath = path.join(__dirname, 'token.json');
if (!fs.existsSync(tokenPath)) {
  tokenPath = path.join(__dirname, 'blogger', 'token.json');
}

// 1. Dapatkan Access Token yang Valid
async function getValidAccessToken() {
  if (!fs.existsSync(tokenPath)) {
    console.error('❌ File token.json belum ditemukan!');
    console.log('👉 Silakan jalankan otentikasi terlebih dahulu dengan perintah: node auth.js');
    return null;
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

// 3. Load Matches from matches.json or Scrape
async function loadMatchesData() {
  let matchesFilePath = path.join(__dirname, 'matches.json');
  if (!fs.existsSync(matchesFilePath)) {
    matchesFilePath = path.join(__dirname, '..', 'matches.json');
  }

  if (fs.existsSync(matchesFilePath)) {
    try {
      const data = JSON.parse(fs.readFileSync(matchesFilePath, 'utf8'));
      if (Array.isArray(data) && data.length > 0) {
        console.log(`📦 Memuat ${data.length} jadwal pertandingan dari matches.json`);
        return data;
      }
    } catch (e) {
      console.warn('⚠️ Gagal membaca matches.json:', e.message);
    }
  }

  return [];
}

// 4. Buat Konten HTML Postingan Blogger
function generatePostHtml(match) {
  const stream1 = match.streamUrl || match.streamJalur1 || '';
  const stream2 = match.server2Url || match.streamJalur2 || '';
  const stream3 = match.streamJalur3 || match.postUrl || '#';
  const home = match.homeTeam || match.title.split(' vs ')[0] || 'Tuan Rumah';
  const away = match.awayTeam || match.title.split(' vs ')[1] || 'Tamu';
  const homeLogo = match.homeLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';
  const awayLogo = match.awayLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';

  return `<!-- FORMAT POSTINGAN PERTANDINGAN MEIWASPORTS PRO -->
<div id="stream-meta" 
     data-streamurl="${stream1}" 
     data-server2="${stream2}"
     data-sourceurl="${stream3}"
     data-kickoff="${match.kickoffIso || ''}" 
     data-kickoff-text="${match.kickoffText || ''}" 
     data-league="${match.league || 'Sport Match'}">
</div>

<div style="background:#0e1422; border-radius:16px; padding:24px; border:1px solid rgba(255,255,255,0.08); margin:15px 0; color:#fff; text-align:center; font-family:'Outfit',sans-serif;">
  <span style="background:rgba(16,185,129,0.15); color:#10b981; font-weight:800; padding:5px 16px; border-radius:50px; font-size:13px; text-transform:uppercase; letter-spacing:0.5px;">
    📌 ${match.league || 'Sport Match'}
  </span>
  
  <div style="display:flex; align-items:center; justify-content:center; gap:20px; margin:20px 0;">
    <div style="flex:1; text-align:right;">
      <img src="${homeLogo}" alt="${home}" style="width:48px; height:48px; object-fit:contain; vertical-align:middle;" />
      <h3 style="margin:6px 0 0 0; font-size:16px; color:#fff;">${home}</h3>
    </div>
    <div style="background:#000; color:#ffe400; font-weight:800; padding:6px 14px; border-radius:8px; font-size:16px; border:1px solid rgba(255,228,0,0.3);">
      ${match.status === 1 ? (match.scoreText || 'LIVE') : 'VS'}
    </div>
    <div style="flex:1; text-align:left;">
      <img src="${awayLogo}" alt="${away}" style="width:48px; height:48px; object-fit:contain; vertical-align:middle;" />
      <h3 style="margin:6px 0 0 0; font-size:16px; color:#fff;">${away}</h3>
    </div>
  </div>

  <p style="color:#94a3b8; font-size:14px; margin:10px 0;">⏰ Jadwal Kick-off: <b style="color:#ffe400;">${match.kickoffText || 'Siap Tayang'}</b></p>
  
  <div style="display:flex; justify-content:center; gap:10px; margin-top:18px; flex-wrap:wrap;">
    <a href="${stream1 || stream3}" target="_blank" style="background:#10b981; color:#000; padding:10px 22px; border-radius:8px; font-weight:800; text-decoration:none; font-size:13px; display:inline-flex; align-items:center; gap:6px;">
      ▶ Putar Siaran (Jalur 1 HD)
    </a>
    <a href="${stream2 || stream3}" target="_blank" style="background:#1e293b; color:#fff; border:1px solid rgba(255,255,255,0.15); padding:10px 22px; border-radius:8px; font-weight:700; text-decoration:none; font-size:13px; display:inline-flex; align-items:center; gap:6px;">
      ⚡ Jalur 2 (FHD)
    </a>
  </div>
</div>`;
}

// 5. Eksekusi Bot Utama
async function runBot() {
  console.log('==================================================');
  console.log('🤖 MEIWASPORTS BLOGGER AUTO-POSTER BERJALAN');
  console.log('==================================================\n');

  const accessToken = await getValidAccessToken();
  if (!accessToken) {
    console.error('❌ Tidak dapat melanjutkan tanpa access token.');
    return;
  }

  const existingTitles = await getExistingPostTitles(accessToken);
  console.log(`ℹ️ Ditemukan ${existingTitles.size} postingan yang sudah ada di blog.\n`);

  const matches = await loadMatchesData();
  if (matches.length === 0) {
    console.log('⚠️ Tidak ada data pertandingan untuk diposting.');
    return;
  }

  let postedCount = 0;
  let skippedCount = 0;

  // Prioritaskan pertandingan LIVE dan yang akan mulai segera
  const candidateMatches = matches.filter(m => m.status !== 2); // Exclude finished

  for (const match of candidateMatches) {
    const postTitle = `${match.title} - ${match.league || 'Live Sports'}`;
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
      skippedCount++;
      continue;
    }

    console.log(`📤 Memposting ke Blogger: ${postTitle} (${match.kickoffText || ''})...`);

    const postBody = {
      kind: 'blogger#post',
      title: postTitle,
      content: generatePostHtml(match),
      labels: [match.league || 'Sport', match.status === 1 ? '🔴 LIVE' : '⏰ Siap Tayang', 'MeiwaSports']
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
      } else {
        console.warn(`   ⚠️ Respon Blogger API:`, result.message || JSON.stringify(result.error || result));
      }
    } catch (err) {
      console.error(`   ❌ Error posting: ${err.message}`);
    }

    // Jeda 2 detik antar postingan agar aman dari rate limit
    await new Promise(r => setTimeout(r, 2000));
  }

  console.log('\n==================================================');
  console.log(`🎉 SIKLUS AUTO-POST SELESAI (${new Date().toLocaleTimeString()}):`);
  console.log(`   - Berhasil diposting baru: ${postedCount} pertandingan`);
  console.log(`   - Dilewati (karena sudah ada): ${skippedCount} pertandingan`);
  console.log('==================================================');
}

// 6. Main Runner
async function main() {
  const args = process.argv.slice(2);
  const isLoop = args.includes('--loop') || args.includes('-l') || args.includes('--watch');

  if (!isLoop) {
    await runBot();
  } else {
    let intervalMinutes = 15;
    const intervalIdx = args.indexOf('--interval');
    if (intervalIdx !== -1 && args[intervalIdx + 1]) {
      const parsed = parseInt(args[intervalIdx + 1], 10);
      if (!isNaN(parsed) && parsed > 0) intervalMinutes = parsed;
    }

    console.log(`🔁 BOT BERJALAN DALAM MODE OTOMATIS (UPDATE SETIAP ${intervalMinutes} MENIT)\n`);
    while (true) {
      try {
        await runBot();
      } catch (err) {
        console.error('⚠️ Terjadi kendala:', err.message);
      }
      console.log(`\n⏳ Menunggu ${intervalMinutes} menit untuk siklus berikutnya...`);
      await new Promise(r => setTimeout(r, intervalMinutes * 60 * 1000));
    }
  }
}

main().catch(err => console.error('Fatal Bot Error:', err));
