--斗地主拆分牌算法
local M = {}
require "landlord_poker"
local inspect = require "inspect"
--local skynet = require "skynet"

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


function M.split(set)
	--先找出单牌(左边没有右边也没有的) 2 和 鬼牌直接定为单牌
	--拆完牌的数据
	local split = {}
	local cards = set--{123, 82, 62, 124, 61, 122, 153, 144, 64, 52, 84, 34, 114, 31, 121, 53, 103}
	local set_t = table_copy_table(cards)
	local cards_Obj = LPokerUtils.numToObj(set_t)
	local cards_nums =LPokerUtils.get_point_nums(cards_Obj)
	local single_cards = LPokerUtils.get_single_cards(cards_nums)
	--第一步拆分完成
	--把拆分出来的牌从手牌中分出来
	local separate_cards = M.separate_card(set_t,single_cards)
	--把拆分出来的牌归类(根据特征值的大类)LPokerUtils.explodeValue(value)
	M.recursive_separate(separate_cards,split)
	--第二步拆分
	local result = M.continue_separate(set_t,split)

	--print(inspect(M.get_max_cards_ex_bomb(result))) 
	--print(inspect(M.get_max_cards(result))) 
	LPokerUtils.sort_type(result)

	M.arrange_cards(result)
	return result
end

function M.continue_separate(set,split)
	local set_t = table_copy_table(set)
	local cards_Obj = LPokerUtils.numToObj(set_t)
	--local cards_nums =LPokerUtils.get_point_nums(cards_Obj)
	--剩余的牌中提取出炸弹,3个,对子

	local all_group = LPokerUtils.getHintCardsType(set_t, 0, 2)
	print("所有牌型",inspect(all_group))
	LPokerUtils.sort_tzz(all_group)

	local x = {}
	M.get_all_group(set_t,cards_Obj,x,0)
	local separate_result = M.get_nums(x)
	local score_result = M.get_total_score(separate_result) or {}
	--skynet.error("每个牌型的分数",inspect(score_result))
	if #score_result < 1 then
		return M.common_separate(set,split)
	end
	local need_result = {}
	for _,v in pairs(M.get_max_score(score_result,3)) do
	 	table.insert(need_result,separate_result[v])
	end 

	print("所有牌",inspect(set_t))
	for k,v in pairs(need_result) do
		--重新整理牌 并重新计算拆牌后都分值 之前单牌是没有计算分值的  如果整理完牌后比较和之前牌的差值过大表示
		--对牌进行进一步整理(3带一带牌合理不,剩下的牌是不是差某张牌就可以组成顺子,剩下的单个数量是否过多)
		local set_tt ,ot_cards
		set_tt = table_copy_table(set_t)
		for x,y in pairs(v) do
			set_tt,ot_cards = M.separate_card_del(set_tt,y.cards)
		end
		local new_group = LPokerUtils.getHintCardsType(set_tt, 0, 2)
		LPokerUtils.sort_tzz(new_group)
		for x,y in pairs(new_group) do
			local score = LPokerUtils.get_cards_score(y.cards)
			table.insert(v,{cards = y.cards,score = score,_type = LPokerUtils.explodeValue(y.tzz)})
		end
	end
	print("最后几组",inspect(need_result))
	local score_result1 = M.get_total_score(need_result)
	local index = M.get_max_score(score_result1,1)
	--找到了最合适的一组牌
	print("找到了最合适的一组牌",inspect(need_result[index[1]])) 
	print("找到了最合适的一组牌",inspect(split))

	--合并 need_result 和 split
	local result = M.merge_table(need_result[index[1]],split)
	LPokerUtils.sort_type(result)
	print("最后结果",inspect(result))
	return result
end

function M.common_separate(set,split)
	local all_group = LPokerUtils.getHintCardsType(set, 0, 2)
	local need_result = {}
	for k,v in pairs(all_group) do
		local score = LPokerUtils.get_cards_score(v.cards)
		local _type = LPokerUtils.explodeValue(v.tzz)
		table.insert(need_result,{cards = v.cards,score = score,_type = LPokerUtils.explodeValue(v.tzz)})
	end

	need_result = M.merge_table(need_result,split)
	
	return need_result
end
--获取最大牌型 不包括炸弹
function M.get_max_cards_ex_bomb(data)
		--skynet.error("get_max_cards_ex_bomb",inspect(data))
	for _,v in pairs(data) do
		if v._type < PokerType.bomb then
			return v
		end
	end
end

--获取牌的数据 _type,类型  nums表示获取第几大的值 99表示到数第二的  100表示最大的
function M.get_cards_by_type(data,_type,nums)
	local t = {}
	for k,v in pairs(data) do
		if v._type == _type then
			table.insert(t,v)
		end
	end
	LPokerUtils.sort_type(t)
	if nums == 100 then
		return t[#t]
	elseif nums == 99 then
		return t[#t - 1] or t[#t]
	else
		return t[nums] or t[#t]
	end
end

--获取牌的数据 除了某种类型
function M.get_cards_ex_type(data,_type)
	local t = {}
	for k,v in pairs(data) do
		if v._type ~= _type then
			table.insert(t,v)
		end
	end
	LPokerUtils.sort_type(t)

	local data = M.get_max_cards_ex_bomb(t)
	if not data then
		return t[#t]
	end
end
--获取最大牌型 包括炸弹
function M.get_max_cards(data)
	return data[1]
end

--获取最小炸弹
function M.get_min_bomb_cards(data)
	local ret
	for _,v in pairs(data) do
		if v._type >= PokerType.bomb then
			ret = v
		end
	end
	return ret
end

function M.merge_table(t1,t2)
	local ret = t1
	for k,v in pairs(t2) do
		table.insert(t1,v)
	end
	return ret
end
--获取分数高的几个牌型(暂定获取3个分数最高的)
function M.get_max_score(data,num)
	local ret = {}
	for i=1,num do
		ret[i] = 0
	end
	for i=1,num do
		local score =  math.max(table.unpack(data))
		for j=1,#data do
			if score == data[j] then
				ret[i] = j
				data[j] = 0
				break
			end
		end
	end
	return ret
end

function M.get_total_score(data)
	local ret = {}
	for i=1,#data do
		local score = 0
		for j=1,#data[i] do
		  	score = score + data[i][j].score
		end
		ret[i] = score
	end
	return ret
end

function M.get_separate_result(data,key,ret)
	if data[key] then
		table.insert(ret ,data[key])
		return M.get_separate_result(data,key//10,ret)
	end
end


function M.get_nums(data)
	local ret = {}
	for k,v in pairs(data) do
		if not data[k * 10 + 1] then
			local tb = {}
			M.get_separate_result(data,k,tb)
			table.insert(ret,tb)
		end
	end
	return ret
end

--原始牌型set
function M.get_all_group(set,cards_Obj,ret,key)
	if not key then
		key = 0
	end
	local set_t = table_copy_table(set)
	local all_group = M.get_DATA(set_t,key)
	LPokerUtils.sort_tzz(all_group)
	for k,v in pairs(all_group) do
		--如果一轮能组成10种以上的牌型数据会错乱 排名大于10的牌型直接舍弃(已经够小了)
		if k < 10 then
			local set_tt,ot_cards = M.separate_card_del(set_t,v.cards)
			local score = LPokerUtils.get_cards_score(ot_cards)
			ret[(10 * key) + k] = {cards = ot_cards,score = score,_type = LPokerUtils.explodeValue(v.tzz)}
			M.get_all_group(set_tt,all_group,ret,(10 * key) + k)
		end
	end

	if not all_group or next(all_group) == nil then
		return ret
	end
end



function M.get_DATA(set,key)
	local ret = {}
	local all_group = LPokerUtils.getHintCardsType(set, 0, 2)
	LPokerUtils.sort_tzz(all_group)
	for k,v in pairs(all_group) do
		local x = LPokerUtils.explodeValue(v.tzz)
		--前俩轮不考虑对子的牌型,从第三轮开始考虑对子
		if (key < 10 and x > 2) or (key > 10 and x > 1) then
			table.insert(ret,v)
		end
	end
	return ret
end

function M.get_other_cards(data,cards)
	for _,v in pairs(data) do
		if v then
			table.insert(cards,v)
		end
	end
end

function M.recursive_separate(cards,split)
	local ret = {}
	local bomb , trio , one_pair ,joke_pair, remain_cards
	bomb , remain_cards = LPokerUtils.getAllBomb(cards , 0)
	trio , remain_cards = LPokerUtils.getAllTrio(remain_cards , 0)
	one_pair , remain_cards = LPokerUtils.getAllOnePair(remain_cards , 0)
	remain_cards,joke_pair = M.separate_joke_pair(remain_cards)
	M.range(bomb,split)
	M.range(trio,split)
	M.range(one_pair,split)
	M.range(joke_pair,split)
	local ex = {}
	for k,v in pairs(remain_cards) do
		local tmp = {v}
		local tmptzz =LPokerUtils.getCardsTypeValue(tmp)
		table.insert(ex,{cards = tmp , tzz = tmptzz})
	end
	M.range(ex,split)
end

--归类
function M.range(tb,split)
	for k,v in pairs(tb) do
		local _type = LPokerUtils.explodeValue(v.tzz)
		local score = LPokerUtils.get_cards_score(v.cards)
		split[#split + 1] = {cards =v.cards,_type = _type,score=score}
	end
end

--set手牌  cards要分离的牌
function M.separate_card(set,cards)
	local ret = {}
	for k,v in pairs(M.get_origin_data(set,cards)) do
		table.insert(ret,M.dorp(set,v)) 
	end

	return ret
end

--set手牌  cards要分离的牌 返回一个新table 不包括分离的牌
function M.separate_card_del(set,cards)
	local set_t = table_copy_table(set)
	local ret = {}
	for k,v in pairs(cards) do
		local c = M.dorp(set_t,v)
		table.insert(ret,c) 
	end
	return set_t,ret
end

function M.separate_joke_pair(cards)
	local ret = cards
	local ret2 = {}
	local joke = {}
	local tzz
	if M.has(ret,160) and M.has(ret,170) then
		joke.cards = {}
		table.insert(	joke.cards,M.dorp(ret,160) )
		table.insert(	joke.cards,M.dorp(ret,170) )
		joke.tzz = LPokerUtils.getCardsTypeValue(joke.cards)
		table.insert(ret2,joke)
	end
	return ret,ret2
end


function M.has(t,c)

	for _,v in pairs(t) do
		if v == c then
			return true
		end
	end
end

function M.get_origin_data(set,cards)
	local ret = {}
	local _cards = table_copy_table(cards)
	local obj = {}
	for i=1,#set do
		obj = LPokerUtils.numToObj(set[i])
		if _cards[obj.value] and _cards[obj.value] > 0 then
			table.insert(ret,set[i])
			_cards[obj.value] = _cards[obj.value] - 1
		end
	end
	return ret
end

function M.dorp(t,c)
		for i,v in ipairs(t) do
		if v == c then
			return table.remove(t,i)
		end
	end
end

function M.add(t,c)
	if type(c) == "table" then
		for _,v in ipairs(c) do
			table.insert(t,v)
		end
	else
		table.insert(t,c)
	end
end

function M.del_separate_data(t,tzz)
	for k,v in pairs(t) do
		if LPokerUtils.getCardsTypeValue(v.cards) == tzz then
			table.remove(t,k)
			return true
		end
	end
end


function M.get_cards_score(t)
	local score = 0
	for k,v in pairs(t) do
		score = score + v.score
	end
	return score
end
--进一步整理拆完后的牌
function M.arrange_cards(t)
	local ret = 1
	for k,v in pairs(t) do
		local cs = {}
		for _,c in pairs(v.cards) do
			cs[c//10] = (cs[c//10] or 0) + 1
		end
		if M.has(cs,3) and not (M.has(cs,1) or M.has(cs,2)) then
			local c
			local index
			for i=#t,1, -1 do
				if t[i]._type == 1 and t[i].score < 4 then
					c = t[i].cards
					index = i
				end
			end
			if not c then
				for i=#t,1, -1 do
					if t[i]._type == 2 and t[i].score < 5 then
						c = t[i].cards
						index = i
					end
				end
			end
			M.add(v.cards,c)
			table.remove(t,index)
		end
	end
end

function M.is_again_separate_cards(set,tzz,result)
	local _score = 10--M.get_cards_score(result)
	local cards = table_copy_table(set)
	cards = {44,52,61,71,72,73,84,82,83,102}
	local all = LPokerUtils.getHintCardsType(cards,0,2)
	print("all",inspect(all))
	for k,v in pairs(all) do
		local x,y = M.separate_card_del(cards,v.cards)
		local res = M.split(x)
		local score = M.get_cards_score(res)

		if ( _score - score ) <= 10 then
			return v , res
		end
	end

end

--[[--M.is_again_separate_cards()
 
 local x = { {
    _type = 21,
    cards = { 32, 44, 52, 62, 74, 82, 91 },
    score = 2
  }, {
    _type = 3,
    cards = { 151, 152, 154 },
    score = 7
  }, {
    _type = 2,
    cards = { 131, 134 },
    score = 5
  }, {
    _type = 2,
    cards = { 142, 144 },
    score = 6
  }, {
    _type = 1,
    cards = { 34 },
    score = -7
  }, {
    _type = 1,
    cards = { 64 },
    score = -4
  }, {
    _type = 1,
    cards = { 112 },
    score = 1
  } } 

M.arrange_cards(x)
print(inspect(x))

]]

local x = {144, 33, 83, 83, 52, 133, 54, 102, 134, 71, 103, 103, 151, 41, 170, 123, 43, 123, 124, 61, 62, 63, 111}
local y = {33, 41, 52, 61, 71, 83}
x,y = M.separate_card_del(x,y)
print(inspect(x))
print(inspect(y))


return M