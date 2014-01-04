fs = require 'fs'
util = require 'util'
crawler = require 'crawler'
mysql = require 'mysql'

count = 0

connection = mysql.createConnection
    host: 'localhost'
    port: 3306
    user: 'root'
    password: '57826502'
    database: 'test2'

c = new crawler.Crawler

    'headers':
        'Cookie': 'cna=NnHYCpjs31ACATonVlcvNAaP; tg=0; _cc_=Vq8l%2BKCLiw%3D%3D; tracknick=%5Cu6CE1%5Cu6CAB%5Cu2606%5Cu84DD%5Cu8336; _tb_token_=T6t1FP8DLim; uc1=cookie14=UoLU47zH%2BCGs3w%3D%3D; mt=ci=0_0; t=8c856cac8a6a0d00a73574e09195921f; cookie2=edf9076e51ff255cbe686887293054ba'

    'forceUTF8': true

    'maxConnections': 1

    'onDrain': () ->
        connection.end()
        report "total:#{count}"

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
                connection.query "call proc_merge_good('#{storeId}','#{defaultImage}','#{price}','#{goodHttp}','#{cid}','#{storeName}','#{goodsName}',@o_retcode)", (err, res) ->
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

            $next = $('a.J_SearchAsync.next')
            if $next.length > 0
                c.queue $next.attr('href') + "###{storeName}###{storeId}###{seePrice}"
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
                cateContent = $('ul.cats-tree').parent().html().replace(/\s+/g, '')
                connection.query "update ecm_store set cate_content='#{cateContent}' where store_id = #{storeId}", (err, res) ->
                    if err
                        report err, "!!!#{storeId} #{storeName}: failed!"

                # fetch url
                urlArray = []
                $('a.cat-name').each () ->
                    href = this.href.replace /\#.+/g, ''
                    if urlArray.indexOf(href, '') is -1
                        if href.indexOf('category-') isnt -1
                            urlArray.push href + "###{storeName}###{storeId}###{seePrice}"
                            #TODO: handle url

                c.queue urlArray
            catch e
                report "#{result.uri}", e
    ]

connection.query 'select store_id,store_name,shop_http,im_ww,see_price from ecm_store', (err, res) ->
    handleStore = (store) ->
        storeId = store['store_id']
        storeName = store['store_name']
        seePrice = store['see_price']
        queueStore store['shop_http'] + "###{store['store_name']}###{store['store_id']}###{store['see_price']}"

    handleStore store for store in res

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

report = (err, msg) ->
    if typeof err is 'string' and not msg?
        util.log err
    else
        msg ?= ''
        util.log msg + '::' + util.inspect err, {depth: 4}