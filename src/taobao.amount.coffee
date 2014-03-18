crawler = require 'crawler'

args = process.argv.slice(2)
url = args[0]
count = 0

c = new crawler.Crawler
    'method': 'POST'

    'headers':
        'Cookie': 'cna=S2WXC+fHUhYCAbSc2MWOXx5g; miid=3533271021856440951; ali_ab=180.156.216.197.1393591678240.9; lzstat_uv=229541500245354180|2185014@3203012@3201199@2945730@2948565@2798379@2043323@3045821@3035619@3296882@2468846@2581762@3328751@3258589@2945527@3241813@3313950; l=donyzjz::1393599356505::11; ck1=; uc3=nk2=pkoYKu3%2BFhbpkw%3D%3D&id2=UoM7y5reHhM%3D&vt3=F8dHqREuFDZIO4SLS4w%3D&lg2=U%2BGCWk%2F75gdr5Q%3D%3D; lgc=%5Cu6CE1%5Cu6CAB%5Cu2606%5Cu84DD%5Cu8336; tracknick=%5Cu6CE1%5Cu6CAB%5Cu2606%5Cu84DD%5Cu8336; _cc_=VT5L2FSpdA%3D%3D; tg=0; mt=ci=23_1&cyk=0_2; pnm_cku822=005fCJmZk4PGRVHHxtEb3EtbnA3YSd%2FN2EaIA%3D%3D%7CfyJ6Zyd9OmIiYXAnZHIpZBU%3D%7CfiB4D15%2BZH9geTp%2FJyN8OzVqKw4OEABJWV5aa0I%3D%7CeSRiYjNhIHA1cGY2dWM4fGctdDZxMnZhNnFmOn1pLHw%2BYCVicyJ0Dw%3D%3D%7CeCVoaEAQTh5bAxRKEhZJEQxWaDMhIzJgcnQ8a2I4KjtpIg8m%7CeyR8C0gHRQBBBhVDGwxUFApVB0YZXwcWRwsBXBsBRAtOEVlwCw%3D%3D%7CeiJmeiV2KHMvangudmM6eXk%2BAA%3D%3D; x=e%3D1%26p%3D*%26s%3D0%26c%3D0%26f%3D0%26g%3D0%26t%3D0%26__ll%3D-1; swfstore=155167; cookie2=54cd55893d4cffb1b860454ebbb40e34; _tb_token_=f5146370be13e; t=61e67613e903af98c4eedf4211a3ae5c; uc1=cookie14=UoLVYB3OmHoLXA%3D%3D; v=0'

    'forceUTF8': true

    'callback': (error, result, $) ->
        count = $('div.search-result span').text().trim()
        if count? and count isnt '' then console.log count else console.log -1
        process.exit(0)

c.queue url
