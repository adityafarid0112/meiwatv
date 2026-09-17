const fs = require('fs');
const path = require('path');

const BLOG_ID = '8531123332112355973';
const credentialsPath = path.join(__dirname, 'client_secrets.json');
const tokenPath = path.join(__dirname, 'token.json');

async function getAccessToken() {
  const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8')).installed;
  const tokenData = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

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
      console.warn('Refresh error:', e.message);
    }
  }
  return tokenData.access_token;
}

// 1. Hapus postingan lama agar daftar pertandingan selalu segar dan rapi
async function cleanOldPosts(token) {
  console.log('🧹 Membersihkan postingan lama di Blogger...');
  const url = `https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts?maxResults=50`;
  const res = await fetch(url, { headers: { 'Authorization': `Bearer ${token}` } });
  const data = await res.json();

  if (data.items) {
    for (const post of data.items) {
      console.log(`🗑️ Menghapus: ${post.title} (ID: ${post.id})...`);
      try {
        await fetch(`https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts/${post.id}`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${token}` }
        });
        console.log(`   ✅ Terhapus.`);
      } catch (e) {
        console.warn(`   ⚠️ Gagal menghapus: ${e.message}`);
      }
      await new Promise(r => setTimeout(r, 600));
    }
  }
}

// 2. Scrape Xoilac dengan urutan Live Teratas & Ekstraksi Embed Stream Player
async function scrapeAndPublishLiveMatches() {
  const token = await getAccessToken();
  await cleanOldPosts(token);

  const SEED_DOMAINS = [
    'https://xoilacz.vip/',
    'https://tft-forests.org/',
    'https://xoilaczbj.tv/',
    'https://xoilac.org/'
  ];
  let html = '';
  let activeDomain = '';

  for (const seed of SEED_DOMAINS) {
    try {
      console.log(`\n📡 Menghubungi seed domain: ${seed}...`);
      const response = await fetch(seed, {
        redirect: 'follow',
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
      });
      if (response.ok) {
        html = await response.text();
        activeDomain = new URL(response.url).origin;
        console.log(`✅ Berhasil terhubung! Domain aktif (setelah redirect): ${activeDomain}`);
        break;
      }
    } catch (e) {
      console.warn(`⚠️ Gagal terhubung ke ${seed}: ${e.message}`);
    }
  }

  if (!html || !activeDomain) {
    throw new Error('Gagal mengambil data dari semua seed domain Xoilac yang tersedia.');
  }

  const allSlugs = html.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{4})\//gi) || [];
  const uniqueSlugs = [...new Set(allSlugs)];

  console.log(`🎯 Ditemukan ${uniqueSlugs.length} pertandingan di Xoilac.\n`);

  const matches = [];
  const nowTime = new Date().getTime();

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

      const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
      const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
      const matchPageUrl = `${activeDomain}/truc-tiep/${slugName}-luc-${timeStr}-ngay-${day}-${month}-${year}/`;

      const kickoffTime = new Date(kickoffIso).getTime();
      const diff = kickoffTime - nowTime;

      // Status: 0 = LIVE NOW (dalam rentang 3 jam dari kickoff), 1 = UPCOMING, 2 = FINISHED
      let status = 1;
      let statusLabel = 'MENUNGGU';
      if (diff <= 0 && diff > -10800000) {
        status = 0; // SEDANG LIVE
        statusLabel = '🔴 SEDANG LIVE';
      } else if (diff <= -10800000) {
        status = 2; // SELESAI
        statusLabel = 'SELESAI';
      }

      // Deteksi Liga & Prioritas Klub Sepakbola Utama
      let league = "Live Match";
      let priorityScore = 0;

      const lowerTitle = title.toLowerCase();
      const lowerSlug = slugName.toLowerCase();

      // Abaikan esports / basket / tenis yang bukan pertandingan utama
      if (lowerSlug.includes('esports') || lowerSlug.includes('u21') || lowerSlug.includes('u19') || lowerSlug.includes('basket') || lowerSlug.includes('tennis')) {
        continue;
      }

      if (/\b(inter|milan|inter milan|roma|as roma|torino|como|parma|udinese|juventus|napoli|lazio|atalanta|fiorentina|bologna|genoa|cagliari|verona|monza|empoli|venezia)\b/i.test(title) && !title.includes('Romania')) {
        league = "Italian Serie A";
        priorityScore += 200;
      } else if (/\b(madrid|real madrid|barcelona|atletico|sevilla|valencia|sociedad|betis|villarreal|athletic)\b/i.test(title)) {
        league = "La Liga Spain";
        priorityScore += 200;
      } else if (/\b(leeds|newcastle|arsenal|chelsea|liverpool|manchester city|manchester united|tottenham|aston villa|everton|brighton|west ham)\b/i.test(title)) {
        league = "Premier League";
        priorityScore += 200;
      } else if (/\b(bayern|munchen|dortmund|leverkusen|leipzig|stuttgart|frankfurt)\b/i.test(title)) {
        league = "German Bundesliga";
        priorityScore += 150;
      }

      // Prioritas Utama untuk pertandingan yang diminta user (Como, Parma, Torino, Roma, Inter, Udinese, Leeds, Newcastle)
      if (/\b(como|parma|torino|roma|inter|udinese|leeds|newcastle)\b/i.test(title) && !title.includes('Romania')) {
        priorityScore += 500;
      }

      // Jangan masukkan pertandingan yang sudah selesai lebih dari 3 jam lalu
      if (status !== 2) {
        matches.push({
          title,
          matchPageUrl,
          kickoffIso,
          kickoffText,
          kickoffTime,
          diff,
          status,
          statusLabel,
          league,
          priorityScore
        });
      }
    }
  }

  // URUTKAN:
  // 1. Prioritas Liga & Klub Terbesar (Priority Score Tertinggi)
  // 2. Sedang Live (status 0) di atas Upcoming (status 1)
  // 3. Waktu Kickoff Terdekat
  matches.sort((a, b) => {
    if (a.priorityScore !== b.priorityScore) return b.priorityScore - a.priorityScore;
    if (a.status !== b.status) return a.status - b.status;
    return a.kickoffTime - b.kickoffTime;
  });

  console.log(`📊 Hasil Pengurutan Pertandingan Unggulan:`);
  matches.slice(0, 10).forEach((m, idx) => {
    console.log(`  ${idx + 1}. [${m.statusLabel}] ${m.title} (${m.kickoffText}) - ${m.league} [Score: ${m.priorityScore}]`);
  });

  // Ambil hingga 10 pertandingan terbaik
  const toPublish = matches.slice(0, 10);

  for (const match of toPublish) {
    console.log(`\n🔍 Mengambil stream embed untuk: ${match.title}...`);
    let server1Url = '';
    let server2Url = '';

    try {
      const res = await fetch(match.matchPageUrl, {
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
      console.warn('   ⚠️ Error scraping embed:', err.message);
    }

    if (!server1Url) server1Url = `${match.matchPageUrl}link/0`;
    if (!server2Url) server2Url = `${match.matchPageUrl}link/1`;

    console.log(`   ⚡ Server 1 Embed: ${server1Url}`);

    const postContent = `<!-- FORMAT POSTINGAN PERTANDINGAN OTOMATIS (SPORTSTREAM BOT) -->
<!-- 1. DATA KONTROL STREAM & JADWAL -->
<div id="stream-meta" 
     data-streamurl="${server1Url}" 
     data-server2="${server2Url}"
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
</div>`;

    const postTitle = `${match.title} - ${match.league}`;
    console.log(`📤 Menerbitkan ke Blogger: ${postTitle}...`);

    try {
      const res = await fetch(`https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts/`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          kind: 'blogger#post',
          title: postTitle,
          content: postContent,
          labels: [match.league, match.status === 0 ? 'Live Now' : 'Upcoming', 'Xoilac']
        })
      });
      const result = await res.json();
      if (result.id) {
        console.log(`   ✅ SUKSES DITERBITKAN: ${result.url}`);
      } else if (result.error && result.error.status === 'PERMISSION_DENIED') {
        console.error(`\n❌ ERROR IZIN AKSES GOOGLE BLOGGER (PERMISSION DENIED):`);
        console.error(`1. Pastikan "Blogger API v3" sudah AKTIF di Google Cloud Console:`);
        console.error(`   👉 https://console.cloud.google.com/apis/library/blogger.googleapis.com?project=sportstream-bot`);
        console.error(`2. Jalankan ulang LOGIN_GOOGLE.bat dan pilih akun Google pemilik blog ini.\n`);
        break;
      } else {
        console.error(`   ❌ Gagal Menerbitkan:`, JSON.stringify(result.error || result));
      }
    } catch (e) {
      console.error(`   ❌ Exception posting: ${e.message}`);
    }

    await new Promise(r => setTimeout(r, 2000));
  }

  console.log('\n==================================================');
  console.log('🎉 SEMUA PERTANDINGAN XOILAC SUDAH DISINKRONKAN KE BLOGGER!');
  console.log('==================================================');
}

scrapeAndPublishLiveMatches().catch(console.error);
