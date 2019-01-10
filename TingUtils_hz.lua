 local inspect = require "inspect"

local ORI_DECK = {}

local ext_card = {}
for i=1,9 do
	ext_card[0x10 + i] = true
end
for i=1,9 do
	ext_card[0x20 + i] = true
end
for i=1,9 do
	ext_card[0x30 + i] = true
end
ext_card[0x40 + 5] = true
local HU = 4
local GANG = 3
local PENG = 2
local CHI = 1

local card = {}
------------------------------------- 
--0x1f 万 character
--0x2f 条 bamboo 
--0x3f 饼 circle
--0x4f 花 flower
	--东南西北中发白 1-7
	
function table_copy_table1(ori_tab)
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

function table_copy_table(set)
	if not set then
		return
	end
	local new_tab = {}
	for i=1,#set do
		new_tab[i] = set[i]
	end
	return new_tab
end

function card:remove_one_sam_card(cards,card,index)
	local num = 1
	for i,v in ipairs(cards) do
		if num >= index then
			if v == card then
				table.remove(cards,i)
				return
			end
		end
		num = num + 1
	end
end

function card:new_deck()
	local t = {}
	for i=1,9 do
		for k=1,4 do
			table.insert(t,0x10+i)
			table.insert(t,0x20+i)
			table.insert(t,0x30+i)
		end
	end
	for i=1,1 do
		for k=1,4 do
			table.insert(t,0x40+5)
		end
	end
	math.randomseed(os.time()-76567211)
	local rand
	for i=1,#t do
		rand = math.random(i,#t)
		t[i],t[rand]=t[rand],t[i]
	end
	return t
end

function card:get_bai_da()
	local t = {}
	for i=1,9 do
		table.insert(t,0x10+i)
		table.insert(t,0x20+i)
		table.insert(t,0x30+i)
	end
	for i=1,7 do
		table.insert(t,0x40+i)
	end
	math.randomseed(os.time()-76567211)
	local rand
	for i=1,#t do
		rand = math.random(i,#t)
		t[i],t[rand]=t[rand],t[i]
	end
	return t[1]
end

function card:sort_card(t)
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

function card:get_feng_ke(card,quan_feng,men_feng)
	local ret = {}
	local ke = self:get_value(card)
	if ke <= 4 then
		if ke == quan_feng then
			table.insert(ret,QUAN_FENG)
		end
		if ke == men_feng then
			table.insert(ret,MEN_FENG)
		end
	end
	if ke == 5 then 
		table.insert(ret,HONG_ZHONG_KE)
	end
	if ke == 6 then 
		table.insert(ret,FA_CAI_KE)
	end
	if ke == 7 then 
		table.insert(ret,BAI_BAN_KE)
	end
	return ret
end

function card:has(t,c)
	for i,v in ipairs(t) do
		if v == c then
			return true
		end
	end
end

function card:drop(t,c)
	for i,v in ipairs(t) do
		if v == c then
			table.remove(t,i)
			return true
		end
	end
	error("not found")
end

function card:drop_one(t,c)
	local ret = t
	--[[for i,v in ipairs(ret) do
				if v == c then
					table.remove(ret,i)
				end
			end]]
	local i = 0
	while(i < #ret ) do
		i = i + 1
		local a = ret[i]
		if a == c then	
		skynet.error(a,c,i)
			table.remove(ret,i)	
			i = i - 1
			return ret
		end
	end
	return ret
end

function card:add(t,c)
	if type(c) == "table" then
		for _,v in ipairs(c) do
			table.insert(t,v)
		end
	else
		table.insert(t,c)
	end
end

function card:get_value(c)
	return c%16
end

function card:get_type(c)
	return math.floor(c/16) 
end

function card:get_specify_nums(t,c)
	local num = 0
	for i,v in ipairs(t) do
		if v == c then
			num = num + 1
		end
	end
	return num
end

function card:check_chi(set,gold,single)
	assert(single ~= gold)
	local t = {}
	local val = self:get_value(single)
	if val > 2 then
		if self:has(set,single - 1) and self:has(set,single - 2) then
			if single - 1 ~= gold and single - 2 ~= gold then
				local temp = {}
				table.insert(temp,single - 1)
				table.insert(temp,single - 2)
				table.insert(t,temp)
			end
		end
	end
	if val < 9 and val > 1 then
		if self:has(set,single - 1) and self:has(set,single + 1) then
			if single - 1 ~= gold and single + 1 ~= gold then
				local temp = {}
				table.insert(temp,single - 1)
				table.insert(temp,single + 1)
				table.insert(t,temp)
			end
		end
	end
	if val < 8 then
		if self:has(set,single + 1) and self:has(set,single + 2) then
			if single + 1 ~= gold and single + 2 ~= gold then
				local temp = {}
				table.insert(temp,single + 1)
				table.insert(temp,single + 2)
				table.insert(t,temp)
			end
		end
	end
	if #t ~= 0 then
		return t
	end
end

function card:check_peng(set,single)
	local nums = 0
	for i,v in ipairs(set) do
		if v == single then
			nums = nums + 1
		end
	end
	if nums >= 2 then
		return true
	end
end

function card:check_gang(set,single)
	local nums = 0
	for i,v in ipairs(set) do
		if v == single then
			nums = nums + 1
		end
	end
	if nums >= 3 then
		return true
	end 
end

function card:get_c(v)
	
	-- if v then
	-- 	local c = {"W","L","O","$"}
	-- 	if v&0xf and c[v>>4] then
	-- 		local str  = tostring(v&0xf)..c[v>>4]
	-- 		return str
	-- 	end
	-- else
	-- 	return"no card"
	-- end
end

function card:get_card_string(t)
	local str = ""
	if not t then
		return str
	end
	if #t == 0 then
		return str
	end
	for k,v in ipairs(t) do
		if v then
			str = str.." "..self:get_c(v)
		end
	end
	return str
end

function card:get_pai_xing_string(t)
	local str = ""
	if not t then
		return str
	end
	for k,v in pairs(t) do
		if type(v) == "table" then
			local index = 1
			for i,p in pairs(v) do
				if p and index == 1 then
					str = str..p
				else
					str = str..","..p
				end
			index = index + 1
			end
			str = str..";"
		else
			str = str..v.." "
		end
		
	end
	return str
end

function card:remove_gang(newCards)
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
function card:remove_peng( newCards )

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
function card:remove_dui( newCards )

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
------------------------------------------------------------------------------------------------
function card:remove_three_same(t)
		if not t then
			print("remove_three_same t is nil")
			return
		end
		if #t%3 ~= 0 and #t == 0 then
			print("remove_three_same 参数错误")
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

	function card:remove_straight(t)
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

function card:check_duidui_hu(set,vars)
	local cards = self:remove_peng(set)
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
	function card:check_3n(set)
		if not set then
			print("remove_straight t is nil")
			return
		end
		if #set%3 ~= 0 then
	 		error("check_3n 参数错误,参数为")
			return
		end
		if #set == 0 then
			return true
		end
		--self:sort_card(set)
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
-------------------------------------------------------------------
function card:check_hu(set)
	--print("check_hu",self:get_card_string(set))
	
	if not set then
		print("set  is nil")
		return false
	end
	if (#set)%3 ~= 2 then
	 	print("check_hu 参数错误,参数为")
		return false
	end


	--self:sort_card(set) --and set[i] < 60
	--skynet.error("check_hu","set =" ,inspect(set))
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
--分离手牌和百搭牌
function card:part_cards(sets,var)
	local vars = {}
	local set = {}
	for i,v in ipairs(sets) do
		if v == var then
			table.insert(vars,v)
		else
			table.insert(set,v)
		end 
	end
	return vars,set
end

function card:splice_by_type(set)
			local t = {[1] = {},[2] = {},[3] = {},[4] = {}}
	for i,v in ipairs(set) do
		-- table.insert(t[v>>4],v)
		table.insert(t[math.floor(v/16)],v)
	end
	--print(inspect(t),inspect(vars))
	return t
end

function card:check_by_splice(set,vars)
	if (#set + #vars)%3 ~= 0 then
		print("check_by_splice, ori_set参数错误,参数为")
		return false
	end
	local t = card:splice_by_type(set)
	if (3 - #t[1]%3)%3 + (3 - #t[2]%3)%3 + (3 - #t[3]%3)%3 + (3 - #t[4]%3)%3>= 5 then
		return false
	end
	local success = {false,false,false,false}
	local var_to_card = {}		--百变牌变为的牌
	for i,v in ipairs(t) do
		if (3 - #t[i]%3)%3 == 0 then
			if #t[i] == 0 or card:check_3n(t[i]) then
				success[i] = true
			end
		end

		if (3 - #t[i]%3)%3 == 1 and (#vars - #var_to_card) >= 1 then
			for k=1,9 do
				local _t = table_copy_table(t[i])
				--print("差1张 原始的_t",inspect(_t))
				--skynet.error("差1张 原始的_t",ORI_DECK[(i-1)*9 + k])
				if ORI_DECK[(i-1)*9 + k] ~= 0 then
					--print("差1张 原始的_t",ORI_DECK[(i-1)*9 + k])
					--skynet.error(string.format("%s %s \x1b[0m", "\x1b[32m",ORI_DECK[(i-1)*9 + k] ))
					table.insert(_t,ORI_DECK[(i-1)*9 + k])
					--print("ssingle",self:get_c(ORI_DECK[(i-1)*9 + k]),(i-1)*9 + k)
					--print("table size:",#t[i])
					if  #t[i] == 0 or card:check_3n(_t) then
						table.insert(var_to_card,ORI_DECK[(i-1)*9 + k])
						success[i] = true
						break
					end
				end
			end
		end

		if (3 - #t[i]%3)%3 == 2 and (#vars - #var_to_card) >= 2 then
			for k1=1,9 do
				if success[i] then
					break
				end
				for k2=1,9 do
					local _t = table_copy_table(t[i])
					--skynet.error("差2张 原始的_t",inspect(_t))
					--skynet.error("差2张 原始的_t",ORI_DECK[(i-1)*9 + k1],ORI_DECK[(i-1)*9 + k2])
					if ORI_DECK[(i-1)*9 + k1]  ~= 0 and ORI_DECK[(i-1)*9 + k2]  ~= 0 then
						--skynet.error("差2张 原始的_t",ORI_DECK[(i-1)*9 + k1],ORI_DECK[(i-1)*9 + k2])
						table.insert(_t,ORI_DECK[(i-1)*9 + k1])
						table.insert(_t,ORI_DECK[(i-1)*9 + k2])
						if #t[i] == 0 or card:check_3n(_t) then
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k1])
							table.insert(var_to_card,ORI_DECK[(i-1)*9 + k2])
							success[i] = true
							break
						end
					end
				end
			end
		end
	end
	if success[1] and success[2] and success[3] and success[4] and #var_to_card == #vars then
		return true,var_to_card
	end
	return false
end

function card:check_hu_var(ori_set,tb)
	--print("check_hu_var","ori_set =" ,inspect(ori_set),"百搭牌为 = ",tb.bai_da)
	if (#ori_set) %3 ~= 2 then
	 	print("check_hu_var, ori_set参数错误,参数为")
		return
	end
	self:sort_card(ori_set)
	local set = {} --其他手牌
	
	local vars = {}	--百搭牌

	vars,set = card:part_cards(ori_set,tb.bai_da)


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
		local check = {}
		for k = 1,#set do
			if k ~= i then
				table.insert(check,set[k])
			end
		end
		local typ,var_to_card
		if #var_t == 0 then
			typ = self:check_3n(check)
		else
			typ,var_to_card = card:check_by_splice(check,var_t)
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
			typ,var_to_card = card:check_by_splice(check,var_t)
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
			typ,var_to_card = card:check_by_splice(check,var_t)
		end
		var_to_card = var_to_card or {}
		table.insert(var_to_card,set[i])
		if typ then
			return HU,var_to_card
		end
	end
	return
end

function card:get_real_set(cards,bai_da,change)
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

function card:check_ting1(t,gold)
	local  ret = {}
	for i,v in ipairs(ORI_DECK) do
		if self:check_hu_var(t,gold) then
			table.insert(ret,v)
		end
	end
	if #ret ~= 0 then
		return true,ret
	end
end

function card:get_base_score(t,base)
	local base_score = 0
	if base then
		base_score = 1
	else
		base_score = 3 * #t
	end
	return 1
end

function card:get_all_value_nums(cards)
	local ret = {}
	for _,v in pairs(cards) do
		if ret[v] then
			ret[v] = ret[v] + 1
		else
			ret[v] = 1
		end
	end
	return ret
end

function card:check_ting(t,tb)
	local ret = {}
	for k,v in pairs(ORI_DECK) do
		if v~=0 then
			local set = table_copy_table(t.set)
			table.insert(set,v)
			local hu = self:check_hu_var(set,tb)
			if hu then
				ret[v] = {}
				ret[v].type = {}
				ret[v].score  = 1
			end
		end
	end
	return ret
end

function card:get_all_cards()
	local ret = {}
	for i=1,#ORI_DECK do
		ret[ORI_DECK[i]] = {}
		ret[ORI_DECK[i]].type = {}
		ret[ORI_DECK[i]].score  = 1
	end
	return ret
end

function card:get_ting(t)
	local tb = {}
	local data = {}
	tb.chi = next(t.chi)
	tb.bai_da = t.bai_da
	
	data.set = {}
	card:sort_card(t.set)
	--判断是不是能够听所有牌
	local set_t = table_copy_table(t.set)
	local num = card:get_specify_nums(set_t,t.bai_da)
	if num > 0 then
		card:drop(set_t,t.bai_da)
		local vars,set1 = card:part_cards(set_t,t.bai_da)

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
		table.insert(ORI_DECK,0x40 + 5)
		local ok = card:check_by_splice(set1,vars)
		if ok then
			return card:get_all_cards()
		end
	end 

	local set = table_copy_table(t.set)
	data.set = set
	card:get_cards(data.set)
	local ting = card:check_ting(data,tb)
	if next(ting) then
		return ting
	else
		return {}
	end
end


--获取需要添加的牌
function card:get_cards(set)
    local last_c = 0
    ORI_DECK = {}
    for i=1,34 do
    	ORI_DECK[i] = 0
    end
    ORI_DECK[32] = 69
    local nums = card:get_all_value_nums(set)
    for k,v in pairs(nums) do
        if last_c ~= k then
            local c_type = self:get_type(k)
            local c_value = self:get_value(k)

            local cards = { k }
            if c_type ~= 4 then
                if ext_card[k-2] and nums[k-2] then
                	cards[#cards + 1] = k - 1
                end
                if ext_card[k-2] and ext_card[k-1] and nums[k-1] then
                	cards[#cards + 1] = k - 2
                end
                if ext_card[k+2] and nums[k+2] then
                	cards[#cards + 1] = k + 1
                end
                if ext_card[k+2] and ext_card[k+1] and nums[k+1] then
                	cards[#cards + 1] = k + 2
                end
            end
            for _,v in pairs(cards) do
            	local c_type = self:get_type(v)
            	local c_value = self:get_value(v)
                ORI_DECK[(c_type-1)*9+c_value] = v
            end
            last_c = k
        end
    end
end

  local tb = {}
  	local set = {{0x21,0x22,0x23,0x25,0x26,0x27,0x38,0x38,0x11,0x11,0x11,0x45,0x45}, --手牌 ,
  			{69,69,69,22,22,20,20,19,19,53},
  			{69,69,22,22,20,20,19,19,53,25},
  			{69,69,69,22,22,20,20,19,19,53,53,49,49},
  			{69,69,69,23,22,22,20,20,19,19,53,53,49},
  			{69,69,22,22,20,20,19,19,53,53,49,49,25},
  			{69,69,69,22,20,20,19,53,53,50,49,49,50}
  }
  	---1 69,69,69,22,22,20,20,19,19,53
  	---2 69,69,22,22,20,20,19,19,53,25
  	---3 69,69,69,22,22,20,20,19,19,53,53,49,49
  	---4 69,69,69,23,22,22,20,20,19,19,53,53,49
  	---5 69,69,22,22,20,20,19,19,53,53,49,49,25
  	---6 69,69,69,22,20,20,19,53,53,50,49,49,50
  	---7 0x21,0x22,0x23,0x25,0x26,0x27,0x38,0x38,0x11,0x11,0x11,0x45,0x45
 

  	tb.chi = {}	--吃的牌
  	tb.peng = {} --碰的牌
  	tb.gang = {}
 	tb.bai_da = 0x45
 	local st11 =  os.clock()
 	for i=1,1 do
	 	for i=2,2 do
	 		tb.set = set[i]
	 		local st1 =  os.clock()
	 		x= 	card:get_ting(tb)
			local st2 = os.clock()
			print("听牌结果",inspect(x))
			print("胡牌结果",st2 - st1)
	 	end
	end
	local st12 =  os.clock()



	--print("胡牌结果",st12 - st11)
-- print(inspect(ext_card))
--local x = card:check_hu_var({ 18, 18, 21, 22, 23, 36, 37, 39, 40, 54, 55, 69, 69, 35 },{bai_da=0x45})
--{ 0, 18, 19, 20, 21, 22, 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 50, 0, 52, 53, 54, 0, 0, 0, 0, 0, 0, 0, 69, 0, 0 }
--胡牌结果	0.217931
--{ 0, 18, 19, 20, 21, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 53, 0, 0, 0, 0, 0, 0, 0, 0, 69, 0, 0 }
--胡牌结果	0.022755

-- 胡牌结果	0.001251
-- 胡牌结果	0.03272
-- 胡牌结果	0.001737
-- 胡牌结果	0.053712
-- 胡牌结果	0.047473
-- 听牌结果	{}

--[[
胡牌结果	0.001032
胡牌结果	0.003914
胡牌结果	0.001787
胡牌结果	0.054422
胡牌结果	0.013881
胡牌结果	0.009726
]]
return card
