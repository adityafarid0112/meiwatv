async function checkWpApi() {
  const url = 'https://tft-forests.org/wp-json/wp/v2/posts?per_page=50';
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const data = await res.json();
  console.log(`WP API returned ${data.length} posts!`);
  if (data.length > 0) {
    console.log('Sample item keys:', Object.keys(data[0]));
    console.log('Sample item title:', data[0].title);
    console.log('Sample item link:', data[0].link);
    console.log('Sample item date:', data[0].date);
  }
}

checkWpApi();
