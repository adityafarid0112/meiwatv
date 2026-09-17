async function dumpPlayerHtml() {
    const url = 'https://xlz.domainkqt.cc/ajax/chanel/type/7/link/channel20/off-tvc?is_off_add=false';
    const res = await fetch(url, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://tft-forests.org/'
        }
    });
    const html = await res.text();
    console.log('--- Full HTML of channel 20 ---');
    console.log(html);
}
dumpPlayerHtml();
