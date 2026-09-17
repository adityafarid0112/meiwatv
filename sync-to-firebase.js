/**
 * sync-to-firebase.js
 * MeiwaTV - Sinkronisasi Otomatis Jadwal & Link Streaming ke Firebase Cloud Firestore
 * Mendukung Multi-Server: Jalur 1 (HLS HD), Jalur 2 (FLV Fast), Jalur 3 (Backup CDN)
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const SEED_DOMAINS = [
    'https://xlz.domainkqt.cc',
    'https://tft-forests.org',
    'https://xoilacz.vip',
    'https://xoilackl.tv'
];

const LOCAL_DATASET = path.join(__dirname, 'compact-matches.json');
const FIREBASE_EXPORT_FILE = path.join(__dirname, 'meiwatv-firebase-export.json');
const SERVICE_ACCOUNT_FILE = path.join(__dirname, 'firebase-service-account.json');

async function fetchJson(url) {
    return new Promise((resolve) => {
        const client = url.startsWith('https') ? https : http;
        const req = client.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://tft-forests.org/'
            },
            timeout: 8000
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (_) {
                    resolve(null);
                }
            });
        });
        req.on('error', () => resolve(null));
        req.on('timeout', () => {
            req.destroy();
            resolve(null);
        });
    });
}

function normalizeMatchData(rawList) {
    if (!Array.isArray(rawList)) return [];

    return rawList.map((item, idx) => {
        const title = item.title || 'Pertandingan Olahraga';
        const parts = title.split(/\s+vs\s+|\s+-\s+/i);
        const homeTeam = parts[0] ? parts[0].trim() : 'Tim Tuan Rumah';
        const awayTeam = parts.length > 1 ? parts[1].trim() : 'Tim Tamu';

        const stream1 = item.streamUrl || item.streamJalur1 || item.stream || '';
        const stream2 = item.server2Url || item.streamJalur2 || '';
        const stream3 = item.postUrl || item.streamJalur3 || '';

        const safeId = (item.id || `match_${idx + 1}_${homeTeam.toLowerCase().replace(/[^a-z0-9]/g, '_')}`).substring(0, 40);

        return {
            id: safeId,
            title: title,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            league: item.league || 'Live Sports',
            kickoffIso: item.kickoffIso || new Date().toISOString(),
            kickoffText: item.kickoffText || 'Live Hari Ini',
            status: item.status === 1 || item.status === 'LIVE' ? 1 : 0,
            streamJalur1: stream1,
            streamJalur2: stream2,
            streamJalur3: stream3,
            streams: {
                jalur1: stream1,
                jalur2: stream2,
                jalur3: stream3
            },
            updatedAt: new Date().toISOString()
        };
    });
}

async function runSync() {
    console.log('====================================================');
    console.log('  MEIWATV - AUTO SYNC JADWAL & STREAMING KE FIREBASE');
    console.log('====================================================\n');

    let matches = [];

    // 1. Coba baca dari dataset lokal yang sudah di-scrape
    if (fs.existsSync(LOCAL_DATASET)) {
        try {
            const raw = JSON.parse(fs.readFileSync(LOCAL_DATASET, 'utf8'));
            matches = normalizeMatchData(raw);
            console.log(`[INFO] Berhasil memuat ${matches.length} pertandingan dari dataset lokal.`);
        } catch (e) {
            console.warn('[WARN] Gagal membaca dataset lokal, beralih ke remote seed...');
        }
    }

    // 2. Jika lokal kosong, coba fetch dari seed domains
    if (matches.length === 0) {
        for (const seed of SEED_DOMAINS) {
            console.log(`[SEED] Mengecek sumber jadwal: ${seed}...`);
            const res = await fetchJson(`${seed}/api/matches`);
            if (res && Array.isArray(res)) {
                matches = normalizeMatchData(res);
                console.log(`[BERHASIL] Ditemukan ${matches.length} jadwal dari ${seed}`);
                break;
            }
        }
    }

    if (matches.length === 0) {
        console.log('[INFO] Menyiapkan sample match default untuk inisialisasi Firebase...');
        matches = [
            {
                id: 'match_arsenal_chelsea',
                title: 'Arsenal vs Chelsea',
                homeTeam: 'Arsenal',
                awayTeam: 'Chelsea',
                league: 'Premier League',
                kickoffIso: new Date().toISOString(),
                kickoffText: 'Hari ini, 21:00 WIB',
                status: 1,
                streamJalur1: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                streamJalur2: 'https://cdn.livepush.io/live/bigbuckbunnyclip/index.m3u8',
                streamJalur3: 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel18/off-tvc?is_off_add=false',
                streams: {
                    jalur1: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                    jalur2: 'https://cdn.livepush.io/live/bigbuckbunnyclip/index.m3u8',
                    jalur3: 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel18/off-tvc?is_off_add=false'
                }
            }
        ];
    }

    // 3. Simpan ke file ekspor Firebase & Asset Aplikasi Flutter
    fs.writeFileSync(FIREBASE_EXPORT_FILE, JSON.stringify(matches, null, 2), 'utf8');
    const flutterAssetPath = path.join(__dirname, 'meiwatv_app', 'assets', 'data', 'matches.json');
    if (fs.existsSync(path.dirname(flutterAssetPath))) {
        fs.writeFileSync(flutterAssetPath, JSON.stringify(matches, null, 2), 'utf8');
    }
    console.log(`\n[EXPORT] File sinkronisasi Firebase & APK disimpan ke:`);
    console.log(` - ${FIREBASE_EXPORT_FILE}`);
    console.log(` - ${flutterAssetPath}`);

    // 4. Jika ada firebase-service-account.json, lakukan upload langsung ke Firestore
    if (fs.existsSync(SERVICE_ACCOUNT_FILE)) {
        try {
            console.log('[FIREBASE] Menghubungkan ke Cloud Firestore...');
            const admin = require('firebase-admin');
            const serviceAccount = require(SERVICE_ACCOUNT_FILE);

            if (!admin.apps.length) {
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });
            }

            const db = admin.firestore();
            const batch = db.batch();

            matches.forEach((match) => {
                const docRef = db.collection('matches').doc(match.id);
                batch.set(docRef, match, { merge: true });
            });

            await batch.commit();
            console.log(`[BERHASIL] ✅ ${matches.length} Pertandingan berhasil di-push ke Firebase Firestore!`);
        } catch (err) {
            console.error('[ERROR] Gagal upload ke Firebase SDK:', err.message);
            console.log('[PETUNJUK] Pastikan paket `firebase-admin` terinstal atau gunakan file JSON export.');
        }
    } else {
        console.log('\n----------------------------------------------------');
        console.log('[PETUNJUK KONEKSI FIREBASE LANGSUNG]:');
        console.log('1. Buka Firebase Console -> Project Settings -> Service Accounts');
        console.log('2. Klik "Generate new private key" dan simpan sebagai:');
        console.log(`   ${SERVICE_ACCOUNT_FILE}`);
        console.log('3. Jalankan kembali: node sync-to-firebase.js');
        console.log('----------------------------------------------------\n');
    }

    console.log('[SELESAI] Proses sinkronisasi selesai.');
}

runSync();
