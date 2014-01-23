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
        host: 'rdsqr7ne2m2ifjm.mysql.rds.aliyuncs.com'
        user: 'test2'
        password: 'xiaoweng51wangpi'
        # host: 'localhost'
        # user: 'root'
        # password: '57826502'
        port: 3306
        database: 'test2'

connection = getConnection()

c = new crawler.Crawler

    'headers':
        'Cookie': 'cna=NnHYCpjs31ACATonVlcvNAaP; tg=0; _cc_=Vq8l%2BKCLiw%3D%3D; tracknick=%5Cu6CE1%5Cu6CAB%5Cu2606%5Cu84DD%5Cu8336; _tb_token_=T6t1FP8DLim; uc1=cookie14=UoLU47zH%2BCGs3w%3D%3D; mt=ci=0_0; t=8c856cac8a6a0d00a73574e09195921f; cookie2=edf9076e51ff255cbe686887293054ba'

    'forceUTF8': true

    'maxConnections': 1

    'callback': (error, result, $) ->
        try
            urlParts = result.uri.split '##'
            storeName = urlParts[1]
            storeId = urlParts[2]
            seePrice = urlParts[3]

            cid = result.uri.match(/category-(\d+).htm/)[1]
            $('dl.item').each (index, element) ->
                $e = $(element)
                defaultImage = pureText $e.find('.photo img').attr('data-ks-lazyload')
                goodsName = $e.find('a.item-name').text()
                price = parsePrice(pureText $e.find('.c-price').text(), seePrice)
                goodHttp = $e.find('a.item-name').attr('href')

                # merge into database
                conn = getConnection()
                conn.query "call proc_merge_good('#{storeId}','#{defaultImage}','#{price}','#{goodHttp}','#{cid}','#{storeName}','#{goodsName}',@o_retcode)", (err, res) ->
                    conn.end()
                    if not err
                        resObj = res[0][0]
                        if resObj['o_retcode'] is -1
                            report "proc_merge_good error! parameter: '#{storeId}','#{defaultImage}','#{price}','#{goodHttp}','#{cid}','#{storeName}','#{goodsName}'"
                        else if resObj['o_retcode'] is 1
                            report "#{resObj['i_goods_name']} in #{resObj['i_store_name']} update successfully"
                        else if resObj['o_retcode'] is 2
                            report "#{resObj['i_goods_name']} in #{resObj['i_store_name']} insert successfully"
                    else
                        report err

                count++

            if fetchType is FETCH_TYPE.ALL
                $next = $('a.J_SearchAsync.next')
                if $next.length > 0
                    c.queue $next.attr('href') + "###{storeName}###{storeId}###{seePrice}"
                else
                    nextFlag = true
                    report "#{storeName}'s #{cid} finished."
            else if fetchType is FETCH_TYPE.SINGLE_PAGE
                nextFlag = true
                report "#{storeName}'s #{cid} finished."
        catch e
            report e

queueStore = (uri) ->
    c.queue [
        'uri': uri
        'callback': (err, result, $) ->
            try
                urlParts = result.uri.split '##'
                storeName = urlParts[1]
                storeId = urlParts[2]
                seePrice = urlParts[3]

                # fetch and update cate_content
                cateContent = $('ul.cats-tree').parent().html().trim().replace(/\"http.+category-(\d+).+\"/g, '"showCat.php?cid=$1&shop_id=' + storeId + '"').replace(/\r\n/g, '')
                conn = getConnection()
                conn.query "update ecm_store set cate_content='#{cateContent}' where store_id = #{storeId}", (err, res) ->
                    conn.end()
                    if err
                        report "!!!#{storeId} #{storeName}: failed!", err

                # fetch url
                urlArray = []
                $('a.cat-name').each () ->
                    href = this.href.replace(/\#.+/g, '') + '&orderType=newOn' + "###{storeName}###{storeId}###{seePrice}"
                    if fetchType is FETCH_TYPE.SINGLE_PAGE and href.indexOf(parsedArguments.cid) is -1 then return
                    if urlArray.indexOf(href, '') is -1 and href.indexOf('category-') isnt -1
                        urlArray.push href

                c.queue urlArray
            catch e
                try
                    report "#{result.uri}", e
                catch ee
                    report "result is undefined or result.uri is undefined", ee
    ]

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
                queueStore store['shop_http'] + "###{store['store_name']}###{store['store_id']}###{store['see_price']}"
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

report = (msg, err) ->
    if typeof msg is 'string' and not err?
        util.log msg
    else if typeof msg is 'object' and not err?
        util.log util.inspect(err, {depth: 4})
    else
        util.log msg + '::' + util.inspect(err, {depth: 4})
