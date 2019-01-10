
                             
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



COMMON = 1
SELF_HU = 2
ROB_GOLD = 3
GOLD_THREE = 4
TIANHU = 5
SECRET_SWIM = 6
UNCONCEALED_SWIM = 7
TWICE_SWIM = 8
THREE_TIMES_SWIM = 9

SPECIAL_SCORE = {1,2,2,2,4,4,4,8,16}

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

function M:get_c(v)
	if v then
		local c = {"W","L","O","^","$"}
		--print(v)
		local str  = tostring(v%16)..c[math.floor(v/16)]
		return str
	else
		return"no card"
	end
end


function M:get_type(c)
	return math.floor(c/16)
end


function M:get_value(c)
	return c%16
end

function M:has(t,c)
	for i,v in ipairs(t) do
		if v == c then
			return true
		end
	end
end


function M:drop(t,c)
	for i,v in ipairs(t) do
		if v == c then
			table.remove(t,i)
			return true
		end
	end
end

function M:get_card_string(t)
	local str = ""
	for k,v in ipairs(t) do
		str = str.." "..self:get_c(v)
	end
	return str
end

function slice_gold(set,gold )
	local gold_num = 0
	for i=#set,1,-1 do
		if set[i] == gold then
			table.remove(set,i)
			gold_num = gold_num + 1
		end
	end
	return set,gold_num
end


function M:remove_three_same_var(set,gold_num)
	--print("remove_three_same_var",self:get_card_string(set),"gold",self:get_c(gold))
	assert((#set + gold_num) % 3 == 0)
	--
	local need_gold = 2
	if #set > 1 and set[1] == set[2] then
		need_gold = need_gold - 1
	end

	if #set > 2 and set[3] == set[1] then
		need_gold = need_gold - 1
	end

	if need_gold > gold_num then
		return false
	else
		local first = set[1] 
		for i = 1,3 - need_gold do
			self:drop(set,first)
		end
		gold_num = gold_num - need_gold
		return true,gold_num 	
	end
	return false
end

function M:remove_straight_var(set,gold_num)
	assert((#set + gold_num) %3 == 0)
	--print("remove_straight_var",self:get_card_string(set),"gold",self:get_c(gold),"gold_num",gold_num)
	
	local first,second,third =  set[1],0,0
	
	
	if set[1] and self:get_type(set[1]) == WORLD then
		return false
	end
	
	
	if self:get_value(set[1]) == 8 then
		if self:has(set,set[1] - 1) then
			second = set[1] - 1
		end

		if self:has(set,set[1] + 1) then
			third = set[1] + 1
		end
	elseif self:get_value(set[1]) == 9 then
		if self:has(set,set[1] - 1) then
			second = set[1] - 1
		end
		if self:has(set,set[1] - 2) then
			third = set[1] - 2
		end
	else
		if self:has(set,set[1] + 1) then
			second = set[1] + 1
		end
		if self:has(set,set[1] + 2) then
			third = set[1] + 2
		end
	end

	local need_gold = 0
	if second == 0 then
		need_gold = need_gold + 1
	end
	if third == 0 then
		need_gold = need_gold + 1
	end
	if need_gold > gold_num then
		return false
	else
		self:drop(set,first)
		if second ~= 0 then
			self:drop(set,second)
		else
			gold_num = gold_num - 1
		end
		if third ~= 0 then
			self:drop(set,third)
		else
			gold_num = gold_num - 1
		end
		return true,gold_num
	end
	--print("remove_straight_var22",self:get_card_string(set),"gold",self:get_c(gold))
	return false
end

function M:check_3n_var(set,gold_num)
	--print("check_3n_var",self:get_card_string(set),"gold","gold_num",gold_num)
 	assert((#set + gold_num) %3 == 0)
 	
 	if #set == 0 then
 		return true
 	end
 	local set_temp = table_copy_table(set)
 	local success,gold_num_t = self:remove_straight_var(set_temp,gold_num)
 	if success then
 		if self:check_3n_var(set_temp,gold_num_t) then
 			return true
 		end
 	end

 	local set_temp = table_copy_table(set)
 	local success,gold_num_t = self:remove_three_same_var(set_temp,gold_num)
 	if success then
 		if self:check_3n_var(set_temp,gold_num_t) then
 			return true
 		end
 	end
 	return false
 end

--普通情况，白板不做先金牌时
function M:check_hu_var(set,gold)
	local set = table_copy_table(set)
	assert(#set %3 == 2)
	self:sort_card(set)
	
	local set,gold_num = slice_gold(set,gold)


	if gold_num >= 3 then
		return GOLD_THREE
	end

	if gold_num == 2 then
		if self:check_3n_var(set,0) then
			return COMMON
		end
	end

	for i = 1,#set - 1 do
		if set[i] == set[i + 1] then
			local set_temp = table_copy_table(set)

			table.remove(set_temp,i)
			table.remove(set_temp,i)
			if self:check_3n_var(set_temp,gold_num) then
				return COMMON
			end
		end
	end 

	if gold_num >= 1 then
		for i = 1,#set do
			
			local set_temp = table_copy_table(set)
			table.remove(set_temp,i)
			if self:check_3n_var(set_temp,gold_num - 1) then
				return COMMON
			end
		end
	end
end

--白板做原先金牌时
function M:check_hu_var_2(set,gold)
	local set = table_copy_table(set)
	assert(#set %3 == 2)
	self:sort_card(set)

	local set,gold_num = slice_gold(set,gold)
	--替换掉白板
	for i,v in ipairs(set) do
		if v == 0x47 then
			set[i] = gold
		end
	end
	self:sort_card(set)

	if gold_num >= 3 then
		return GOLD_THREE
	end

	if gold_num == 2 then
		if self:check_3n_var(set,0) then
			return COMMON
		end
	end

	for i = 1,#set - 1 do
		if set[i] == set[i + 1] then
			local set_temp = table_copy_table(set)
			table.remove(set_temp,i)
			table.remove(set_temp,i)
			if self:check_3n_var(set_temp,gold_num) then
				return COMMON
			end
		end
	end 

	if gold_num >= 1 then
		for i = 1,#set do
			
			local set_temp = table_copy_table(set)
			table.remove(set_temp,i)
			if self:check_3n_var(set_temp,gold_num - 1) then
				return COMMON
			end
		end
	end
end

function M:check_hu(set,gold)
	return  self:check_hu_var(set,gold) or self:check_hu_var_2(set,gold)
end

function M:check_ting(t)
	local ret = {}
	for k,v in pairs(ORI_DECK) do
		local set = table_copy_table(t.set)
		table.insert(set,v)
		local hu,baida_change = self:check_hu(set,t.bai_da)

		if hu then

			ret[v] = {}
			--ret[v].type  = hu
			--ret[v].tai   = 1--self:get_tai_xing(data)
			--ret[v].score = SPECIAL_SCORE[hu]--self:calculate_fan_xing_num(t.lose_type,ret[v].type,ret[v].tai)
			--ret[v].tai_num = 2--self:calculate_tai_xing_num(ret[v].tai)
		end
	end
	return ret
end
local card_type = {}
card_type[1] = "普通胡"
card_type[2] = "自摸"
card_type[3] = "抢金"
card_type[4] = "三金"
card_type[5] = "天胡"
card_type[6] = "暗游"
card_type[7] = "明游"
card_type[8] = "双游"
card_type[9] = "三游"

local function get_hu_type(t)
	local str = ""
	str = str..card_type[t]..","
	return str
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
		self:sort_card(set)
		local c = 0
		c = table.remove(set,i)
		tb.set = set
		if c ~= last_c then
			local ting = self:check_ting(tb)
			if next(ting) ~= nil then
				ret[c] = ting
			end
			--local str = ""
			
		end
		last_c = c
	end
	return ret
end

--[[	local tb = {}
	tb.set = {0x15,0x17,0x35,0x35,0x35} --手牌
	tb.chi = {}	--吃的牌
	tb.peng = {} --碰的牌
	tb.gang = {} --杠的牌
	tb.bai_da = 0x33    --百搭牌
local x = 	M:get_ting(tb)
]]
return M