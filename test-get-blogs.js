const fs = require('fs');
const path = require('path');

const credentialsPath = path.join(__dirname, 'client_secrets.json');
const tokenPath = path.join(__dirname, 'token.json');

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

async function listBlogs() {
  const token = await getAccessToken();
  console.log('Testing Blogger API token...');
  const res = await fetch('https://www.googleapis.com/blogger/v3/users/self/blogs', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const data = await res.json();
  console.log('Blogger users/self/blogs response:');
  console.log(JSON.stringify(data, null, 2));
}

listBlogs().catch(console.error);
