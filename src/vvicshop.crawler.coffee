#
# usage: node vvicshop.crawler.js ../output/vvicshop.sql
#
#

crawler = require 'crawler'
fs = require 'fs'
util = require 'util'

args = process.argv.slice(2)
outputFile = args[0]
content = ''
counter = 0
page = 1
mainSellMap = {}
batchSize = 10

c = new crawler.Crawler

    'maxConnections': 20

    'onDrain': () ->
        fs.appendFileSync "#{outputFile}", content
        console.log 'All complete'

    'callback': (error, result, $) ->

        pureText = (txt) ->
            if txt? then $.trim txt else ''

        handleSeePrice = (price) ->
            if price is '五折' then '减半' else price

        isServiceAvailable = (serviceName) ->
            if services isnt '' and services.indexOf(serviceName) isnt -1 then '1' else '0'

        getWWFromUrl = (url) ->
            regex = /uid=(.+)&site/
            result = regex.exec url
            if result? and result.length > 1 then decodeURI(result[1]) else ''

        if result.uri.indexOf('tab') isnt -1
            $('.shopitem li').each (index, element) ->
                c.queue 'http://www.vvic.com/' + $(this).find('a').attr('href')
        else
            shopname = pureText $('div.profile .title').text()
            marketFloorDangkou = pureText($('div.profile li:first').text()).substr(3).split(' ')
            market = pureText $('div.profile li:first span').eq(0).text()
            floor = pureText $('div.profile li:first span').eq(1).text().replace('楼', '')
            dangkou = pureText $('div.profile li:first span').eq(2).text().replace('档', '')
            taobao = pureText $('div.profile li').eq(10).find('a').attr('href')
            dataPack = ''
            mobile = pureText $('div.profile li').eq(2).find('span').text()
            ww = getWWFromUrl(pureText $('div.profile li').eq(8).find('a').attr('href'))
            shopRange = if mainSellMap[shopname]? then pureText mainSellMap[shopname][0] else ''
            qq = pureText $('div.profile li').eq(3).find('span').text()
            services = pureText $('.services').text();
            price = handleSeePrice pureText($('div.profile li').eq(4).find('span').text())
            content += util.format """
                insert into ecm_store_gz (
                shop_mall,floor,address,store_name,see_price,
                im_qq,im_ww,tel,shop_http,has_link,
                serv_refund,serv_exchgoods,serv_sendgoods,serv_probexch,serv_deltpic,
                serv_modpic,shop_range,serv_golden,csv_http)
                values(
                '%s','%s','%s','%s','%s',
                '%s','%s','%s','%s','%s',
                '%s','%s','%s','%s','%s',
                '%s','%s','%s','%s');\n
                """,
                market, floor, dangkou, shopname, price,
                qq, ww, mobile, taobao, '0',
                isServiceAvailable('退现金'), isServiceAvailable('包换款'), isServiceAvailable('一件代发'), '', isServiceAvailable('细节实拍'),
                isServiceAvailable('实拍'), shopRange, isServiceAvailable('金牌档口'), dataPack

            console.log "#{++counter}.#{shopname} : complete"
            delete mainSellMap[shopname]
            if counter % batchSize is 0
              fs.appendFileSync "#{outputFile}", content
              content = ''
              console.log "content flushed."

c.queue [
    "http://www.vvic.com/tab13.html",
    "http://www.vvic.com/tab12.html",
    "http://www.vvic.com/tab3.html",
    "http://www.vvic.com/tab2.html",
    "http://www.vvic.com/tab6.html",
    "http://www.vvic.com/tab21.html",
    "http://www.vvic.com/tab18.html",
    "http://www.vvic.com/tab18.html",
    "http://www.vvic.com/tab15.html",
    "http://www.vvic.com/tab4.html",
    "http://www.vvic.com/tab10.html",
    "http://www.vvic.com/tab14.html",
    "http://www.vvic.com/tab19.html",
    "http://www.vvic.com/tab8.html",
    "http://www.vvic.com/tab11.html",
    "http://www.vvic.com/tab7.html",
    "http://www.vvic.com/tab5.html"
]
