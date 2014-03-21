util = require 'util'
mysql = require 'mysql'

args = process.argv.slice(2)

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
        database: 'wangpi51'
        port: 3306

connection = getConnection()

connection.query args[0], (err, res) ->
    connection.end()
    report "result is: ", res

report = (msg, err) ->
    if typeof msg is 'string' and not err?
        util.log msg
    else if typeof msg is 'object' and not err?
        util.log util.inspect(err, {depth: 4})
    else
        util.log msg + '::' + util.inspect(err, {depth: 4})
