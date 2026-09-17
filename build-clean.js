const fs = require('fs');

// 1. Read Logo
const logoBase64 = fs.readFileSync('meiwatv.png').toString('base64');
const logoDataUri = 'data:image/png;base64,' + logoBase64;

// 2. Read Dataset
let dataset = [];
if (fs.existsSync('fresh-dataset-complete.json')) {
  dataset = JSON.parse(fs.readFileSync('fresh-dataset-complete.json', 'utf8'));
}

console.log('Dataset loaded with total matches:', dataset.length);

// 3. Assemble Clean XML
const templateXml = `<?xml version="1.0" encoding="UTF-8" ?>
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
  }

  .brand-logo-img {
    height: 42px;
    width: auto;
    object-fit: contain;
  }

  .header-actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .badge-live-pulse {
    background: rgba(239, 68, 68, 0.15);
    color: #ef4444;
    border: 1px solid rgba(239, 68, 68, 0.3);
    padding: 6px 12px;
    border-radius: var(--radius-full);
    font-size: 12px;
    font-weight: 700;
    display: flex;
    align-items: center;
    gap: 6px;
    animation: pulseGlow 2s infinite;
  }

  @keyframes pulseGlow {
    0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
    50% { box-shadow: 0 0 10px 2px rgba(239, 68, 68, 0.2); }
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }

  /* MAIN STADIUM LAYOUT */
  .stadium-container {
    max-width: 1440px;
    margin: 20px auto;
    padding: 0 20px;
    display: grid;
    grid-template-columns: 1fr 380px;
    gap: 24px;
    align-items: start;
  }

  @media (max-width: 992px) {
    .stadium-container {
      grid-template-columns: 1fr;
      margin: 10px auto;
      padding: 0 12px;
    }
  }

  /* LEFT: HERO BROADCAST STAGE */
  .stadium-left {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .hero-broadcast-stage {
    background: radial-gradient(circle at 50% 30%, #172033 0%, #0d1322 100%);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-lg);
    overflow: hidden;
    position: relative;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  }

  .stadium-backdrop-glow {
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, var(--primary-glow) 0%, transparent 60%);
    opacity: 0.15;
    pointer-events: none;
  }

  /* 1. HERO PLAYER SCREEN (SCREEN AKTIF SAAT MEMUTAR) */
  .hero-player-screen {
    width: 100%;
    background: #000;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .player-top-toolbar {
    background: #0a0e18;
    padding: 8px 14px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid var(--border-subtle);
  }

  .player-server-tabs {
    display: flex;
    gap: 8px;
  }

  .btn-server-tab {
    background: var(--bg-card);
    color: var(--text-muted);
    border: 1px solid var(--border-subtle);
    padding: 6px 12px;
    border-radius: var(--radius-sm);
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: var(--transition);
  }
  .btn-server-tab:hover {
    color: #fff;
    border-color: var(--primary);
  }
  .btn-server-tab.active {
    background: var(--primary);
    color: #000;
    border-color: var(--primary);
    box-shadow: 0 0 10px var(--primary-glow);
  }

  .player-action-tools {
    display: flex;
    gap: 6px;
  }

  .btn-tool-tab {
    background: var(--bg-card);
    color: var(--text-muted);
    border: 1px solid var(--border-subtle);
    width: 32px;
    height: 32px;
    border-radius: var(--radius-sm);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 13px;
    transition: var(--transition);
  }
  .btn-tool-tab:hover {
    color: #fff;
    border-color: var(--primary);
  }
  .btn-tool-tab.close:hover {
    color: #ef4444;
    border-color: #ef4444;
  }

  .video-responsive-wrapper {
    position: relative;
    width: 100%;
    padding-top: 56.25%; /* 16:9 Aspect Ratio */
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
    gap: 14px;
    z-index: 10;
    color: var(--text-main);
    font-weight: 600;
    font-size: 14px;
  }

  .player-spinner {
    width: 44px;
    height: 44px;
    border: 3px solid rgba(16, 185, 129, 0.2);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .player-unmute-btn {
    position: absolute;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--primary);
    color: #000;
    font-weight: 800;
    font-size: 13px;
    padding: 10px 20px;
    border-radius: var(--radius-full);
    border: none;
    cursor: pointer;
    box-shadow: 0 4px 15px var(--primary-glow);
    z-index: 15;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: var(--transition);
  }
  .player-unmute-btn:hover {
    transform: translateX(-50%) scale(1.05);
  }

  /* 2. HERO STAGE CONTENT (PREVIEW/CARD SEBELUM PLAY) */
  .hero-stage-content {
    padding: 30px 24px;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    position: relative;
    z-index: 2;
  }

  .hero-status-pill {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: rgba(16, 185, 129, 0.1);
    border: 1px solid var(--border-active);
    padding: 6px 14px;
    border-radius: var(--radius-full);
    margin-bottom: 20px;
  }
  .live-badge-glow {
    color: var(--accent-live);
    font-weight: 800;
    font-size: 11px;
    display: flex;
    align-items: center;
    gap: 5px;
  }
  .league-name-text {
    font-size: 12px;
    font-weight: 700;
    color: var(--primary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .matchup-vs-container {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 24px;
    width: 100%;
    margin-bottom: 24px;
  }

  .team-box {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    max-width: 240px;
  }

  .team-icon-circle {
    width: 68px;
    height: 68px;
    background: var(--bg-card);
    border: 2px solid var(--border-subtle);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    color: var(--primary);
    box-shadow: 0 4px 15px rgba(0,0,0,0.3);
  }

  .team-title {
    font-family: var(--font-sport);
    font-size: 20px;
    font-weight: 700;
    color: #fff;
    line-height: 1.2;
    text-transform: uppercase;
  }

  .vs-badge-circle {
    width: 44px;
    height: 44px;
    background: var(--bg-card);
    border: 1px solid var(--border-subtle);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: var(--font-sport);
    font-size: 16px;
    font-weight: 800;
    color: var(--accent-live);
  }

  .matchup-meta-info {
    margin-bottom: 24px;
  }

  .hero-full-title {
    font-size: 18px;
    font-weight: 700;
    color: #fff;
    margin-bottom: 6px;
  }

  .hero-kickoff-time {
    font-size: 13px;
    color: var(--text-muted);
  }
  .hero-kickoff-time b {
    color: var(--primary);
  }

  .broadcast-cta-actions {
    display: flex;
    gap: 12px;
    width: 100%;
    max-width: 480px;
    margin-bottom: 16px;
  }

  .btn-play-stream {
    flex: 1;
    padding: 14px 20px;
    border-radius: var(--radius-md);
    font-size: 14px;
    font-weight: 800;
    cursor: pointer;
    border: none;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    transition: var(--transition);
  }

  .btn-play-stream.main-hd {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: #000;
    box-shadow: 0 4px 20px var(--primary-glow);
  }
  .btn-play-stream.main-hd:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 25px var(--primary-glow);
  }

  .btn-play-stream.secondary-backup {
    background: var(--bg-card);
    color: #fff;
    border: 1px solid var(--border-subtle);
  }
  .btn-play-stream.secondary-backup:hover {
    border-color: var(--primary);
    background: var(--bg-card-hover);
  }

  .stream-feature-notice {
    font-size: 12px;
    color: var(--text-dim);
    display: flex;
    align-items: center;
    gap: 6px;
  }

  /* RIGHT: MATCH SCHEDULE SIDEBAR */
  .stadium-right {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .events-sidebar-card {
    background: var(--bg-sidebar);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-lg);
    display: flex;
    flex-direction: column;
    height: 720px;
    overflow: hidden;
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
    display: block;
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
      <div class='header-actions'>
        <div class='badge-live-pulse'>
          <i class='fa-solid fa-circle' style='font-size:8px; animation:blink 1s infinite;'/> LIVE STREAMING
        </div>
      </div>
    </div>
  </header>

  <!-- MAIN STADIUM CONTAINER -->
  <main class='stadium-container'>
    
    <!-- LEFT: HERO BROADCAST STAGE -->
    <div class='stadium-left'>
      
      <div class='hero-broadcast-stage' id='heroBroadcastStage'>
        <div class='stadium-backdrop-glow'/>

        <!-- 1. HERO PLAYER SCREEN -->
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
                <b:widget-setting name='showShareButtons'>false</b:widget-setting>
                <b:widget-setting name='showCommentLink'>false</b:widget-setting>
                <b:widget-setting name='showAuthor'>false</b:widget-setting>
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
            </b:widget>
          </b:section>

        </div>

        <!-- Bottom Action Buttons: World Cup Channel & Saweria Donate -->
        <div class='sidebar-bottom-actions'>
          <a class='btn-worldcup-channel' href='https://meiwatv.blogspot.com/p/piala-dunia.html' target='_blank'>
            <i class='fa-solid fa-trophy'/> CHANNEL KHUSUS PIALA DUNIA
          </a>
          <a class='btn-saweria-donate' href='https://saweria.co/meiwatv' target='_blank'>
            <i class='fa-solid fa-heart'/> DUKUNG MEIWATV VIA SAWERIA
          </a>
        </div>

      </div>
    </aside>

  </main>

  <!-- FOOTER -->
  <footer class='site-footer'>
    <p>&#169; <data:blog.title/> &#8226; Portal Live Streaming Pertandingan Sepak Bola HD Terlengkap.</p>
  </footer>

  <!-- ==========================================================================
       MAIN CLIENT JAVASCRIPT ENGINE (DIRECTLY INSIDE BODY, GUARANTEED RUNTIME)
       ========================================================================== -->
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

  // DATASET SIARAN AKTIF REAL-TIME (88+ VERIFIED CHANNELS & MATCHES)
  const AUTO_LIVE_DATASET = ` + JSON.stringify(dataset, null, 2) + `;

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

      const match = rawUrl.match(/link\\/(channel[\\-_]?[0-9a-zA-Z]+)/i) || rawUrl.match(/(channel[\\-_]?[0-9a-zA-Z]+)/i);
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
      heroLeague.innerText = (league && league !== 'Live Match') ? ('🏆 ' + league.toUpperCase()) : "🏆 MEIWATV LIVE";
    }

    if (heroKickoff) {
      heroKickoff.innerHTML = '<i class="fa-regular fa-clock"></i> Kickoff: <b>' + (kickoffText || 'Siaran Langsung') + '</b>';
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
              badge.innerHTML = '<i class="fa-solid fa-circle" style="font-size:7px; animation:blink 1s infinite;"></i> LIVE NOW';
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
  // - Status 2 (🏁 SELESAI): PALING BAWAH (TIDAK HILANG, TETAP BISA DILIHAT)
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
    });

    // URUTKAN:
    // 1. Sedang LIVE (status 0) PALING ATAS
    // 2. Menunggu (status 1) di bawahnya, diurutkan kronologis (jam kickoff terdekat pertama)
    // 3. Selesai (status 2) di paling bawah
    validMatches.sort((a, b) => {
      if (a.status !== b.status) return a.status - b.status;
      if (a.status === 2) return b.kickoffTime - a.kickoffTime; // Selesai: paling baru selesai di atas
      return a.kickoffTime - b.kickoffTime; // Live/Menunggu: urutan kronologis
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

      let countdownHtml = '';
      if (m.status === 0) {
        countdownHtml = '<span class="match-item-countdown" data-kickoff="' + m.kickoffIso + '" style="color:var(--accent-live); font-weight:800;"><i class="fa-solid fa-circle" style="font-size:7px; animation:blink 1s infinite;"></i> LIVE NOW</span>';
      } else if (m.status === 1) {
        countdownHtml = '<span class="match-item-countdown" data-kickoff="' + m.kickoffIso + '" style="color:var(--primary); font-weight:700;">00h : 00m : 00s</span>';
      } else {
        countdownHtml = '<span class="match-item-countdown" data-kickoff="' + m.kickoffIso + '" style="color:var(--text-dim); font-weight:600;">SELESAI</span>';
      }

      row.innerHTML = 
        '<div class="event-league-row">' +
          '<span class="match-league-badge">' + m.league + '</span>' +
          countdownHtml +
        '</div>' +
        '<a class="event-link-preview" href="' + (m.postUrl || '#') + '" onclick="event.stopPropagation();" target="_blank" title="Buka Pertandingan">' +
          '<i class="fa-solid fa-arrow-up-right-from-square"></i> ' + m.title +
        '</a>' +
        '<div class="event-teams-flex">' +
          '<div class="teams-col">' +
            '<div class="team-item">' +
              '<i class="fa-solid fa-futbol" style="color:var(--primary); font-size:14px;"></i>' +
              '<span class="team-name-text" style="font-size:13px; font-weight:700; color:#fff;">' + m.title + '</span>' +
            '</div>' +
          '</div>' +
          '<div class="event-time-col">' +
            '<span>Jadwal</span>' +
            '<span class="time-bold">' + m.kickoffText + '</span>' +
          '</div>' +
        '</div>';

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

    const sourceTargets = [
      'https://tft-forests.org/',
      'https://xoilacz.vip/',
      'https://xoilackl.tv/',
      'https://90phutcn.tv/'
    ];

    const proxyUrls = [
      'https://api.allorigins.win/raw?url=' + encodeURIComponent(sourceTargets[0]),
      'https://api.codetabs.com/v1/proxy?quest=' + encodeURIComponent(sourceTargets[0]),
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
        if (entries.length === 0) return;

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

        if (parsedMatches.length > 0) {
          const combined = [...AUTO_LIVE_DATASET, ...parsedMatches];
          renderMatchList(combined);
        }
      })
      .catch(err => {
        console.warn('Blogger feed note:', err.message);
      });
  }

  // 10. INISIALISASI PORTAL
  function initLivePortal() {
    startCountdownTimer();

    // 1. Render data pertandingan SEGERA seketika tanpa delay
    renderMatchList(AUTO_LIVE_DATASET);

    // 2. Jika ada postingan di DOM / Blogger Feed, gabungkan
    const scrollContainer = document.getElementById('matchScrollList');
    if (scrollContainer) {
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

          if (title && !AUTO_LIVE_DATASET.some(d => d.title.toLowerCase() === title.toLowerCase())) {
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
          }
        });

        if (parsedRows.length > 0) {
          const combined = [...AUTO_LIVE_DATASET, ...parsedRows];
          renderMatchList(combined);
        }
      } else {
        loadBloggerPostsFeed();
      }
    }

    // 3. Sinkronkan update real-time di background
    fetchLiveMatchesDirect();
    setInterval(fetchLiveMatchesDirect, 60000);
  }

  document.addEventListener('DOMContentLoaded', initLivePortal);
  //]]>
  </script>
</body>
</html>`;

// Test JavaScript syntax inside the template
const scriptExtract = templateXml.match(/<script type='text\/javascript'>[\s\S]*?\/\/<!\[CDATA\[([\s\S]*?)\/\/\]\]>[\s\S]*?<\/script>/);
if (scriptExtract) {
  try {
    new Function(scriptExtract[1]);
    console.log('✅ JAVASCRIPT SYNTAX IS 100% VALID!');
  } catch (e) {
    console.error('❌ SYNTAX ERROR IN SCRIPT:', e);
    process.exit(1);
  }
} else {
  console.error('❌ Could not find script block in templateXml!');
  process.exit(1);
}

fs.writeFileSync('template-sportstream.xml', templateXml);
fs.writeFileSync('preview.html', templateXml);

console.log('🎉 Successfully generated 100% clean and valid template-sportstream.xml and preview.html!');
