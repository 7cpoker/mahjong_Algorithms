local inspect = require "inspect"
local skynet = require "skynet"
local M = {}

ORI_DECK = {}
for i=1,9 do
	table.insert(ORI_DECK,0x10 + i)
end
for i=1,9 do
	table.insert(ORI_DECK,0x20 + i)
end
for i=1,9 do
	table.insert(ORI_DECK,0x30 + i)
end
for i=1,7 do
	table.insert(ORI_DECK,0x40 + i)
end

local HU = 4
--胡牌类型(番型)
local HU_TYPE = {
	SAN_BAI_DA 			= 1 ,--三百搭
	DAN_DIAO			= 3 ,--单吊
	QING_ONE_SUIT 		= 11,--清一色
	MIX_ONE_SUIT 		= 12,--混一色
	DUI_DUI_HU 			= 13,--对对胡
	NOT_BAI_DA 			= 14,--无百搭
	QI_XIAO_DUI			= 15,--七小对
	QUAN_LAO_TOU  		= 16,--全老头
}


--台型(抬头胡限制必有牌型)
local DUI_DUI_HU = 1
local MIX_ONE_SUIT = 2 --混一色
local QING_ONE_SUIT = 3 --清一色
local QUAN_LAO_TOU  = 4 --全老头

--台型
local TAI_XING = {
	HONG_ZHONG_KE 	= 1,
	FA_CAI_KE 		= 2,
	BAI_BAN_KE 		= 3,
	MEN_FENG 		= 4,
	NOT_BAI_DA 		= 5,
	DUI_DUI_HU 		= 6,
	MIX_ONE_SUIT 	= 7,
	QING_ONE_SUIT 	= 8,
	QUAN_LAO_TOU  	= 9,
	QUAN_FENG		= 10 
}

local YING_ZI_MO = {}
local TAI_TOU_HU = {}
local CHU_DIAN_HU = {}
YING_ZI_MO.FAN_XING_SCORE = { 2,1,1,1,5,4,1,1,1,1,2,1,1,1,1,3}
TAI_TOU_HU.FAN_XING_SCORE = {1,1,1,1,2,2,1,1,1,1,0,0,0,0,0,0} --番型,番
CHU_DIAN_HU.FAN_XING_SCORE = { 2,1,1,1,5,4,0,0,0,0,2,1,1,1,1}
TAI_TOU_HU.TAI_XING_SCORE = {1,1,1,1,1,2,2,4,10,1} -- 台型分

function table_copy_table(ori_tab)
	if (type(ori_tab) ~= "table") then
		return nil
	end
	local new_tab = {}
	for i,v in pairs(ori_tab) do
		local vtyp = type(v)
		if (vtyp == "table") then
			new_tab[i] = table_copy_table(v)
		elseif (vtyp == "thread") then
			new_tab[i] = v
		elseif (vtyp == "userdata") then
			new_tab[i] = v
		else
			new_tab[i] = v
		end
	end
	return new_tab
end





function M:sort_card(t)
	skynet.error(inspect(t))
		if not t then
			--return
		end

		table.sort(t, function(a,b)
			local sa,ra = a%16,math.floor(a/16)
			local sb,rb = b%16,math.floor(b/16)
			if ra == rb then
				return sa < sb
			else
				return ra < rb
			end
			
		end)
end

function M:get_type(c)
	return math.floor(c/16)
end

function M:get_value(c)
	return c%16
end

function M:add(t,c)
	if type(c) == "table" then
		for _,v in ipairs(c) do
			table.insert(t,v)
		end
	else
		table.insert(t,c)
	end
	--t.issorted = false
end

function M:remove_gang(newCards)
	-- body
	local cards = {}
	for i,v in ipairs(newCards) do
		table.insert(cards,v)
	end

	local i = 0
	while(i < #cards - 3) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		local c = cards[i+2]
		local d = cards[i+3]
		if a == b and b == c and c == d then	
			table.remove(cards,i + 3)
			table.remove(cards,i + 2)
			table.remove(cards,i + 1)
			table.remove(cards,i)	
			i = i - 1
		end
	end

	return cards
end

-- 移除碰
function M:remove_peng( newCards )

	local cards = {}
	for i,v in ipairs(newCards) do
		table.insert(cards,v)
	end


	local i = 0
	while(i < #cards - 2) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		local c = cards[i+2]
		if a == b and b == c then	
			table.remove(cards,i + 2)
			table.remove(cards,i+1)
			table.remove(cards,i)	
			i = i - 1
		end
	end

	return cards
end
-- 移除dui
function M:remove_dui( newCards )

	local cards = {}
	for i,v in ipairs(newCards) do
		table.insert(cards,v)
	end


	local i = 0
	while(i < #cards - 1) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		if a == b then	
			table.remove(cards,i+1)
			table.remove(cards,i)	
			i = i - 1
		end
	end

	return cards
end

function M:check_duidui_hu(set,vars)
	local cards = self:remove_peng(set)
	--print(inspect(cards))
	local bd_cards = {}
	if #vars >= 3 then
		--bd_cards = self:remove_peng(bd_cards)
	end
	local var_to_card = {}

	for k,v in pairs(cards) do
		if not bd_cards[v] then
			bd_cards[v] = 1
		else
			bd_cards[v] = bd_cards[v] + 1

		end
	end
	local need_num = 0
	local duizi = true
	for k,v in pairs(bd_cards) do
		if duizi then
			local need = (2 - v)
			need_num = need
			if need > 0 then
				for i=1,need do
					table.insert(var_to_card,k)
				end
			end
			duizi = false
		else
			local need = (3 - v)
			need_num = need_num + need
			if need > 0 then
				for i=1,need do
					table.insert(var_to_card,k)
				end
			end
		end
	end
	if need_num <= #vars then
		return true,var_to_card
	end
	return false,{}
end

--对对胡
function M:dui_dui_hu(set)

	cards = self:remove_gang(set)
	
	cards = self:remove_peng(cards)

	if #cards == 2 then 
		if cards[1] == cards[2] then
			return true
		end
	end

	cards = self:remove_peng(set)

	if #cards == 2 then 
		if cards[1] == cards[2] then
			return true
		end
	end

	return false
end


function M:seven_dui(set)
	if #set ~= 14 then
		return false
	end

	local cards = {}
	for i,v in ipairs(set) do
		table.insert(cards,v)
	end

	cards = M:remove_dui(cards)

	if #cards == 0 then
		return true
	end
	return false
end

--检测清一色,混一色
function M:qing_yi_se(set)
	local color
	for _,v in pairs(set) do
		if not color then
			color = self:get_type(v)
		end
		if color ~= self:get_type(v) or self:get_type(v) == 4 then
			return false
		end
	end
	return true
end

--是否混一色
function M:hun_yi_se(set)
	local color1 = {}
	local color2 = {}
	for i,v in ipairs(set) do
		local color = self:get_type(v)
		if color == 4 then
			table.insert(color1,color)
		else
			table.insert(color2,color)
		end
	end
	if #color1 > 0 and #color2 > 0 then
		if color2[1] == color2[#color2] then
			return true
		end
	end
	
	return false
end
--全老头
function M:quan_lao_tou(set)
	for _,v in pairs(set) do
		if self:get_type(v) ~= 4 then
			return false
		end
	end
	return true
end

function M:remove_straight(t)
		if not t then
			print("remove_straight t is nil")
			return
		end
		if #t%3 ~= 0 and #t == 0 then
			print("remove_straight t is error,t is")
			return
		end
		local ret = {}
		for i=1,#t - 2 do
			if self:get_type(t[i]) == 4 then
				break
			end
			local found1
			local found2
			local position = {}
			table.insert(position,i)
			for k = i,#t do
				if not found1 and t[i] + 1 == t[k] then
					found1  = true 
					table.insert(position,k)
				end 

				if not found2 and t[i] + 2 == t[k] then
					found2  = true 
					table.insert(position,k)
				end 

				if found2 and found1 then
					break
				end
			end
			if found2 and found1 then
				for i = #position,1,-1 do
					table.insert(ret,table.remove(t,position[i]))
				end
				return true,ret
			end
		end
end

function M:remove_three_same(t)
		if not t then
			print("remove_three_same t is nil")
			return
		end
		if #t%3 ~= 0 and #t == 0 then
			print("remove_three_same 参数错误",inspect(t))
			return 
		end
		local found = false
		local begin
		for i=1,#t - 2 do
			if t[i] == t[i + 1] and t[i] == t[i + 2] then
				found = true
				begin = i
				break
			end
		end

		if found then
			local ret = {}
			for k=1,3 do
				table.insert(ret,table.remove(t,begin))
			end
			return true,ret
		end
end

function M:check_3n(set)
		if not set then
			print("check_3n set is nil")
			return
		end
		if #set%3 ~= 0 then
	 		print("check_3n 参数错误,参数为",inspect(t))
			return
		end
		self:sort_card(set)
		local t1 = table_copy_table(set)
		local t2 = table_copy_table(set)
		if self:remove_three_same(t1) then
			if #t1 == 0 or self:check_3n(t1)then
				return true
			end
		end

		if self:remove_straight(t2) then
			if #t2 == 0 or self:check_3n(t2) then
				return true
			end
		end
		return false
end

function M:check_hu(set)
	if not set then
		print("set  is nil")
		return false
	end
	if (#set)%3 ~= 2 then
	 	print("check_hu 参数错误,参数为",inspect(t))
		return false
	end


	self:sort_card(set)
	for i=1,#set - 1 do
		if set[i] == set[i + 1]  then
			while i + 2 <= #set and set[i + 1] == set[i + 2] do
				i = i + 1
			end
			local check = {}
			for k = 1,#set do
				if k ~= i and k ~= i + 1 then
					table.insert(check,set[k])
				end
			end
			if #check == 0 or self:check_3n(check) then
				return HU
			end
		end
	end
end

function M:check_hu_var(ori_set,bai_da,seven_dui)
	if (#ori_set) %3 ~= 2 then
		return
	end
	function check_by_splice(set,vars)
		if (#set + #vars)%3 ~= 0 then
			return false
		end
		
		function splice_by_type(set)
			local t = {[1] = {},[2] = {},[3] = {},[4] = {}}
			--skynet.error("splice_by_type",set)
			for i,v in ipairs(set) do
				table.insert(t[v>>4],v)
			end
			return t
		end
		local t = splice_by_type(set)
		if (3 - #t[1]%3)%3 + (3 - #t[2]%3)%3 + (3 - #t[3]%3)%3 + (3 - #t[4]%3)%3>= 4 then
			return false
		end
		local success = {false,false,false,false}
		local var_to_card = {}		--百变牌变为的牌
		for i,v in ipairs(t) do
			if (3 - #t[i]%3)%3 == 0 then
				if #t[i] == 0 or self:check_3n(t[i]) then
					success[i] = true
				end
			end

			if (3 - #t[i]%3)%3 == 1 then
				for k=1,9 do
					local _t = table_copy_table(t[i])
					if not ORI_DECK[(i-1)*9 + k] then
						break
					end
					table.insert(_t,ORI_DECK[(i-1)*9 + k])
					if  #t[i] == 0 or self:check_3n(_t) then
						table.insert(var_to_card,ORI_DECK[(i-1)*9 + k])
						success[i] = true
						break
					end
				end
			end

			if (3 - #t[i]%3)%3 == 2 then
				for k1=1,9 do
					if success[i] then
						break
					end
					for k2=1,9 do
						local _t = table_copy_table(t[i])
						if not ORI_DECK[(i-1)*9 + k1] then
							break
						end
						if not ORI_DECK[(i-1)*9 + k2] then 
							break
						end
						table.insert(_t,ORI_DECK[(i-1)*9 + k1])
						table.insert(_t,ORI_DECK[(i-1)*9 + k2])
						if #t[i] == 0 or self:check_3n(_t) then
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k1])
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k2])
							success[i] = true
							break
						end
					end
				end
			end
		end

		if success[1] and success[2] and success[3] and success[4] then
			return true,var_to_card
		end
		return false
	end
	self:sort_card(ori_set)
	local set = {} --其他手牌
	
	local vars = {}	--百搭牌

	for i,v in ipairs(ori_set) do
		if v == bai_da then
			table.insert(vars,v)
		else
			table.insert(set,v)
		end 
	end
	--特殊牌型
	--对对胡
	local ddh_set = table_copy_table(set)
	local hu,baida_change = self:check_duidui_hu(ddh_set,vars)
	if hu then
		return HU,baida_change
	end
	--七小对
	if seven_dui then
	local qxd_set = table_copy_table(set)
	if #qxd_set + #vars == 14 then
	 local x = self:remove_dui(qxd_set)
		if #x == #vars then
			return HU,x
		end
		if #x < #vars and (#vars - #x)%2 == 0 then
			return HU,x
		end
		if #x == 0 and #vars%2 == 0 then
			return HU,{}
		end
	end
	end

	

	if #vars == 3 then
		if self:check_hu(set) then
			return HU,{}
		end
		--俩个癞子做将
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card = check_by_splice(set,var_t)
		if typ then
			return HU,var_to_card
		end 
		--两张普通牌做将3
		local var_t= table_copy_table(vars)
		local set_t= table_copy_table(set)
		local i=0
		local have = {}
		while(i<(#set_t-1)) do
			i = i + 1
			local a = set_t[i]
			local b = set_t[i+1]
			if a == b then
				if not have[a] then
					table.remove(set_t,i+1)
					table.remove(set_t,i)	
					i = i - 1
					local typ,var_to_card = check_by_splice(set_t,var_t)
					if typ then
						return HU,var_to_card
					else
						table.insert(set_t,a)
						table.insert(set_t,b)
					end
					have[a] = true
				end
			end
		end
	end

	if #vars == 4 then
		local t = table_copy_table(set)
		table.insert(t,t.bai_da)
		
		local typ,var_to_card = self:check_hu_var(t,var)
		if typ then
			return HU,var_to_card
		end
		--
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card = check_by_splice(set,var_t)
		if typ then
			return HU,var_to_card
		end
		--两张普通牌做将
		local var_t= table_copy_table(vars)
		local set_t= table_copy_table(set)
		local i=0
		local have = {}
		while(i<#set_t-1) do
			i = i + 1
			local a = set_t[i]
			local b = set_t[i+1]
			if a == b then
				if not have[a] then
					table.remove(set_t,i+1)
					table.remove(set_t,i)	
					i = i - 1
					local typ,var_to_card = check_by_splice(set_t,var_t)
					if typ then
						return HU,var_to_card
					else
						table.insert(set_t,a)
						table.insert(set_t,b)
					end
					have[a] = true
				end
			end
		end
		
	end

	if #vars == 0 then
		return self:check_hu(set),{}
	end

	--所有对子的情形
	
	self:sort_card(set)

	--1.癞子是对子的情形(优先)
	if #vars == 2 then
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card
		if #var_t == 0 then
			typ = self:check_3n(set)
		else
			typ,var_to_card = check_by_splice(set,var_t)
		end
		if typ then
			return HU,var_to_card
		end
	end

	--2.本身就是对子的情形
	for i=1,#set - 1 do

		if set[i] == set[i + 1] then
			while i + 2 <= #set and set[i + 1] == set[i + 2] do
				i = i + 1
			end
			local check = {}
			for k = 1,#set do
				if k ~= i and k ~= i + 1 then
					table.insert(check,set[k])
				end
			end
			local var_t = table_copy_table(vars)
			
			local typ,var_to_card
		if #var_t == 0 then
			typ = self:check_3n(check)
		else
			typ,var_to_card = check_by_splice(check,var_t)
		end
			if typ then
				return HU,var_to_card
			end
		end
	end
	--3.与癞子结合成对子的情形
	for i=1,#set do
		if set[i] == set[i + 1] then
			while i + 2 <= #set and set[i + 1] == set[i + 2] do
				i = i + 1
			end
		end
		local check = {}
		for k = 1,#set do
			if k ~= i then
				table.insert(check,set[k])
			end
		end
		local var_t = table_copy_table(vars)
		assert(#var_t ~= 0)
		table.remove(var_t)
		local typ,var_to_card
		if #var_t == 0 then
			typ = self:check_3n(check)
		else
			typ,var_to_card = check_by_splice(check,var_t)
		end
		var_to_card = var_to_card or {}
		table.insert(var_to_card,set[i])
		if typ then
			return HU,var_to_card
		end
	end
	return
end


function M:get_bai_da_num(hand_cards,bai_da)
	local num = 0
	for _,v in pairs(hand_cards) do
		if v == bai_da then
			num = num + 1
		end
	end
	return num
end

function M:calculate_fan_xing_num(option,t)
	local num = 0
	if option == 1 then
		for _,v in pairs(t) do
			if v then
				num = num + YING_ZI_MO.FAN_XING_SCORE[v]
			end
		end
	elseif option == 2 then
		for _,v in pairs(t) do
			if v then
				num = num + TAI_TOU_HU.FAN_XING_SCORE[v]
			end
		end
	elseif	option == 3 then
		for _,v in pairs(t) do
			if v then
				num = num + CHU_DIAN_HU.FAN_XING_SCORE[v]
			end
		end
	else 
		
	end
	num = 2^num
	return math.floor(num) 
end

local card_type = {}
card_type[1] ="三百搭"
card_type[3] ="单吊"
card_type[11]="清一色"
card_type[12]="混一色"
card_type[13]="对对胡"
card_type[14]="无百搭"
card_type[15]="七小对"
card_type[16]="全老头"

local function get_hu_type(t)
	local str = ""
	for _,v in pairs(t) do
		str = str..card_type[v]..","
	end
	return str
end
local tai_type = {"红中刻","发财刻","白板刻","门风","无百搭","对对胡","混一色","清一色","全老头","圈风"}
local function get_tai_type(t)
	local str = ""
	for _,v in pairs(t) do
		str = str..tai_type[v]..","
	end
	return str
end

local function get_c(v)
	
	if v then
		local c = {"W","L","O","$"}
		if v%16 and c[math.floor(v/16)] then
			local str  = tostring(v%16)..c[math.floor(v/16)]
			return str
		end
	else
		return"no card"
	end
end

local function get_card_string(t)
	local str = ""
	if not t then
		return str
	end
	if #t == 0 then
		return str
	end
	for k,v in ipairs(t) do
		if v then
			str = str.." "..get_c(v)
		end
	end
	return str
end


function M:get_feng_ke(card,quan_feng,men_feng)
	local ret = {}
	local ke = self:get_value(card)
	if ke <= 4 then
		if ke == quan_feng then
			table.insert(ret,TAI_XING.QUAN_FENG)
		end
		if ke == men_feng then
			table.insert(ret,TAI_XING.MEN_FENG)
		end
	end
	if ke == 5 then 
		table.insert(ret,TAI_XING.HONG_ZHONG_KE)
	end
	if ke == 6 then 
		table.insert(ret,TAI_XING.FA_CAI_KE)
	end
	if ke == 7 then 
		table.insert(ret,TAI_XING.BAI_BAN_KE)
	end
	return ret
end

function M:check_ke(t)
	local result = {}
	local cards = {}
	for k,v in pairs(t.set) do
		if self:get_type(v) == 4 then
			if cards[v] then
				cards[v] = cards[v] + 1
			else
				cards[v] = 1
			end
		end
	end

	for k,v in pairs(cards) do
		if v >= 3 then
			self:add(result,self:get_feng_ke(k,t.quan_feng,t.men_feng))
		end 
	end
	return result
end

function M:get_real_set(cards,bai_da,change)

	if not change then
		return cards
	end

	if #change == 0 then
		return cards
	end
	local set = {}
	local num = 0
	for _,v in pairs(cards) do
		if v ~= bai_da  then
			table.insert(set,v)
		else
			if num == #change then
				table.insert(set,v)
			else 
				num = num + 1
			end
		end
	end
	for _,v in pairs(change) do
		table.insert(set,v)
	end
	self:sort_card(set)
	return set
end

function M:check_tai_xing(set,chi)
	self:sort_card(set)
	local tai_xing = {}
	--清一色
	if self:qing_yi_se(set) then
		table.insert(tai_xing,QING_ONE_SUIT)
	end
	--混一色
	if self:hun_yi_se(set) then
		table.insert(tai_xing,MIX_ONE_SUIT)
	end
	--全老头
	if self:quan_lao_tou(set,bai_da) then
		table.insert(tai_xing,QUAN_LAO_TOU)
	end
	--对对胡
	if #chi == 0 and self:dui_dui_hu(set,bai_da) then
		table.insert(tai_xing,DUI_DUI_HU)
	end
	if #tai_xing > 0 then
		return true
	else
		return false
	end
end

function M:check_hu_type(t)
	local ret = {}
	self:sort_card(t.set)
	self:sort_card(t.before_set)
	local bai_da_num = self:get_bai_da_num(t.before_set,t.bai_da)
	if bai_da_num == 3 then
		table.insert(ret,HU_TYPE.SAN_BAI_DA)
	end
	
	if #t.hand_cards == 2 then
		table.insert(ret,HU_TYPE.DAN_DIAO)
	end
	if t.lose_type ~= 2 then
		if bai_da_num == 0 then
			table.insert(ret,HU_TYPE.NOT_BAI_DA)
		end
		if self:qing_yi_se(t.set) then
			table.insert(ret,HU_TYPE.QING_ONE_SUIT)
		end
		if self:hun_yi_se(t.set) then
			table.insert(ret,HU_TYPE.MIX_ONE_SUIT)
		end
		if not t.chi and self:dui_dui_hu(t.set) then
			table.insert(ret,HU_TYPE.DUI_DUI_HU)
		end
		if t.seven_dui and self:seven_dui(t.set) then
			table.insert(ret,HU_TYPE.QI_XIAO_DUI)
		end
		if self:quan_lao_tou(t.set) then
			table.insert(ret,HU_TYPE.QUAN_LAO_TOU)
		end
	end
	--print("check_hu_type is",string.format("%s %s \x1b[0m", "\x1b[32m",inspect(ret)))
	return ret
end

function M:calculate_tai_xing_num(t)
 	local num = 0

 	for _,v in pairs(t) do
 		if v then
 			num = num + TAI_TOU_HU.TAI_XING_SCORE[v]
 		end
 	end

 	return num
end

function M:get_tai_xing(t)
	local ret = {}
	if t.lose_type ~= 2 then
		return ret
	end
	--print("get_tai_xing",inspect(t))
	self:sort_card(t.set)
	self:sort_card(t.before_set)
	self:add(ret,self:check_ke(t))
	
	local bai_da_num = self:get_bai_da_num(t.before_set,t.bai_da)
	if bai_da_num == 0 then
		table.insert(ret,TAI_XING.NOT_BAI_DA)
	end
	if not t.chi and self:dui_dui_hu(t.set) then
		table.insert(ret,TAI_XING.DUI_DUI_HU)
	end
	if self:hun_yi_se(t.set) then
		table.insert(ret,TAI_XING.MIX_ONE_SUIT)
	end
	if self:qing_yi_se(t.set) then
		table.insert(ret,TAI_XING.QING_ONE_SUIT)
	end
	if self:quan_lao_tou(t.set) then
		table.insert(ret,TAI_XING.QUAN_LAO_TOU)
	end

	--print("get_tai_xing is",string.format("%s %s \x1b[0m", "\x1b[31m",inspect(ret)))

	return ret
end

function M:get_score(t)
	for k,v in pairs(t) do
		print(k,v)
	end
end

function M:check_ting(t)
	--print("check_ting",inspect(t))
	if t.lose_type == 2 then
		t.seven_dui = false
	elseif t.lose_type == 3 then
		t.seven_dui = true
	end
	local ret = {}
	for k,v in pairs(ORI_DECK) do
		local set = table_copy_table(t.set)
		table.insert(set,v)
		local hu,baida_change = self:check_hu_var(set,t.bai_da,t.seven_dui)
		local all_set = table_copy_table(t.all_set)
		table.insert(all_set,v)
		local real_set = self:get_real_set(all_set,t.bai_da,baida_change)
		local tai_xing = true
		if t.lose_type == 2 then
			tai_xing = self:check_tai_xing(real_set,t.chi)
		end
		if hu and tai_xing then
			ret[v] = {}
			--[[local data = {}
			data.hand_cards = set
			data.before_set = all_set
			data.bai_da = t.bai_da
			data.seven_dui = t.seven_dui
			data.set	= real_set
			data.lose_type = t.lose_type
			data.quan_feng = t.quan_feng
			data.men_feng  = t.men_feng
			if t.chi and #t.chi > 0 then
				data.chi = true
			end
			ret[v].type  = self:check_hu_type(data)
			ret[v].tai   = self:get_tai_xing(data)
			ret[v].score = self:calculate_fan_xing_num(t.lose_type,ret[v].type,ret[v].tai)
			ret[v].tai_num = self:calculate_tai_xing_num(ret[v].tai)
			]]
		end
	end
	return ret
end

function M:get_ting(t)
	local tb = {}
	local ret = {}
	tb.chi = t.chi
	tb.bai_da = t.bai_da
	tb.lose_type = t.lose_type
	tb.seven_dui = t.seven_dui
	tb.quan_feng = t.quan_feng
	tb.men_feng  = t.men_feng
	for i=1,#t.set do
		tb.set = {}
		tb.all_set = {}
		local set = table_copy_table(t.set)
		self:sort_card(set)
		local c = 0
		c = table.remove(set,i)
		if c ~= last_c then
			tb.set = set
			for _,v in pairs(set) do
				if v then
					table.insert(tb.all_set,v)
				end
			end
			for _,v in pairs(t.peng) do
				if v then
				 	table.insert(tb.all_set,v)
				end
			end
			for _,v in pairs(t.gang) do
				if v then
				 	table.insert(tb.all_set,v)
				end
			end
			for _,v in pairs(t.chi) do
				if v then 
					table.insert(tb.all_set,v)
				end
			end
			--print("打出",get_c(c))
			local ting = M:check_ting(tb)
			if next(ting) ~= nil then
				ret[c] = ting
			end
			--[[local str = ""
			for k,v in pairs(ting) do
				print(string.format("胡的牌: %s  胡牌类型: %s  番数: %d 台型: %s 台数: %d",get_c(k),get_hu_type(v.type) or "无" ,v.score,get_tai_type(v.tai) or "NOT",v.tai_num))
			end
			print()
			print()]]
		end
		last_c = c
	end
	return ret
end
--[[
local t = {}
local tb = {}
tb.set = {0x41,0x45,0x45,0x45,0x33,0x11,0x21,0x22,0x42,0x43,0x23,0x11,0x32,0x23} --手牌
tb.chi = {}	--吃的牌
tb.peng = {} --碰的牌
tb.gang = {} --杠的牌
tb.bai_da = 0x45    --百搭牌
tb.lose_type = 3    --玩法 1.硬自摸,2.抬头胡,3.触电胡
tb.seven_dui = true --是否检测7小对(硬自摸为选项,抬头胡没有七小对,触电胡有七小对)
tb.quan_feng = 1 	--圈风(1,东 2,南 3,西 4,北)
tb.men_feng  = 1 	--门风(1,东 2,南 3,西 4,北)

local starttime = os.clock();
local x =  M:get_ting(tb)
--print(inspect(x))
local endtime = os.clock();

print(string.format("cost time : %.4f", endtime - starttime))
]]
return M