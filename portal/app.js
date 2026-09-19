/**
 * MEIWA APPS PORTAL - Interactive Engine
 */

document.addEventListener("DOMContentLoaded", () => {
  initDynamicContent();
  initModalLogic();
  initShowcaseTabs();
  initFaqAccordion();
  initSmoothScroll();
});

/**
 * Inisialisasi teks & data dinamis dari config.js ke elemen HTML
 */
function initDynamicContent() {
  if (typeof MEIWA_CONFIG === "undefined") return;

  // 1. Set Sports Details
  const sports = MEIWA_CONFIG.apps.sports;
  if (sports) {
    document.querySelectorAll(".sports-version").forEach(el => el.textContent = sports.version);
    document.querySelectorAll(".sports-size").forEach(el => el.textContent = sports.fileSize);
    document.querySelectorAll(".sports-android").forEach(el => el.textContent = sports.minAndroid);
    document.querySelectorAll(".sports-updated").forEach(el => el.textContent = sports.releaseDate);
  }

  // 2. Set Studio Details
  const studio = MEIWA_CONFIG.apps.studio;
  if (studio) {
    document.querySelectorAll(".studio-version").forEach(el => el.textContent = studio.version);
    document.querySelectorAll(".studio-size").forEach(el => el.textContent = studio.fileSize);
    document.querySelectorAll(".studio-android").forEach(el => el.textContent = studio.minAndroid);
    document.querySelectorAll(".studio-updated").forEach(el => el.textContent = studio.releaseDate);
  }

  // 3. Render FAQ Dinamis
  const faqListContainer = document.getElementById("faqList");
  if (faqListContainer && MEIWA_CONFIG.faq && MEIWA_CONFIG.faq.length > 0) {
    faqListContainer.innerHTML = MEIWA_CONFIG.faq.map((item, index) => `
      <div class="faq-item ${index === 0 ? 'active' : ''}">
        <button class="faq-question" type="button" aria-expanded="${index === 0}">
          <span>${item.q}</span>
          <span class="faq-icon">+</span>
        </button>
        <div class="faq-answer" style="${index === 0 ? 'max-height: 200px;' : ''}">
          <p>${item.a}</p>
        </div>
      </div>
    `).join("");
  }
}

/**
 * Logika Modal Download & Pilihan Server
 */
function initModalLogic() {
  const modal = document.getElementById("downloadModal");
  const closeBtn = document.getElementById("modalCloseBtn");
  const modalOverlay = document.querySelector(".modal-overlay");

  if (!modal) return;

  window.openDownloadModal = function(appKey) {
    const app = MEIWA_CONFIG.apps[appKey];
    if (!app) return;

    // Update Modal Information
    document.getElementById("modalAppIcon").src = appKey === "sports" 
      ? "assets/logo-sports.png" 
      : "assets/logo-studio.png";
    
    document.getElementById("modalAppName").textContent = app.name;
    document.getElementById("modalAppTagline").textContent = `${app.version} • ${app.fileSize} • ${app.minAndroid}`;

    // Servers
    const serverList = document.getElementById("modalServerList");
    let serverHtml = '';

    const stbSize = appKey === 'sports' ? '44.6 MB' : '15.6 MB';
    const hpSize = appKey === 'sports' ? '45.3 MB' : '18.0 MB';
    const univSize = appKey === 'sports' ? '129.8 MB' : '50.6 MB';

    // 1. Versi Ringan STB / Smart TV (Sangat Hemat Memori)
    if (app.downloadUrlSTB) {
      serverHtml += `
        <a href="${app.downloadUrlSTB}" class="server-btn" target="_blank" rel="noopener noreferrer">
          <div class="server-btn-info">
            <span class="server-btn-title">📺 Versi Ringan: STB / Smart TV (Hemat Memori)</span>
            <span class="server-btn-sub">Format 32-bit (armeabi-v7a) • Sangat ringan & anti-lag di TV Box (${stbSize})</span>
          </div>
          <span class="server-badge" style="background: #10B981; color: #fff;">${stbSize}</span>
        </a>
      `;
    }

    // 2. Versi Khusus HP Android (64-bit)
    if (app.downloadUrlHP) {
      serverHtml += `
        <a href="${app.downloadUrlHP}" class="server-btn" target="_blank" rel="noopener noreferrer">
          <div class="server-btn-info">
            <span class="server-btn-title">📱 Versi Ringan: HP Android (64-Bit)</span>
            <span class="server-btn-sub">Format ARM64 • Dioptimalkan untuk Smartphone modern (${hpSize})</span>
          </div>
          <span class="server-badge" style="background: #8B5CF6; color: #fff;">${hpSize}</span>
        </a>
      `;
    }

    // 3. Versi Universal (Semua Tipe HP & TV)
    if (app.downloadUrlUniversal) {
      serverHtml += `
        <a href="${app.downloadUrlUniversal}" class="server-btn" target="_blank" rel="noopener noreferrer">
          <div class="server-btn-info">
            <span class="server-btn-title">🌐 Versi Universal (Semua Jenis HP & TV)</span>
            <span class="server-btn-sub">Format Fat APK Kompatibel untuk semua perangkat Android (${univSize})</span>
          </div>
          <span class="server-badge" style="background: #64748B; color: #fff;">${univSize}</span>
        </a>
      `;
    }

    serverList.innerHTML = serverHtml;

    // Changelog
    const changelogList = document.getElementById("modalChangelogList");
    if (changelogList && app.changelog) {
      changelogList.innerHTML = app.changelog.map(log => `<li>${log}</li>`).join("");
    }

    modal.classList.add("active");
    document.body.style.overflow = "hidden";
  };

  function closeModal() {
    modal.classList.remove("active");
    document.body.style.overflow = "";
  }

  if (closeBtn) closeBtn.addEventListener("click", closeModal);
  modal.addEventListener("click", (e) => {
    if (e.target === modal) closeModal();
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && modal.classList.contains("active")) {
      closeModal();
    }
  });
}

/**
 * Tab Preview Showcase (MeiwaSports vs MeiwaStudio)
 */
function initShowcaseTabs() {
  const tabs = document.querySelectorAll(".showcase-tab-btn");
  const views = document.querySelectorAll(".showcase-view");

  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      views.forEach(v => v.classList.remove("active"));

      tab.classList.add("active");
      const targetId = tab.getAttribute("data-target");
      const targetView = document.getElementById(targetId);
      if (targetView) targetView.classList.add("active");
    });
  });
}

/**
 * FAQ Accordion Toggle
 */
function initFaqAccordion() {
  document.addEventListener("click", (e) => {
    const questionBtn = e.target.closest(".faq-question");
    if (!questionBtn) return;

    const item = questionBtn.closest(".faq-item");
    const answer = item.querySelector(".faq-answer");
    const isExpanded = item.classList.contains("active");

    // Close others
    document.querySelectorAll(".faq-item").forEach(other => {
      if (other !== item) {
        other.classList.remove("active");
        const otherAns = other.querySelector(".faq-answer");
        if (otherAns) otherAns.style.maxHeight = "0px";
      }
    });

    if (isExpanded) {
      item.classList.remove("active");
      answer.style.maxHeight = "0px";
    } else {
      item.classList.add("active");
      answer.style.maxHeight = answer.scrollHeight + 30 + "px";
    }
  });
}

/**
 * Smooth Scroll
 */
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener("click", function(e) {
      const target = document.querySelector(this.getAttribute("href"));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({
          behavior: "smooth",
          block: "start"
        });
      }
    });
  });
}

/**
 * Toast Notification Helper
 */
function showToast(message) {
  let toast = document.getElementById("portalToast");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "portalToast";
    toast.className = "toast";
    document.body.appendChild(toast);
  }

  toast.innerHTML = `<span>✨</span><span>${message}</span>`;
  toast.classList.add("show");

  setTimeout(() => {
    toast.classList.remove("show");
  }, 3500);
}
