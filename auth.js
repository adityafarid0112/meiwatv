const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const readline = require('readline');

const credentialsPath = path.join(__dirname, 'client_secrets.json');
const tokenPath = path.join(__dirname, 'token.json');

if (!fs.existsSync(credentialsPath)) {
  console.error('File client_secrets.json tidak ditemukan!');
  process.exit(1);
}

const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8')).installed;
const clientId = credentials.client_id;
const clientSecret = credentials.client_secret;
const redirectUri = 'http://localhost:3000/oauth2callback';
const scope = 'https://www.googleapis.com/auth/blogger';

const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=${encodeURIComponent(scope)}&access_type=offline&prompt=select_account%20consent`;

console.log('==================================================');
console.log('🤖 SPORTSTREAM BOT - OTENTIKASI GOOGLE BLOGGER API');
console.log('==================================================\n');
console.log('Membuka browser untuk login akun Google Anda...');
console.log('Jika browser tidak terbuka otomatis, silakan klik/salin link ini:\n');
console.log(authUrl + '\n');
console.log('==================================================');
console.log('Menunggu persetujuan dari browser...\n');

// Otomatis buka browser di Windows
exec(`start "" "${authUrl}"`);

async function exchangeCodeForToken(code) {
  try {
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code: code.trim(),
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: 'authorization_code'
      })
    });

    const tokenData = await tokenResponse.json();

    if (tokenData.error) {
      throw new Error(tokenData.error_description || tokenData.error);
    }

    fs.writeFileSync(tokenPath, JSON.stringify(tokenData, null, 2), 'utf8');

    console.log('\n==================================================');
    console.log('✅ SUKSES: Token akses berhasil disimpan ke token.json!');
    console.log('Sekarang Bot sudah siap memposting otomatis ke Blogger Anda.');
    console.log('==================================================\n');
    process.exit(0);
  } catch (err) {
    console.error('❌ Gagal mengambil token:', err.message);
  }
}

const server = http.createServer(async (req, res) => {
  if (req.url.startsWith('/oauth2callback')) {
    const urlParams = new URLSearchParams(req.url.split('?')[1]);
    const code = urlParams.get('code');
    const error = urlParams.get('error');

    if (error) {
      res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end('<h1>❌ Login Gagal atau Dibatalkan</h1><p>Silakan coba kembali.</p>');
      console.error('Error saat otentikasi:', error);
      server.close();
      return;
    }

    if (code) {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(`
        <div style="font-family: sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #10b981;">✅ Otentikasi Berhasil!</h1>
          <p style="font-size: 16px; color: #333;">Token akses Google Blogger API berhasil disimpan.</p>
          <p style="color: #666;">Anda bisa menutup tab ini dan kembali ke aplikasi.</p>
        </div>
      `);
      server.close();
      await exchangeCodeForToken(code);
    }
  }
});

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') {
    console.log('⚠️ Port 3000 sedang terpakai, silakan tutup jendela CMD sebelumnya.');
  }
});

server.listen(3000);
