#
# usage: node cell001.crawler.js hz
#
# update ecm_store s, ecm_store_new n set s.shop_mall = n.shop_mall, s.floor = n.floor, s.address = n.address, s.store_name = n.store_name, s.see_price = n.see_price, s.tel = n.tel, s.shop_http = n.shop_http, s.serv_refund = n.serv_refund, s.serv_exchgoods = n.serv_exchgoods, s.serv_sendgoods = n.serv_sendgoods, s.serv_probexch = n.serv_probexch, s.serv_deltpic = n.serv_deltpic, s.serv_modpic = n.serv_modpic, s.shop_range = n.shop_range, s.serv_golden = n.serv_golden, s.csv_http = n.csv_http where s.im_ww = n.im_ww;
#
# create table tmp_ecm_store select t.store_id from ecm_store t where t.store_id not in (select s.store_id from ecm_store s, ecm_store_new n where s.im_ww = n.im_ww);
#
# delete from ecm_store where store_id in (select store_id from tmp_ecm_store);
#
# drop table tmp_ecm_store;
#
# insert into ecm_store(shop_mall,floor,address,store_name,see_price,im_qq,im_ww,tel,shop_http,has_link,serv_refund,serv_exchgoods,serv_sendgoods,serv_probexch,serv_deltpic,serv_modpic,shop_range,serv_golden,csv_http) select shop_mall,floor,address,store_name,see_price,im_qq,im_ww,tel,shop_http,has_link,serv_refund,serv_exchgoods,serv_sendgoods,serv_probexch,serv_deltpic,serv_modpic,shop_range,serv_golden,csv_http from ecm_store_new where store_id not in (select store_id from ecm_store);
#
# delete from ecm_goods where store_id not in (select store_id from ecm_store);
#
# insert into ecm_store(shop_mall,floor,address,store_name,see_price,im_qq,im_ww,tel,shop_http,has_link,serv_refund,serv_exchgoods,serv_sendgoods,serv_probexch,serv_deltpic,serv_modpic,shop_range,serv_golden,csv_http) select shop_mall,floor,address,store_name,see_price,im_qq,im_ww,tel,shop_http,has_link,serv_refund,serv_exchgoods,serv_sendgoods,serv_probexch,serv_deltpic,serv_modpic,shop_range,serv_golden,csv_http from ecm_store_new where shop_http not in (select shop_http from ecm_store);
#
# update ecm_store set state = 1;

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
        console.log "services: #{services}, #{serviceName}, #{services.indexOf(serviceName)}"
        if services isnt '' and services.indexOf(serviceName) isnt -1 then '1' else '0'

      extractWWFromUrl = (url) ->
        group = url.match /touid=(.+)&siteid/
        if group.length > 1 then decodeURI group[1] else ''

      $marketListItem = $('div.dk')

      if $marketListItem.length > 0
        $marketListItem.each (index, element) ->
          $e = $(element)
          c.queue $e.find('.sh a').eq(0).attr('href') + '#' + $('.filter-unit-l').text() + '#' + $e.closest('.unit').find('.unit-hd').text()
      else
        console.log '-------------------------'
        console.log result.uri
        marketFloorDangkou = result.uri.split('#').slice(1)
        market = pureText marketFloorDangkou[0]
        console.log market
        floor = pureText marketFloorDangkou[1]
        console.log floor
        dangkou = pureText $('.dk a').text()
        console.log dangkou
        taobao = pureText $('ul.menu-list li').eq(1).find('a').attr('href')
        console.log taobao
        dataPack = $('.fw .download').attr('href')
        console.log dataPack
        mobile = pureText $('li.kd').prev().text().split('：')[1]
        console.log mobile
        ww = pureText $('.sub_wrap li:eq(1) a:eq(0)').text()
        console.log ww
        qq = ''
        services = pureText $('.fw').text()
        price = 'P'
        shopname = pureText $('.store_name a').text()
        console.log shopname
        mainSell = pureText $('li.kd').prev().prev().text().split('：')[1]
        console.log mainSell
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
  "http://sell001.com/market.htm?kid=15",
  "http://sell001.com/market.htm?kid=16",
  "http://sell001.com/market.htm?kid=17"]
