async function testImg() {
  const homeTeamId = "vjxm8ghjyd1r6od";
  const url = `https://imgts.sportpulseapiz.com/football/team/${homeTeamId}/image/small`;
  try {
    const res = await fetch(url);
    console.log('Status for team logo url:', res.status, res.headers.get('content-type'), url);
  } catch (e) {
    console.log('Error:', e.message);
  }
}
testImg();
