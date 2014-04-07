#
# usage: node cell001.crawler.js hz
#

crawler = require 'crawler'
fs = require 'fs'
util = require 'util'

args = process.argv.slice(2)
region = args[0]
content = ''
counter = 0

c = new crawler.Crawler

    'maxConnections': 20

    'onDrain': () ->
      fs.writeFileSync "../output/sell001.#{region}", content
      console.log 'All complete'

    'callback': (error, result, $) ->

      if error
        console.log error
        return

      pureText = (txt) ->
        if txt? then $.trim txt else ''

      isServiceAvailable = (serviceName) ->
        if services isnt '' and services.indexOf(serviceName) isnt -1 then '1' else '0'

      extractWWFromUrl = (url) ->
        group = url.match /touid=(.+)&siteid/
        if group.length > 1 then decodeURI group[1] else ''

      $marketListItem = $('div.dk')

      if $marketListItem.length > 0
        $marketListItem.each (index, element) ->
          $e = $(element)
          c.queue 'http://sell001.com/' + $e.find('.sh a').eq(0).attr('href') + '#' + $('.filter-unit-l').text() + '#' + $e.closest('.unit').find('.unit-hd').text()
      else
        marketFloorDangkou = result.uri.split('#').slice(1)
        market = pureText marketFloorDangkou[0]
        floor = pureText marketFloorDangkou[1]
        dangkou = pureText $('.shop_dk a').text()
        taobao = pureText $('ul.menu-list li').eq(1).find('a').attr('href')
        dataPack = pureText $('ul.menu-list li').eq(2).find('a').attr('href')
        mobile = pureText $('.shop_zl_m > ul > li').eq(5).text().split('：')[1]
        ww = pureText extractWWFromUrl($('.shop_zl_m > ul > li').eq(2).find('a').attr('href'))
        qq = ''
        services = pureText $('li.tuihuan').text()
        price = 'P'
        shopname = pureText $('.shop_zl_m > ul > li').eq(1).text().split('：')[1] + dangkou
        mainSell = pureText $('.shop_zl_m > ul > li').eq(6).text().split('：')[1]
        content += util.format """
          insert into ecm_store_new (
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
          isServiceAvailable('可退'), isServiceAvailable('可换款'), isServiceAvailable('一件代发'), '', isServiceAvailable('细节实拍'),
          isServiceAvailable('模特实拍'), mainSell, isServiceAvailable('金牌档口'), dataPack

        console.log "#{++counter}.#{shopname} : complete"

c.queue [
  "http://sell001.com/market.htm?kid=1",
  "http://sell001.com/market.htm?kid=2",
  "http://sell001.com/market.htm?kid=3",
  "http://sell001.com/market.htm?kid=4",
  "http://sell001.com/market.htm?kid=5",
  "http://sell001.com/market.htm?kid=6",
  "http://sell001.com/market.htm?kid=7",
  "http://sell001.com/market.htm?kid=8",
  "http://sell001.com/market.htm?kid=9",
  "http://sell001.com/market.htm?kid=10",
  "http://sell001.com/market.htm?kid=11",
  "http://sell001.com/market.htm?kid=12",
  "http://sell001.com/market.htm?kid=13",
  "http://sell001.com/market.htm?kid=99"]
