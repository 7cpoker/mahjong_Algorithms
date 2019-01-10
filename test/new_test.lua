local M = {}
require "landlord_poker"
local inspect = require "inspect"
--local skynet = require "skynet"

--枚举
local Single = 1
local Double = 2
local Three  = 3
local Bomb   = 4
local SingleSeq = 5
local DoubleSeq = 6
local ThreeSeq  = 7

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
	local cards = {33,33,33,43,44,54,53,61,62}
	--{33,33,33,43,44,54,83,82,93,92,103,104,111,112,122,121}
	--{33,43,54,62,71,82,91,104,111,123,131,141}
	--{41,42,54,61,64,74,83,93,103,114,121,122,123,141,144,151,152,153,160,170}--set--{123, 82, 62, 124, 61, 122, 153, 144, 64, 52, 84, 34, 114, 31, 121, 53, 103}
	local set_t = table_copy_table(cards)
	local cards_Obj = LPokerUtils.numToObj(set_t)
	local cards_nums =LPokerUtils.get_point_nums(cards_Obj)

	M.split_card_type(cards_nums)

	--local single_cards,remain_cards = LPokerUtils.get_single_cards(cards_nums)
	--print(inspect(single_cards))
	--print(inspect(remain_cards))
	--第一步拆分完成
	--把拆分出来的牌从手牌中分出来
	--local separate_cards = M.separate_card(set_t,single_cards)
	--把拆分出来的牌归类(根据特征值的大类)LPokerUtils.explodeValue(value)
	--M.recursive_separate(separate_cards,split)
	--第二步拆分
	--local result = M.continue_separate(set_t,split)

	--print(inspect(M.get_max_cards_ex_bomb(result))) 
	--print(inspect(M.get_max_cards(result))) 
	--LPokerUtils.sort_type(result)

	--M.arrange_cards(result)
	return result
end

function M.split_card_type(set)
	local result = {}
	local cards = table_copy_table(set)
	--判断是否有王炸
	if cards[16] and cards[16] == 2 then
		table.insert(result,{_type = Bomb,cards = {16,16} })
		cards[16] = 0
	end
	--处理其他炸弹
	for k,v in pairs(cards) do
		if v == 4 then
			table.insert(result,{_type = Bomb,cards = {k,k,k,k} })
			cards[k] = cards[k] - 4
		end
	end

	--处理2
	if cards[15] then
		if cards[15]  == 1 then
			table.insert(result,{_type = Single,cards = {15} })
			cards[15] = cards[15] - 1
		elseif cards[15]  == 2 then
			table.insert(result,{_type = Double,cards = {15,15} })
			cards[15] = cards[15] - 2
		elseif cards[15]  == 3 then
			table.insert(result,{_type = Three,cards = {15,15,15} })
			cards[15] = cards[15] - 3
		end
	end

	--释放为0的数据
	LPokerUtils.free_value(cards)

	--优先查单顺 然后双顺 再查找3顺 
	--只是单纯的查找不重复的顺子
	local single_seq = M.get_single_straight(cards) or {}
	LPokerUtils.free_value(cards)

	--对单顺进一步处理 把单顺加长
	if #single_seq > 0 then
		M.update_single_leg(single_seq,cards)
	end

	--合并单顺   拼接出一个更长的或者拼接出一个双顺(不考虑多出牌的情况,因为多出的最大为10)
	local _type
	if #single_seq > 1 then
		 _type = M.merge_single_seq(single_seq,#single_seq)
	end
	--把合并后的单顺加到结果中,并释放数据
	for i=1,#single_seq do
		table.insert(result,{_type = _type or SingleSeq,cards = single_seq[i] })
	end
	LPokerUtils.free_value(cards)
	--查找双顺
	local double_seq = M.get_double_straight(cards)
	print("double_seq",inspect(double_seq))

	for i=1,#double_seq do
		table.insert(result,{_type = DoubleSeq ,cards = double_seq[i] })
	end
	--剩下的牌里面有没有三顺
	--local three_seq = M.get_three_straight(cards)
	--print("three_seq",inspect(three_seq))

	--剩下的牌
	local other_cards = M.get_other_type(cards)
	print("other_cards",inspect(other_cards))
	for i=1,#other_cards do
		table.insert(result,other_cards[i])
	end

	print("x",inspect(result))
	print("+++",inspect(cards))
	
	M.deal_cards(result,set)


	for k,v in pairs(result) do

	end
end

--nums 牌    num ：长度    index 最大：99 最小：1
function M.get_single_straight(nums,num,index)
	if not num then
		num = 5
	end
	local ret = {}
	local exist = true

	while exist and M.get_card_nums(nums) >= 5 do	
		local max = 0
		for k,v in pairs(nums) do
			if v then
				local cards = {}
				for i=k,k+num - 1 do
					if not nums[i] then
						cards = {}
						break
					end
					table.insert(cards,i)
				end
				if #cards == num then
					M.del_cards_value(nums,cards)
					LPokerUtils.free_value(nums)
					table.insert(ret,cards)
					break
				end
				if k > max then
					max = k
				end
				if k == max then
					exist = false	
				end
			end
		end
	end

	if next(ret) == nil then
		return
	else
		return ret
	end
end

function M.get_double_straight(nums,num)
	print(inspect(nums))
	if not num then
		num = 3
	end
	local ret = {}
	local exist = true
	while exist and M.get_card_nums(nums) >= 6 do	
		local max = 0
		for k,v in pairs(nums) do
			if v then 
				local cards = {}
				for i=k,k+num - 1 do
					if not nums[i] or nums[i] < 2 then
						cards = {}
						break
					end
					table.insert(cards,i)
					table.insert(cards,i)
				end
				if #cards == num * 2 then
					M.del_cards_value(nums,cards)
					LPokerUtils.free_value(nums)
					table.insert(ret,cards)
					break
				end
				if k > max then
					max = k
				end
				if k == max then
					exist = false	
				end
			end
		end
	end

	if next(ret) == nil then
		return
	else
		return ret
	end
end

--获取剩余牌型
function M.get_other_type(nums,num)
	print(inspect(nums))
	local ret = {}

	for k,v in pairs(nums) do
		if v == 3 then
			table.insert(ret,{_type = Three,cards = {k,k,k} })
			nums[k] = nums[k] - 3
		elseif v == 2 then
			table.insert(ret,{_type = Double,cards = {k,k} })
			nums[k] = nums[k] - 2
		elseif v == 1 then
			table.insert(ret,{_type = Single,cards = {k} })
			nums[k] = nums[k] - 1
		end
	end


	if next(ret) == nil then
		return
	else
		return ret
	end
end

function M.deal_cards(cards,sets)
	--最后处理
	--[[
		1.剩下的单牌能否组成3个或者对子 能组成对子则找到另一张牌去处(一般在顺子里) 
		并判断是否能从中脱离组成对子 条件:顺子长度大于5,并且在第一张或者最后一张
	]]
	for k,v in pairs(cards) do
		if v._type == Single then
			if sets[v.cards[1]] == 2 then
				
			elseif sets[v.cards[1]] == 3 then
				print("++++++++2")
				--两张牌分散在两个单顺的不考虑
				for x,y in pairs(cards) do
					if y._type == DoubleSeq then
						if #y.cards > 3 then
							if y.cards[#y.cards] == v.cards[1] or y.cards[1] == v.cards[1] then
								M.dorp(y.cards,v.cards[1])
								M.dorp(y.cards,v.cards[1])
								M.add(v.cards,v.cards[1])
								M.add(v.cards,v.cards[1])
								v._type = Three
							end
						end
					end
				end
			end
		end
	end

end

function M.get_card_nums(cards)
	local num = 0
	for k,v in pairs(cards) do
		num = num + v
	end
	return num
end

function M.del_cards_value(nums,cards)
	for _,v in pairs(cards) do
		if nums[v] then
			nums[v] = nums[v] - 1
		end
	end
end

function M.merge_single_seq(single_seq)
	for i=1,#single_seq - 1 do
		for j=i+1,#single_seq do
			local single_seq1 = single_seq[i]
			local single_seq2 = single_seq[j]
			if single_seq1[#single_seq1] + 1 == single_seq2[1] or single_seq1[1] - 1 == single_seq2[#single_seq2] then
				M.add(single_seq1,single_seq2)
				table.remove(single_seq,j)
				return SingleSeq
			end

			if #single_seq1 == #single_seq2 and single_seq1[1] == single_seq2[1] then
				M.add(single_seq1,single_seq2)
				table.remove(single_seq,j)
				table.sort( single_seq1, function (a,b)
					return a < b
				end )
				return DoubleSeq
			end
		end
	end
end

function M.update_single_leg(single_seq,cards)
	for i=1,#single_seq do
		local leg = #single_seq[i]
		local index = 1
		while cards[ single_seq[i][leg] + index ] do
			if cards[ single_seq[i][leg] + index ] then
				table.insert(single_seq[i],single_seq[i][leg] + index)
				cards[ single_seq[i][leg] + index ] = cards[ single_seq[i][leg] + index ]- 1
			end
			index = index + 1
		end
	end
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

M.split()