const fs = require('fs');
const path = require('path');

function generateBloggerTemplate() {
    const matchesFile = path.join(__dirname, 'matches.json');
    const matches = JSON.parse(fs.readFileSync(matchesFile, 'utf8'));

    console.log(`🔨 Membangun Template Blogger SportStream dengan ${matches.length} pertandingan...`);

    const xmlTemplate = `<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html>
<html b:css='false' b:defaultwidgetversion='2' b:layoutsVersion='3' expr:dir='data:blog.languageDirection' xmlns='http://www.w3.org/1999/xhtml' xmlns:b='http://www.google.com/2005/gml/b' xmlns:data='http://www.google.com/2005/gml/data' xmlns:expr='http://www.google.com/2005/gml/expr'>
<head>
  <meta charset='utf-8'/>
  <meta content='no-referrer' name='referrer'/>
  <meta content='width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=5' name='viewport'/>
  <title><data:blog.pageTitle/></title>
  <b:include data='blog' name='all-head-content'/>

  <!-- Google Fonts: Plus Jakarta Sans & Outfit -->
  <link href='https://fonts.googleapis.com' rel='preconnect'/>
  <link crossorigin='anonymous' href='https://fonts.gstatic.com' rel='preconnect'/>
  <link href='https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&amp;family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap' rel='stylesheet'/>
  <!-- Font Awesome Icons -->
  <link href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css' rel='stylesheet'/>
  <!-- HLS.js & FLV.js Stream Player Engine -->
  <script src='https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js'></script>
  <script src='https://cdnjs.cloudflare.com/ajax/libs/flv.js/1.6.4/flv.min.js'></script>

  <b:skin><![CDATA[
  /* ==========================================================================
     MEIWATV - UNIFIED THEATER LIVE STREAMING PORTAL
     ========================================================================== */
  :root {
    --bg-dark: #070a10;
    --bg-card: #0e1422;
    --bg-card-hover: #162035;
    --bg-surface: #121929;
    --bg-header: #05080e;
    
    --primary-green: #10b981;
    --primary-neon: #00eb1f;
    --primary-glow: rgba(16, 185, 129, 0.35);
    
    --accent-gold: #ffe400;
    --accent-red: #ef4444;
    --accent-red-glow: rgba(239, 68, 68, 0.4);
    
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --text-dim: #64748b;
    
    --border-subtle: rgba(255, 255, 255, 0.08);
    --border-hover: rgba(16, 185, 129, 0.5);
    
    --radius-sm: 8px;
    --radius-md: 12px;
    --radius-lg: 16px;
    --radius-full: 9999px;
    
    --font-main: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
    --font-heading: 'Outfit', sans-serif;
    --transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  }

  *, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    background-color: var(--bg-dark);
    color: var(--text-main);
    font-family: var(--font-main);
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
    overflow-x: hidden;
  }

  /* SITE HEADER */
  .site-header {
    background: var(--bg-header);
    border-bottom: 1px solid var(--border-subtle);
    position: sticky;
    top: 0;
    z-index: 1000;
    backdrop-filter: blur(12px);
  }

  .nav-container {
    max-width: 1540px;
    margin: 0 auto;
    padding: 0 16px;
    height: 64px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .brand-logo {
    display: flex;
    align-items: center;
    text-decoration: none;
    flex-shrink: 0;
  }

  .brand-logo-img {
    height: 38px;
    width: auto;
    object-fit: contain;
  }

  /* Navigation Header Tabs */
  .nav-menu-links {
    display: flex;
    align-items: center;
    gap: 4px;
    list-style: none;
    overflow-x: auto;
    scrollbar-width: none;
    -ms-overflow-style: none;
    padding: 4px 0;
  }
  .nav-menu-links::-webkit-scrollbar { display: none; }

  .nav-item-btn {
    background: transparent;
    border: 1px solid transparent;
    color: var(--text-muted);
    font-family: var(--font-heading);
    font-size: 13.5px;
    font-weight: 700;
    padding: 7px 12px;
    border-radius: var(--radius-full);
    cursor: pointer;
    transition: var(--transition);
    white-space: nowrap;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    text-decoration: none;
  }

  .nav-item-btn:hover {
    color: #fff;
    background: rgba(255, 255, 255, 0.06);
  }

  .nav-item-btn.active {
    color: #000;
    background: var(--primary-green);
    border-color: var(--primary-green);
    box-shadow: 0 0 12px var(--primary-glow);
  }

  .nav-item-btn.btn-nav-live.active {
    background: var(--accent-red);
    color: #fff;
    border-color: var(--accent-red);
    box-shadow: 0 0 12px var(--accent-red-glow);
  }

  .header-actions {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .btn-saweria-top {
    background: rgba(255, 228, 0, 0.12);
    border: 1px solid rgba(255, 228, 0, 0.3);
    color: var(--accent-gold);
    font-weight: 700;
    font-size: 12.5px;
    padding: 6px 12px;
    border-radius: var(--radius-full);
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: var(--transition);
  }
  .btn-saweria-top:hover {
    background: var(--accent-gold);
    color: #000;
  }

  .btn-apk-top {
    background: linear-gradient(135deg, #10b981, #059669);
    color: #fff;
    font-weight: 800;
    font-size: 12.5px;
    padding: 6px 14px;
    border-radius: var(--radius-full);
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 6px;
    box-shadow: 0 2px 10px rgba(16, 185, 129, 0.3);
    transition: var(--transition);
  }
  .btn-apk-top:hover {
    filter: brightness(1.1);
    transform: translateY(-1px);
  }

  /* SPONSOR BANNER */
  .adsterra-banner-container {
    max-width: 1540px;
    margin: 12px auto 0 auto;
    padding: 0 16px;
  }
  .adsterra-wrapper-box {
    background: var(--bg-card);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-md);
    padding: 8px;
    text-align: center;
    min-height: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* UNIFIED THEATER MAIN LAYOUT */
  .main-theater-container {
    max-width: 1540px;
    margin: 14px auto 30px auto;
    padding: 0 16px;
  }

  .unified-theater-grid {
    display: grid;
    grid-template-columns: 1fr 390px;
    gap: 16px;
    align-items: start;
  }

  @media (max-width: 1100px) {
    .unified-theater-grid {
      grid-template-columns: 1fr;
    }
  }

  /* THEATER PLAYER BOX (LEFT COLUMN) */
  .theater-player-card {
    background: var(--bg-card);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-lg);
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
  }

  .player-top-bar {
    padding: 10px 14px;
    background: rgba(0, 0, 0, 0.4);
    border-bottom: 1px solid var(--border-subtle);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    flex-wrap: wrap;
  }

  .player-match-badge {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .live-indicator {
    background: var(--accent-red);
    color: #fff;
    font-size: 11px;
    font-weight: 800;
    padding: 2px 8px;
    border-radius: var(--radius-full);
    display: inline-flex;
    align-items: center;
    gap: 5px;
    animation: pulseGlow 1.5s infinite;
  }

  @keyframes pulseGlow {
    0%, 100% { opacity: 1; transform: scale(1); }
    50% { opacity: 0.85; transform: scale(0.98); }
  }

  .player-server-group {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .btn-server {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--border-subtle);
    color: var(--text-muted);
    font-size: 11.5px;
    font-weight: 700;
    padding: 4px 10px;
    border-radius: var(--radius-sm);
    cursor: pointer;
    transition: var(--transition);
    display: inline-flex;
    align-items: center;
    gap: 4px;
  }
  .btn-server:hover {
    color: #fff;
    background: rgba(255, 255, 255, 0.1);
  }
  .btn-server.active {
    background: var(--primary-green);
    color: #000;
    border-color: var(--primary-green);
    font-weight: 800;
  }

  /* 16:9 VIDEO PLAYER CONTAINER */
  .video-container-169 {
    position: relative;
    width: 100%;
    padding-top: 56.25%; /* 16:9 Aspect Ratio */
    background: #000;
  }

  .video-container-169 video,
  .video-container-169 iframe,
  .video-container-169 .player-stage-screen {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
    object-fit: contain;
  }

  .player-stage-screen {
    background: radial-gradient(circle at center, #162035 0%, #070a10 85%);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 24px;
    z-index: 5;
  }

  .player-stage-league {
    color: var(--primary-green);
    font-weight: 800;
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 6px;
  }

  .player-stage-title {
    font-family: var(--font-heading);
    font-size: clamp(18px, 3.5vw, 26px);
    font-weight: 900;
    color: #fff;
    margin-bottom: 8px;
    max-width: 90%;
  }

  .player-stage-time {
    color: var(--text-muted);
    font-size: 13.5px;
    margin-bottom: 20px;
  }

  .btn-play-stream-huge {
    background: linear-gradient(135deg, #10b981, #059669);
    color: #fff;
    border: none;
    font-family: var(--font-heading);
    font-size: 15px;
    font-weight: 900;
    padding: 12px 28px;
    border-radius: var(--radius-full);
    cursor: pointer;
    box-shadow: 0 4px 20px rgba(16, 185, 129, 0.4);
    display: inline-flex;
    align-items: center;
    gap: 10px;
    transition: var(--transition);
  }
  .btn-play-stream-huge:hover {
    transform: scale(1.05);
    box-shadow: 0 6px 25px rgba(16, 185, 129, 0.6);
  }

  /* DETAILS BAR & DIRECT STREAM ACTIONS UNDER PLAYER */
  .player-match-detail-bar {
    padding: 14px 18px;
    background: var(--bg-surface);
    border-top: 1px solid var(--border-subtle);
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .player-detail-main-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }

  .detail-match-teams {
    display: flex;
    align-items: center;
    gap: 12px;
    font-family: var(--font-heading);
    font-size: 16px;
    font-weight: 800;
  }

  .detail-team-logo {
    width: 28px;
    height: 28px;
    object-fit: contain;
  }

  .detail-score-pill {
    background: #000;
    color: var(--accent-gold);
    padding: 2px 10px;
    border-radius: var(--radius-full);
    font-size: 14px;
    font-weight: 800;
    border: 1px solid rgba(255, 228, 0, 0.3);
  }

  .player-action-buttons {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
  }

  .btn-copy-stream {
    background: linear-gradient(135deg, #10b981, #059669);
    color: #fff;
    border: 1px solid #10b981;
    font-family: var(--font-heading);
    font-size: 12.5px;
    font-weight: 800;
    padding: 7px 14px;
    border-radius: var(--radius-sm);
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    box-shadow: 0 2px 10px rgba(16, 185, 129, 0.3);
    transition: var(--transition);
  }
  .btn-copy-stream:hover {
    filter: brightness(1.15);
    transform: translateY(-1px);
  }

  .btn-open-source {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--border-subtle);
    color: var(--text-main);
    font-size: 12px;
    font-weight: 700;
    padding: 7px 12px;
    border-radius: var(--radius-sm);
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    text-decoration: none;
    transition: var(--transition);
  }
  .btn-open-source:hover {
    background: rgba(255, 255, 255, 0.12);
    color: #fff;
  }

  /* DIRECT STREAM LINK INPUT BOX */
  .stream-link-box {
    display: flex;
    align-items: center;
    background: #000;
    border: 1px solid rgba(16, 185, 129, 0.35);
    border-radius: var(--radius-sm);
    padding: 3px 6px 3px 12px;
    gap: 8px;
  }
  .stream-link-tag {
    font-size: 11px;
    font-weight: 800;
    color: var(--primary-green);
    white-space: nowrap;
  }
  .stream-link-input {
    flex: 1;
    background: transparent;
    border: none;
    color: #cbd5e1;
    font-family: monospace;
    font-size: 11.5px;
    outline: none;
    width: 100%;
  }
  .btn-quick-copy {
    background: var(--bg-surface);
    border: 1px solid var(--border-subtle);
    color: #fff;
    font-size: 11px;
    font-weight: 700;
    padding: 3px 8px;
    border-radius: 4px;
    cursor: pointer;
    transition: var(--transition);
    white-space: nowrap;
  }
  .btn-quick-copy:hover {
    background: var(--primary-green);
    color: #000;
  }

  /* TOAST NOTIFICATION */
  .toast-notification {
    position: fixed;
    bottom: 24px;
    right: 24px;
    background: #0e1422;
    color: #fff;
    border: 1px solid var(--primary-green);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.6), 0 0 15px var(--primary-glow);
    padding: 12px 20px;
    border-radius: var(--radius-md);
    font-size: 13px;
    font-weight: 700;
    display: flex;
    align-items: center;
    gap: 10px;
    z-index: 99999;
    transform: translateY(100px);
    opacity: 0;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    pointer-events: none;
  }
  .toast-notification.show {
    transform: translateY(0);
    opacity: 1;
    pointer-events: auto;
  }

  /* RIGHT COLUMN: INTERACTIVE PLAYLIST */
  .interactive-playlist-card {
    background: var(--bg-card);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-lg);
    display: flex;
    flex-direction: column;
    height: calc(100vh - 120px);
    max-height: 720px;
    min-height: 480px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  }

  .playlist-header-bar {
    padding: 12px 14px;
    border-bottom: 1px solid var(--border-subtle);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    background: rgba(0, 0, 0, 0.25);
  }

  .playlist-header-title {
    font-family: var(--font-heading);
    font-size: 14.5px;
    font-weight: 800;
    color: #fff;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .playlist-counter-badge {
    background: rgba(16, 185, 129, 0.15);
    color: var(--primary-green);
    border: 1px solid rgba(16, 185, 129, 0.3);
    font-size: 11px;
    font-weight: 800;
    padding: 2px 8px;
    border-radius: var(--radius-full);
  }

  .playlist-search-wrap {
    padding: 8px 12px;
    border-bottom: 1px solid var(--border-subtle);
    position: relative;
  }

  .playlist-search-input {
    width: 100%;
    background: var(--bg-surface);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-md);
    padding: 7px 12px 7px 32px;
    color: #fff;
    font-size: 12.5px;
    outline: none;
    transition: var(--transition);
  }
  .playlist-search-input:focus {
    border-color: var(--primary-green);
    box-shadow: 0 0 8px var(--primary-glow);
  }
  .playlist-search-icon {
    position: absolute;
    left: 22px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-dim);
    font-size: 12px;
  }

  .playlist-scroll-area {
    padding: 8px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 6px;
    flex: 1;
  }

  /* CATEGORY DIVIDER INSIDE PLAYLIST */
  .playlist-category-divider {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 10px 4px 10px;
    margin-top: 4px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  }
  .playlist-divider-title {
    font-family: var(--font-heading);
    font-size: 13px;
    font-weight: 800;
    color: var(--primary-green);
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .playlist-divider-count {
    background: rgba(255, 255, 255, 0.08);
    color: var(--text-muted);
    font-size: 10px;
    font-weight: 800;
    padding: 1px 6px;
    border-radius: var(--radius-full);
  }

  /* MATCH CARD ROW IN PLAYLIST */
  .match-row-item {
    background: var(--bg-surface);
    border: 1px solid var(--border-subtle);
    border-radius: var(--radius-md);
    padding: 9px 12px;
    cursor: pointer;
    transition: var(--transition);
    display: flex;
    flex-direction: column;
    gap: 5px;
  }
  .match-row-item:hover, .match-row-item.active {
    background: var(--bg-card-hover);
    border-color: var(--primary-green);
    transform: translateX(2px);
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
  }

  .match-row-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 11px;
    color: var(--text-muted);
  }
  .match-row-league {
    color: var(--primary-green);
    font-weight: 700;
    max-width: 65%;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .match-row-time {
    font-size: 10.5px;
    color: var(--text-muted);
  }

  .match-row-teams-grid {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 6px;
  }
  .team-entry {
    display: flex;
    align-items: center;
    gap: 6px;
    flex: 1;
    font-size: 12.5px;
    font-weight: 700;
    color: #fff;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .team-entry.away {
    justify-content: flex-end;
    text-align: right;
  }
  .team-mini-logo {
    width: 20px;
    height: 20px;
    object-fit: contain;
    flex-shrink: 0;
  }

  .match-row-score-badge {
    background: #000;
    color: var(--accent-gold);
    font-family: var(--font-heading);
    font-size: 12px;
    font-weight: 800;
    padding: 2px 8px;
    border-radius: var(--radius-sm);
    border: 1px solid rgba(255, 228, 0, 0.25);
    flex-shrink: 0;
  }
  .match-row-vs-badge {
    background: rgba(255, 255, 255, 0.05);
    color: var(--text-muted);
    font-size: 11px;
    font-weight: 800;
    padding: 2px 6px;
    border-radius: var(--radius-sm);
    flex-shrink: 0;
  }

  .btn-copy-row-link {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid var(--border-subtle);
    color: var(--text-muted);
    width: 26px;
    height: 26px;
    border-radius: var(--radius-sm);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    cursor: pointer;
    transition: var(--transition);
    flex-shrink: 0;
  }
  .btn-copy-row-link:hover {
    background: var(--primary-green);
    color: #000;
    border-color: var(--primary-green);
    transform: scale(1.12);
    box-shadow: 0 0 10px var(--primary-glow);
  }

  /* HIDE UNWANTED BLOGGER STUFF */
  .post-hidden-meta,
  .event-link-preview,
  .match-source-link {
    display: none !important;
    visibility: hidden !important;
    opacity: 0 !important;
  }
  ]]></b:skin>
  <b:template-skin><![CDATA[ ]]></b:template-skin>
</head>

<body>

  <!-- HEADER -->
  <header class='site-header'>
    <div class='nav-container'>
      <a class='brand-logo' expr:href='data:blog.homepageUrl'>
        <img alt='MEIWATV' class='brand-logo-img' src='https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/meiwatv1.png'/>
      </a>

      <!-- Navigation Links: Langsung terhubung dengan Playlist sebelah kanan -->
      <ul class='nav-menu-links'>
        <li><button class='nav-item-btn btn-nav-live active' data-cat='live' onclick='filterMatchesBySport("live", this)' type='button'><i class='fa-solid fa-circle-dot' style='color:#ef4444;'/> 🔴 Sedang LIVE</button></li>
        <li><button class='nav-item-btn' data-cat='football' onclick='filterMatchesBySport("football", this)' type='button'><i class='fa-solid fa-futbol'/> Sepak Bola</button></li>
        <li><button class='nav-item-btn' data-cat='basketball' onclick='filterMatchesBySport("basketball", this)' type='button'><i class='fa-solid fa-basketball'/> Basket</button></li>
        <li><button class='nav-item-btn' data-cat='badminton' onclick='filterMatchesBySport("badminton", this)' type='button'><i class='fa-solid fa-feather'/> Bulu Tangkis</button></li>
        <li><button class='nav-item-btn' data-cat='tennis' onclick='filterMatchesBySport("tennis", this)' type='button'><i class='fa-solid fa-baseball'/> Tenis</button></li>
        <li><button class='nav-item-btn' data-cat='volleyball' onclick='filterMatchesBySport("volleyball", this)' type='button'><i class='fa-solid fa-volleyball'/> Voli</button></li>
        <li><button class='nav-item-btn' data-cat='esports' onclick='filterMatchesBySport("esports", this)' type='button'><i class='fa-solid fa-gamepad'/> Esports</button></li>
        <li><button class='nav-item-btn' data-cat='all' onclick='filterMatchesBySport("all", this)' type='button'><i class='fa-solid fa-calendar-days'/> Semua Jadwal</button></li>
      </ul>

      <div class='header-actions'>
        <a class='btn-saweria-top' href='https://saweria.co/meiwatv' rel='noopener noreferrer' target='_blank'>
          <span>☕ Donasi</span>
        </a>
        <a class='btn-apk-top' href='https://drive.google.com/file/d/1CDQW3bNBs-3H6M6ADBXWtKllW70wJJ9V/view?usp=sharing' rel='noopener noreferrer' target='_blank'>
          <span>🚀 Unduh APK</span>
        </a>
      </div>
    </div>
  </header>

  <!-- SPONSOR & ADS BANNER -->
  <div class='adsterra-banner-container'>
    <div class='adsterra-wrapper-box' id='adsterra-slot-728x90'>
      <a href='https://www.profitableratecpmnetwork.com/r1x7jbv2ys?key=c06365de807e3e8605b4e7e665953775' rel='noopener noreferrer' target='_blank' style='color:#94a3b8; font-size:12px; display:flex; align-items:center; gap:8px;'>
        <i class='fa-solid fa-rectangle-ad' style='color:#10b981; font-size:16px;'/>
        <span>Sponsor &amp; Iklan Resmi MeiwaSports - Klik untuk Kunjungi Partner Kami</span>
      </a>
    </div>
  </div>

  <!-- MAIN UNIFIED THEATER WORKSPACE (PLAYER LEFT + PLAYLIST RIGHT) -->
  <main class='main-theater-container'>
    <div class='unified-theater-grid'>

      <!-- LEFT: VIDEO THEATER PLAYER BOX -->
      <section class='theater-player-card' id='playerSection'>
        <div class='player-top-bar'>
          <div class='player-match-badge'>
            <span class='live-indicator' id='playerLiveBadge'>
              <i class='fa-solid fa-circle-dot'/> <span>🔴 LIVE</span>
            </span>
            <span id='playerLeagueText' style='color:var(--text-muted); font-size:13px;'>Turnamen Olahraga</span>
          </div>

          <!-- Server / Jalur Switcher -->
          <div class='player-server-group'>
            <button class='btn-server active' id='btnServer1' onclick='switchServer(1)' type='button'>
              <i class='fa-solid fa-play'/> <span>Jalur 1 (HD)</span>
            </button>
            <button class='btn-server' id='btnServer2' onclick='switchServer(2)' type='button'>
              <i class='fa-solid fa-bolt'/> <span>Jalur 2 (FHD)</span>
            </button>
            <button class='btn-server' id='btnServer3' onclick='switchServer(3)' type='button'>
              <i class='fa-solid fa-server'/> <span>Jalur 3 (Backup)</span>
            </button>
          </div>
        </div>

        <!-- 16:9 Video Frame -->
        <div class='video-container-169'>
          <video autoplay='autoplay' controls='controls' id='mainVideoPlayer' playsinline='playsinline' poster='' style='display:none;'/>

          <!-- Live Stage Screen (Tampil saat video siap atau sebelum klik) -->
          <div class='player-stage-screen' id='playerStage'>
            <span class='player-stage-league' id='stageLeague'>Premier League</span>
            <h2 class='player-stage-title' id='stageTitle'>Pilih Pertandingan untuk Mulai Menonton</h2>
            <p class='player-stage-time' id='stageKickoff'>Siaran Langsung Kualitas HD Tanpa Buffering</p>
            <button class='btn-play-stream-huge' id='btnStagePlay' onclick='triggerStagePlay()' type='button'>
              <i class='fa-solid fa-circle-play fa-xl'/> <span>PUTAR SIARAN SEKARANG</span>
            </button>
          </div>
        </div>

        <!-- Detail Bar Under Player -->
        <div class='player-match-detail-bar'>
          <div class='player-detail-main-row'>
            <div class='detail-match-teams'>
              <img alt='' class='detail-team-logo' id='detailHomeLogo' src='https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png'/>
              <span id='detailHomeTeam'>Tim Tuan Rumah</span>
              <span class='detail-score-pill' id='detailScore'>VS</span>
              <span id='detailAwayTeam'>Tim Tamu</span>
              <img alt='' class='detail-team-logo' id='detailAwayLogo' src='https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png'/>
            </div>

            <div class='player-action-buttons'>
              <button class='btn-copy-stream' id='btnCopyBlogMatchLink' onclick='copyCurrentMatchBlogLink()' type='button'>
                <i class='fa-solid fa-copy'/> <span>Salin Link Pertandingan</span>
              </button>
              <button class='btn-open-source' id='btnOpenNewTab' onclick='openCurrentMatchNewTab()' type='button'>
                <i class='fa-solid fa-expand'/> <span>Layar Penuh</span>
              </button>
              <button class='btn-open-source' onclick='shareCurrentMatch()' type='button'>
                <i class='fa-solid fa-share-nodes'/> <span>Bagikan</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- RIGHT: INTERACTIVE PLAYLIST & SCHEDULE PANEL -->
      <aside class='interactive-playlist-card'>
        <div class='playlist-header-bar'>
          <div class='playlist-header-title'>
            <span id='playlistCategoryIcon'>🔴</span> <span id='playlistCategoryLabel'>Pertandingan LIVE</span>
          </div>
          <span class='playlist-counter-badge' id='playlistTotalCount'>0 MATCH</span>
        </div>

        <!-- Quick Filter Search Input -->
        <div class='playlist-search-wrap'>
          <i class='fa-solid fa-magnifying-glass playlist-search-icon'/>
          <input class='playlist-search-input' id='playlistSearchInput' oninput='handleMatchSearch(this.value)' placeholder='Cari tim atau liga...' type='text'/>
        </div>

        <!-- Scrollable Match List with Sport Separators -->
        <div class='playlist-scroll-area' id='playlistContainer'>
          <!-- Injected via JavaScript -->
        </div>
      </aside>

    </div>
  </main>

  <!-- TOAST NOTIFICATION -->
  <div class='toast-notification' id='playerToast'>
    <i class='fa-solid fa-circle-check' style='color:#10b981; font-size:18px;'/>
    <span id='toastMessage'>Link siaran berhasil disalin!</span>
  </div>

  <!-- HIDDEN BLOGGER SECTION (UNTUK SYNC POSTS) -->
  <div style='display:none !important;'>
    <b:section id='main' showaddelement='no'>
      <b:widget id='Blog1' locked='true' title='Blog Posts' type='Blog' version='2'>
        <b:includable id='main'>
          <b:loop values='data:posts' var='post'>
            <article class='blogger-raw-post' expr:id='"post-" + data:post.id'>
              <a expr:href='data:post.url'><data:post.title/></a>
              <div class='post-body-content'><data:post.body/></div>
            </article>
          </b:loop>
        </b:includable>
      </b:widget>
    </b:section>
  </div>

  <!-- JAVASCRIPT ENGINE & DIRECT HLS VIDEO PLAYBACK -->
  <script type='text/javascript'>
  //<![CDATA[
  const AUTO_LIVE_DATASET = ${JSON.stringify(matches, null, 2)};

  let allLoadedMatches = [...AUTO_LIVE_DATASET];
  let currentActiveMatch = null;
  let activeCurrentServer = 1;
  let activeStreamUrlServer1 = "";
  let activeStreamUrlServer2 = "";
  let activeStreamUrlServer3 = "";
  let currentCategoryFilter = "live";
  let currentSearchKeyword = "";

  let hlsInstance = null;
  let flvPlayerInstance = null;
  let adsterraClickCounter = 0;

  // ADSTERRA TRIGGER: SETIAP KLIK PERTANDINGAN / AKSI
  function triggerAdsterra() {
    adsterraClickCounter++;
    const adUrls = [
      "https://www.profitableratecpmnetwork.com/r1x7jbv2ys?key=c06365de807e3e8605b4e7e665953775",
      "https://www.profitableratecpmnetwork.com/nhgf41xe?key=c1f7258bb9659ab225647c310b68619e"
    ];
    const targetAd = adUrls[adsterraClickCounter % adUrls.length];
    try {
      const adWin = window.open(targetAd, '_blank');
      if (adWin) {
        adWin.blur();
        window.focus();
      }
    } catch (_) {}
  }

  // TOAST NOTIFICATION HELPER
  function showToastNotification(msg) {
    const toast = document.getElementById('playerToast');
    const msgEl = document.getElementById('toastMessage');
    if (toast && msgEl) {
      msgEl.textContent = msg;
      toast.classList.add('show');
      setTimeout(function() {
        toast.classList.remove('show');
      }, 3500);
    }
  }

  // 1. SPORT CATEGORY METADATA HELPER
  function getSportCategoryMeta(catString, title, league) {
    const text = ((catString || '') + ' ' + (title || '') + ' ' + (league || '')).toLowerCase();
    if (text.includes('basket') || text.includes('bóng rổ') || text.includes('nba') || text.includes('wnba') || text.includes('vba') || text.includes('baloncesto') || text.includes('bundesliga')) {
      return { icon: '🏀', name: 'Bola Basket', key: 'basketball' };
    }
    if (text.includes('badminton') || text.includes('bulu tangkis') || text.includes('cầu lông') || text.includes('bwf')) {
      return { icon: '🏸', name: 'Bulu Tangkis', key: 'badminton' };
    }
    if (text.includes('tenis') || text.includes('tennis') || text.includes('atp') || text.includes('wta') || text.includes('davis cup')) {
      return { icon: '🎾', name: 'Tenis', key: 'tennis' };
    }
    if (text.includes('voli') || text.includes('volleyball') || text.includes('bóng chuyền')) {
      return { icon: '🏐', name: 'Bola Voli', key: 'volleyball' };
    }
    if (text.includes('esport') || text.includes('dota') || text.includes('league of legends') || text.includes('crossfire') || text.includes('cs2') || text.includes('csgo') || text.includes('pubg') || text.includes('lcs') || text.includes('lec') || text.includes('lit') || text.includes('vcs') || text.includes('lpl') || text.includes('gaming') || text.includes('pgl') || text.includes('starladder') || text.includes('cct') || text.includes('hyperx') || text.includes('nodwin') || text.includes('rift')) {
      return { icon: '🎮', name: 'Esports & Gaming', key: 'esports' };
    }
    return { icon: '⚽', name: 'Sepak Bola', key: 'football' };
  }

  // 2. RENDER INTERACTIVE PLAYLIST
  function renderInteractivePlaylist(matchesToRender) {
    allLoadedMatches = matchesToRender || AUTO_LIVE_DATASET;

    const playlistContainer = document.getElementById('playlistContainer');
    const playlistLabel = document.getElementById('playlistCategoryLabel');
    const playlistIcon = document.getElementById('playlistCategoryIcon');
    const playlistTotalCount = document.getElementById('playlistTotalCount');
    if (!playlistContainer) return;

    const liveCount = allLoadedMatches.filter(m => m.status === 1).length;

    let filtered = allLoadedMatches.filter(m => {
      const sportMeta = getSportCategoryMeta(m.sportCategory || '', m.title || '', m.league || '');
      const isLive = m.status === 1;

      if (currentCategoryFilter === 'live') {
        if (liveCount > 0) {
          if (!isLive) return false;
        } else {
          // Jika belum ada live, tampilkan semua jadwal hari ini agar list tidak kosong
          // Loloskan
        }
      } else if (currentCategoryFilter !== 'all') {
        if (sportMeta.key !== currentCategoryFilter) return false;
      }

      if (currentSearchKeyword.trim() !== '') {
        const query = currentSearchKeyword.toLowerCase();
        const searchTarget = ((m.title || '') + ' ' + (m.homeTeam || '') + ' ' + (m.awayTeam || '') + ' ' + (m.league || '')).toLowerCase();
        return searchTarget.includes(query);
      }
      return true;
    });

    const titlesMap = {
      live: { icon: '🔴', title: liveCount > 0 ? 'Pertandingan SEDANG LIVE' : 'Semua Jadwal Olahraga Hari Ini' },
      football: { icon: '⚽', title: 'Jadwal & Live Sepak Bola' },
      basketball: { icon: '🏀', title: 'Jadwal & Live Bola Basket' },
      badminton: { icon: '🏸', title: 'Jadwal & Live Bulu Tangkis' },
      tennis: { icon: '🎾', title: 'Jadwal & Live Tenis' },
      volleyball: { icon: '🏐', title: 'Jadwal & Live Bola Voli' },
      esports: { icon: '🎮', title: 'Jadwal & Live Esports' },
      all: { icon: '🌐', title: 'Semua Jadwal Olahraga' }
    };

    const currentMeta = titlesMap[currentCategoryFilter] || { icon: '🏆', title: 'Jadwal Olahraga' };
    if (playlistIcon) playlistIcon.textContent = currentMeta.icon;
    if (playlistLabel) playlistLabel.textContent = currentMeta.title;
    if (playlistTotalCount) playlistTotalCount.textContent = filtered.length + ' MATCH';

    if (filtered.length === 0) {
      playlistContainer.innerHTML = \`
        <div style="text-align:center; padding:40px 10px; color:var(--text-muted);">
          <i class="fa-solid fa-calendar-xmark fa-2x" style="color:var(--text-dim); margin-bottom:8px;"></i>
          <p style="font-weight:700; font-size:13px; color:#fff;">Tidak ada pertandingan ditemukan</p>
          <p style="font-size:11.5px; color:var(--text-dim); margin-top:2px;">Silakan pilih kategori lain atau ubah kata kunci pencarian.</p>
        </div>\`;
      return;
    }

    const groupOrder = ['football', 'basketball', 'badminton', 'tennis', 'volleyball', 'esports'];
    const groups = {};
    groupOrder.forEach(k => { groups[k] = []; });

    filtered.forEach(m => {
      const meta = getSportCategoryMeta(m.sportCategory || '', m.title || '', m.league || '');
      if (!groups[meta.key]) groups[meta.key] = [];
      groups[meta.key].push(m);
    });

    let fullHtml = '';

    groupOrder.forEach(groupKey => {
      const list = groups[groupKey];
      if (!list || list.length === 0) return;

      const sampleMeta = getSportCategoryMeta(groupKey, '', '');

      if (currentCategoryFilter === 'live' || currentCategoryFilter === 'all') {
        fullHtml += \`
          <div class="playlist-category-divider">
            <div class="playlist-divider-title">
              <span>\${sampleMeta.icon}</span> <span>\${sampleMeta.name} \${currentCategoryFilter === 'live' ? 'LIVE' : ''}</span>
            </div>
            <span class="playlist-divider-count">\${list.length}</span>
          </div>
        \`;
      }

      list.forEach(match => {
        const globalIdx = allLoadedMatches.indexOf(match);
        const isLive = match.status === 1;
        const isFinished = match.status === 2;
        const homeName = match.homeTeam || match.title.split(' vs ')[0] || 'Tim 1';
        const awayName = match.awayTeam || match.title.split(' vs ')[1] || 'Tim 2';
        const homeLogo = match.homeLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';
        const awayLogo = match.awayLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';

        let scoreBadge = '';
        if (isLive && match.scoreText) {
          scoreBadge = \`<span class="match-row-score-badge">\${match.scoreText}</span>\`;
        } else if (isLive) {
          scoreBadge = \`<span class="match-row-score-badge">LIVE</span>\`;
        } else if (isFinished) {
          scoreBadge = \`<span class="match-row-vs-badge" style="color:var(--text-dim);">FT</span>\`;
        } else {
          scoreBadge = \`<span class="match-row-vs-badge">VS</span>\`;
        }

        const activeClass = (currentActiveMatch && currentActiveMatch.title === match.title) ? ' active' : '';

        fullHtml += \`
          <div class="match-row-item\${activeClass}" onclick="selectMatchCard(\${globalIdx})" id="match-row-\${globalIdx}">
            <div class="match-row-header">
              <span class="match-row-league">\${match.league || 'Turnamen Olahraga'}</span>
              <div style="display:flex; align-items:center; gap:6px;">
                <span class="match-row-time">
                  \${isLive ? '<span class="live-indicator" style="padding:1px 6px; font-size:9.5px;"><i class="fa-solid fa-circle fa-2xs"></i> LIVE</span>' : '<i class="fa-regular fa-clock"></i> ' + (match.kickoffText || '')}
                </span>
                <button class="btn-copy-row-link" onclick="copySpecificMatchLink(\${globalIdx}, event)" title="Salin Link Pertandingan Blog Ini" type="button">
                  <i class="fa-solid fa-copy"></i>
                </button>
              </div>
            </div>

            <div class="match-row-teams-grid">
              <div class="team-entry">
                <img src="\${homeLogo}" alt="\${homeName}" class="team-mini-logo" onerror="this.src='https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png'"/>
                <span>\${homeName}</span>
              </div>

              \${scoreBadge}

              <div class="team-entry away">
                <span>\${awayName}</span>
                <img src="\${awayLogo}" alt="\${awayName}" class="team-mini-logo" onerror="this.src='https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png'"/>
              </div>
            </div>
          </div>
        \`;
      });
    });

    playlistContainer.innerHTML = fullHtml;

    // Auto-load match jika belum terpilih
    if (!currentActiveMatch && filtered.length > 0) {
      setHeroMatchPreview(filtered[0]);
    }
  }

  // 3. FILTER MATCHES BY SPORT (HEADER TABS CLICK)
  function filterMatchesBySport(category, clickedElement) {
    triggerAdsterra();
    currentCategoryFilter = category;

    document.querySelectorAll('.nav-item-btn').forEach(el => {
      el.classList.remove('active');
    });

    document.querySelectorAll('[data-cat="' + category + '"]').forEach(el => {
      el.classList.add('active');
    });

    if (clickedElement) {
      clickedElement.classList.add('active');
    }

    renderInteractivePlaylist(allLoadedMatches);
  }

  // 4. SEARCH HANDLER
  function handleMatchSearch(keyword) {
    currentSearchKeyword = keyword;
    renderInteractivePlaylist(allLoadedMatches);
  }

  // 5. SELECT MATCH CARD & SET PREVIEW
  function selectMatchCard(index) {
    const match = allLoadedMatches[index];
    if (!match) return;
    setHeroMatchPreview(match);
    playMatchDirect(index, 1);
  }

  function setHeroMatchPreview(match) {
    currentActiveMatch = match;
    activeStreamUrlServer1 = match.streamJalur1 || (match.streams ? match.streams.jalur1 : '') || match.postUrl || '';
    activeStreamUrlServer2 = match.streamJalur2 || (match.streams ? match.streams.jalur2 : '') || '';
    activeStreamUrlServer3 = match.streamJalur3 || (match.streams ? match.streams.jalur3 : '') || '';

    // Update URL parameter di browser agar link pertandingan bisa langsung dibagikan
    try {
      const matchSlug = match.id || match.title.toLowerCase().replace(/[^a-z0-9]+/g, '-');
      window.history.replaceState(null, '', '?match=' + matchSlug);
    } catch (_) {}

    const leagueEl = document.getElementById('playerLeagueText');
    if (leagueEl) leagueEl.textContent = match.league || 'Turnamen Olahraga';

    const stageLeague = document.getElementById('stageLeague');
    if (stageLeague) stageLeague.textContent = match.league || 'Turnamen Olahraga';

    const stageTitle = document.getElementById('stageTitle');
    if (stageTitle) stageTitle.textContent = match.title;

    const stageKickoff = document.getElementById('stageKickoff');
    if (stageKickoff) {
      if (match.status === 1) {
        stageKickoff.innerHTML = '<b style="color:#ef4444;">🔴 PERTANDINGAN SEDANG LIVE</b>';
      } else {
        stageKickoff.innerHTML = 'Jadwal Kick-off: <b>' + (match.kickoffText || 'Siap Tayang') + '</b>';
      }
    }

    const homeNameEl = document.getElementById('detailHomeTeam');
    if (homeNameEl) homeNameEl.textContent = match.homeTeam || match.title.split(' vs ')[0] || 'Tuan Rumah';

    const awayNameEl = document.getElementById('detailAwayTeam');
    if (awayNameEl) awayNameEl.textContent = match.awayTeam || match.title.split(' vs ')[1] || 'Tamu';

    const scoreEl = document.getElementById('detailScore');
    if (scoreEl) {
      if (match.status === 1 && match.scoreText) scoreEl.textContent = match.scoreText;
      else if (match.status === 1) scoreEl.textContent = 'LIVE';
      else if (match.status === 2) scoreEl.textContent = match.scoreText || 'FT';
      else scoreEl.textContent = 'VS';
    }

    const homeLogoEl = document.getElementById('detailHomeLogo');
    if (homeLogoEl) homeLogoEl.src = match.homeLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';

    const awayLogoEl = document.getElementById('detailAwayLogo');
    if (awayLogoEl) awayLogoEl.src = match.awayLogo || 'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/Logo%20Meiwa%20icon.png';

    document.querySelectorAll('.match-row-item').forEach(el => el.classList.remove('active'));
    const activeEl = document.getElementById('match-row-' + allLoadedMatches.indexOf(match));
    if (activeEl) activeEl.classList.add('active');
  }

  // 6. DIRECT HLS VIDEO PLAYBACK ENGINE
  function playMatchDirect(index, serverIndex) {
    const match = allLoadedMatches[index];
    if (match) setHeroMatchPreview(match);
    activeCurrentServer = serverIndex || 1;

    triggerAdsterra();

    if (window.innerWidth < 1100) {
      const playerCard = document.getElementById('playerSection');
      if (playerCard) {
        playerCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }

    document.querySelectorAll('.btn-server').forEach((btn, idx) => {
      if (idx + 1 === activeCurrentServer) btn.classList.add('active');
      else btn.classList.remove('active');
    });

    let targetStreamUrl = activeStreamUrlServer1;
    if (activeCurrentServer === 2 && activeStreamUrlServer2) targetStreamUrl = activeStreamUrlServer2;
    if (activeCurrentServer === 3 && activeStreamUrlServer3) targetStreamUrl = activeStreamUrlServer3;

    executeStreamPlayback(targetStreamUrl, match);
  }

  function executeStreamPlayback(streamUrl, match) {
    const video = document.getElementById('mainVideoPlayer');
    const stage = document.getElementById('playerStage');

    if (hlsInstance) {
      hlsInstance.destroy();
      hlsInstance = null;
    }
    if (flvPlayerInstance) {
      flvPlayerInstance.destroy();
      flvPlayerInstance = null;
    }

    if (!streamUrl || streamUrl.trim() === '') {
      if (stage) stage.style.display = 'flex';
      if (video) { video.pause(); video.style.display = 'none'; }
      return;
    }

    // Pastikan URL m3u8 direct channel jika masih berbentuk web link
    let finalStreamUrl = streamUrl;
    if (!finalStreamUrl.endsWith('.m3u8') && !finalStreamUrl.endsWith('.flv')) {
      const chanMatch = finalStreamUrl.match(/channel(-?\\d+)/i);
      if (chanMatch) {
        const cId = chanMatch[1].replace('-', '');
        finalStreamUrl = 'https://live2.zundrixmediapipeline.com/live/channel' + cId + '.m3u8';
      } else if (match && match.streamJalur1 && match.streamJalur1.endsWith('.m3u8')) {
        finalStreamUrl = match.streamJalur1;
      } else {
        finalStreamUrl = 'https://live2.zundrixmediapipeline.com/live/channel1.m3u8';
      }
    }

    const isDirectFlv = finalStreamUrl.endsWith('.flv') || finalStreamUrl.includes('.flv?');

    // 1. FLV Playback
    if (isDirectFlv && typeof flvjs !== 'undefined' && flvjs.isSupported()) {
      if (stage) stage.style.display = 'none';
      if (video) {
        video.style.display = 'block';
        try {
          flvPlayerInstance = flvjs.createPlayer({ type: 'flv', url: finalStreamUrl, isLive: true, cors: true });
          flvPlayerInstance.attachMediaElement(video);
          flvPlayerInstance.load();
          const playPromise = video.play();
          if (playPromise !== undefined) {
            playPromise.catch(() => {
              video.muted = true;
              video.play().catch(() => {});
            });
          }
          return;
        } catch (e) {
          console.warn('FLV error:', e);
        }
      }
    }

    // 2. HLS.js Playback (Desktop Chrome, Edge, Firefox, Android)
    if (typeof Hls !== 'undefined' && Hls.isSupported()) {
      if (stage) stage.style.display = 'none';
      if (video) {
        video.style.display = 'block';
        try {
          hlsInstance = new Hls({
            enableWorker: true,
            lowLatencyMode: true,
            backBufferLength: 90
          });
          hlsInstance.loadSource(finalStreamUrl);
          hlsInstance.attachMedia(video);
          hlsInstance.on(Hls.Events.MANIFEST_PARSED, function() {
            const playPromise = video.play();
            if (playPromise !== undefined) {
              playPromise.catch(() => {
                video.muted = true;
                video.play().catch(() => {});
              });
            }
          });
          hlsInstance.on(Hls.Events.ERROR, function(event, data) {
            if (data.fatal) {
              switch (data.type) {
                case Hls.ErrorTypes.NETWORK_ERROR:
                  hlsInstance.startLoad();
                  break;
                case Hls.ErrorTypes.MEDIA_ERROR:
                  hlsInstance.recoverMediaError();
                  break;
                default:
                  hlsInstance.destroy();
                  break;
              }
            }
          });
          return;
        } catch (e) {
          console.warn('HLS.js error:', e);
        }
      }
    }

    // 3. Native HLS (Safari iOS, iPad, Mac, Native WebViews)
    if (video && video.canPlayType('application/vnd.apple.mpegurl')) {
      if (stage) stage.style.display = 'none';
      video.style.display = 'block';
      video.src = finalStreamUrl;
      const playPromise = video.play();
      if (playPromise !== undefined) {
        playPromise.catch(() => {
          video.muted = true;
          video.play().catch(() => {});
        });
      }
      return;
    }

    // Fallback tampilan
    if (stage) stage.style.display = 'flex';
    if (video) { video.pause(); video.style.display = 'none'; }
  }

  function triggerStagePlay() {
    triggerAdsterra();
    if (currentActiveMatch) {
      const idx = allLoadedMatches.indexOf(currentActiveMatch);
      playMatchDirect(idx >= 0 ? idx : 0, 1);
    } else if (allLoadedMatches.length > 0) {
      selectMatchCard(0);
    }
  }

  function switchServer(serverIdx) {
    activeCurrentServer = serverIdx;
    triggerAdsterra();

    document.querySelectorAll('.btn-server').forEach((btn, idx) => {
      if (idx + 1 === activeCurrentServer) btn.classList.add('active');
      else btn.classList.remove('active');
    });

    let targetStreamUrl = activeStreamUrlServer1;
    if (activeCurrentServer === 2 && activeStreamUrlServer2) targetStreamUrl = activeStreamUrlServer2;
    if (activeCurrentServer === 3 && activeStreamUrlServer3) targetStreamUrl = activeStreamUrlServer3;

    if (currentActiveMatch) {
      executeStreamPlayback(targetStreamUrl, currentActiveMatch);
    }
  }

  // 7. COPY LINK PERTANDINGAN BLOG (E.G. HTTPS://MEIWAOLAHRAGA.BLOGSPOT.COM/?MATCH=...)
  function getMatchBlogLink(match) {
    let baseUrl = window.location.href.split('?')[0].split('#')[0];
    const slug = (match.title || match.id || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
    return baseUrl + '?match=' + encodeURIComponent(slug);
  }

  function findMatchByKeywordOrSlug(param) {
    if (!param || !allLoadedMatches || allLoadedMatches.length === 0) return -1;
    const cleanParam = decodeURIComponent(param).toLowerCase().replace(/[^a-z0-9]/g, '');
    if (!cleanParam) return -1;

    // 1. Cek exact slug atau ID
    let idx = allLoadedMatches.findIndex(m => {
      const slug = (m.title || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      const mId = (m.id || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      return slug === cleanParam || mId === cleanParam;
    });
    if (idx >= 0) return idx;

    // 2. Cek substring match pada title / tim
    idx = allLoadedMatches.findIndex(m => {
      const slug = (m.title || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      const home = (m.homeTeam || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      const away = (m.awayTeam || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      return slug.includes(cleanParam) || cleanParam.includes(slug) || (home && cleanParam.includes(home)) || (away && cleanParam.includes(away));
    });
    return idx;
  }

  function copyCurrentMatchBlogLink() {
    triggerAdsterra();
    if (!currentActiveMatch) return;
    const url = getMatchBlogLink(currentActiveMatch);
    copyTextToClipboard(url, '✅ Link pertandingan ' + currentActiveMatch.title + ' berhasil disalin!');
    
    const btn = document.getElementById('btnCopyBlogMatchLink');
    if (btn) {
      const oldHtml = btn.innerHTML;
      btn.innerHTML = '<i class="fa-solid fa-check"></i> <span>Tersalin!</span>';
      setTimeout(() => { btn.innerHTML = oldHtml; }, 2000);
    }
  }

  function copySpecificMatchLink(index, event) {
    if (event) event.stopPropagation();
    triggerAdsterra();
    const match = allLoadedMatches[index];
    if (!match) return;
    const url = getMatchBlogLink(match);
    copyTextToClipboard(url, '✅ Link pertandingan ' + match.title + ' berhasil disalin!');
  }

  function fallbackCopyText(text, successMsg) {
    try {
      const textArea = document.createElement('textarea');
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      textArea.style.top = '-999999px';
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();
      const successful = document.execCommand('copy');
      document.body.removeChild(textArea);
      if (successful) {
        showToastNotification(successMsg || 'Link berhasil disalin!');
        return;
      }
    } catch (_) {}
    prompt('Salin link pertandingan berikut:', text);
  }

  function copyTextToClipboard(text, successMsg) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(() => {
        showToastNotification(successMsg || 'Link berhasil disalin!');
      }).catch(() => {
        fallbackCopyText(text, successMsg);
      });
    } else {
      fallbackCopyText(text, successMsg);
    }
  }

  function openCurrentMatchNewTab() {
    triggerAdsterra();
    const video = document.getElementById('mainVideoPlayer');
    if (video && video.style.display !== 'none') {
      if (video.requestFullscreen) {
        video.requestFullscreen();
        return;
      } else if (video.webkitRequestFullscreen) {
        video.webkitRequestFullscreen();
        return;
      } else if (video.msRequestFullscreen) {
        video.msRequestFullscreen();
        return;
      }
    }
  }

  function shareCurrentMatch() {
    triggerAdsterra();
    if (currentActiveMatch) {
      const url = getMatchBlogLink(currentActiveMatch);
      if (navigator.share) {
        navigator.share({
          title: currentActiveMatch.title + ' - Live Streaming MeiwaSports',
          url: url
        }).catch(() => {});
      } else {
        copyTextToClipboard(url, 'Link siaran pertandingan berhasil disalin!');
      }
    }
  }

  // 8. REAL-TIME MATCHES SYNC FROM GITHUB
  function fetchLiveMatchesDirect() {
    const syncSources = [
      'https://raw.githubusercontent.com/adityafarid0112/meiwatv/main/matches.json',
      'https://cdn.jsdelivr.net/gh/adityafarid0112/meiwatv@main/matches.json'
    ];

    function tryFetchSource(idx) {
      if (idx >= syncSources.length) return;
      fetch(syncSources[idx] + '?_t=' + Date.now())
        .then(res => {
          if (!res.ok) throw new Error('Sync source failed');
          return res.json();
        })
        .then(data => {
          if (Array.isArray(data) && data.length > 0) {
            allLoadedMatches = data;
            renderInteractivePlaylist(allLoadedMatches);
            if (currentActiveMatch) {
              const updated = allLoadedMatches.find(m => m.id === currentActiveMatch.id || m.title === currentActiveMatch.title);
              if (updated) {
                setHeroMatchPreview(updated);
              }
            }
          }
        })
        .catch(() => {
          tryFetchSource(idx + 1);
        });
    }

    tryFetchSource(0);
  }

  function activateMatchFromUrl() {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      let matchParam = urlParams.get('match') || urlParams.get('m_id');
      if (!matchParam && window.location.hash) {
        matchParam = window.location.hash.replace('#', '').replace('match=', '').replace('match-', '');
      }

      if (matchParam && allLoadedMatches.length > 0) {
        const foundIdx = findMatchByKeywordOrSlug(matchParam);
        if (foundIdx >= 0) {
          const targetMatch = allLoadedMatches[foundIdx];
          const sportMeta = getSportCategoryMeta(targetMatch.sportCategory || '', targetMatch.title || '', targetMatch.league || '');

          if (targetMatch.status === 1) {
            currentCategoryFilter = 'live';
          } else {
            currentCategoryFilter = sportMeta.key || 'all';
          }

          document.querySelectorAll('.nav-item-btn').forEach(el => el.classList.remove('active'));
          const activeNavBtn = document.querySelector('[data-cat="' + currentCategoryFilter + '"]');
          if (activeNavBtn) activeNavBtn.classList.add('active');

          renderInteractivePlaylist(allLoadedMatches);
          setHeroMatchPreview(targetMatch);

          if (targetMatch.status === 1) {
            playMatchDirect(foundIdx, 1);
          } else {
            const stage = document.getElementById('playerStage');
            const video = document.getElementById('mainVideoPlayer');
            if (stage) stage.style.display = 'flex';
            if (video) { video.pause(); video.style.display = 'none'; }
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // 9. INIT ON DOM LOAD
  function initLivePortal() {
    const hasLive = AUTO_LIVE_DATASET.some(m => m.status === 1);
    if (!hasLive) {
      currentCategoryFilter = 'all';
      document.querySelectorAll('.nav-item-btn').forEach(el => el.classList.remove('active'));
      const allNavBtn = document.querySelector('[data-cat="all"]');
      if (allNavBtn) allNavBtn.classList.add('active');
    }

    renderInteractivePlaylist(AUTO_LIVE_DATASET);

    const matchFound = activateMatchFromUrl();

    if (!matchFound && allLoadedMatches.length > 0) {
      setHeroMatchPreview(allLoadedMatches[0]);
    }

    setTimeout(function() {
      fetchLiveMatchesDirect();
      setInterval(fetchLiveMatchesDirect, 120000);
    }, 4000);
  }

  document.addEventListener('DOMContentLoaded', initLivePortal);
  //]]>
  </script>
</body>
</html>`;

    const rootXmlPath = path.join(__dirname, 'template-sportstream.xml');
    const bloggerXmlPath = path.join(__dirname, 'blogger', 'template-sportstream.xml');
    const updateXmlPath = path.join(__dirname, 'template-sportstream-update.xml');
    const bloggerUpdateXmlPath = path.join(__dirname, 'blogger', 'template-sportstream-update.xml');

    fs.writeFileSync(rootXmlPath, xmlTemplate, 'utf8');
    fs.writeFileSync(bloggerXmlPath, xmlTemplate, 'utf8');
    fs.writeFileSync(updateXmlPath, xmlTemplate, 'utf8');
    fs.writeFileSync(bloggerUpdateXmlPath, xmlTemplate, 'utf8');

    console.log('✅ Berhasil membangun template-sportstream.xml dan blogger/template-sportstream.xml!');
}

generateBloggerTemplate();
