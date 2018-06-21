--
-- Author: Liuq
-- Date: 2016-04-15 01:21:40
--
local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"

function response.getuserbyid(uid)
	local db = mongo.client({host = host})

	db[db_name].testdb:dropIndex("*")
	db[db_name].testdb:drop()

	local ret = db[db_name].testdb:findOne({test_key = 1})
	assert(ret and ret.test_key == 1)
	
end