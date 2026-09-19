const fs = require('fs');
const path = require('path');

const credentialsPath = path.join(__dirname, 'client_secrets.json');
const tokenPath = path.join(__dirname, 'token.json');
const BLOG_ID = '8531123332112355973';

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

async function testCreatePost() {
  const token = await getAccessToken();
  console.log('Testing creating a post...');

  const postBody = {
    kind: 'blogger#post',
    title: 'Inter Miami vs Cruz Azul - CONCACAF Champions Cup',
    content: `<div id="stream-meta" 
     data-streamurl="https://xlz.domainkqt.cc/ajax/chanel/type/8/link/channel21/off-tvc?is_off_add=false" 
     data-server2="https://xlz.domainkqt.cc/ajax/chanel/type/5/link/channel-21/off-tvc?is_off_add=false"
     data-kickoff="2026-09-17T07:00:00+07:00" 
     data-kickoff-text="17/09/2026, 07:00 WIB" 
     data-league="CONCACAF Champions Cup">
</div>
<div style="background: #111826; border-radius: 12px; padding: 20px; color: #fff; text-align: center;">
  <h2>Inter Miami vs Cruz Azul</h2>
  <p>Kickoff: 17/09/2026, 07:00 WIB</p>
</div>`,
    labels: ['CONCACAF Champions Cup', 'Live Now', 'Xoilac']
  };

  const res = await fetch(`https://www.googleapis.com/blogger/v3/blogs/${BLOG_ID}/posts/`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(postBody)
  });

  const data = await res.json();
  console.log('Response status:', res.status);
  console.log('Response body:', JSON.stringify(data, null, 2));
}

testCreatePost().catch(console.error);
