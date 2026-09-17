const fs = require('fs');
const path = require('path');

const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'live-matches.json'), 'utf8'));

// Format into a clean, lightweight JS array of matches
const cleanMatches = data.slice(0, 30).map(m => ({
  title: m.title,
  league: m.league,
  streamUrl: m.streamUrl || `${m.matchPageUrl}link/0`,
  server2Url: m.server2Url || `${m.matchPageUrl}link/1`,
  postUrl: m.matchPageUrl,
  kickoffIso: m.kickoffIso,
  kickoffText: m.kickoffText,
  status: m.status
}));

fs.writeFileSync(path.join(__dirname, 'compact-matches.json'), JSON.stringify(cleanMatches, null, 2), 'utf8');
console.log(`Generated ${cleanMatches.length} compact matches!`);
