const fs = require('fs');

const logoBase64 = fs.readFileSync('meiwatv.png').toString('base64');
const logoDataUri = 'data:image/png;base64,' + logoBase64;

// Read Link nonton Online.txt
const sourceList = fs.readFileSync('Link nonton Online.txt', 'utf8')
  .split('\n')
  .map(l => l.trim())
  .filter(l => l.startsWith('http'));

console.log('Loaded reference source list:', sourceList);

// Target template logic
const xmlTemplate = `<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html>
<html b:css='false' b:defaultwidgetversion='2' b:layoutsVersion='3' expr:dir='data:blog.languageDirection' xmlns='http://www.w3.org/1999/xhtml' xmlns:b='http://www.google.com/2005/gml/b' xmlns:data='http://www.google.com/2005/gml/data' xmlns:expr='http://www.google.com/2005/gml/expr'>
<head>
  <meta charset='utf-8'/>
  <meta content='no-referrer' name='referrer'/>
  <meta content='width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=5' name='viewport'/>
  <title><data:blog.pageTitle/></title>
  <b:include data='blog' name='all-head-content'/>

  <!-- Google Fonts: Plus Jakarta Sans & Rajdhani -->
  <link href='https://fonts.googleapis.com' rel='preconnect'/>
  <link crossorigin='anonymous' href='https://fonts.gstatic.com' rel='preconnect'/>
  <link href='https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;family=Rajdhani:wght@600;700;800&amp;display=swap' rel='stylesheet'/>
  <!-- Font Awesome Icons -->
  <link href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css' rel='stylesheet'/>
  <!-- HLS.js & FLV.js Stream Player Engine -->
  <script src='https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js'/>
  <script src='https://cdnjs.cloudflare.com/ajax/libs/flv.js/1.6.4/flv.min.js'/>

  <b:skin><![CDATA[
  /* ==========================================================================
     MEIWATV LIVE STREAMING PORTAL - PRO EDITION
     ========================================================================== */
  :root {
    --bg-main: #0b0f19;
    --bg-card: #121826;
    --bg-card-hover: #1b2438;
    --bg-surface: #1e293b;
    --bg-sidebar: #0f1523;
    
    --primary: #10b981;
    --primary-glow: rgba(16, 185, 129, 0.3);
    --accent-blue: #3b82f6;
    --accent-live: #ef4444;
    --accent-live-glow: rgba(239, 68, 68, 0.4);
    --saweria-green: #22c55e;
    
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --text-dim: #64748b;
    
    --border-subtle: rgba(255, 255, 255, 0.08);
    --border-active: rgba(16, 185, 129, 0.4);
    
    --radius-sm: 8px;
    --radius-md: 12px;
    --radius-lg: 16px;
    --radius-full: 9999px;
    
    --font-main: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
    --font-sport: 'Rajdhani', sans-serif;
    --transition: all 0.2s ease-in-out;
  }

  *, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    background-color: var(--bg-main);
    color: var(--text-main);
    font-family: var(--font-main);
    font-size: 14px;
    line-height: 1.5;
    min-height: 100vh;
    overflow-x: hidden;
  }

  a {
    color: inherit;
    text-decoration: none;
    transition: var(--transition);
  }

  /* HEADER & NAV */
  .site-header {
    background: #090d16;
    border-bottom: 1px solid var(--border-subtle);
    position: sticky;
    top: 0;
    z-index: 100;
  }

  .nav-container {
    max-width: 1440px;
    margin: 0 auto;
    padding: 0 20px;
    height: 64px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .brand-logo {
    display: flex;
    align-items: center;
    gap: 10px;
    text-decoration: none;
  }

  .brand-logo-img {
    height: 38px;
    width: auto;
    max-width: 180px;
    object-fit: contain;
    background: #ffffff;
    padding: 4px 12px;
    border-radius: var(--radius-sm);
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
    transition: var(--transition);
  }

  .brand-logo:hover .brand-logo-img {
    transform: scale(1.02);
    box-shadow: 0 0 15px rgba(59, 130, 246, 0.5);
  }

  /* MAIN STADIUM SPLIT LAYOUT */
  .stadium-container {
    max-width: 1440px;
    margin: 20px auto;
    padding: 0 20px;
    display: grid;
    grid-template-columns: 1fr 380px;
    gap: 20px;
    align-items: start;
  }

  @media (max-width: 1024px) {
    .stadium-container {
      grid-template-columns: 1fr;
    }
  }

  /* HERO BROADCAST STAGE */
  .hero-broadcast-stage {
    position: relative;
    width: 100%;
    min-height: 380px;
    background: radial-gradient(circle at 50% 15%, #1e293b 0%, #090d16 85%);
    border-radius: var(--radius-md);
    overflow: hidden;
    border: 1px solid rgba(16, 185, 129, 0.25);
    box-shadow: 0 15px 35px rgba(0, 0, 0, 0.7), inset 0 1px 0 rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 35px 20px;
    text-align: center;
  }

  .stadium-backdrop-glow {
    position: absolute;
    top: -60px;
    left: 50%;
    transform: translateX(-50%);
    width: 500px;
    height: 300px;
    background: radial-gradient(circle, rgba(16, 185, 129, 0.25) 0%, rgba(59, 130, 246, 0.15) 50%, transparent 70%);
    filter: blur(40px);
    pointer-events: none;
  }

  .hero-stage-content {
    position: relative;
    z-index: 2;
    width: 100%;
    max-width: 680px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
  }

  .hero-status-pill {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
    justify-content: center;
  }

  .live-badge-glow {
    background: rgba(239, 68, 68, 0.2);
    color: #f87171;
    border: 1px solid rgba(239, 68, 68, 0.4);
    font-size: 12px;
    font-weight: 800;
    padding: 5px 14px;
    border-radius: var(--radius-full);
    letter-spacing: 0.5px;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    box-shadow: 0 0 15px rgba(239, 68, 68, 0.3);
  }

  .league-name-text {
    background: rgba(16, 185, 129, 0.15);
    color: var(--primary);
    border: 1px solid rgba(16, 185, 129, 0.3);
    font-size: 12px;
    font-weight: 800;
    padding: 5px 14px;
    border-radius: var(--radius-full);
    text-transform: uppercase;
  }

  .matchup-vs-container {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 24px;
    margin: 10px 0;
    width: 100%;
  }

  .team-box {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
  }

  .team-icon-circle {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02));
    border: 2px solid rgba(255, 255, 255, 0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 26px;
    color: var(--primary);
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
    transition: var(--transition);
  }
  .hero-broadcast-stage:hover .team-icon-circle {
    border-color: var(--primary);
    box-shadow: 0 0 20px var(--primary-glow);
  }

  .team-title {
    font-family: var(--font-sport);
    font-size: 22px;
    font-weight: 800;
    color: #fff;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }

  .vs-badge-circle {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: #0f1523;
    border: 1px solid rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: var(--font-sport);
    font-size: 16px;
    font-weight: 800;
    color: #94a3b8;
  }

  .matchup-meta-info {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .hero-full-title {
    font-family: var(--font-sport);
    font-size: 26px;
    font-weight: 800;
    color: #fff;
    letter-spacing: 0.5px;
  }

  .hero-kickoff-time {
    font-size: 14px;
    color: var(--text-muted);
  }
  .hero-kickoff-time b {
    color: var(--primary);
  }

  /* CALL TO ACTION BUTTONS */
  .broadcast-cta-actions {
    display: flex;
    flex-direction: column;
    gap: 10px;
    width: 100%;
    max-width: 480px;
    margin-top: 10px;
  }

  .btn-play-stream {
    width: 100%;
    padding: 14px 24px;
    border-radius: var(--radius-sm);
    font-size: 15px;
    font-weight: 800;
    cursor: pointer;
    border: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    transition: all 0.25s ease;
  }

  .btn-play-stream.main-hd {
    background: linear-gradient(135deg, #10b981, #059669);
    color: #000;
    box-shadow: 0 4px 20px rgba(16, 185, 129, 0.4);
  }
  .btn-play-stream.main-hd:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(16, 185, 129, 0.6);
    background: linear-gradient(135deg, #34d399, #10b981);
  }

  .btn-play-stream.secondary-backup {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.15);
    color: #f8fafc;
  }
  .btn-play-stream.secondary-backup:hover {
    background: rgba(255, 255, 255, 0.12);
    border-color: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
  }

  /* IN-PAGE LIVE VIDEO PLAYER SCREEN */
  .hero-player-screen {
    width: 100%;
    display: flex;
    flex-direction: column;
    border-radius: var(--radius-md);
    overflow: hidden;
    background: #000;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.8);
    border: 1px solid rgba(16, 185, 129, 0.3);
    margin-bottom: 10px;
    z-index: 5;
  }

  .player-top-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    background: #0d131f;
    padding: 8px 12px;
    border-bottom: 1px solid var(--border-subtle);
    gap: 8px;
    flex-wrap: wrap;
  }

  .player-server-tabs {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .btn-server-tab {
    background: rgba(255, 255, 255, 0.08);
    color: #cbd5e1;
    border: 1px solid rgba(255, 255, 255, 0.12);
    padding: 6px 14px;
    border-radius: var(--radius-sm);
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: var(--transition);
  }

  .btn-server-tab:hover, .btn-server-tab.active {
    background: var(--primary);
    color: #000;
    border-color: var(--primary);
    box-shadow: 0 0 12px var(--primary-glow);
  }

  .player-action-tools {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .btn-tool-tab {
    background: rgba(255, 255, 255, 0.08);
    color: #94a3b8;
    border: 1px solid rgba(255, 255, 255, 0.12);
    width: 32px;
    height: 32px;
    border-radius: var(--radius-sm);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 13px;
    transition: var(--transition);
  }

  .btn-tool-tab:hover {
    background: rgba(255, 255, 255, 0.2);
    color: #fff;
  }

  .btn-tool-tab.close:hover {
    background: #ef4444;
    color: #fff;
  }

  .video-responsive-wrapper {
    position: relative;
    width: 100%;
    padding-top: 56.25%;
    background: #000;
  }

  .video-responsive-wrapper video,
  .video-responsive-wrapper iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
    background: #000;
    object-fit: contain;
  }

  .player-unmute-btn {
    position: absolute;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #10b981, #059669);
    color: #000;
    font-weight: 800;
    font-size: 13px;
    padding: 10px 22px;
    border-radius: var(--radius-full);
    border: none;
    cursor: pointer;
    z-index: 20;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.6);
  }

  .player-loading-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.85);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 12px;
    color: var(--primary);
    font-size: 14px;
    font-weight: 700;
    z-index: 10;
  }

  .player-spinner {
    width: 40px;
    height: 40px;
    border: 3px solid rgba(16, 185, 129, 0.2);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
  }

  .stream-feature-notice {
    font-size: 12px;
    color: var(--text-dim);
    margin-top: 4px;
  }

  /* RIGHT SIDEBAR: SCHEDULE LIST */
  .events-sidebar-card {
    background: var(--bg-sidebar);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-md);
    overflow: hidden;
    display: flex;
    flex-direction: column;
    height: 680px;
  }

  .sidebar-tabs-nav {
    display: flex;
    background: #0a0e18;
    border-bottom: 1px solid var(--border-subtle);
  }

  .tab-btn {
    flex: 1;
    text-align: center;
    padding: 12px 6px;
    font-size: 13px;
    font-weight: 700;
    color: var(--text-muted);
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
    transition: var(--transition);
  }
  .tab-btn.active {
    color: #fff;
    background: var(--bg-sidebar);
    border-bottom-color: var(--primary);
  }

  /* MATCH LIST ITEMS */
  .sidebar-match-scroll {
    flex: 1;
    overflow-y: auto;
    padding: 10px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .sidebar-match-scroll::-webkit-scrollbar {
    width: 5px;
  }
  .sidebar-match-scroll::-webkit-scrollbar-thumb {
    background: var(--bg-surface);
    border-radius: 4px;
  }

  .match-event-row {
    background: var(--bg-card);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-sm);
    padding: 10px 12px;
    transition: var(--transition);
    display: block;
    cursor: pointer;
  }
  .match-event-row:hover, .match-event-row.active {
    border-color: var(--border-active);
    background: var(--bg-card-hover);
    transform: translateX(2px);
  }

  .event-league-row {
    font-size: 12px;
    font-weight: 700;
    color: var(--text-muted);
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .event-link-preview {
    font-size: 10px;
    color: var(--text-dim);
    margin-bottom: 8px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .event-teams-flex {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
  }

  .teams-col {
    display: flex;
    flex-direction: column;
    gap: 4px;
    flex: 1;
  }

  .team-item {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 13px;
    font-weight: 600;
    color: #fff;
  }

  .event-time-col {
    text-align: right;
    font-size: 11px;
    color: var(--text-muted);
    line-height: 1.3;
    white-space: nowrap;
  }
  .event-time-col .time-bold {
    font-weight: 800;
    color: var(--primary);
    font-size: 12px;
    display: block;
  }

  /* BOTTOM ACTION BUTTONS */
  .sidebar-bottom-actions {
    padding: 12px;
    background: #0a0e18;
    border-top: 1px solid var(--border-subtle);
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .btn-worldcup-channel {
    background: linear-gradient(135deg, #2563eb, #1d4ed8);
    color: #fff;
    font-weight: 700;
    font-size: 13px;
    padding: 10px;
    border-radius: var(--radius-sm);
    text-align: center;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }
  .btn-worldcup-channel:hover {
    background: #1d4ed8;
  }

  .btn-saweria-donate {
    background: linear-gradient(135deg, #15803d, #166534);
    color: #fff;
    font-weight: 700;
    font-size: 13px;
    padding: 10px;
    border-radius: var(--radius-sm);
    text-align: center;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }
  .btn-saweria-donate:hover {
    background: #166534;
  }

  /* FOOTER */
  .site-footer {
    background: #080c14;
    border-top: 1px solid var(--border-subtle);
    padding: 30px 20px;
    margin-top: 40px;
    text-align: center;
    font-size: 12px;
    color: var(--text-dim);
  }
  ]]></b:skin>
  <b:template-skin><![CDATA[ ]]></b:template-skin>
</head>

<body>

  <!-- HEADER -->
  <header class='site-header'>
    <div class='nav-container'>
      <a class='brand-logo' expr:href='data:blog.homepageUrl'>
        <img alt='MEIWATV' class='brand-logo-img' src='${logoDataUri}'/>
      </a>

      <div style='display:flex; align-items:center; gap:8px;'>
        <span style='background:rgba(239, 68, 68, 0.15); color:#f87171; border:1px solid rgba(239, 68, 68, 0.3); font-size:12px; font-weight:800; padding:4px 12px; border-radius:50px; display:inline-flex; align-items:center; gap:6px;'>
          <i class='fa-solid fa-circle' style='font-size:7px; animation:blink 1s infinite;'/> 24/7 LIVE
        </span>
      </div>
    </div>
  </header>

  <!-- STADIUM MAIN WRAPPER -->
  <div class='stadium-container'>

    <!-- LEFT: HERO MATCH BROADCAST STAGE -->
    <div class='stadium-left'>
      <div class='hero-broadcast-stage' id='heroBroadcastStage'>
        <div class='stadium-backdrop-glow'/>

        <!-- 1. IN-PAGE LIVE VIDEO PLAYER SCREEN -->
        <div class='hero-player-screen' id='heroPlayerScreen' style='display:none;'>
          <div class='player-top-toolbar'>
            <div class='player-server-tabs'>
              <button class='btn-server-tab active' id='tabServer1' onclick='switchPlayerServer(1)'>
                <i class='fa-solid fa-play'/> SERVER 1 HD
              </button>
              <button class='btn-server-tab' id='tabServer2' onclick='switchPlayerServer(2)'>
                <i class='fa-solid fa-satellite-dish'/> SERVER 2 (CADANGAN)
              </button>
            </div>
            <div class='player-action-tools'>
              <button class='btn-tool-tab' onclick='toggleFullscreenPlayer()' title='Layar Penuh'>
                <i class='fa-solid fa-expand'/>
              </button>
              <button class='btn-tool-tab' onclick='openStreamInNewTab()' title='Buka di Tab Baru'>
                <i class='fa-solid fa-arrow-up-right-from-square'/>
              </button>
              <button class='btn-tool-tab close' onclick='closePlayerScreen()' title='Tutup Player'>
                <i class='fa-solid fa-xmark'/>
              </button>
            </div>
          </div>
          <div class='video-responsive-wrapper' id='videoWrapper'>
            <!-- Primary: HTML5 Video with HLS.js & FLV.js Stream Engine -->
            <video autoplay='autoplay' controls='controls' id='liveVideoElement' muted='muted' playsinline='playsinline'/>

            <!-- Unmute Overlay Banner -->
            <button class='player-unmute-btn' id='playerUnmuteBtn' onclick='togglePlayerAudio(event)' style='display:none;'>
              <i class='fa-solid fa-volume-high'/> KLIK UNTUK MENGAKTIFKAN SUARA
            </button>

            <!-- Fallback: Embed Iframe Player -->
            <iframe allow='autoplay; fullscreen; encrypted-media; picture-in-picture' allowfullscreen='true' frameborder='0' id='livePlayerIframe' referrerpolicy='no-referrer' scrolling='no' src='about:blank' style='display:none;'>
            </iframe>

            <!-- Loading Spinner Overlay -->
            <div class='player-loading-overlay' id='playerLoadingOverlay' style='display:none;'>
              <div class='player-spinner'/>
              <span>Menghubungkan ke Siaran Live HD...</span>
            </div>
          </div>
        </div>
        
        <!-- 2. HERO MATCH CARD INFO & PLAY CTA -->
        <div class='hero-stage-content' id='heroStageContent'>
          <!-- Live Status Pulse -->
          <div class='hero-status-pill'>
            <span class='live-badge-glow' id='heroStatusPill'>
              <i class='fa-solid fa-circle' style='font-size:8px; animation:blink 1s infinite;'/> SIARAN LANGSUNG AKTIF
            </span>
            <span class='league-name-text' id='heroLeagueBadge'>🏆 MEIWATV LIVE</span>
          </div>

          <!-- Teams Matchup Flex -->
          <div class='matchup-vs-container'>
            <div class='team-box home'>
              <div class='team-icon-circle'><i class='fa-solid fa-shield-halved'/></div>
              <div class='team-title' id='heroHomeTeam'>Pilih Pertandingan</div>
            </div>
            <div class='vs-badge-circle'>
              <span>VS</span>
            </div>
            <div class='team-box away'>
              <div class='team-icon-circle'><i class='fa-solid fa-shield-halved'/></div>
              <div class='team-title' id='heroAwayTeam'>Dari Jadwal</div>
            </div>
          </div>

          <!-- Match Timing & Full Title -->
          <div class='matchup-meta-info'>
            <h2 class='hero-full-title' id='heroMatchTitle'>Pilih Pertandingan Live Streaming</h2>
            <div class='hero-kickoff-time' id='heroKickoffLabel'>
              <i class='fa-regular fa-clock'/> Jadwal: <b>Pilih dari daftar di sebelah kanan</b>
            </div>
          </div>

          <!-- PRIMARY BROADCAST CALL-TO-ACTION BUTTONS -->
          <div class='broadcast-cta-actions'>
            <button class='btn-play-stream main-hd' id='btnPlayServer1' onclick='launchStreamServer(1)'>
              <i class='fa-solid fa-play'/> PUTAR SIARAN LANGSUNG (SERVER 1 HD)
            </button>
            <button class='btn-play-stream secondary-backup' id='btnPlayServer2' onclick='launchStreamServer(2)'>
              <i class='fa-solid fa-satellite-dish'/> SERVER 2 (CADANGAN)
            </button>
          </div>

          <div class='stream-feature-notice'>
            <i class='fa-solid fa-circle-check' style='color:var(--primary);'/> Siaran Kualitas 1080p 60FPS &#8226; Server FLV &amp; HLS Cepat Tanpa Buffer
          </div>
        </div>
      </div>

      <!-- [SLOT IKLAN 1 - 728x90] -->
      <div class='adsterra-banner-container' style='margin: 15px 0; padding: 15px; background: rgba(255,255,255,0.02); border: 1px dashed rgba(255,255,255,0.15); border-radius: 8px; text-align: center;'>
        <div style='font-size: 11px; color: var(--text-dim); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 1px;'>
          <i class='fa-solid fa-rectangle-ad'/> SPONSOR / IKLAN ADSTERRA (728x90)
        </div>
        <div id='adsterra-slot-728x90' style='min-height: 90px; display: flex; align-items: center; justify-content: center; color: var(--text-muted); font-size: 13px;'>
          <span style='background: rgba(255,255,255,0.05); padding: 10px 20px; border-radius: 6px; border: 1px solid rgba(255,255,255,0.08);'>
            <script>
  atOptions = {
    &#39;key&#39; : &#39;0b453dca166b5389587addc2ba0a053a&#39;,
    &#39;format&#39; : &#39;iframe&#39;,
    &#39;height&#39; : 90,
    &#39;width&#39; : 728,
    &#39;params&#39; : {}
  };
            </script>
            <script src='https://www.highrevenueformat.com/0b453dca166b5389587addc2ba0a053a/invoke.js'/>
          </span>
        </div>
      </div>

    </div>

    <!-- RIGHT: SCHEDULE SIDEBAR -->
    <aside class='stadium-right'>
      <div class='events-sidebar-card'>
        
        <div class='sidebar-tabs-nav'>
          <button class='tab-btn active' style='cursor:default; font-size:14px; text-transform:uppercase; letter-spacing:0.5px;'>
            <i class='fa-solid fa-satellite-dish' style='color:var(--accent-live); margin-right:6px;'/> Live Streaming
          </button>
        </div>

        <!-- Match Schedule List -->
        <div class='sidebar-match-scroll' id='matchScrollList'>
          
          <b:section class='main' id='main' showaddelement='no'>
            <b:widget id='Blog1' locked='true' title='Postingan Blog' type='Blog' version='2' visible='true'>
              <b:widget-settings>
                <b:widget-setting name='showDateHeader'>false</b:widget-setting>
                <b:widget-setting name='style.textcolor'>#ffffff</b:widget-setting>
                <b:widget-setting name='showShareButtons'>true</b:widget-setting>
                <b:widget-setting name='showCommentLink'>true</b:widget-setting>
                <b:widget-setting name='style.urlcolor'>#ffffff</b:widget-setting>
                <b:widget-setting name='showAuthor'>false</b:widget-setting>
                <b:widget-setting name='style.linkcolor'>#ffffff</b:widget-setting>
                <b:widget-setting name='style.unittype'>TextAndImage</b:widget-setting>
                <b:widget-setting name='style.bgcolor'>#ffffff</b:widget-setting>
                <b:widget-setting name='timestampLabel'/>
                <b:widget-setting name='reactionsLabel'/>
                <b:widget-setting name='showAuthorProfile'>false</b:widget-setting>
                <b:widget-setting name='style.layout'>1x1</b:widget-setting>
                <b:widget-setting name='showLabels'>true</b:widget-setting>
                <b:widget-setting name='showLocation'>true</b:widget-setting>
                <b:widget-setting name='postLabelsLabel'/>
                <b:widget-setting name='showTimestamp'>true</b:widget-setting>
                <b:widget-setting name='postsPerAd'>3</b:widget-setting>
                <b:widget-setting name='showBacklinks'>false</b:widget-setting>
                <b:widget-setting name='style.bordercolor'>#ffffff</b:widget-setting>
                <b:widget-setting name='showInlineAds'>true</b:widget-setting>
                <b:widget-setting name='showReactions'>false</b:widget-setting>
              </b:widget-settings>
              <b:includable id='main' var='top'>
                
                <b:if cond='data:posts'>
                  <b:loop values='data:posts' var='post'>
                    <div class='match-event-row' expr:data-posttitle='data:post.title' expr:data-posturl='data:post.url' onclick='handleMatchClick(this)'>
                      
                      <div class='event-league-row'>
                        <span class='match-league-badge'>
                          <b:if cond='data:post.labels'>
                            <b:loop values='data:post.labels' var='label'>
                              <data:label.name/>
                            </b:loop>
                          <b:else/>
                            Live Match
                          </b:if>
                        </span>
                        <span class='match-item-countdown'>00h : 00m : 00s</span>
                      </div>
                      
                      <a class='event-link-preview' expr:href='data:post.url' onclick='event.stopPropagation();' target='_blank' title='Buka Pertandingan'>
                        <i class='fa-solid fa-arrow-up-right-from-square'/> <data:post.title/>
                      </a>
                      
                      <div class='event-teams-flex'>
                        <div class='teams-col'>
                          <div class='team-item'>
                            <i class='fa-solid fa-futbol' style='color:var(--primary); font-size:14px;'/>
                            <span class='team-name-text' style='font-size:13px; font-weight:700; color:#fff;'><data:post.title/></span>
                          </div>
                        </div>
                        <div class='event-time-col'>
                          <span>Jadwal</span>
                          <span class='time-bold'><data:post.timestamp/></span>
                        </div>
                      </div>

                      <div class='post-hidden-meta' style='display:none;'>
                        <data:post.body/>
                      </div>

                    </div>
                  </b:loop>
                <b:else/>
                  <div class='empty-feed-placeholder' id='emptyFeedLoader' style='padding:30px 20px; text-align:center; color:var(--text-muted);'>
                    <div class='player-spinner' style='margin:0 auto 12px auto; width:32px; height:32px;'/>
                    <div style='font-size:14px; font-weight:700; color:#fff; margin-bottom:6px;'>Memuat Jadwal Live Real-Time...</div>
                    <div style='font-size:12px; color:var(--text-dim);'>Sinkronisasi otomatis dengan siaran aktif</div>
                  </div>
                </b:if>

              </b:includable>
              <b:includable id='aboutPostAuthor'>
  <div class='author-name'>
    <a class='g-profile' expr:href='data:post.author.profileUrl' rel='author' title='author profile'>
      <span>
        <data:post.author.name/>
      </span>
    </a>
  </div>
  <div>
    <span class='author-desc'>
      <data:post.author.aboutMe/>
    </span>
  </div>
</b:includable>
              <b:includable id='addComments'>
  <a expr:href='data:post.commentsUrl' expr:onclick='data:post.commentsUrlOnclick'>
    <b:message name='messages.postAComment'/>
  </a>
</b:includable>
              <b:includable id='blogThisShare'>
  <b:with value='&quot;window.open(this.href, \&quot;_blank\&quot;, \&quot;height=270,width=475\&quot;); return false;&quot;' var='onclick'>
    <b:include name='platformShare'/>
  </b:with>
</b:includable>
              <b:includable id='bylineByName' var='byline'>
  <b:switch var='data:byline.name'>
  <b:case value='share'/>
    <b:include cond='data:post.shareUrl' name='postShareButtons'/>
  <b:case value='comments'/>
    <b:include cond='data:post.allowComments' name='postCommentsLink'/>
  <b:case value='location'/>
    <b:include cond='data:post.location' name='postLocation'/>
  <b:case value='timestamp'/>
    <b:include cond='not data:view.isPage' name='postTimestamp'/>
  <b:case value='author'/>
    <b:include name='postAuthor'/>
  <b:case value='labels'/>
    <b:include cond='data:post.labels' name='postLabels'/>
  <b:case value='icons'/>
    <b:include cond='data:post.emailPostUrl' name='emailPostIcon'/>
  </b:switch>
</b:includable>
              <b:includable id='bylineRegion' var='regionItems'>
  <b:loop values='data:regionItems' var='byline'>
    <b:include data='byline' name='bylineByName'/>
  </b:loop>
</b:includable>
              <b:includable id='commentAuthorAvatar'>
  <div class='avatar-image-container'>
    <img class='author-avatar' expr:src='data:comment.authorAvatarSrc' height='35' width='35'/>
  </div>
</b:includable>
              <b:includable id='commentDeleteIcon' var='comment'>
  <span expr:class='&quot;item-control &quot; + data:comment.adminClass'>
    <b:if cond='data:showCmtPopup'>
      <div class='goog-toggle-button'>
        <div class='goog-inline-block comment-action-icon'/>
      </div>
    <b:else/>
      <a class='comment-delete' expr:href='data:comment.deleteUrl' expr:title='data:messages.deleteComment'>
        <img src='https://resources.blogblog.com/img/icon_delete13.gif'/>
      </a>
    </b:if>
  </span>
</b:includable>
              <b:includable id='commentForm' var='post'>
  <div class='comment-form'>
    <a name='comment-form'/>
    <h4 id='comment-post-message'><data:messages.postAComment/></h4>
    <b:if cond='data:this.messages.blogComment != &quot;&quot;'>
      <p><data:this.messages.blogComment/></p>
    </b:if>
    <b:include data='post' name='commentFormIframeSrc'/>
    <iframe allowtransparency='allowtransparency' class='blogger-iframe-colorize blogger-comment-from-post' expr:height='data:cmtIframeInitialHeight ?: &quot;90px&quot;' frameborder='0' id='comment-editor' name='comment-editor' src='' width='100%'/>
    <data:post.cmtfpIframe/>
    <script type='text/javascript'>
      BLOG_CMT_createIframe(&#39;<data:post.appRpcRelayPath/>&#39;);
    </script>
  </div>
</b:includable>
              <b:includable id='commentFormIframeSrc' var='post'>
  <a expr:href='data:post.commentFormIframeSrc' id='comment-editor-src'/>
</b:includable>
              <b:includable id='commentItem' var='comment'>
  <div class='comment' expr:id='&quot;c&quot; + data:comment.id'>
    <b:include cond='data:blog.enabledCommentProfileImages' name='commentAuthorAvatar'/>

    <div class='comment-block'>
      <div class='comment-author'>
        <b:if cond='data:comment.authorUrl'>
          <b:message name='messages.authorSaidWithLink'>
            <b:param expr:value='data:comment.author' name='authorName'/>
            <b:param expr:value='data:comment.authorUrl' name='authorUrl'/>
          </b:message>
        <b:else/>
          <b:message name='messages.authorSaid'>
            <b:param expr:value='data:comment.author' name='authorName'/>
          </b:message>
        </b:if>
      </div>
      <div expr:class='&quot;comment-body&quot; + (data:comment.isDeleted ? &quot; deleted&quot; : &quot;&quot;)'>
        <data:comment.body/>
      </div>
      <div class='comment-footer'>
        <span class='comment-timestamp'>
          <a expr:href='data:comment.url' title='comment permalink'>
            <data:comment.timestamp/>
          </a>
          <b:include data='comment' name='commentDeleteIcon'/>
        </span>
      </div>
    </div>
  </div>
</b:includable>
              <b:includable id='commentList' var='comments'>
  <div id='comments-block'>
    <b:loop values='data:comments' var='comment'>
      <b:include data='comment' name='commentItem'/>
    </b:loop>
  </div>
</b:includable>
              <b:includable id='commentPicker' var='post'>
  <b:if cond='data:post.showThreadedComments'>
    <b:include data='post' name='threadedComments'/>
  <b:else/>
    <b:include data='post' name='comments'/>
  </b:if>
</b:includable>
              <b:includable id='comments' var='post'>
  <section expr:class='&quot;comments&quot; + (data:post.embedCommentForm ? &quot; embed&quot; : &quot;&quot;)' expr:data-num-comments='data:post.numberOfComments' id='comments'>
    <a name='comments'/>
    <b:if cond='data:post.allowComments'>

      <b:include name='commentsTitle'/>

      <div expr:id='data:widget.instanceId + &quot;_comments-block-wrapper&quot;'>
        <b:include cond='data:post.comments' data='post.comments' name='commentList'/>
      </div>

      <b:if cond='data:post.commentPagingRequired'>
        <div class='paging-control-container'>
          <b:if cond='data:post.hasOlderLinks'>
            <a expr:class='data:post.oldLinkClass' expr:href='data:post.oldestLinkUrl'>
              <data:messages.oldest/>
            </a>
            <a expr:class='data:post.oldLinkClass' expr:href='data:post.olderLinkUrl'>
              <data:messages.older/>
            </a>
          </b:if>

          <span class='comment-range-text'>
            <data:post.commentRangeText/>
          </span>

          <b:if cond='data:post.hasNewerLinks'>
            <a expr:class='data:post.newLinkClass' expr:href='data:post.newerLinkUrl'>
              <data:messages.newer/>
            </a>
            <a expr:class='data:post.newLinkClass' expr:href='data:post.newestLinkUrl'>
              <data:messages.newest/>
            </a>
          </b:if>
        </div>
      </b:if>

      <div class='footer'>
        <b:if cond='data:post.embedCommentForm'>
          <b:if cond='data:post.allowNewComments'>
            <b:include data='post' name='commentForm'/>
          <b:else/>
            <data:post.noNewCommentsText/>
          </b:if>
        <b:else/>
          <b:if cond='data:post.allowComments'>
            <b:include data='post' name='addComments'/>
          </b:if>
        </b:if>
      </div>
    </b:if>
    <b:if cond='data:showCmtPopup'>
      <div id='comment-popup'>
        <iframe allowtransparency='allowtransparency' frameborder='0' id='comment-actions' name='comment-actions' scrolling='no'>
        </iframe>
      </div>
    </b:if>
  </section>
</b:includable>
              <b:includable id='commentsLink'>
  <a class='comment-link' expr:href='data:post.commentsUrl' expr:onclick='data:post.commentsUrlOnclick'>
    <b:if cond='data:post.numberOfComments &gt; 0'>
      <b:message name='messages.numberOfComments'>
        <b:param expr:value='data:post.numberOfComments' name='numComments'/>
      </b:message>
    <b:else/>
      <data:messages.postAComment/>
    </b:if>
  </a>
</b:includable>
              <b:includable id='commentsLinkIframe'>
  <!-- G+ comments, no longer available. The includable is retained for backwards-compatibility. -->
</b:includable>
              <b:includable id='commentsTitle'>
  <h3 class='title'><data:messages.comments/></h3>
</b:includable>
              <b:includable id='defaultAdUnit'>
  <ins class='adsbygoogle' data-ad-format='auto' expr:data-ad-client='data:adClientId ?: data:blog.adsenseClientId' expr:data-ad-host='data:blog.adsenseHostId' expr:style='data:style ?: &quot;display: block;&quot;'>
    <b:attr cond='not data:blog.analytics4' expr:value='data:blog.analyticsAccountNumber' name='data-analytics-uacct'/>
  </ins>
  <script>
   (adsbygoogle = window.adsbygoogle || []).push({});
  </script>
</b:includable>
              <b:includable id='emailPostIcon'>
  <span class='byline post-icons'>
    <!-- email post links -->
    <span class='item-action'>
      <a expr:href='data:post.emailPostUrl' expr:title='data:messages.emailPost'>
        <b:include data='{ iconClass: &quot;touch-icon sharing-icon&quot; }' name='emailIcon'/>
      </a>
    </span>
  </span>
</b:includable>
              <b:includable id='facebookShare'>
  <b:with value='&quot;window.open(this.href, \&quot;_blank\&quot;, \&quot;height=430,width=640\&quot;); return false;&quot;' var='onclick'>
    <b:include name='platformShare'/>
  </b:with>
</b:includable>
              <b:includable id='feedLinks'>
  <b:if cond='!data:view.isPost'> <!-- Blog feed links -->
    <b:if cond='data:feedLinks'>
      <div class='blog-feeds'>
        <b:include data='feedLinks' name='feedLinksBody'/>
      </div>
    </b:if>
  <b:else/> <!--Post feed links -->
    <div class='post-feeds'>
      <b:loop values='data:posts' var='post'>
        <b:if cond='data:post.allowComments and data:post.feedLinks'>
          <b:include data='post.feedLinks' name='feedLinksBody'/>
        </b:if>
      </b:loop>
    </div>
  </b:if>
</b:includable>
              <b:includable id='feedLinksBody' var='links'>
  <div class='feed-links'>
  <data:messages.subscribeTo/>
  <b:loop values='data:links' var='f'>
     <a class='feed-link' expr:href='data:f.url' expr:type='data:f.mimeType' target='_blank'><data:f.name/> (<data:f.feedType/>)</a>
  </b:loop>
  </div>
</b:includable>
              <b:includable id='footerBylines'>
  <b:if cond='data:widgets.Blog.first.footerBylines'>
    <b:loop index='i' values='data:widgets.Blog.first.footerBylines' var='region'>
      <b:if cond='not data:region.items.empty'>
        <div expr:class='&quot;post-footer-line post-footer-line-&quot; + (data:i + 1)'>
          <b:with value='&quot;footer-&quot; + (data:i + 1)' var='regionName'>
            <b:include data='region.items' name='bylineRegion'/>
          </b:with>
        </div>
      </b:if>
    </b:loop>
  </b:if>
</b:includable>
              <b:includable id='googlePlusShare'>
</b:includable>
              <b:includable id='headerByline'>
  <b:if cond='data:widgets.Blog.first.headerByline'>
    <div class='post-header'>
      <div class='post-header-line-1'>
        <b:with value='&quot;header-1&quot;' var='regionName'>
          <b:include data='data:widgets.Blog.first.headerByline.items' name='bylineRegion'/>
        </b:with>
      </div>
    </div>
  </b:if>
</b:includable>
              <b:includable id='homePageLink'>
  <a class='home-link' expr:href='data:blog.homepageUrl'>
    <data:messages.home/>
  </a>
</b:includable>
              <b:includable id='iframeComments' var='post'>
  <!-- G+ comments, no longer available. The includable is retained for backwards-compatibility. -->
</b:includable>
              <b:includable id='inlineAd' var='post'>
  <b:if cond='!data:view.isPreview'>
    <b:if cond='data:this.adCode or data:this.adClientId or data:blog.adsenseClientId'>
      <!-- Ad -->
      <div class='inline-ad'>
        <b:if cond='data:this.adCode != &quot;&quot;'>
          <data:this.adCode/>
        <b:else/>
          <b:include cond='data:this.adClientId or data:blog.adsenseClientId' name='defaultAdUnit'/>
        </b:if>
      </div>
    </b:if>
  <b:else/>
    <div class='inline-ad'>
      <div class='inline-ad-placeholder'>
        <span><b:message name='messages.adsGoHere'/></span>
      </div>
    </div>
  </b:if>
</b:includable>
              <b:includable id='linkShare'>
  <b:with value='&quot;window.prompt(\&quot;Copy to clipboard: Ctrl+C, Enter\&quot;, \&quot;&quot; + data:originalUrl + &quot;\&quot;); return false;&quot;' var='onclick'>
    <b:include name='platformShare'/>
  </b:with>
</b:includable>
              <b:includable id='nextPageLink'>
  <a class='blog-pager-older-link' expr:href='data:olderPageUrl' expr:id='data:widget.instanceId + &quot;_blog-pager-older-link&quot;' expr:title='data:messages.olderPosts'>
    <data:messages.olderPosts/>
  </a>
</b:includable>
              <b:includable id='otherSharingButton'>
  <span class='sharing-platform-button sharing-element-other' expr:aria-label='data:messages.shareToOtherApps.escaped' expr:data-url='data:originalUrl' expr:title='data:messages.shareToOtherApps.escaped' role='menuitem' tabindex='-1'>
    <b:with value='{key: &quot;sharingOther&quot;}' var='platform'>
      <b:include name='sharingPlatformIcon'/>
    </b:with>
    <span class='platform-sharing-text'><data:messages.shareOtherApps.escaped/></span>
  </span>
</b:includable>
              <b:includable id='platformShare'>
  <a expr:class='&quot;goog-inline-block sharing-&quot; + data:platform.key' expr:data-url='data:originalUrl' expr:href='data:shareUrl + &quot;&amp;target=&quot; + data:platform.target' expr:onclick='data:onclick ? data:onclick : &quot;&quot;' expr:title='data:platform.shareMessage' target='_blank'>
    <span class='share-button-link-text'>
      <data:platform.shareMessage/>
    </span>
  </a>
</b:includable>
              <b:includable id='post' var='post'>
  <div class='post'>
    <b:include data='post' name='postMeta'/>
    <b:include data='post' name='postTitle'/>
    <b:include name='headerByline'/>
    <b:if cond='data:view.isSingleItem'>
      <b:include data='post' name='postBody'/>
    <b:else/>
      <b:include data='post' name='postBodySnippet'/>
      <b:include data='post' name='postJumpLink'/>
    </b:if>
    <b:include data='post' name='postFooter'/>
  </div>
</b:includable>
              <b:includable id='postAuthor'>
  <span class='byline post-author vcard'>
    <span class='post-author-label'>
      <data:byline.label/>
    </span>
    <span class='fn'>
      <b:if cond='data:post.author.profileUrl'>
        <meta expr:content='data:post.author.profileUrl'/>
        <a class='g-profile' expr:href='data:post.author.profileUrl' rel='author' title='author profile'>
          <span><data:post.author.name/></span>
        </a>
      <b:else/>
        <span><data:post.author.name/></span>
      </b:if>
    </span>
  </span>
</b:includable>
              <b:includable id='postBody' var='post'>
  <!-- If metaDescription is empty, use the post body as the schema.org description too, for G+/FB snippeting. -->
  <div class='post-body entry-content float-container' expr:id='&quot;post-body-&quot; + data:post.id'>
    <data:post.body/>
  </div>
</b:includable>
              <b:includable id='postBodySnippet' var='post'>
  <b:include data='post' name='postBody'/>
</b:includable>
              <b:includable id='postCommentsAndAd' var='post'>
  <article class='post-outer-container'>
    <!-- Post title and body -->
    <div class='post-outer'>
      <b:include data='post' name='post'/>
    </div>

    <!-- Comments -->
    <b:include cond='data:view.isSingleItem' data='post' name='commentPicker'/>

    <!-- Show ad inside post container, after comments, if single item. -->
    <b:include cond='data:view.isSingleItem and data:post.includeAd' data='post' name='inlineAd'/>
  </article>

  <!-- Show ad outside post container (between posts) for feed pages. -->
  <b:include cond='data:view.isMultipleItems and data:post.includeAd' data='post' name='inlineAd'/>
</b:includable>
              <b:includable id='postCommentsLink'>
  <b:if cond='data:view.isMultipleItems'>
    <span class='byline post-comment-link container'>
      <b:include cond='data:post.commentSource != 1' name='commentsLink'/>
    </span>
  </b:if>
</b:includable>
              <b:includable id='postFooter' var='post'>
  <div class='post-footer'>
    <b:include name='footerBylines'/>
    <b:include data='post' name='postFooterAuthorProfile'/>
  </div>
</b:includable>
              <b:includable id='postFooterAuthorProfile' var='post'>
  <b:if cond='data:post.author.aboutMe and data:view.isPost'>
    <div class='author-profile'>
      <b:if cond='data:post.author.authorPhoto.url'>
        <img class='author-image' expr:src='data:post.author.authorPhoto.url' width='50px'/>
        <div class='author-about'>
          <b:include data='post' name='aboutPostAuthor'/>
        </div>
      <b:else/>
        <b:include data='post' name='aboutPostAuthor'/>
      </b:if>
    </div>
  </b:if>
</b:includable>
              <b:includable id='postHeader' var='post'>
  <b:include name='headerByline'/>
</b:includable>
              <b:includable id='postJumpLink' var='post'>
  <div class='jump-link flat-button'>
    <a expr:href='data:post.url fragment &quot;more&quot;' expr:title='data:post.title'>
      <b:eval expr='data:blog.jumpLinkMessage'/>
    </a>
  </div>
</b:includable>
              <b:includable id='postLabels'>
  <span class='byline post-labels'>
    <span class='byline-label'><data:byline.label/></span>
    <b:loop index='i' values='data:post.labels' var='label'>
      <a expr:href='data:label.url' rel='tag'>
        <data:label.name/>
      </a>
    </b:loop>
  </span>
</b:includable>
              <b:includable id='postLocation'>
  <span class='byline post-location'>
    <data:byline.label/>
    <a expr:href='data:post.location.mapsUrl' target='_blank'><data:post.location.name/></a>
  </span>
</b:includable>
              <b:includable id='postMeta' var='post'>
  <b:include data='post' name='postMetadataJSON'/>
</b:includable>
              <b:includable id='postMetadataJSONImage'>
  &quot;image&quot;: {
    &quot;@type&quot;: &quot;ImageObject&quot;,
    <b:if cond='data:post.featuredImage.isResizable'>
    &quot;url&quot;: &quot;<b:eval expr='resizeImage(data:post.featuredImage, 1200, &quot;1200:630&quot;)'/>&quot;,
    &quot;height&quot;: 630,
    &quot;width&quot;: 1200
    <b:else/>
    &quot;url&quot;: &quot;https://blogger.googleusercontent.com/img/b/U2hvZWJveA/AVvXsEgfMvYAhAbdHksiBA24JKmb2Tav6K0GviwztID3Cq4VpV96HaJfy0viIu8z1SSw_G9n5FQHZWSRao61M3e58ImahqBtr7LiOUS6m_w59IvDYwjmMcbq3fKW4JSbacqkbxTo8B90dWp0Cese92xfLMPe_tg11g/w1200/&quot;,
    &quot;height&quot;: 348,
    &quot;width&quot;: 1200
    </b:if>
  },
</b:includable>
              <b:includable id='postMetadataJSONPublisher'>
 &quot;publisher&quot;: {
    &quot;@type&quot;: &quot;Organization&quot;,
    &quot;name&quot;: &quot;Blogger&quot;,
    &quot;logo&quot;: {
      &quot;@type&quot;: &quot;ImageObject&quot;,
      &quot;url&quot;: &quot;https://blogger.googleusercontent.com/img/b/U2hvZWJveA/AVvXsEgfMvYAhAbdHksiBA24JKmb2Tav6K0GviwztID3Cq4VpV96HaJfy0viIu8z1SSw_G9n5FQHZWSRao61M3e58ImahqBtr7LiOUS6m_w59IvDYwjmMcbq3fKW4JSbacqkbxTo8B90dWp0Cese92xfLMPe_tg11g/h60/&quot;,
      &quot;width&quot;: 206,
      &quot;height&quot;: 60
    }
  },
</b:includable>
              <b:includable id='postPagination'>
  <div class='blog-pager container' id='blog-pager'>
    <b:include cond='data:newerPageUrl' name='previousPageLink'/>
    <b:include cond='data:olderPageUrl' name='nextPageLink'/>
    <b:include cond='data:view.url != data:blog.homepageUrl' name='homePageLink'/>
  </div>
</b:includable>
              <b:includable id='postReactions'>
  <!-- Reaction feature no longer available. The includable is retained for backwards-compatibility. -->
</b:includable>
              <b:includable id='postShareButtons'>
  <div class='byline post-share-buttons goog-inline-block'>
    <b:with value='data:sharingId ?: ((data:widget.instanceId ?: &quot;sharing&quot;) + &quot;-&quot; + (data:regionName ?: &quot;byline&quot;) + &quot;-&quot; + data:post.id)' var='sharingId'>
      <!-- Note: 'sharingButtons' includable is from the default Sharing widget markup. -->
      <b:include data='{                                                sharingId: data:sharingId,                                                originalUrl: data:post.url,                                                platforms: data:this.sharing.platforms,                                                shareUrl: data:post.shareUrl,                                                shareTitle: data:post.title,                                              }' name='sharingButtons'/>
    </b:with>
  </div>
</b:includable>
              <b:includable id='postTimestamp'>
  <span class='byline post-timestamp'>
    <data:byline.label/>
    <b:if cond='data:post.url'>
      <meta expr:content='data:post.url.canonical'/>
      <a class='timestamp-link' expr:href='data:post.url' rel='bookmark' title='permanent link'>
        <time class='published' expr:datetime='data:post.date.iso8601' expr:title='data:post.date.iso8601'>
          <data:post.date/>
        </time>
      </a>
    </b:if>
  </span>
</b:includable>
              <b:includable id='postTitle' var='post'>
  <a expr:name='data:post.id'/>
  <b:if cond='data:post.title != &quot;&quot;'>
    <h3 class='post-title entry-title'>
      <b:if cond='data:post.link or (data:post.url and data:view.url != data:post.url)'>
        <a expr:href='data:post.link ?: data:post.url'><data:post.title/></a>
      <b:else/>
        <data:post.title/>
      </b:if>
    </h3>
  </b:if>
</b:includable>
              <b:includable id='previousPageLink'>
  <a class='blog-pager-newer-link' expr:href='data:newerPageUrl' expr:id='data:widget.instanceId + &quot;_blog-pager-newer-link&quot;' expr:title='data:messages.newerPosts'>
    <data:messages.newerPosts/>
  </a>
</b:includable>
              <b:includable id='sharingButton'>
  <span expr:aria-label='data:platform.shareMessage' expr:class='&quot;sharing-platform-button sharing-element-&quot; + data:platform.key' expr:data-href='data:shareUrl + &quot;&amp;target=&quot; + data:platform.target' expr:data-url='data:originalUrl' expr:title='data:platform.shareMessage' role='menuitem' tabindex='-1'>
    <b:include name='sharingPlatformIcon'/>
    <span class='platform-sharing-text'><data:platform.name/></span>
  </span>
</b:includable>
              <b:includable id='sharingButtonContent'>
  <div class='flat-icon-button ripple'>
    <b:include name='shareIcon'/>
  </div>
</b:includable>
              <b:includable id='sharingButtons'>
  <div class='sharing' expr:aria-owns='&quot;sharing-popup-&quot; + data:sharingId' expr:data-title='data:shareTitle'>
    <button class='sharing-button touch-icon-button' expr:aria-controls='&quot;sharing-popup-&quot; + data:sharingId' expr:aria-label='data:messages.share.escaped' expr:id='&quot;sharing-button-&quot; + data:sharingId' role='button'>
      <b:include name='sharingButtonContent'/>
    </button>
    <b:include name='sharingButtonsMenu'/>
  </div>
</b:includable>
              <b:includable id='sharingButtonsMenu'>
  <div class='share-buttons-container'>
    <ul aria-hidden='true' class='share-buttons hidden' expr:aria-label='data:messages.share.escaped' expr:id='&quot;sharing-popup-&quot; + data:sharingId' role='menu'>
      <b:loop values='(data:platforms ?: data:blog.sharing.platforms) filter (p =&gt; p.key not in {&quot;blogThis&quot;})' var='platform'>
        <li>
          <b:include name='sharingButton'/>
        </li>
      </b:loop>
      <li aria-hidden='true' class='hidden'>
        <b:include name='otherSharingButton'/>
      </li>
    </ul>
  </div>
</b:includable>
              <b:includable id='sharingPlatformIcon'>
  <b:include data='{ iconClass: (&quot;touch-icon sharing-&quot; + data:platform.key) }' expr:name='data:platform.key + &quot;Icon&quot;'/>
</b:includable>
              <b:includable id='threadedCommentForm' var='post'>
  <div class='comment-form'>
    <a name='comment-form'/>
    <h4 id='comment-post-message'><data:messages.postAComment/></h4>
    <b:if cond='data:this.messages.blogComment != &quot;&quot;'>
      <p><data:this.messages.blogComment/></p>
    </b:if>
    <b:include data='post' name='commentFormIframeSrc'/>
    <iframe allowtransparency='allowtransparency' class='blogger-iframe-colorize blogger-comment-from-post' expr:height='data:cmtIframeInitialHeight ?: &quot;90px&quot;' frameborder='0' id='comment-editor' name='comment-editor' src='' width='100%'/>
    <data:post.cmtfpIframe/>
    <script type='text/javascript'>
      BLOG_CMT_createIframe(&#39;<data:post.appRpcRelayPath/>&#39;);
    </script>
  </div>
</b:includable>
              <b:includable id='threadedCommentJs' var='post'>
  <script async='async' expr:src='data:post.commentSrc' type='text/javascript'/>
  <b:template-script inline='true' name='threaded_comments'/>
  <script type='text/javascript'>
    blogger.widgets.blog.initThreadedComments(
        <data:post.commentJso/>,
        <data:post.commentMsgs/>,
        <data:post.commentConfig/>);
  </script>
</b:includable>
              <b:includable id='threadedComments' var='post'>
  <section class='comments threaded' expr:data-embed='data:post.embedCommentForm' expr:data-num-comments='data:post.numberOfComments' id='comments'>
    <a name='comments'/>

    <b:include name='commentsTitle'/>

    <div class='comments-content'>
      <b:if cond='data:post.embedCommentForm'>
        <b:include data='post' name='threadedCommentJs'/>
      </b:if>
      <div id='comment-holder'>
         <data:post.commentHtml/>
      </div>
    </div>

    <p class='comment-footer'>
      <b:if cond='data:post.allowNewComments'>
        <b:include data='post' name='threadedCommentForm'/>
      <b:else/>
        <data:post.noNewCommentsText/>
      </b:if>
      <b:if cond='data:post.showManageComments'>
        <b:include data='post' name='manageComments'/>
      </b:if>
    </p>

    <b:if cond='data:showCmtPopup'>
      <div id='comment-popup'>
        <iframe allowtransparency='allowtransparency' frameborder='0' id='comment-actions' name='comment-actions' scrolling='no'>
        </iframe>
      </div>
    </b:if>
  </section>
</b:includable>
              <b:includable id='tooltipCss'>
  <!-- LINT.IfChange -->
  <style>
    .post-body a.b-tooltip-container {
      position: relative;
      display: inline-block;
    }

    .post-body a.b-tooltip-container .b-tooltip {
      display: block !important;
      position: absolute;
      top: 100%;
      left: 50%;
      transform: translate(-20%, 1px);
      visibility: hidden;
      opacity: 0;
      z-index: 1;
      transition: opacity 0.2s ease-in-out;
    }

    .post-body a.b-tooltip-container .b-tooltip iframe {
      width: 200px;
      height: 198px;
      max-width: none;
      border: none;
      border-radius: 20px;
      box-shadow: 1px 1px 3px 1px rgba(0, 0, 0, 0.2);
    }

    @media (hover: hover) {
      .post-body a.b-tooltip-container:hover .b-tooltip {
        visibility: visible;
        opacity: 1;
      }
    }
  </style>
  <!-- LINT.ThenChange(//depot/google3/java/com/google/blogger/b2/layouts/widgets/v2-style.css) -->
</b:includable>
            </b:widget>
          </b:section>

        </div>

        <!-- [SLOT IKLAN 2 - 300x250] -->
        <div class='adsterra-banner-sidebar' style='margin: 10px; padding: 12px; background: rgba(255,255,255,0.02); border: 1px dashed rgba(255,255,255,0.15); border-radius: 6px; text-align: center;'>
          <div style='font-size: 10px; color: var(--text-dim); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 1px;'>
            <i class='fa-solid fa-rectangle-ad'/> SPONSOR / IKLAN SIDEBAR (300x250)
          </div>
          <div id='adsterra-slot-300x250' style='min-height: 80px; display: flex; align-items: center; justify-content: center; color: var(--text-muted); font-size: 12px;'>
            <span style='background: rgba(255,255,255,0.05); padding: 8px 14px; border-radius: 6px; border: 1px solid rgba(255,255,255,0.08);'>
              <script>
  atOptions = {
    &#39;key&#39; : &#39;b3ebfb84dfe7f276ec8ca6b0601afc33&#39;,
    &#39;format&#39; : &#39;iframe&#39;,
    &#39;height&#39; : 60,
    &#39;width&#39; : 468,
    &#39;params&#39; : {}
  };
              </script>
              <script src='https://www.highrevenueformat.com/b3ebfb84dfe7f276ec8ca6b0601afc33/invoke.js'/>
            </span>
          </div>
        </div>

        <!-- Bottom Action Buttons -->
        <div class='sidebar-bottom-actions'>
          <button class='btn-worldcup-channel' onclick='fetchLiveMatchesDirect()' style='border:none; cursor:pointer;'>
            <i class='fa-solid fa-rotate'/> Refresh Jadwal
          </button>
          <a class='btn-saweria-donate' href='https://saweria.co/meiwatv' target='_blank'>
            <i class='fa-solid fa-mug-hot'/> Saweria (Donasi)
          </a>
        </div>

      </div>
    </aside>

  </div>

  <!-- FOOTER -->
  <footer class='site-footer'>
    <p>Portal Link Live Streaming Olahraga Terlengkap &amp; Tercepat - MEIWATV.</p>
  </footer>

  <!-- CLIENT-SIDE SCRIPT -->
  <script type='text/javascript'>
  //<![CDATA[

  const ADSTERRA_DIRECT_LINK = "https://www.profitableratecpmnetwork.com/nhgf41xe?key=c1f7258bb9659ab225647c310b68619e";

  let activeStreamUrlServer1 = "";
  let activeStreamUrlServer2 = "";
  let activeCurrentServer = 1;
  let currentTargetKickoff = null;

  let flvPlayerInstance = null;
  let hlsInstance = null;
  let adsterraOpenedForSession = false;

  // DATASET SIARAN AKTIF REAL-TIME (VERIFIED ACTIVE CHANNELS)
  const AUTO_LIVE_DATASET = [
    {
      "title": "Inter Miami vs Cruz Azul",
      "league": "CONCACAF Champions Cup",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel13",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-13",
      "postUrl": "https://tft-forests.org/truc-tiep/inter-miami-vs-cruz-azul-luc-0700-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T07:00:00+07:00",
      "kickoffText": "17/09/2026, 07:00 WIB"
    },
    {
      "title": "Corinthians Sp vs Estudiantes Lp",
      "league": "Copa Libertadores",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel9",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-9",
      "postUrl": "https://tft-forests.org/truc-tiep/corinthians-sp-vs-estudiantes-lp-luc-0730-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T07:30:00+07:00",
      "kickoffText": "17/09/2026, 07:30 WIB"
    },
    {
      "title": "Cartagines Deportiva vs Deportivo Saprissa",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel28",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-28",
      "postUrl": "https://tft-forests.org/truc-tiep/cartagines-deportiva-vs-deportivo-saprissa-luc-0730-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T07:30:00+07:00",
      "kickoffText": "17/09/2026, 07:30 WIB"
    },
    {
      "title": "Pottu Via Ho vs Delfin Sc",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel8",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-8",
      "postUrl": "https://tft-forests.org/truc-tiep/pottu-via-ho-vs-delfin-sc-luc-0700-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T07:00:00+07:00",
      "kickoffText": "17/09/2026, 07:00 WIB"
    },
    {
      "title": "Deportivo Metropolitano vs Caracas Fc",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel7",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-7",
      "postUrl": "https://tft-forests.org/truc-tiep/deportivo-metropolitano-vs-caracas-fc-luc-0630-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T06:30:00+07:00",
      "kickoffText": "17/09/2026, 06:30 WIB"
    },
    {
      "title": "Once Caldas vs Deportes Tolima",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel17",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-17",
      "postUrl": "https://tft-forests.org/truc-tiep/once-caldas-vs-deportes-tolima-luc-0615-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T06:15:00+07:00",
      "kickoffText": "17/09/2026, 06:15 WIB"
    },
    {
      "title": "Montreal Impact vs Vancouver Whitecaps",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel23",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-23",
      "postUrl": "https://tft-forests.org/truc-tiep/montreal-impact-vs-vancouver-whitecaps-luc-0600-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T06:00:00+07:00",
      "kickoffText": "17/09/2026, 06:00 WIB"
    },
    {
      "title": "Atletico Mineiro vs Santos",
      "league": "La Liga Spain",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel18",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-18",
      "postUrl": "https://tft-forests.org/truc-tiep/atletico-mineiro-vs-santos-luc-0500-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T05:00:00+07:00",
      "kickoffText": "17/09/2026, 05:00 WIB"
    },
    {
      "title": "Botafogo Rj vs Gremio Rs",
      "league": "Live Match",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel12",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-12",
      "postUrl": "https://tft-forests.org/truc-tiep/botafogo-rj-vs-gremio-rs-luc-0530-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T05:30:00+07:00",
      "kickoffText": "17/09/2026, 05:30 WIB"
    },
    {
      "title": "Columbus Crew vs Orlando City",
      "league": "Premier League",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/7/link/channel28",
      "server2Url": "https://tft-forests.org/truc-tiep/columbus-crew-vs-orlando-city-luc-0600-ngay-17-09-2026/link/1",
      "postUrl": "https://tft-forests.org/truc-tiep/columbus-crew-vs-orlando-city-luc-0600-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T06:00:00+07:00",
      "kickoffText": "17/09/2026, 06:00 WIB"
    },
    {
      "title": "Ldu Quito vs Palmeiras",
      "league": "Copa Libertadores",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel22",
      "server2Url": "https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-22",
      "postUrl": "https://tft-forests.org/truc-tiep/ldu-quito-vs-palmeiras-luc-0500-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T05:00:00+07:00",
      "kickoffText": "17/09/2026, 05:00 WIB"
    },
    {
      "title": "Brazil vs Bolivia",
      "league": "World Cup Qualifiers",
      "streamUrl": "https://xlz.domainkqt.cc/ajax/chanel/type/7/link/channel33",
      "server2Url": "https://tft-forests.org/truc-tiep/brazil-vs-bolivia-luc-0700-ngay-17-09-2026/link/1",
      "postUrl": "https://tft-forests.org/truc-tiep/brazil-vs-bolivia-luc-0700-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T07:00:00+07:00",
      "kickoffText": "17/09/2026, 07:00 WIB"
    },
    {
      "title": "Eintracht Frankfurt vs All For One Gaming",
      "league": "German Bundesliga",
      "streamUrl": "https://tft-forests.org/truc-tiep/eintracht-frankfurt-vs-all-for-one-gaming-luc-2300-ngay-17-09-2026/link/0",
      "server2Url": "https://tft-forests.org/truc-tiep/eintracht-frankfurt-vs-all-for-one-gaming-luc-2300-ngay-17-09-2026/link/1",
      "postUrl": "https://tft-forests.org/truc-tiep/eintracht-frankfurt-vs-all-for-one-gaming-luc-2300-ngay-17-09-2026/",
      "kickoffIso": "2026-09-17T23:00:00+07:00",
      "kickoffText": "17/09/2026, 23:00 WIB"
    }
  ];

  // 1. EXTRACTOR DARI KONTEN POSTINGAN BLOGGER
  function extractStreamInfo(bodyHtml, fallbackUrl, fallbackDateIso, fallbackDateText, postTitle) {
    let streamUrl = "";
    let server2Url = "";
    let kickoffIso = fallbackDateIso || "";
    let kickoffText = fallbackDateText || "";
    let league = "Live Match";

    if (bodyHtml) {
      const cleanHtml = bodyHtml
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>');

      const streamUrlMatch = cleanHtml.match(/data-streamurl=["']([^"']+)["']/i);
      if (streamUrlMatch && streamUrlMatch[1]) streamUrl = streamUrlMatch[1].trim();

      const server2Match = cleanHtml.match(/data-server2=["']([^"']+)["']/i);
      if (server2Match && server2Match[1]) server2Url = server2Match[1].trim();

      const kickoffMatch = cleanHtml.match(/data-kickoff=["']([^"']+)["']/i);
      if (kickoffMatch && kickoffMatch[1]) kickoffIso = kickoffMatch[1].trim();

      const kickoffTextMatch = cleanHtml.match(/data-kickoff-text=["']([^"']+)["']/i);
      if (kickoffTextMatch && kickoffTextMatch[1]) kickoffText = kickoffTextMatch[1].trim();

      const leagueMatch = cleanHtml.match(/data-league=["']([^"']+)["']/i);
      if (leagueMatch && leagueMatch[1]) league = leagueMatch[1].trim();
    }

    if (!streamUrl) streamUrl = fallbackUrl || "about:blank";

    return { streamUrl, server2Url, kickoffIso, kickoffText, league };
  }

  function triggerAdsterraPopunder() {
    if (!adsterraOpenedForSession && ADSTERRA_DIRECT_LINK && ADSTERRA_DIRECT_LINK.startsWith('http')) {
      adsterraOpenedForSession = true;
      try {
        const pop = window.open(ADSTERRA_DIRECT_LINK, '_blank');
        if (pop) pop.blur();
        window.focus();
      } catch (e) {}
    }
  }

  // 2. RESOLVER STREAM CDN (FLV / HLS / DIRECT CHANNEL)
  function resolveStreamEndpoints(rawUrl) {
    let flvUrl = "";
    let hlsUrl = "";
    let channel = "";

    if (rawUrl) {
      if (rawUrl.includes('.flv')) flvUrl = rawUrl;
      if (rawUrl.includes('.m3u8')) hlsUrl = rawUrl;

      const match = rawUrl.match(/link\/(channel[\\-_]?[0-9a-zA-Z]+)/i) || rawUrl.match(/(channel[\\-_]?[0-9a-zA-Z]+)/i);
      if (match && match[1]) {
        channel = match[1].replace(/[^a-zA-Z0-9]/g, '');
        flvUrl = 'https://live2.zundrixmediapipeline.com/live/' + channel + '.flv';
        hlsUrl = 'https://live2.zundrixmediapipeline.com/live/' + channel + '.m3u8';
      }
    }

    return { flvUrl, hlsUrl, channel };
  }

  // 3. LAUNCH STREAM SERVER: LANGSUNG PUTAR DI HALAMAN BLOG
  function launchStreamServer(serverNum) {
    activeCurrentServer = serverNum;
    const targetUrl = (serverNum === 2 && activeStreamUrlServer2) ? activeStreamUrlServer2 : activeStreamUrlServer1;
    triggerAdsterraPopunder();
    playInPageStream(targetUrl, serverNum);
  }

  function playInPageStream(streamUrl, serverNum) {
    const playerScreen = document.getElementById('heroPlayerScreen');
    const stageContent = document.getElementById('heroStageContent');
    const video = document.getElementById('liveVideoElement');
    const iframe = document.getElementById('livePlayerIframe');
    const loader = document.getElementById('playerLoadingOverlay');
    const unmuteBtn = document.getElementById('playerUnmuteBtn');
    const tab1 = document.getElementById('tabServer1');
    const tab2 = document.getElementById('tabServer2');

    if (!playerScreen || !video) return;

    playerScreen.style.display = 'flex';
    if (stageContent) stageContent.style.display = 'none';
    if (loader) loader.style.display = 'flex';

    if (tab1 && tab2) {
      if (serverNum === 2) {
        tab1.classList.remove('active');
        tab2.classList.add('active');
      } else {
        tab1.classList.add('active');
        tab2.classList.remove('active');
      }
    }

    // Reset player instances
    if (flvPlayerInstance) {
      try {
        flvPlayerInstance.pause();
        flvPlayerInstance.unload();
        flvPlayerInstance.detachMediaElement();
        flvPlayerInstance.destroy();
      } catch (e) {}
      flvPlayerInstance = null;
    }
    if (hlsInstance) {
      try {
        hlsInstance.destroy();
      } catch (e) {}
      hlsInstance = null;
    }

    video.style.display = 'block';
    if (iframe) iframe.style.display = 'none';

    video.muted = true;
    video.defaultMuted = true;

    const rawUrl = streamUrl || activeStreamUrlServer1 || "";
    const endpoints = resolveStreamEndpoints(rawUrl);

    console.log("🎬 Memutar Live Stream HD MEIWATV:", endpoints);

    // Event listener: hilangkan loader segera saat video berputar!
    const clearLoader = function() {
      if (loader) loader.style.display = 'none';
      if (unmuteBtn && video.muted) unmuteBtn.style.display = 'inline-flex';
    };

    video.onplaying = clearLoader;
    video.onloadeddata = clearLoader;
    video.ontimeupdate = function() {
      if (video.currentTime > 0) clearLoader();
    };

    // Primary: HLS.js (Adaptive 1080p, bebas preflight CORS, stabil di semua browser)
    if (endpoints.hlsUrl && window.Hls && Hls.isSupported()) {
      hlsInstance = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
        backBufferLength: 30,
        manifestLoadingTimeOut: 4000,
        manifestLoadingMaxRetry: 2
      });
      hlsInstance.loadSource(endpoints.hlsUrl);
      hlsInstance.attachMedia(video);
      hlsInstance.on(Hls.Events.MANIFEST_PARSED, function() {
        video.play().catch(e => console.log('HLS play deferred:', e));
      });
      hlsInstance.on(Hls.Events.ERROR, function(event, data) {
        if (data.fatal) {
          console.warn('HLS fatal error, trying FLV fallback:', data.type);
          tryFlvFallback(endpoints.flvUrl);
        }
      });
    } else if (endpoints.flvUrl && window.flvjs && flvjs.isSupported()) {
      tryFlvFallback(endpoints.flvUrl);
    } else if (video.canPlayType('application/vnd.apple.mpegurl') && endpoints.hlsUrl) {
      video.src = endpoints.hlsUrl;
      video.play().catch(e => console.log('Safari play deferred:', e));
    } else if (rawUrl && rawUrl.startsWith('http') && iframe) {
      video.style.display = 'none';
      iframe.style.display = 'block';
      iframe.src = rawUrl;
      clearLoader();
    }

    function tryFlvFallback(flvUrl) {
      if (!flvUrl || !window.flvjs || !flvjs.isSupported()) {
        clearLoader();
        return;
      }
      try {
        flvPlayerInstance = flvjs.createPlayer({
          type: 'flv',
          isLive: true,
          url: flvUrl,
          cors: true,
          hasAudio: true,
          hasVideo: true
        }, {
          enableWorker: false,
          lazyLoad: false,
          autoCleanupSourceBuffer: true
        });
        flvPlayerInstance.attachMediaElement(video);
        flvPlayerInstance.load();
        video.play().catch(e => console.log('FLV play deferred:', e));
      } catch (e) {
        console.warn('FLV init error:', e);
        clearLoader();
      }
    }

    // Safety timeout: jangan biarkan spinner berputar lebih dari 2.5 detik
    setTimeout(clearLoader, 2500);

    playerScreen.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function togglePlayerAudio(e) {
    if (e) e.stopPropagation();
    const video = document.getElementById('liveVideoElement');
    const unmuteBtn = document.getElementById('playerUnmuteBtn');
    if (video) {
      video.muted = false;
      video.volume = 1.0;
    }
    if (unmuteBtn) unmuteBtn.style.display = 'none';
  }

  function switchPlayerServer(serverNum) {
    activeCurrentServer = serverNum;
    const targetUrl = (serverNum === 2 && activeStreamUrlServer2) ? activeStreamUrlServer2 : activeStreamUrlServer1;
    playInPageStream(targetUrl, serverNum);
  }

  function closePlayerScreen() {
    const playerScreen = document.getElementById('heroPlayerScreen');
    const stageContent = document.getElementById('heroStageContent');
    const video = document.getElementById('liveVideoElement');
    const iframe = document.getElementById('livePlayerIframe');
    const unmuteBtn = document.getElementById('playerUnmuteBtn');

    if (flvPlayerInstance) {
      try {
        flvPlayerInstance.pause();
        flvPlayerInstance.unload();
        flvPlayerInstance.detachMediaElement();
        flvPlayerInstance.destroy();
      } catch (e) {}
      flvPlayerInstance = null;
    }
    if (hlsInstance) {
      try {
        hlsInstance.destroy();
      } catch (e) {}
      hlsInstance = null;
    }
    if (video) {
      video.pause();
      video.removeAttribute('src');
      video.load();
    }
    if (iframe) iframe.src = 'about:blank';
    if (unmuteBtn) unmuteBtn.style.display = 'none';

    if (playerScreen && stageContent) {
      playerScreen.style.display = 'none';
      stageContent.style.display = 'flex';
    }
  }

  function openStreamInNewTab() {
    const rawUrl = (activeCurrentServer === 2 && activeStreamUrlServer2) ? activeStreamUrlServer2 : activeStreamUrlServer1;
    const endpoints = resolveStreamEndpoints(rawUrl);
    const targetUrl = endpoints.hlsUrl || endpoints.flvUrl || rawUrl;
    if (targetUrl && targetUrl !== 'about:blank') {
      window.open(targetUrl, '_blank');
    }
  }

  function toggleFullscreenPlayer() {
    const wrapper = document.getElementById('videoWrapper');
    const video = document.getElementById('liveVideoElement');
    if (!wrapper && !video) return;

    if (!document.fullscreenElement) {
      if (wrapper && wrapper.requestFullscreen) {
        wrapper.requestFullscreen().catch(err => {
          if (video && video.requestFullscreen) video.requestFullscreen();
        });
      } else if (video && video.webkitEnterFullscreen) {
        video.webkitEnterFullscreen();
      }
    } else {
      if (document.exitFullscreen) document.exitFullscreen();
    }
  }

  // 4. TERAPKAN PERTANDINGAN KE HERO BROADCAST STAGE
  function applyMatchToPlayer(title, streamUrl, server2Url, kickoffIso, kickoffText, league) {
    activeStreamUrlServer1 = streamUrl || "";
    activeStreamUrlServer2 = server2Url || "";

    const heroTitle = document.getElementById('heroMatchTitle');
    const heroLeague = document.getElementById('heroLeagueBadge');
    const heroKickoff = document.getElementById('heroKickoffLabel');
    const heroHome = document.getElementById('heroHomeTeam');
    const heroAway = document.getElementById('heroAwayTeam');
    const playerScreen = document.getElementById('heroPlayerScreen');

    if (heroTitle) heroTitle.innerText = title || "Pilih Pertandingan";

    if (playerScreen && playerScreen.style.display !== 'none') {
      const targetUrl = (activeCurrentServer === 2 && activeStreamUrlServer2) ? activeStreamUrlServer2 : activeStreamUrlServer1;
      playInPageStream(targetUrl, activeCurrentServer);
    }

    if (title && title.includes(' vs ')) {
      const parts = title.split(/\\s+vs\\s+/i);
      if (heroHome && parts[0]) heroHome.innerText = parts[0].trim();
      if (heroAway && parts[1]) heroAway.innerText = parts[1].trim();
    } else if (title && title.includes(' - ')) {
      const parts = title.split(/\\s+-\\s+/i);
      if (heroHome && parts[0]) heroHome.innerText = parts[0].trim();
      if (heroAway && parts[1]) heroAway.innerText = parts[1].trim();
    } else {
      if (heroHome) heroHome.innerText = title || "Tim Kandang";
      if (heroAway) heroAway.innerText = "Tim Tandang";
    }

    if (heroLeague) {
      heroLeague.innerText = (league && league !== 'Live Match') ? '🏆 ' + league.toUpperCase() : "🏆 MEIWATV LIVE";
    }

    if (heroKickoff) {
      heroKickoff.innerHTML = '<i class=\\'fa-regular fa-clock\\'></i> Kickoff: <b>' + (kickoffText || 'Siaran Langsung') + '</b>';
    }

    if (kickoffIso) {
      const parsed = new Date(kickoffIso).getTime();
      currentTargetKickoff = !isNaN(parsed) ? parsed : null;
    } else {
      currentTargetKickoff = null;
    }
  }

  function handleMatchClick(rowEl) {
    if (!rowEl) return;
    document.querySelectorAll('.match-event-row').forEach(r => r.classList.remove('active'));
    rowEl.classList.add('active');

    const title = rowEl.getAttribute('data-posttitle') || 'Live Match';
    const streamUrl = rowEl.getAttribute('data-streamurl') || '';
    const server2Url = rowEl.getAttribute('data-server2') || '';
    const kickoffIso = rowEl.getAttribute('data-kickoff') || '';
    const kickoffText = rowEl.getAttribute('data-postdate') || '';
    const league = rowEl.querySelector('.match-league-badge') ? rowEl.querySelector('.match-league-badge').innerText : 'Live Match';

    applyMatchToPlayer(title, streamUrl, server2Url, kickoffIso, kickoffText, league);

    if (window.innerWidth <= 992) {
      const heroStage = document.getElementById('heroBroadcastStage');
      if (heroStage) {
        heroStage.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }
  }

  // 5. SMART COUNTDOWN ENGINE
  function startCountdownTimer() {
    setInterval(() => {
      const now = new Date().getTime();
      document.querySelectorAll('.match-item-countdown').forEach(badge => {
        const kickoffAttr = badge.getAttribute('data-kickoff');
        if (kickoffAttr) {
          const matchTarget = new Date(kickoffAttr).getTime();
          if (!isNaN(matchTarget)) {
            const diff = matchTarget - now;
            if (diff > 0) {
              const totalSec = Math.floor(diff / 1000);
              const h = String(Math.floor(totalSec / 3600)).padStart(2, '0');
              const m = String(Math.floor((totalSec % 3600) / 60)).padStart(2, '0');
              const s = String(totalSec % 60).padStart(2, '0');
              badge.innerText = h + 'h : ' + m + 'm : ' + s + 's';
              badge.style.color = "var(--primary)";
            } else if (diff >= -9000000) {
              badge.innerHTML = '<i class=\\'fa-solid fa-circle\\' style=\\'font-size:7px; animation:blink 1s infinite;\\'></i> LIVE NOW';
              badge.style.color = "var(--accent-live)";
            } else {
              badge.innerText = 'SELESAI';
              badge.style.color = "var(--text-dim)";
            }
          }
        }
      });
    }, 1000);
  }

  function parseTimestampToMs(isoStr, textStr) {
    if (isoStr) {
      const t = new Date(isoStr).getTime();
      if (!isNaN(t)) return t;
    }
    if (textStr) {
      const match = textStr.match(/(\\d{1,2})[\\/\\-](\\d{1,2})[\\/\\-](\\d{4})[,\\s]+(\\d{1,2})[:\\.](\\d{2})/);
      if (match) {
        const day = match[1].padStart(2, '0');
        const month = match[2].padStart(2, '0');
        const year = match[3];
        const hour = match[4].padStart(2, '0');
        const min = match[5].padStart(2, '0');
        const parsedIso = year + '-' + month + '-' + day + 'T' + hour + ':' + min + ':00+07:00';
        const t = new Date(parsedIso).getTime();
        if (!isNaN(t)) return t;
      }
    }
    return 0;
  }

  // 6. PROCESS, FILTER & SORT ENGINE
  // - Status 0 (🔴 SEDANG LIVE): PALING ATAS
  // - Status 1 (⏳ MENUNGGU): DI BAWAHNYA, DIURUTKAN DARI JAM KICKOFF TERDEKAT
  // - Status 2 (🏁 SELESAI): HILANGKAN DARI DAFTAR (FILTERED OUT)
  function processAndSortMatches(rawMatches) {
    const now = new Date().getTime();
    const validMatches = [];
    const seenTitles = new Set();

    rawMatches.forEach(m => {
      if (!m) return;
      const title = (m.title || "Live Match").trim();
      const cleanKey = title.toLowerCase().replace(/[^a-z0-9]/g, '');
      if (seenTitles.has(cleanKey)) return;
      seenTitles.add(cleanKey);

      const kickoffIso = m.kickoffIso || (m.info ? m.info.kickoffIso : "") || "";
      const kickoffText = m.kickoffText || (m.info ? (m.info.kickoffText || m.dateText) : "") || m.dateText || "";
      const league = m.league || (m.info ? m.info.league : "") || "Live Match";
      const streamUrl = m.streamUrl || (m.info ? m.info.streamUrl : "") || "";
      const server2Url = m.server2Url || (m.info ? m.info.server2Url : "") || "";
      const postUrl = m.postUrl || "#";

      let kickoffTime = parseTimestampToMs(kickoffIso, kickoffText);
      const diff = kickoffTime ? (kickoffTime - now) : 0;

      // ATURAN STATUS:
      // 0 = SEDANG LIVE (Kickoff dalam rentang 2.5 jam terakhir)
      // 1 = MENUNGGU (Kickoff di masa mendatang)
      // 2 = SELESAI (Kickoff lebih dari 2.5 jam yang lalu)
      let status = 1;
      if (kickoffTime) {
        if (diff <= 0 && diff >= -9000000) {
          status = 0; // 🔴 SEDANG LIVE
        } else if (diff < -9000000) {
          status = 2; // 🏁 SELESAI
        } else {
          status = 1; // ⏳ MENUNGGU
        }
      } else {
        status = 0; // Default live jika tidak ada info waktu spesifik
      }

      // HILANGKAN PERTANDINGAN YANG SUDAH SELESAI
      if (status !== 2) {
        validMatches.push({
          title,
          league,
          streamUrl,
          server2Url,
          postUrl,
          kickoffIso,
          kickoffText,
          kickoffTime: kickoffTime || now,
          diff,
          status
        });
      }
    });

    // URUTKAN:
    // 1. Sedang LIVE (status 0) PALING ATAS
    // 2. Menunggu (status 1) di bawahnya, diurutkan kronologis (jam kickoff terdekat pertama)
    validMatches.sort((a, b) => {
      if (a.status !== b.status) return a.status - b.status;
      return a.kickoffTime - b.kickoffTime;
    });

    return validMatches;
  }

  // 7. RENDER LIST PERTANDINGAN KE SIDEBAR
  function renderMatchList(rawMatches) {
    const scrollContainer = document.getElementById('matchScrollList');
    if (!scrollContainer || !rawMatches || rawMatches.length === 0) return;

    const matches = processAndSortMatches(rawMatches);
    if (matches.length === 0) return;

    scrollContainer.innerHTML = '';
    const createdRows = [];

    matches.forEach((m, idx) => {
      const row = document.createElement('div');
      row.className = 'match-event-row' + (idx === 0 ? ' active' : '');
      row.setAttribute('data-posttitle', m.title);
      row.setAttribute('data-posturl', m.postUrl || '#');
      row.setAttribute('data-streamurl', m.streamUrl);
      row.setAttribute('data-server2', m.server2Url || '');
      row.setAttribute('data-kickoff', m.kickoffIso);
      row.setAttribute('data-postdate', m.kickoffText);
      row.onclick = function() { handleMatchClick(this); };

      const countdownHtml = m.status === 0
        ? '<span class=\\'match-item-countdown\\' data-kickoff=\\'' + m.kickoffIso + '\\' style=\\'color:var(--accent-live); font-weight:800;\\'><i class=\\'fa-solid fa-circle\\' style=\\'font-size:7px; animation:blink 1s infinite;\\'></i> LIVE NOW</span>'
        : '<span class=\\'match-item-countdown\\' data-kickoff=\\'' + m.kickoffIso + '\\'>00h : 00m : 00s</span>';

      row.innerHTML = \`
        <div class='event-league-row'>
          <span class='match-league-badge'>\${m.league}</span>
          \${countdownHtml}
        </div>
        <a class='event-link-preview' href='\${m.postUrl || '#'}' onclick='event.stopPropagation();' target='_blank' title='Buka Pertandingan'>
          <i class='fa-solid fa-arrow-up-right-from-square'></i> \${m.title}
        </a>
        <div class='event-teams-flex'>
          <div class='teams-col'>
            <div class='team-item'>
              <i class='fa-solid fa-futbol' style='color:var(--primary); font-size:14px;'></i>
              <span class='team-name-text' style='font-size:13px; font-weight:700; color:#fff;'>\${m.title}</span>
            </div>
          </div>
          <div class='event-time-col'>
            <span>Jadwal</span>
            <span class='time-bold'>\${m.kickoffText}</span>
          </div>
        </div>
      \`;

      scrollContainer.appendChild(row);
      createdRows.push(row);
    });

    if (createdRows.length > 0) {
      handleMatchClick(createdRows[0]);
    }
  }

  // 8. REAL-TIME AUTO DISCOVERY DARI SUMBER LIVE (DENGAN MULTI-SOURCE FAILOVER DARI LIST LINK)
  function fetchLiveMatchesDirect() {
    const scrollContainer = document.getElementById('matchScrollList');
    if (!scrollContainer) return;

    // Render dataset live teratas seketika
    renderMatchList(AUTO_LIVE_DATASET);

    const sourceTargets = [
      'https://tft-forests.org/',
      'https://xoilacz.vip/',
      'https://xoilackl.tv/',
      'https://90phutcn.tv/'
    ];

    const proxyUrls = [
      'https://api.allorigins.win/raw?url=' + encodeURIComponent(sourceTargets[0]),
      'https://corsproxy.org/?' + encodeURIComponent(sourceTargets[0]),
      'https://cors.eu.org/' + sourceTargets[0]
    ];

    function tryFetchProxy(index) {
      if (index >= proxyUrls.length) return;

      fetch(proxyUrls[index])
        .then(res => {
          if (!res.ok) throw new Error('Proxy status: ' + res.status);
          return res.text();
        })
        .then(rawHtml => {
          const slugRegex = /\\/truc-tiep\\/([a-z0-9\\-]+)-luc-(\\d{4})-ngay-(\\d{2})-(\\d{2})-(\\d{4})\\//gi;
          const allSlugs = rawHtml.match(slugRegex) || [];
          const uniqueSlugs = [...new Set(allSlugs)];

          if (uniqueSlugs.length === 0) return;

          const liveScraped = [];

          uniqueSlugs.forEach(slug => {
            const parsed = slug.match(/\\/truc-tiep\\/([a-z0-9\\-]+)-luc-(\\d{4})-ngay-(\\d{2})-(\\d{2})-(\\d{4})\\//i);
            if (!parsed) return;

            const slugName = parsed[1];
            const rawTitle = slugName.replace(/-/g, ' ');
            const title = rawTitle.replace(/\\b\\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
            const timeStr = parsed[2];
            const day = parsed[3];
            const month = parsed[4];
            const year = parsed[5];
            const hour = timeStr.slice(0, 2);
            const min = timeStr.slice(2, 4);

            const kickoffIso = year + '-' + month + '-' + day + 'T' + hour + ':' + min + ':00+07:00';
            const kickoffText = day + '/' + month + '/' + year + ', ' + hour + ':' + min + ' WIB';
            const matchPageUrl = 'https://tft-forests.org/truc-tiep/' + slugName + '-luc-' + timeStr + '-ngay-' + day + '-' + month + '-' + year + '/';

            let league = "Live Match";
            const lower = title.toLowerCase();
            if (lower.includes('milan') || lower.includes('roma') || lower.includes('parma') || lower.includes('como') || lower.includes('juventus') || lower.includes('napoli') || lower.includes('inter')) {
              league = "Italian Serie A";
            } else if (lower.includes('madrid') || lower.includes('barcelona') || lower.includes('atletico') || lower.includes('sevilla') || lower.includes('santos')) {
              league = "La Liga Spain";
            } else if (lower.includes('arsenal') || lower.includes('chelsea') || lower.includes('liverpool') || lower.includes('city') || lower.includes('united') || lower.includes('newcastle')) {
              league = "Premier League";
            } else if (lower.includes('munchen') || lower.includes('dortmund') || lower.includes('leverkusen') || lower.includes('frankfurt')) {
              league = "German Bundesliga";
            } else if (lower.includes('libertadores') || lower.includes('quito') || lower.includes('palmeiras')) {
              league = "Copa Libertadores";
            } else if (lower.includes('champions') || lower.includes('cruz azul') || lower.includes('miami')) {
              league = "CONCACAF Champions Cup";
            }

            // Hubungkan dengan verified channel endpoint jika ada
            const existing = AUTO_LIVE_DATASET.find(a => a.postUrl === matchPageUrl || a.title.toLowerCase() === title.toLowerCase());
            const streamUrl = existing ? existing.streamUrl : (matchPageUrl + 'link/0');
            const server2Url = existing ? existing.server2Url : (matchPageUrl + 'link/1');

            liveScraped.push({
              title,
              postUrl: matchPageUrl,
              streamUrl,
              server2Url,
              kickoffIso,
              kickoffText,
              league
            });
          });

          if (liveScraped.length > 0) {
            const combined = [...AUTO_LIVE_DATASET, ...liveScraped];
            renderMatchList(combined);
          }
        })
        .catch(err => {
          console.warn('Real-time proxy note:', err.message);
          tryFetchProxy(index + 1);
        });
    }

    tryFetchProxy(0);
  }

  // 9. DYNAMIC BLOGGER FEED LOADER
  function loadBloggerPostsFeed() {
    fetch('/feeds/posts/default?alt=json&max-results=50')
      .then(response => {
        if (!response.ok) throw new Error('Blogger feed unavailable');
        return response.json();
      })
      .then(data => {
        const entries = (data && data.feed && data.feed.entry) ? data.feed.entry : [];
        if (entries.length === 0) {
          fetchLiveMatchesDirect();
          return;
        }

        const parsedMatches = [];

        entries.forEach(entry => {
          const title = (entry.title && entry.title.$t) ? entry.title.$t : 'Live Match';
          const altLink = entry.link ? entry.link.find(l => l.rel === 'alternate') : null;
          const postUrl = altLink ? altLink.href : '#';
          const bodyHtml = (entry.content && entry.content.$t) ? entry.content.$t : ((entry.summary && entry.summary.$t) ? entry.summary.$t : '');
          const dateIso = (entry.published && entry.published.$t) ? entry.published.$t : '';
          
          let dateText = '';
          if (dateIso) {
            try {
              dateText = new Date(dateIso).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
            } catch (e) {
              dateText = dateIso;
            }
          }

          const info = extractStreamInfo(bodyHtml, postUrl, dateIso, dateText, title);

          parsedMatches.push({
            title,
            postUrl,
            streamUrl: info.streamUrl,
            server2Url: info.server2Url,
            kickoffIso: info.kickoffIso,
            kickoffText: info.kickoffText || dateText,
            league: info.league
          });
        });

        const combined = [...AUTO_LIVE_DATASET, ...parsedMatches];
        renderMatchList(combined);
      })
      .catch(err => {
        console.warn('Blogger feed note, switching to live source:', err.message);
        fetchLiveMatchesDirect();
      });
  }

  // 10. INISIALISASI PORTAL
  function initLivePortal() {
    startCountdownTimer();

    const scrollContainer = document.getElementById('matchScrollList');
    if (!scrollContainer) return;

    const allRows = Array.from(scrollContainer.querySelectorAll('.match-event-row'));

    if (allRows.length > 0) {
      const parsedRows = [];

      allRows.forEach(row => {
        const title = row.getAttribute('data-posttitle') || '';
        const postUrl = row.getAttribute('data-posturl') || '#';
        const dateIso = row.getAttribute('data-kickoff') || '';
        const dateText = row.getAttribute('data-postdate') || '';
        const hiddenMeta = row.querySelector('.post-hidden-meta');
        const bodyHtml = hiddenMeta ? hiddenMeta.innerHTML : '';

        const info = extractStreamInfo(bodyHtml, postUrl, dateIso, dateText, title);

        parsedRows.push({
          title,
          postUrl,
          streamUrl: info.streamUrl,
          server2Url: info.server2Url,
          kickoffIso: info.kickoffIso || dateIso,
          kickoffText: info.kickoffText || dateText,
          league: info.league
        });
      });

      const combined = [...AUTO_LIVE_DATASET, ...parsedRows];
      renderMatchList(combined);
    } else {
      loadBloggerPostsFeed();
    }
  }

  document.addEventListener('DOMContentLoaded', initLivePortal);
  //]]>
  </script>
</body>
</html>`;

fs.writeFileSync('template-sportstream.xml', xmlTemplate);
fs.writeFileSync('preview.html', xmlTemplate);
console.log('Successfully wrote template-sportstream.xml with MEIWATV logo, updated adsterra link, and saweria link!');
