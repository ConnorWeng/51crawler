#
# usage: node taobao.ecmall.js <storeId> <cid> <outputFile>
#        node taobao.ecmall.js <outputFile>
#
util = require 'util'
crawler = require 'crawler'
mysql = require 'mysql'

FETCH_TYPE =
    SINGLE_PAGE: 0
    ALL: 1

parseArguments = (args) ->
    if args.length == 1
        type = FETCH_TYPE.ALL
        outputFile = args[0]
    else if args.length == 3
        type = FETCH_TYPE.SINGLE_PAGE
        storeId = args[0]
        cid = args[1]
        outputFile = args[2]
    argsObj =
        type: type
        storeId: storeId
        cid: cid
        outputFile: outputFile

args = process.argv.slice(2)
parsedArguments = parseArguments args
fetchType = parsedArguments.type
outputFile = parsedArguments.outputFile
count = 0
stores = []
nextFlag = true

getConnection = () ->
    mysql.createConnection
        # host: 'rdsqr7ne2m2ifjm.mysql.rds.aliyuncs.com'
        # user: 'test2'
        # password: 'xiaoweng51wangpi'
        host: 'localhost'
        user: 'root'
        password: '57826502'
        port: 3306
        database: 'ecmall'

connection = getConnection()

c = new crawler.Crawler

    'headers':
        'Cookie': 'v=0; cna=MducCx8MKHsCAXTufkeemcwX; mt=ci%3D0_0; cookie2=96d64c9c38951a732fbaf3aea12dd2da; t=22bc108d7a9e3d3688e85700c4ffccd9; pnm_cku822=095WsMPac%2FFS4KgNn94nvw9Wm70ODBULv%2B84c4%3D%7CWUCLjKhqo9Lm%2FfJ1ccsWeSQ%3D%7CWMEKRlVG2DtUY3lc7%2BUsT237sjg%2FK64XSg%3D%3D%7CX0YLbX78NUR3aqcgpAbHqJAMQ6V25Fk2A5gWUWXXNlNlf%2FLVwcu5%7CXkdILojyXz4MFd7ZvediAziDmrVHgwVkAB%2FGyX68IfbU%2B%2BM%3D%7CXUeMwNRe85KrMv6YnBbDoo6Um9yo8jNCcOgjJNdt0Ie2q6YBsjCN5Nzz6w%3D%3D%7CXMYK7F8liOvH3hMUpzXkiaU%2FJw%3D%3D; _tb_token_=hS96Ba65n; uc1=cookie14=UoLVZqA23zK9Yg%3D%3D'

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
                goodHttp = $e.find('a.item-name').attr('href')
                defaultImage = pureText $e.find('.photo img').attr('data-ks-lazyload')
                goodsName = $e.find('a.item-name').text()
                description = goodHttp.substr(goodHttp.lastIndexOf('id=') + 3)
                cateName = ''
                price = parsePrice pureText($e.find('.c-price').text()), seePrice

                conn = getConnection()
                conn.query "call proc_add_good('#{storeId}', '#{goodsName}', '#{description}', '#{defaultImage}', '#{price}', @o_retcode)", (err, res) ->
                    conn.end()
                    if not err
                        resObj = res[0][0]
                        if resObj['o_retcode'] is 0
                            report "#{resObj['i_description']} - succeed"
                        else if resObj['o_retcode'] is 1
                            report "#{resObj['i_description']} - already exists."
                        else if resObj['o_retcode'] is -1
                            report 'failed to add good'
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
