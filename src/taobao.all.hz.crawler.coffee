util = require 'util'
crawler = require 'crawler'
mysql = require 'mysql'

FETCH_TYPE =
    SINGLE_PAGE: 0
    ALL: 1

parseArguments = (args) ->
    if args.length == 0
        type = FETCH_TYPE.ALL
    else if args.length == 2
        type = FETCH_TYPE.SINGLE_PAGE
        storeId = args[0]
        cid = args[1]
    argsObj =
        type: type
        storeId: storeId
        cid: cid

args = process.argv.slice(2)
parsedArguments = parseArguments args
fetchType = parsedArguments.type
count = 0
stores = []
nextFlag = true

getConnection = () ->
    mysql.createConnection
        # host: 'rdsqr7ne2m2ifjm.mysql.rds.aliyuncs.com'
        # user: 'test2'
        # password: 'xiaoweng51wangpi'
        # host: 'localhost'
        # user: 'root'
        # password: '57826502'
        # database: 'test2'
        host: 'rdsqr7ne2m2ifjm.mysql.rds.aliyuncs.com'
        user: 'wangpi51'
        password: '51374b78b104'
        database: 'wangpi51_hz'
        port: 3306

connection = getConnection()

c = new crawler.Crawler
    'method': 'POST'

    'headers':
        'Cookie': 'cna=S2WXC+fHUhYCAbSc2MWOXx5g; miid=3533271021856440951; ali_ab=180.156.216.197.1393591678240.9; ck1=; uc3=nk2=B02oN3Be6g%3D%3D&id2=UoCKFOIGhiM%3D&vt3=F8dHqRBjeDiNc5VkpI8%3D&lg2=URm48syIIVrSKA%3D%3D; lgc=donyzjz; tracknick=donyzjz; _cc_=WqG3DMC9EA%3D%3D; tg=0; lzstat_uv=229541500245354180|2185014@3203012@3201199@2945730@2948565@2798379@2043323@3045821@3035619@3296882@2468846@2581762@3328751@3258589@2945527@3241813@3313950; l=donyzjz::1393599356505::11; v=0; cookie2=2a6ef628bc4b0a1eac9c3e659d64c3b1; mt=ci=0_0; t=61e67613e903af98c4eedf4211a3ae5c; x=e%3D1%26p%3D*%26s%3D0%26c%3D0%26f%3D0%26g%3D0%26t%3D0%26__ll%3D-1; swfstore=92836; _tb_token_=ee7bead50136b; uc1=cookie14=UoLVYfWzqzKWiQ%3D%3D'

    'forceUTF8': true

    'maxConnections': 1

    'callback': (error, result, $) ->
        try
            if $('.cats-tree').length > 0
                isNewTemplate = true
                itemSelector = 'dl.item'
            else
                isNewTemplate = false
                itemSelector = 'div.item'

            if $('.item-not-found').length is 0
                urlParts = result.uri.split '##'
                storeName = urlParts[1]
                storeId = urlParts[2]
                seePrice = urlParts[3]

                $(itemSelector).each (index, element) ->
                    $e = $(element)
                    defaultImage = getDefaultImage isNewTemplate, $e
                    goodsName = getGoodsName isNewTemplate, $e
                    price = getPrice isNewTemplate, $e, seePrice
                    goodHttp = getGoodHttp isNewTemplate, $e
                    date = new Date()
                    dateTime = parseInt(date.getTime() / 1000)

                    if goodsName.indexOf('邮费') is -1 and goodsName.indexOf('运费') is -1 and goodsName.indexOf('淘宝网 - 淘！我喜欢') is -1
                        mergeIntoDB storeId, defaultImage, price, goodHttp, storeName, goodsName, dateTime
                        count++

                if fetchType is FETCH_TYPE.ALL
                    $next = $('a.J_SearchAsync.next')
                    if $next.length > 0
                        c.queue $next.attr('href') + "###{storeName}###{storeId}###{seePrice}"
                    else
                        nextFlag = true
                        report "#{storeName} is finished."
                else if fetchType is FETCH_TYPE.SINGLE_PAGE
                    nextFlag = true
                    report "#{storeName} is finished."
        catch e
            report e

storeSql = 'select store_id,store_name,shop_http,im_ww,see_price from ecm_store where state = 1 order by store_id'
if fetchType is FETCH_TYPE.SINGLE_PAGE then storeSql = "select store_id,store_name,shop_http,im_ww,see_price from ecm_store where state = 1 and store_id = '#{parsedArguments.storeId}' order by store_id"

connection.query storeSql, (err, res) ->
    handleStore = () ->
        if nextFlag
            nextFlag = false
            if stores.length > 0
                store = stores.shift()
                storeId = store['store_id']
                storeName = store['store_name']
                seePrice = store['see_price']
                c.queue store['shop_http'] + '/search.htm?search=y&orderType=newOn_desc' + "###{store['store_name']}###{store['store_id']}###{store['see_price']}"
            else
                return
        setTimeout handleStore, 1000

    connection.end()
    stores = res
    setTimeout handleStore, 1000

pureText = (txt) ->
    if txt? then txt.trim() else ''

parsePrice = (price, seePrice) ->
    rawPrice = parseFloat price
    if not seePrice? then return rawPrice.toFixed(2)
    if seePrice.indexOf('减半') isnt -1
        (rawPrice / 2).toFixed(2)
    else if seePrice.indexOf('减') is 0
        (rawPrice - parseFloat(seePrice.substr(1))).toFixed(2)
    else if seePrice is '实价'
        rawPrice.toFixed(2)
    else if seePrice.indexOf('*') is 0
        (rawPrice * parseFloat(seePrice.substr(1))).toFixed(2)
    else
        report "不支持该see_price: #{seePrice}"
        rawPrice

getGoodHttp = (isNewTemplate, $element) ->
    if isNewTemplate
        $element.find('a.item-name').attr('href')
    else
        $element.find('div.desc a').attr('href')

getPrice = (isNewTemplate, $element, seePrice) ->
    if seePrice is 'P'
        return getGoodsName().match(/P(\d+)/)[1]
    if isNewTemplate
        parsePrice pureText($element.find('.c-price').text()), seePrice
    else
        price = $element.find('div.price strong').text()
        parsePrice pureText(price.substr(0, price.length-1)), seePrice

getGoodsName = (isNewTemplate, $element) ->
    if isNewTemplate
        $element.find('a.item-name').text()
    else
        pureText $element.find('div.desc').text()

getDefaultImage = (isNewTemplate, $element) ->
    if isNewTemplate
        pureText $element.find('.photo img').attr('data-ks-lazyload')
    else
        pureText $element.find('div.pic img').attr('data-ks-lazyload')

mergeIntoDB = (storeId, defaultImage, price, goodHttp, storeName, goodsName, dateTime) ->
    conn = getConnection()
    conn.query "call proc_merge_good_all('#{storeId}','#{defaultImage}','#{price}','#{goodHttp}','#{storeName}','#{goodsName}','#{dateTime}',@o_retcode)", (err, res) ->
        conn.end()
        if not err
            resObj = res[0][0]
            if resObj['o_retcode'] is -1
                report "proc_merge_good error! parameter: '#{storeId}','#{defaultImage}','#{price}','#{goodHttp}','#{storeName}','#{goodsName}','#{dateTime}'"
            else if resObj['o_retcode'] is 1
                report "#{resObj['i_goods_name']} in #{resObj['i_store_name']} update successfully"
            else if resObj['o_retcode'] is 2
                report "#{resObj['i_goods_name']} in #{resObj['i_store_name']} insert successfully"
        else
            report err

report = (msg, err) ->
    if typeof msg is 'string' and not err?
        util.log msg
    else if typeof msg is 'object' and not err?
        util.log util.inspect(err, {depth: 4})
    else
        util.log msg + '::' + util.inspect(err, {depth: 4})
