#
# usage: node 17zwd.crawler.js hz <max_page>
#        node 17zwd.crawler.js gz <max_page>
#

crawler = require 'crawler'
fs = require 'fs'
util = require 'util'

args = process.argv.slice(2)
region = args[0]
maxPage = args[1]
content = ''
counter = 0
page = 1
mainSellMap = {}

c = new crawler.Crawler

    'maxConnections': 20

    'onDrain': () ->
        fs.writeFileSync "../output/17zwd.#{region}", content
        console.log 'All complete'


    'callback': (error, result, $) ->

        pureText = (txt) ->
            if txt? then $.trim txt else ''

        isServiceAvailable = (serviceName) ->
            if services.indexOf serviceName isnt -1 then '1' else '0'

        $marketListItem = $('.market-list-item')

        if $marketListItem.length > 0
            $marketListItem.each (index, element) ->
                $e = $(element)
                shopname = pureText $e.find('.market-list-item-sname a').text()
                mainSell = pureText $e.find('.market-list-item-sells').text()
                mainSellMap[shopname] = mainSell
                c.queue "http://#{region}.17zwd.com/" + $e.find('.market-list-item-sname a').attr('href')
        else
            marketFloorDangkou = pureText($('.shopcontent-message li:first').text()).substr(3).split(' - ')
            market = pureText marketFloorDangkou[0]
            floor = pureText marketFloorDangkou[1]
            dangkou = pureText marketFloorDangkou[2]
            taobao = pureText $('.shopcontent-connection li').eq(0).find('a').eq(0).attr('href')
            dataPack = pureText $('.shopcontent-connection li').eq(0).find('a').eq(2).attr('href')
            mobile = pureText $('.shopcontent-connection li').eq(1).text()
            ww = pureText $('.shopcontent-connection li').eq(2).text()
            qq = pureText $('.shopcontent-connection li').eq(3).text()
            services = pureText $('.shopcontent-tsfw li').eq(1).text()
            price = pureText $.trim($('.shopcontent-message li').eq(1).text()).substr(3)
            shopname = pureText $('span.shopname-span').text()
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
                '%s','%s','%s','%s');
                """,
                market, floor, dangkou, shopname, price,
                qq, ww, mobile, taobao, '0',
                isServiceAvailable('退现金'), isServiceAvailable('包换款'), isServiceAvailable('一件代发'), '', isServiceAvailable('细节实拍'),
                isServiceAvailable('模特实拍'), pureText(mainSellMap[shopname]), isServiceAvailable('金牌档口'), dataPack

            console.log "#{++counter}.#{shopname} : complete"
            delete mainSellMap[shopname]

while page < maxPage
    c.queue "http://#{region}.17zwd.com/market.aspx?page=#{page++}"
