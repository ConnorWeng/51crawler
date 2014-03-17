crawler = require 'crawler'

args = process.argv.slice(2)
url = args[0]
count = 0

c = new crawler.Crawler
    'headers':
        'Cookie': 'cna=S2WXC+fHUhYCAbSc2MWOXx5g; miid=3533271021856440951; ali_ab=180.156.216.197.1393591678240.9; ck1=; uc3=nk2=B02oN3Be6g%3D%3D&id2=UoCKFOIGhiM%3D&vt3=F8dHqRBjeDiNc5VkpI8%3D&lg2=URm48syIIVrSKA%3D%3D; lgc=donyzjz; tracknick=donyzjz; _cc_=WqG3DMC9EA%3D%3D; tg=0; lzstat_uv=229541500245354180|2185014@3203012@3201199@2945730@2948565@2798379@2043323@3045821@3035619@3296882@2468846@2581762@3328751@3258589@2945527@3241813@3313950; l=donyzjz::1393599356505::11; v=0; cookie2=2a6ef628bc4b0a1eac9c3e659d64c3b1; mt=ci=0_0; t=61e67613e903af98c4eedf4211a3ae5c; x=e%3D1%26p%3D*%26s%3D0%26c%3D0%26f%3D0%26g%3D0%26t%3D0%26__ll%3D-1; swfstore=92836; _tb_token_=ee7bead50136b; uc1=cookie14=UoLVYfWzqzKWiQ%3D%3D'

    'forceUTF8': true

    'callback': (error, result, $) ->
        count = $('div.search-result span').text().trim()
        console.log count
        process.exit(0);

c.queue url
