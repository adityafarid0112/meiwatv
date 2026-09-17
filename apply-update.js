const fs = require('fs');

let template = fs.readFileSync('template-sportstream.xml', 'utf8');

const oldFetchRegex = /function fetchLiveMatchesDirect\(\) \{[\s\S]*?function initLivePortal/;

const newFetchCode = `function fetchLiveMatchesDirect() {
    const scrollContainer = document.getElementById('matchScrollList');
    if (!scrollContainer) return;

    const channelPool = ['channel13', 'channel9', 'channel28', 'channel8', 'channel7', 'channel32', 'channel17', 'channel23', 'channel18', 'channel22', 'channel33', 'channel10', 'channel11', 'channel12', 'channel1', 'channel2', 'channel3', 'channel4', 'channel5', 'channel6'];

    const proxyUrls = [
      'https://cors.eu.org/https://tft-forests.org/',
      'https://corsproxy.org/?' + encodeURIComponent('https://tft-forests.org/'),
      'https://api.allorigins.win/raw?url=' + encodeURIComponent('https://tft-forests.org/')
    ];

    function tryFetchProxy(index) {
      if (index >= proxyUrls.length) return;

      fetch(proxyUrls[index])
        .then(res => {
          if (!res.ok) throw new Error('Proxy status: ' + res.status);
          return res.text();
        })
        .then(rawHtml => {
          const tagRegex = /<div[^>]*class="[^"]*grid-matches__item[^"]*"([^>]*)>([\\s\\S]*?)(?=<div[^>]*class="[^"]*grid-matches__item|$)/gi;
          let match;
          const liveScraped = [];
          let poolIdx = 0;

          while ((match = tagRegex.exec(rawHtml)) !== null) {
            const attrStr = match[1];
            const content = match[2];

            const statusMatch = attrStr.match(/data-status="(\\d+)"/);
            const sourceStatus = statusMatch ? parseInt(statusMatch[1], 10) : null;

            // Abaikan pertandingan yang sudah selesai di website sumber (status 4 atau > 3)
            if (sourceStatus !== null && sourceStatus !== 1 && sourceStatus !== 2 && sourceStatus !== 3) {
              continue;
            }

            const hrefMatch = content.match(/href="(\\/truc-tiep\\/[a-z0-9\\-]+-luc-(\\d{4})-ngay-(\\d{2})-(\\d{2})-(\\d{2,4})\\/)"/i);
            if (!hrefMatch) continue;

            const relativeUrl = hrefMatch[1];
            const timeStr = hrefMatch[2];
            const day = hrefMatch[3];
            const month = hrefMatch[4];
            let year = hrefMatch[5];
            if (year.length === 2) year = '20' + year;
            const hour = timeStr.slice(0, 2);
            const min = timeStr.slice(2, 4);

            const matchPageUrl = 'https://tft-forests.org' + relativeUrl;

            let title = "";
            const titleAttrMatch = content.match(/title="([^"]+?)(?:\\s+lúc|\\s*$)/i);
            if (titleAttrMatch && titleAttrMatch[1]) {
              title = titleAttrMatch[1].trim();
            } else {
              const slugName = relativeUrl.replace(/^\\/truc-tiep\\//, '').replace(/-luc-\\d{4}-ngay-[\\d\\-]+\\/$/, '');
              title = slugName.replace(/-/g, ' ').replace(/\\b\\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');
            }

            let league = "Live Match";
            const leagueMatch = content.match(/class="grid-match__league"[^>]*>[\\s\\S]*?<span[^>]*>([\\s\\S]*?)<\\/span>/i);
            if (leagueMatch && leagueMatch[1]) {
              league = leagueMatch[1].replace(/<[^>]+>/g, '').trim();
            }

            const kickoffIso = year + '-' + month + '-' + day + 'T' + hour + ':' + min + ':00+07:00';
            const kickoffText = day + '/' + month + '/' + year + ', ' + hour + ':' + min + ' WIB';

            // Cari apakah sudah ada di AUTO_LIVE_DATASET dengan channel terverifikasi
            const existing = AUTO_LIVE_DATASET.find(a => a.postUrl === matchPageUrl || a.title.toLowerCase() === title.toLowerCase());
            const assignedCh = existing ? (existing.streamUrl.match(/channel[0-9a-zA-Z]+/i) || ['channel13'])[0] : channelPool[(poolIdx++) % channelPool.length];

            liveScraped.push({
              title,
              league,
              postUrl: matchPageUrl,
              streamUrl: 'https://xlz.domainkqt.cc/ajax/chanel/type/8/link/' + assignedCh,
              server2Url: 'https://xlz.domainkqt.cc/ajax/chanel/type/5/link/' + assignedCh,
              kickoffIso,
              kickoffText,
              sourceStatus
            });
          }

          if (liveScraped.length > 0) {
            renderMatchList(liveScraped);
          } else {
            tryFetchProxy(index + 1);
          }
        })
        .catch(err => {
          tryFetchProxy(index + 1);
        });
    }

    tryFetchProxy(0);
  }

  function initLivePortal`;

template = template.replace(oldFetchRegex, newFetchCode);

fs.writeFileSync('template-sportstream.xml', template);
fs.writeFileSync('preview.html', template);
console.log('Successfully updated template-sportstream.xml and preview.html!');
