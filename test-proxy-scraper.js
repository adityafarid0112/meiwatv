const fs = require('fs');

async function testScraperWithProxy() {
  const proxyList = [
    'https://cors.eu.org/https://tft-forests.org/',
    'https://corsproxy.org/?' + encodeURIComponent('https://tft-forests.org/')
  ];

  let rawHtml = '';
  for (const p of proxyList) {
    try {
      console.log('Trying proxy:', p);
      const res = await fetch(p, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (res.ok) {
        rawHtml = await res.text();
        console.log('Successfully fetched via proxy! Length:', rawHtml.length);
        break;
      }
    } catch (e) {
      console.log('Proxy error:', e.message);
    }
  }

  if (!rawHtml) {
    console.error('All proxies failed.');
    return;
  }

  const slugRegex = /\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{2,4})\//gi;
  const allSlugs = [...new Set(rawHtml.match(slugRegex) || [])];
  console.log(`Found ${allSlugs.length} unique slugs from proxy scrape!`);

  const now = new Date().getTime();
  const liveList = [];
  const upcomingList = [];

  allSlugs.forEach(slug => {
    const match = slug.match(/\/truc-tiep\/([a-z0-9\-]+)-luc-(\d{4})-ngay-(\d{2})-(\d{2})-(\d{2,4})\//i);
    if (!match) return;

    const slugName = match[1];
    const timeStr = match[2];
    const day = match[3];
    const month = match[4];
    let year = match[5];
    if (year.length === 2) year = '20' + year;

    const hour = timeStr.slice(0, 2);
    const min = timeStr.slice(2, 4);

    const kickoffIso = `${year}-${month}-${day}T${hour}:${min}:00+07:00`;
    const kickoffText = `${day}/${month}/${year}, ${hour}:${min} WIB`;
    const kickoffTime = new Date(kickoffIso).getTime();
    if (isNaN(kickoffTime)) return;

    const diff = kickoffTime - now;

    let status = 2;
    if (diff <= 0 && diff >= -7200000) {
      status = 0; // LIVE
    } else if (diff > 0) {
      status = 1; // UPCOMING
    } else {
      status = 2; // SELESAI
    }

    if (status === 2) return; // Skip finished

    const rawTitle = slugName.replace(/-/g, ' ');
    const title = rawTitle.replace(/\b\w/g, l => l.toUpperCase()).replace(/ Vs /g, ' vs ');

    const item = {
      title,
      kickoffIso,
      kickoffText,
      kickoffTime,
      diff,
      status
    };

    if (status === 0) liveList.push(item);
    else upcomingList.push(item);
  });

  upcomingList.sort((a, b) => a.kickoffTime - b.kickoffTime);

  console.log(`\n=== 🔴 REALTIME LIVE MATCHES (${liveList.length}) ===`);
  liveList.forEach(m => console.log(`- ${m.title} (${m.kickoffText})`));

  console.log(`\n=== ⏳ REALTIME UPCOMING MATCHES (${upcomingList.length}) ===`);
  upcomingList.slice(0, 10).forEach(m => console.log(`- ${m.title} (${m.kickoffText})`));
}

testScraperWithProxy();
