
--柳州麻将听牌算法: ting(tb)
	--传入的参数 tb
	--[[
	tb.set = {} --手牌
	tb.chi = {}	--吃的牌
	tb.peng = {} --碰的牌
	tb.gang = {} --杠的牌
	]]
--返回参数(两个)：是否需要进行听牌判断，success
--


--柳州麻将听牌算法: get_ting(tb,success)

--传入的参数 tb ,success
--[[
	tb.set = {} --手牌
	tb.chi = {}	--吃的牌
	tb.peng = {} --碰的牌
	tb.gang = {} --杠的牌
]]
--success:由ting(tb)返回

--返回参数
--[[
{
  [69] = { {--手牌打出的牌
      [20] = {--胡的牌和相应的结果
        men_qing = true,
        score = 4,
        type = { 2 }
      },
      [21] = {
        men_qing = true,
        score = 8,
        type = { 3, 2 }
      }
    } }
}
]]
local tableSort = table.sort
local mathFloor = math.floor
local tableRemove = table.remove
local M = {}
local ORI_DECK = {}
local HU = 4
--胡牌类型
HU_TYPE = {
PING_HU					= 1, --平胡
QING_ONE_SUIT 			= 2, --清一色
DUI_DUI_HU 				= 3,  --对对胡
QI_XIAO_DUI  			= 4, --七小对
QUAN_QIU_REN			= 5,--全球人
}

HU_TYPE.ZI_MO_SCORE = {1,2,2,2,2}

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

local function get_three_same(t)
	local found
	local begin
	local pos = {}
	for i=1,#t - 2 do
		if t[i] == t[i + 1] and t[i] == t[i + 2] then
			if found ~= t[i] then
				found = t[i]
				for j=1,3 do
					pos[#pos+1] = i + j - 1
				end
			end
		end
	end
	if #pos > 0 then
		return true,pos
	end
end

function M:sort_card(t)
	if not t then
		return
	end
		tableSort(t, function(a,b)
			local sa,ra = a%16,mathFloor(a/16)
			local sb,rb = b%16,mathFloor(b/16)
			if ra == rb then
				return sa < sb
			else
				return ra < rb
			end
			
		end)
end

function M:get_type(c)
	return mathFloor(c/16)
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

function M:remove_gang(newCards)
	-- body
	local cards = {}
	--for i,v in ipairs(newCards) do
	for i = 1 , #newCards do
		--table.insert(cards,v)
		cards[#cards+1]  = newCards[i]
	end

	local i = 0
	while(i < #cards - 3) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		local c = cards[i+2]
		local d = cards[i+3]
		if a == b and b == c and c == d then	
			tableRemove(cards,i + 3)
			tableRemove(cards,i + 2)
			tableRemove(cards,i + 1)
			tableRemove(cards,i)	
			i = i - 1
		end
	end

	return cards
end

-- 移除碰
function M:remove_peng( newCards )

	local cards = {}
	--for i,v in ipairs(newCards) do
	for i = 1 , #newCards do
		--table.insert(cards,v)
		cards[#cards+1]  = newCards[i]
	end


	local i = 0
	while(i < #cards - 2) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		local c = cards[i+2]
		if a == b and b == c then	
			tableRemove(cards,i + 2)
			tableRemove(cards,i+1)
			tableRemove(cards,i)	
			i = i - 1
		end
	end

	return cards
end
-- 移除dui
function M:remove_dui( newCards )

	local cards = {}
	--for i,v in ipairs(newCards) do
	for i = 1 , #newCards do
		--table.insert(cards,v)
		cards[#cards+1]  = newCards[i]
	end


	local i = 0
	while(i < #cards - 1) do
		i = i + 1
		local a = cards[i]
		local b = cards[i+1]
		if a == b then	
			tableRemove(cards,i+1)
			tableRemove(cards,i)	
			i = i - 1
		end
	end

	return cards
end

function M:remove_straight(t)
		if not t then
			return
		end
		if #t%3 ~= 0 and #t == 0 then
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
			--table.insert(position,i)
			position[#position+1]  = i
			for k = i,#t do
				if not found1 and t[i] + 1 == t[k] then
					found1  = true 
					--table.insert(position,k)
					position[#position+1]  = k
				end 

				if not found2 and t[i] + 2 == t[k] then
					found2  = true 
					--table.insert(position,k)
					position[#position+1]  = k
				end 

				if found2 and found1 then
					break
				end
			end
			if found2 and found1 then
				for i = #position,1,-1 do
					--table.insert(ret,table.remove(t,position[i]))
					ret[#ret+1]  = tableRemove(t,position[i])
				end
				return true,ret
			end
		end
end

function M:remove_three_same(t)
		if not t then
			return
		end
		if #t%3 ~= 0 and #t == 0 then
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
				--table.insert(ret,table.remove(t,begin))
				ret[#ret+1]  = tableRemove(t,begin)
			end
			return true,ret
		end
end


function M:check_3n_new( set,flag )
	-- body
	if not set then
		return false;
	end

	if #set%3 ~= 0 then
		return false;
	end
	self:sort_card(set)
	local set_count = #set;

	local three_same_flag,three_same_pos = get_three_same(set)

	local set_flag = {};
	if not flag and three_same_flag then
		for i=1,#three_same_pos do
			set_flag[three_same_pos[i]] = true
		end
	end
	local i = 1;
	while true do
		--先找三个相同的情况
		local first = 0; --找到顺子第一个值
		if self:get_type(first) == 4 then
			return
		end
		local arr_idx = {0,0,0};
		for j = i,set_count -2 do
			if set_flag[j] == nil then
				first = set[j];
				arr_idx[1] = j;
                i = j;
				break;
			end
		end
		--找不到第一个值，所有数据都组成顺子
		if first == 0 then
			return true;
		end

		--从顺子下一个
		for k = arr_idx[1] + 1,set_count do
			if set_flag[k] == nil then
				for n = 1,#arr_idx - 1 do
					if arr_idx[n+1] == 0 and first + n == set[k] then
						arr_idx[n+1] = k;
					end
				end
				--如果值已经大于等于顺子最后一个值，判断是否本顺子的值都能在set数组中找到
				if set[k] >= first + #arr_idx - 1 then
					for n = 1,#arr_idx do
						--等于0 代表有顺子的值找不到 代表起始值为first的顺子不能再 set中找到
						if arr_idx[n] == 0 then
							if flag and three_same_flag then
								return self:check_3n_new(set,true)
							else
								return false;
							end
						end
					end
					--值已经组成顺子，将对应的值设脏，下次不会找这个对应的数据
					
					for n = 1,#arr_idx do
						set_flag[arr_idx[n]] = true;
					end
				end
			end
		end

		--如果找不到就找是否有3个的可能性
		if arr_idx[1] ~= 0 and arr_idx[2] == 0 and arr_idx[3] == 0 then
			if set[arr_idx[1]] == set[arr_idx[1]+1] and set[arr_idx[1]] == set[arr_idx[1]+2] then
				arr_idx[2] = arr_idx[1]+1
				arr_idx[3] = arr_idx[1]+2
				for n = 1,#arr_idx do
					set_flag[arr_idx[n]] = true;
				end
			end
		end
        for n = 1,#arr_idx do
			--等于0 代表有顺子的值找不到 代表起始值为first的顺子不能再 set中找到
			if arr_idx[n] == 0 then
				if flag and three_same_flag then
					return self:check_3n_new(set,true)
				else
					return false;
				end
				
			end
		end
	end
	

	return true;
end

function M:check_3n(set)
		if not set then
			return false
		end
		if #set%3 ~= 0 then
			return false
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

function M:remove_three_same_new(set)
	local found = false
	local begin
	for i=1,set_count,3 do
		if all_three_same then
			if t[i] ~= t[i + 1] or t[i] ~= t[i + 2] then
				all_three_same = false;
                break;
			end
		end
	end
	if found then
		local ret = {}
		for k=1,3 do
			--table.insert(ret,table.remove(t,begin))
			ret[#ret+1]  = tableRemove(t,begin)
		end
		return true,ret
	end
end

function M:check_hu(set)
	if not set then
		return false
	end
	if (#set)%3 ~= 2 then
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
					--table.insert(check,set[k])
					check[#check+1]  = set[k]
				end
			end
			if #check == 0 or self:check_3n_new(check) then
				return HU
			end
		end
	end
end

function M:check_hu_var(ori_set)
	if (#ori_set) %3 ~= 2 then
		return
	end
	self:sort_card(ori_set)
	local set = {} --其他手牌
	--for i,v in ipairs(ori_set) do
	for i = 1 , #ori_set do
		--table.insert(set,v) 
		set[#set+1]  = ori_set[i]
	end
	--特殊牌型
	--七小对
	local qxd_set = table_copy_table(set)
	if #qxd_set == 14 then
	 local x = self:remove_dui(qxd_set)
		if #x == 0 then
			return HU
		end
	end
	return self:check_hu(set)
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
	--for i,v in ipairs(set) do
	for i = 1,#set do
		local color = self:get_type(v)
		if color == 4 then
			--table.insert(color1,color)
			color1[#color1+1]  = color

		else
			--table.insert(color2,color)
			color2[#color2+1]  = color
		end
	end
	if #color1 > 0 and #color2 > 0 then
		if color2[1] == color2[#color2] then
			return true
		end
	end
	
	return false
end

--对对胡
function M:dui_dui_hu(set)
	--self:sort_card(set)

	local cards = self:remove_gang(set)
	
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
	--self:sort_card(set)

	if #set ~= 14 then
		return false
	end

	-- body
	local cards = {}
	--for i,v in ipairs(set) do
	for i = 1,#set do
		--table.insert(cards,v)
		cards[#cards+1]  = set[i]
	end

	cards = self:remove_dui(cards)

	if #cards == 0 then
		return true
	end
	return false
end

function M:check_hu_type(t)
	local cm = {} 
	local sp  = {}
	if not t.chi and self:dui_dui_hu(t.all_set) then
		--table.insert(cm,HU_TYPE.DUI_DUI_HU)
		cm[#cm+1]  = HU_TYPE.DUI_DUI_HU
	end
	if self:qing_yi_se(t.all_set) then
		--table.insert(cm,HU_TYPE.QING_ONE_SUIT)
		cm[#cm+1]  = HU_TYPE.QING_ONE_SUIT
	end
	if self:seven_dui(t.all_set) then
		--table.insert(cm,HU_TYPE.QI_XIAO_DUI)
		cm[#cm+1]  = HU_TYPE.QI_XIAO_DUI
	end
	if #t.set == 2 and t.set[1] == t.set[2] then
		--table.insert(cm,HU_TYPE.QUAN_QIU_REN)
		cm[#cm+1]  = HU_TYPE.QUAN_QIU_REN
	end
	local base = true
	if #cm == 0 then
		--table.insert(cm,HU_TYPE.PING_HU)
		cm[#cm+1]  = HU_TYPE.PING_HU
	else
		base = false
	end

	return cm,base
end

function M:get_score(t)
	local score = 0
	for _,v in pairs(t) do
		if v < 6 then
			score = score + HU_TYPE.ZI_MO_SCORE[v]
		end
	end
	return score
end


local card_type = {"平胡","清一色","对对胡","七小对","全球人"}

local function get_hu_type(t)
	local str = ""
	for _,v in pairs(t) do
		str = str..card_type[v]..","
	end
	return str
end

local function get_c(v)
	
	if v then
		local c = {"W","L","O","$"}
		if v%16 and c[mathFloor(v/16)] then
			local str  = tostring(v%16)..c[mathFloor(v/16)]
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

function M:tableCopy(set)
	return table_copy_table(set)
end

function M:check_ting(t)
	-- local starttime = os.clock()
	local ret = {}
	for k,v in pairs(ORI_DECK) do
		local set = table_copy_table(t.set or {})
		--table.insert(set,v)
		set[#set+1]  = v
		if self:check_hu_var(set) then
			-- table.insert(ret, v)
			ret[v] = {}
			-- local all_set = table_copy_table(t.all_set)
			-- --table.insert(all_set,v)
			-- all_set[#all_set+1]  = v
			-- local data = {}
			-- data.all_set = all_set
			-- data.set 	 = set
			-- if t.chi and #t.chi > 0 then
			-- 	data.chi     = true
			-- end		
			-- local men_qing = 1
			-- if #data.set == 14 and #data.all_set == 14 then
			-- 	men_qing = 2
			-- end 
			-- ret[v].type  = self:check_hu_type(data)

			-- ret[v].score = self:get_score(ret[v].type) * men_qing
			-- if men_qing == 2 then
			-- 	ret[v].men_qing = true
			-- else
			-- 	ret[v].men_qing = false
			-- end
		end
	end
	-- local endtime = os.clock()
	-- print(string.format("check_ting cost time : %.4f", endtime - starttime))
	return ret  
end

local function create_ori_deck(t)
	ORI_DECK = {}
	for j=1,4 do
		if not t[j] then
			local nums = 9
			if j == 4 then
				nums = 7
			end
			for i=1,nums do
				--table.insert(ORI_DECK,0x10 + i)
				ORI_DECK[#ORI_DECK+1]  = 0x10 * j + i
			end
		end
	end
end

function M:get_ting(t)

	local set = table_copy_table(t.set)
	for k, v in pairs(set) do
		if v == t.card then
			tableRemove(set, k)
			break
		end
	end

	local flag,success = self:ting(set)
	if not flag then
		return {}
	end
	--create_ori_deck(success)
	local c = t.card
	local ret = {}
	-- local starttime = os.clock()
	
	local ting = M:check_ting({
		["set"] = set
	})
	return ting


	-- if next(ting) ~= nil then
	-- 	ret[c] = {}
	-- 	--table.insert(ret[c],ting)
	-- 	ret[c][1]  = ting
	-- end


	-- -- local ret = {}
	-- -- local tb = {}
	-- -- tb.chi = {}	-- 吃的牌
	-- -- tb.peng = {} -- 碰的牌
	-- -- tb.gang = {} -- 杠的牌
	-- -- local last_c = 0
	-- -- --M:sort_card(t.set)
	-- -- for i=1,#t.set do
	-- -- 	tb.set = {}
	-- -- 	tb.all_set = {}
	-- -- 	local set = table_copy_table(t.set)
	-- -- 	local c = 0
	-- -- 	c = tableRemove(set,i)
	-- -- 	tb.set = set
	-- -- 	for _,v in pairs(set) do
	-- -- 	 	if v then
	-- -- 			--table.insert(tb.all_set,v)
	-- -- 			tb.all_set[#tb.all_set+1]  = v
	-- -- 		end
	-- -- 	end
	-- -- 	for _,v in pairs(t.peng or {}) do
	-- -- 	  	if v then
	-- -- 	 		--table.insert(tb.all_set,v)
	-- -- 	 		tb.all_set[#tb.all_set+1]  = v
	-- -- 	 	end
	-- -- 	end
	-- -- 	for _,v in pairs(t.gang or {}) do
	-- -- 	  	if v then
	-- -- 	 		--table.insert(tb.all_set,v)
	-- -- 	 		tb.all_set[#tb.all_set+1]  = v
	-- -- 	 	end
	-- -- 	end
	-- -- 	for _,v in pairs(t.chi or {}) do
	-- -- 	  	if v then 
	-- -- 	 		--table.insert(tb.all_set,v)
	-- -- 	 		tb.all_set[#tb.all_set+1]  = v
	-- -- 	 	end
	-- -- 	end
	-- -- 	if c ~= last_c then
	-- -- 		--print("打出",get_c(c))
	-- -- 		local ting = M:check_ting(tb)
	-- -- 		if next(ting) ~= nil then
	-- -- 			ret[c] = {}
	-- -- 			--table.insert(ret[c],ting)
	-- -- 			ret[c][#ret[c]+1]  = ting
	-- -- 		end
	-- -- 		--[[local str = ""
	-- -- 		for k,v in pairs(ting) do
	-- -- 			print(string.format("胡的牌: %s  胡牌类型: %s  子数: %d 门清: %s",get_c(k),get_hu_type(v.type),v.score,v.men_qing))
	-- -- 		end
	-- -- 		print()
	-- -- 		print()]]
	-- -- 	end
	-- -- 	last_c = c
	-- -- end
	-- local endtime = os.clock()
	-- print(string.format("get_ting cost time : %.4f", endtime - starttime))
	-- return ret
end

local function splice_by_type(set,card)
	if not set then
		return {}
	end
	local t = {[1] = {},[2] = {},[3] = {},[4] = {}}
	for i =1,#set do
		--table.insert(t[set[i]>>4],v)
		t[mathFloor(set[i]/16)][#t[mathFloor(set[i]/16)]+1] = set[i]
	end
	return t
end

local function get_dui_num(set)
	local nums = 0
	for i=1,#set - 1 do
		--三张会算两对
		if set[i] == set[i+1] then
			nums = nums + 1
		end
	end
	if nums >=	 2 then
		return nums
	end
end

function M:ting(set)
	local t = splice_by_type(set)
	local success = {false,false,false,false}
	local etr  = 0
	for i=1,#t do
		etr = etr + #t[i] % 3
	end
	if etr == 1 or etr == 4 then
		for i=1,#t do
			success[i] = self:check_3n_new(t[i])
			if #t[i] == 0 then
				success[i] = true
			end
		end
	end
	local times = 0
	for k, v in pairs(success) do
		if v == true then
			times = times + 1
		end
	end
	-- for i=1,#success do
	-- 	if success[i] then
	-- 		times = times + 1
	-- 	end
	-- end
	--针对七小对的处理
	if get_dui_num(set) > 5 then
		return true, success
	end 

	if times >= 2 then	
		for i=1,#success do
			if not success[i] then
				self:get_cards(t[i])
			end
		end
		return true, success
	end
end
--获取需要添加的牌
function M:get_cards(set)
	local last_c = 0
	for i=1,#set do
		if last_c ~= set[i] then
			local c_type = self:get_type(set[i])
			local c_value = self:get_value(set[i])

			local cards = { set[i] }
			if c_type ~= 4 then
				if c_value == 1 then
					cards[#cards + 1] = set[i] + 1
				elseif c_value == 9 then
					cards[#cards + 1] = set[i] - 1
				else
					cards[#cards + 1] = set[i] + 1
					cards[#cards + 1] = set[i] - 1
				end

			end
			for _,v in pairs(cards) do
				if not self:has(ORI_DECK,v) then
					ORI_DECK[#ORI_DECK + 1] = v
				end
			end
		end
	end
end

return M



--[[function get_ting_str()
	local starttime = os.clock()
	local tb = {}
	tb.set = {0x11,0x11,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x19,0x19,0x45} --手牌
	tb.chi = {}	--吃的牌
	tb.peng = {} --碰的牌
	tb.gang = {} --杠的牌
	tb.card = 0x45
	if #tb.set%3 ~= 2 then
		error("please input right nums!!!!!")
	end
	--local success = {false,false,false,false}
	local data
	for i=1,1 do
		data = M:get_ting(tb)
	end
		
	print(inspect(data))

	local endtime = os.clock()
	print(string.format("check_ting cost time : %.4f", endtime - starttime))
end

get_ting_str()
]]