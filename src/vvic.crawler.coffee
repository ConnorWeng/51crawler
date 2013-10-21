#
# usage: node vvic.crawler.js hz <max_page> <output_directory>
#        node vvic.crawler.js gz <max_page> <output_directory>
#

crawler = require 'crawler'
fs = require 'fs'
util = require 'util'

args = process.argv.slice(2)
region = args[0]
regionChinese = if region is 'hz' then '杭州' else '广州'
maxPage = args[1]
outputDirectory = args[2]
content = ''
counter = 0
page = 1
mainSellMap = {}

c = new crawler.Crawler

    'maxConnections': 20

    'onDrain': () ->
        fs.writeFileSync "#{outputDirectory}vvic.#{region}", content
        console.log 'All complete'


    'callback': (error, result, $) ->

        pureText = (txt) ->
            if txt? then $.trim txt else ''

        isServiceAvailable = (serviceName) ->
            if services isnt '' and services.indexOf(serviceName) isnt -1 then '1' else '0'

        getWWFromUrl = (url) ->
            regex = /uid=(.+)&site/
            result = regex.exec url
            if result.length > 1 then decodeURI(result[1]) else ''

        $marketListItem = $('li.list-item')

        if $marketListItem.length > 0
            $marketListItem.each (index, element) ->
                $e = $(element)
                shopname = pureText $e.find('.list-info h4 a').text()
                if shopname isnt ''
                    mainSell = pureText $e.find('.list-info p:first span').text()
                    ww = getWWFromUrl(pureText $e.find('.shop-info-list a:first').attr('href'))
                    mainSellMap[shopname] = [mainSell, ww]
                    c.queue "http://www.vvic.com/" + $e.find('.list-info h4 a').attr('href')
        else
            shopname = pureText $('div.profile .title').text()
            marketFloorDangkou = pureText($('div.profile li:first').text()).substr(3).split(' ')
            market = pureText $('div.profile li:first span').eq(0).text()
            floor = pureText $('div.profile li:first span').eq(1).text()
            dangkou = pureText $('div.profile li:first span').eq(2).text()
            taobao = pureText $('div.profile li').eq(10).find('a').attr('href')
            dataPack = ''
            mobile = pureText $('div.profile li').eq(2).find('span').text()
            ww = if mainSellMap[shopname]? then pureText mainSellMap[shopname][1] else ''
            shopRange = if mainSellMap[shopname]? then pureText mainSellMap[shopname][0] else ''
            qq = pureText $('div.profile li').eq(3).find('span').text()
            services = pureText $('.services').text();
            price = pureText $('div.profile li').eq(4).find('span').text()
            content += util.format """
                insert into ecm_store_#{region} (
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
                isServiceAvailable('模特实拍'), shopRange, isServiceAvailable('金牌档口'), dataPack

            console.log "#{++counter}.#{shopname} : complete"
            delete mainSellMap[shopname]

while page <= maxPage
    c.queue "http://www.vvic.com/store.htm?shop.city=#{regionChinese}&currentPageNumber=#{page++}"
