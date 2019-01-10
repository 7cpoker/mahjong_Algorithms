local M = {}
local inspect = require "inspect"
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

COMMON = 1
PING_HU_ONE_FLOWER = 2
TIANHU = 3
ROB_GOLD = 4
PING_HU_NO_FLOWER = 5
GOLD_THREE = 6
GOLD_SPARROW = 7
GOLD_DRAGON = 8 
--新类型
MIX_ONE_SUIT = 9 --混一色
ONE_SUIT = 10 --清一色

SPECIAL_SCORE = {1,15,30,30,30,40,60,120,120,240}


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
	if not t then
		return
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

	function remove_three_same(t)

		assert(#t%3 == 0 and #t > 0)
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
			--print("remove success same:",get_card_string(t))
			return true,ret
		end
		--print("remove failed same:",get_card_string(t))
	end

	function remove_straight(t)
		--print("remove before straight:",get_card_string(t))
		assert(#t%3 == 0 and #t > 0)
		local ret = {}
		for i=1,#t - 2 do
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
				--print("remove success straight:",get_card_string(t))
				return true,ret
			end
		end
		--print("remove failed straight:",get_card_string(t))
	end

	function check_3n(set)
		assert(#set%3 == 0)
		M:sort_card(set)

		local t1 = table_copy_table(set)
		local t2 = table_copy_table(set)
		if remove_three_same(t1) then
			if #t1 == 0 or check_3n(t1)then
				--print("return",true)
				return true
			end
		end

		if remove_straight(t2) then
			--print("table sz",#t2)
			if #t2 == 0 or check_3n(t2) then
				return true
			end
		end
		return false
	end

function M:check_hu(set)
	assert((#set)%3 == 2)
	
	self:sort_card(set)
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

			if #check == 0 or check_3n(check) then
				return COMMON
			end
		end
	end
end

function M:check_identical(t,gold)
	local temp = {}
	local have_gold
	for i,v in ipairs(t) do
		if v ~= gold then
			table.insert(temp,v)
		else
			have_gold = true
		end
	end
	local  first  = temp[1]
	for i,v in ipairs(temp) do
		if self:get_type(first) ~= self:get_type(v) then
			return false
		end
	end
	if not have_gold or self:get_type(first) == self:get_type(gold) then
		return ONE_SUIT
	else
		return MIX_ONE_SUIT
	end
end

function M:check_hu_var(ori_set,var)
	assert((#ori_set) %3 == 2)
	function check_by_splice(set,vars)

		assert((#set + #vars)%3 == 0)
		
		function splice_by_type(set)
			local t = {[1] = {},[2] = {},[3] = {}}

			for i,v in ipairs(set) do
				table.insert(t[v>>4],v)
			end
			return t
		end
		local t = splice_by_type(set)
		if (3 - #t[1]%3)%3 + (3 - #t[2]%3)%3 + (3 - #t[3]%3)%3 >= 3 then
			return false
		end
		local success = {false,false,false}
		local var_to_card = {}		--百变牌变为的牌
		for i,v in ipairs(t) do
			if (3 - #t[i]%3)%3 == 0 then
				if #t[i] == 0 or check_3n(t[i]) then
					success[i] = true
				end
			end

			if (3 - #t[i]%3)%3 == 1 then
				for k=1,9 do
					local _t = table_copy_table(t[i])
					table.insert(_t,ORI_DECK[(i-1)*9 + k])
					
					if  #t[i] == 0 or check_3n(_t) then
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
						table.insert(_t,ORI_DECK[(i-1)*9 + k1])
						table.insert(_t,ORI_DECK[(i-1)*9 + k2])
						if #t[i] == 0 or check_3n(_t) then
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k1])
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k2])
							success[i] = true
							break
						end
					end
				end
			end
		end

		--print("success",success[1],success[2],success[3])
		if success[1] and success[2] and success[3] then
			return true,var_to_card
		end
		return false
	end

	local  set = {}
	--table.insert(set,single)
	
	local vars = {}

	for i,v in ipairs(ori_set) do
		if v == var then
			table.insert(vars,v)
		else
			table.insert(set,v)
		end 
	end
	--print("vars nums:",#vars)
	if #vars == 3 then
		if self:check_hu(set) then
			return GOLD_DRAGON,{}
		end
		--金雀情况
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card = check_by_splice(set,var_t)
		if typ then
			return GOLD_SPARROW,var_to_card
		end 

		return GOLD_THREE,{}
	end

	if #vars == 4 then
		local t = table_copy_table(set)
		table.insert(t,var)
		--print("=======================================================>")
		--print(get_card_string(t),"---",get_c(var),get_c(single))
		local typ,var_to_card = self:check_hu_var(t,var)
		if typ then
			return GOLD_DRAGON,var_to_card
		end
		--金雀情况
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card = check_by_splice(set,var_t)
		if typ then
			return GOLD_SPARROW,var_to_card
		end

		return GOLD_THREE,{}
	end

	if #vars == 0 then
		return self:check_hu(set),{}
	end

	--所有对子的情形
	
	self:sort_card(set)

	--1.癞子是对子的情形(优先)
	if #vars == 2 then
		--print("laizi is duizi")
		local var_t = table_copy_table(vars)
		table.remove(var_t)
		table.remove(var_t)
		local typ,var_to_card = check_by_splice(set,var_t)
		if typ then
			return GOLD_SPARROW,var_to_card
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
			local typ,var_to_card = check_by_splice(check,var_t)
			if typ then
				return COMMON,var_to_card
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

		local typ,var_to_card = check_by_splice(check,var_t)
		var_to_card = var_to_card or {}
		table.insert(var_to_card,set[i])
		if typ then
			--print("laizi and other is  duizi")
			return COMMON,var_to_card
		end
	end
	return
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

local card_type = {}
card_type[1] ="平胡"
card_type[2] ="平胡（一花）"
card_type[3]="清一色"
card_type[4]="混一色"
card_type[5]="平胡（无花无杠）"
card_type[6]="三金倒"
card_type[7]="金雀"
card_type[8]="金龙"
card_type[9]="混一色"
card_type[10]="清一色"

local function get_hu_type(t)
	local str = ""
	str = str..card_type[t]..","
	return str
end

function M:check_ting(t)
	local ret = {}
	for k,v in pairs(ORI_DECK) do
		local set = table_copy_table(t.set)
		table.insert(set,v)
		local hu,baida_change = self:check_hu_var(set,t.bai_da)
		local all_set = table_copy_table(t.all_set)
		table.insert(all_set,v)
		if hu then
			local tp =  self:check_identical(all_set,t.bai_da)
			if tp then
				hu = tp
			end
			ret[v] = {}
			--ret[v].type  = hu
			--ret[v].tai   = 1--self:get_tai_xing(data)
			--ret[v].score = SPECIAL_SCORE[hu]--self:calculate_fan_xing_num(t.lose_type,ret[v].type,ret[v].tai)
			--ret[v].tai_num = 2--self:calculate_tai_xing_num(ret[v].tai)
		end
	end
	return ret
end

function M:get_ting(t)
	local tb = {}
	local ret = {}
	tb.chi = t.chi
	tb.bai_da = t.bai_da
	for i=1,#t.set do
		tb.set = {}
		tb.all_set = {}
		local set = table_copy_table(t.set)
		M:sort_card(set)
		local c = 0
		c = table.remove(set,i)
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
		if c ~= last_c then
			--print("打出",get_c(c))
			local ting = M:check_ting(tb)
			if next(ting) ~= nil then
				ret[c] = ting
			end
			--local str = ""
			--for k,v in pairs(ting) do
				--print(string.format("胡的牌: %s  胡牌类型: %s  番数: %d",get_c(k),get_hu_type(v.type) or "无" ,v.score))
			--end
			--print()
			--print()
		end
		last_c = c
	end
	return ret
end

--[[local tb = {}
	tb.set = {0x15,0x35,0x35,0x35,0x27} --手牌
	tb.chi = {}	--吃的牌
	tb.peng = {} --碰的牌
	tb.gang = {} --杠的牌
	tb.bai_da = 0x33    --百搭牌(金牌)
local start = os.clock()
local x
for i=1,100 do
	x= 	M:get_ting(tb)
end

print("耗时",os.clock() - start,"s")
print(inspect(x))
]]	
return M