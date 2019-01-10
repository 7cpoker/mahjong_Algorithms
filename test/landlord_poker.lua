--[[
	根据一组合法牌计算特征值，用来比较大小
	特征值结构为
	【牌型大类（两位） | 节数（两位） | 牌值（三位）| 预留一位（默认4），比如癞子牌或其它地方用】
	比如55566637特征值为31 02 005 4。31表示三顺带单，02表示两节（从5到6），005是取最小那节的牌值，4是默认值。

	牌型代码和例子：
	单张。1。单张A2K的值依次是1 01 014 4，1 01 015 4，1 01 013 4。
	对子。2。对7 = 2 01 007 4。
	三条。3。三个5 = 3 01 005 4。
	三带单。4。5557 = 4 01 005 4。
	三带对。5。55577 = 5 01 005 4。
	四带单。6
	四带对。7
	四带两单张。8。555579 = 8 01 005 4。
	四带两对。9。55557799 = 9 01 005 4。

	单顺。21。456789 = 21 06 004 4。
	双顺。22。556677 = 22 03 005 4。
	三顺。23
	三顺带单。飞机。24。66677735 = 24 02 006 4。
	三顺带对。飞机。25
	四顺。26。
	四顺带单。27。
	四顺带两单。28。
	四顺带两对。29。

	四条。炸弹。41。JJJJ = 41 01 011 4。
	双王。火箭。51。大小王 = 51 01 000 4。
]]

-------------------------------------------------------------------------------
local xtable = {}
local inspect = require "inspect"
-- update(t, t1, t2...) 把 t1 t2 等的key复制到t中
function xtable.update (t,...)
    for i = 1,select('#',...) do
        for k,v in pairs(select(i,...)) do
            t[k] = v
        end
    end
    return t
end

-- 浅拷贝
function xtable.copy(tab)
    if type(tab) == 'table' then
        return xtable.update({}, tab)
    end
end

function xtable.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
-------------------------------------------------------------------------------

PokerType = { }

PokerType.single = 1 -- 单张
PokerType.onePair = 2 -- 一对
PokerType.trio = 3 -- 三条（三张一样大小的牌）
PokerType.trioWithSingle = 4 -- 三带单
PokerType.trioWithPair = 5 -- 三带对
PokerType.bomb = 41 -- 四张（炸弹）
PokerType.fourWithSingle = 6 -- 四带单
PokerType.fourWithOnePair = 7 -- 四带一对
PokerType.fourWithTwoSingle = 8 -- 四带两单张
PokerType.fourWithTwoPair = 9	-- 四带两对

PokerType.singleStraight = 21	--单顺
PokerType.pairStraight = 22		--连对
PokerType.trioStraight = 23	--飞机（不带牌）
PokerType.trioStraightWithSingle = 24 --飞机 带单张
PokerType.trioStraightWithPair = 25	-- 飞机 带对
PokerType.fourStraight = 26	--航天飞机（不带牌）
PokerType.fourStraightWithSingle = 27 -- 航天飞机 带单
PokerType.fourStraightWithTwoSingle = 28	--航天飞机 带两单张
PokerType.fourStraightWithTwoPair = 29		--航天飞机 带两对

PokerType.jokePair = 51	-- 王炸
----------------------------------------------------------
LPokerUtils = { }

-- 方块3是31，梅花3是32，方块K是131，方块1、2依次是141、151，小王160，大王170
local TAG = "LPokerUtils"

-- 获取提示牌型
-- cardsData 包含的扑克牌
-- tzz 牌型特征值
-- priority -1 单牌优先 2 其他牌优先
function LPokerUtils.getHintCardsType(cardsData, tzz, priority)
	local a , b , c = LPokerUtils.explodeValue(tzz)

	local result = {}
	-- 你大了，选择所有可能牌型
	if tzz == 0 and priority == 2 then
		--不拆大小王
		local cards = {}
		table.move(cardsData, 1, #cardsData, 1, cards)
		table.sort(cards)
		if cards[#cards]==170 and cards[#cards-1]==160 then
			table.remove(cards)
			table.remove(cards)
		end

		local result20 = LPokerUtils.getAllTrioStraightWithSingle(cards, tzz)
		if not(result20 == nil) and #result20 > 0 then
			for _,bomb in ipairs(result20) do
				table.insert(result , bomb)
			end
		end

		local result2 = LPokerUtils.getAllTrioStraight(cards, tzz)
		if not(result2 == nil) and #result2 > 0 then
			for _,bomb in ipairs(result2) do
				table.insert(result , bomb)
			end
		end

		local result3 = LPokerUtils.getAllPairStraight(cards, tzz)
		if not(result3 == nil) and #result3 > 0 then
			for _,bomb in ipairs(result3) do
				table.insert(result , bomb)
			end
		end

		local result4 = LPokerUtils.getAllSingleStraight(cards, tzz)
		if not(result4 == nil) and #result4 > 0 then
			for _,bomb in ipairs(result4) do
				table.insert(result , bomb)
			end
		end

		local result6 = LPokerUtils.getAllTrioWithSingle(cards, tzz)
		if not(result6 == nil) and #result6 > 0 then
			for _,bomb in ipairs(result6) do
				table.insert(result , bomb)
			end
		end

		local result5 = LPokerUtils.getAllTrioWithPair(cards, tzz)
		if  not(result5 == nil) and #result5 > 0 then
			for _,bomb in ipairs(result5) do
				table.insert(result , bomb)
			end
		end

		local result7 = LPokerUtils.getAllTrio(cards, tzz)
		if not(result7 == nil) and #result7 > 0 then
			for _,bomb in ipairs(result7) do
				table.insert(result , bomb)
			end
		end

		--单张,不拆牌
		table.sort(cards)
		for i=1,#cards do
			if cards[i]//10 ~= (cards[i-1] or 0)//10 and cards[i]//10 ~= (cards[i+1] or 0)//10 then
				local tmpcards = {cards[i]}
				local tmptzz = LPokerUtils.getCardsTypeValue(tmpcards)
				table.insert(result, {cards=tmpcards, tzz=tmptzz})
			end
		end

		local result8 = LPokerUtils.getAllOnePairEX(cardsData , tzz)
		if #result8 > 0 then
			for _,bomb in ipairs(result8) do
				table.insert(result , bomb)
			end
		end

		local result1 = LPokerUtils.getAllFourWithTwoSingle(cardsData, tzz)
		print(inspect(result1))
		if not(result1 == nil) and #result1 > 0 then
			for _,bomb in ipairs(result1) do
				table.insert(result , bomb)
			end
		end

	else
		if a == PokerType.single or tzz == 0 then
			result = LPokerUtils.getAllSingle(cardsData , tzz)
		elseif a == PokerType.onePair then
			result = LPokerUtils.getAllOnePairEX(cardsData , tzz)
		elseif a == PokerType.trio then
			result = LPokerUtils.getAllTrioEx(cardsData , tzz)
		elseif a == PokerType.bomb then
			result = LPokerUtils.getAllBombEx(cardsData , tzz)
		elseif a == PokerType.trioWithSingle then
			result = LPokerUtils.getAllTrioWithSingle(cardsData , tzz)
		elseif a == PokerType.trioWithPair then
			result = LPokerUtils.getAllTrioWithPair(cardsData , tzz)
		elseif a == PokerType.fourWithSingle then
			result = LPokerUtils.getAllFourWithSingle(cardsData , tzz)
		elseif a == PokerType.fourWithTwoSingle then
			result = LPokerUtils.getAllFourWithTwoSingle(cardsData , tzz)
		elseif a == PokerType.singleStraight then
			result = LPokerUtils.getAllSingleStraight(cardsData , tzz)
		elseif a == PokerType.pairStraight then
			result = LPokerUtils.getAllPairStraight(cardsData , tzz)
		elseif a == PokerType.trioStraight then
			result = LPokerUtils.getAllTrioStraight(cardsData , tzz)
		elseif a == PokerType.trioStraightWithSingle then
			result = LPokerUtils.getAllTrioStraightWithSingle(cardsData , tzz)
		end
	end
	if result == nil then result = { } end

	local resultBomb = LPokerUtils.getBombAndKokePair(cardsData , tzz)
	if not(resultBomb == nil) and #resultBomb > 0 then
		for _,v in ipairs(resultBomb) do
			table.insert(result, v)
		end
	end
	return result
end

function LPokerUtils.getBombAndKokePair(cardsData , tzz)
	local result = {}
	local bombs = LPokerUtils.getAllBomb(cardsData , tzz)
	local jokePair = LPokerUtils.getAllJokePair(cardsData)
	if not(bombs == nil) then
		for _,bomb in ipairs(bombs) do
			table.insert(result , bomb)
		end
	end
	if not(jokePair == nil)  then
		table.insert(result , jokePair[1])
	end
	return result
end

--[[
	是否在bomb	中
	例如
	cardId: 9
	bomb:	{91, 92, 93, 94}
]]
local function isInBomb(cardId, bomb)
	for k,v in pairs(bomb) do
		if xtable.contains(v.cards, cardId) then
			return true
		end
	end
	return false
end

function LPokerUtils.getMySingle2(cards)
	local result = {}
	for _,c in pairs(cards) do
		if c>=151 and c<=154 then
			table.insert(result, {c})
		end
	end
	return result
end

-- 获取所有单张牌型，优先给出不能组成其他牌型的牌（如对子，三条，炸弹等）
-- 返回{{}}
function LPokerUtils.getAllSingle(cardsData , tzz)
	if #(cardsData) < 1 then return {} , cardsData end
	cardsData = xtable.copy(cardsData)
	local result = {}
	local bomb , trio , onePair , remainCards
	bomb , remainCards = LPokerUtils.getAllBomb(cardsData , 0)
	trio , remainCards = LPokerUtils.getAllTrio(remainCards , 0)
	onePair , remainCards = LPokerUtils.getAllOnePair(remainCards , 0)

	
	local sortFunc = function(a, b) return a < b end
	table.sort(remainCards, sortFunc)
	table.sort(cardsData, sortFunc)
	for i=1 , #(remainCards) do
		local tmptzz = LPokerUtils.getCardsTypeValue({remainCards[i]})
		if tzz < tmptzz then
			table.insert(result , {cards = {remainCards[i]} , tzz = tmptzz})
		end
	end

	if #result == 0 then
		result = LPokerUtils.getBombAndKokePair(cardsData , tzz)
	end

	if #result == 0 then
		-- 如果无剩余牌了，则拆牌型返回(不拆bomb，bomb可以直接大上)
		for k,v in pairs(cardsData) do
			if not isInBomb(v, bomb) then
				local tmptzz = LPokerUtils.getCardsTypeValue({v})
				if tzz < tmptzz then
					table.insert(result , {cards = {v} , tzz = tmptzz})
				end
			end
		end
	end

	return result
end

function LPokerUtils.getAllSingleEx(cardsData , tzz)
	if #(cardsData) < 1 then return {} , cardsData end
	cardsData = xtable.copy(cardsData)
	local result = {}
	local bomb , trio , onePair , remainCards
	bomb , remainCards = LPokerUtils.getAllBomb(cardsData , 0)
	trio , remainCards = LPokerUtils.getAllTrio(remainCards , 0)
	onePair , remainCards = LPokerUtils.getAllOnePair(remainCards , 0)

	if #remainCards == 0 then
		for i,v in ipairs(onePair) do
			local tmptzz = LPokerUtils.getCardsTypeValue({v.cards[1]})
			local tmptzz2 = LPokerUtils.getCardsTypeValue({v.cards[2]})
			if tmptzz > tzz then
				table.insert(result , {cards = {v.cards[1]} , tzz = tmptzz})
				table.insert(result , {cards = {v.cards[2]} , tzz = tmptzz2})
			end
		end
	end
	local sortFunc = function(a, b) return a < b end
	table.sort(remainCards, sortFunc)
	table.sort(cardsData, sortFunc)
	for i=1 , #(remainCards) do
		local tmptzz = LPokerUtils.getCardsTypeValue({remainCards[i]})
		if tzz < tmptzz then
			table.insert(result , {cards = {remainCards[i]} , tzz = tmptzz})
		end
	end

	return result
end

function LPokerUtils.getMyPair(cards)
	if #cards < 2 then return {} end
	table.sort(cards)
	local result = {}
	local i, n = 1, #cards
	while i <= n - 1 do
		if cards[i]//10 == cards[i+1]//10 then
			table.insert(result , {cards[i], cards[i+1]})
			i = i + 2
		else
			i = i + 1
		end
	end
	return result
end

function LPokerUtils.getAllOnePair(cardsData , tzz, isonlyPair)
	if #(cardsData) < 2 then return {} , cardsData end
	local bomb , trio , onePair , cardsData_
	bomb , cardsData_ = LPokerUtils.getAllBomb(cardsData , 0)
	trio , cardsData_ = LPokerUtils.getAllTrio(cardsData_ , 0)
	
	local cards = LPokerUtils.numToObj(cardsData_)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	for i=1,len - 1 do
		if cards[i].value == cards[i+1].value and not (cards[i].value == 16 or cards[i].value == 17) then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1])}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if not(#(result) > 0 and tmptzz == result[#(result)].tzz) then 
				if tmptzz > tzz then
					table.insert(result , {cards = tmp , tzz = tmptzz})
					table.insert(usedCards ,tmp[1])
					table.insert(usedCards ,tmp[2])
				end
			end
		end
	end

	for _,v in ipairs(trio) do
		if not xtable.contains(usedCards , v.cards[1]) and
			not xtable.contains(usedCards , v.cards[2]) and 
			not xtable.contains(usedCards , v.cards[3]) then
			local tmp = { v.cards[1] , v.cards[2]}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if tmptzz > tzz then
				table.insert(result , {cards = tmp , tzz = tmptzz})
				table.insert(usedCards ,tmp[1])
				table.insert(usedCards ,tmp[2])
			end
		end
	end

	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end
	return result , remainCards
end

function LPokerUtils.getAllOnePairEX(cardsData , tzz)
	if #(cardsData) < 2 then return {} , cardsData end
	local bomb , trio , onePair , jokePair, cardsData_
	bomb , cardsData_ = LPokerUtils.getAllBomb(cardsData , 0)
	trio , cardsData_ = LPokerUtils.getAllTrio(cardsData_ , 0)

	local cards = LPokerUtils.numToObj(cardsData_)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	for i=1,len - 1 do
		if cards[i].value == cards[i+1].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1])}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if not(#(result) > 0 and tmptzz == result[#(result)].tzz) then 
				if tmptzz > tzz and tmp[1] ~= 160 then
					table.insert(result , {cards = tmp , tzz = tmptzz})
					table.insert(usedCards ,tmp[1])
					table.insert(usedCards ,tmp[2])
				end
			end
		end
	end

	if #result == 0 then
		result = LPokerUtils.getBombAndKokePair(cardsData , tzz)
	end
	if #result == 0 then
		for _,v in ipairs(trio) do
			if not xtable.contains(usedCards , v.cards[1]) and
				not xtable.contains(usedCards , v.cards[2]) and 
				not xtable.contains(usedCards , v.cards[3]) then
				local tmp = { v.cards[1] , v.cards[2]}
				local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
				if tmptzz > tzz then
					table.insert(result , {cards = tmp , tzz = tmptzz})
					table.insert(usedCards ,tmp[1])
					table.insert(usedCards ,tmp[2])
				end
			end
		end
	end

	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end
	return result , remainCards
end


--不拆牌，仅获取是一对的牌
function LPokerUtils.getAllOnlyPair(cardsData , tzz)  
	if #(cardsData) < 2 then return {} , cardsData end
	local bomb , trio , onePair , jokePair, cardsData_
	bomb , cardsData_ = LPokerUtils.getAllBomb(cardsData , 0)
	trio , cardsData_ = LPokerUtils.getAllTrio(cardsData_ , 0)
	
	local cards = LPokerUtils.numToObj(cardsData_)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	for i=1,len - 1 do
		if cards[i].value == cards[i+1].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1])}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if not(#(result) > 0 and tmptzz == result[#(result)].tzz) then 
				if tmptzz > tzz and tmp[1] ~= 160 then
					table.insert(result , {cards = tmp , tzz = tmptzz})
					table.insert(usedCards ,tmp[1])
					table.insert(usedCards ,tmp[2])
				end
			end
		end
	end
	return result
end

function LPokerUtils.getMyTrio(cards)
	if #cards < 3 then return {} end
	table.sort(cards)
	local result = {}
	local i, n = 1, #cards
	while i <= n - 2 do
		if cards[i]//10 == cards[i+2]//10 then
			table.insert(result, {cards[i], cards[i+1], cards[i+2]})
			i = i + 3
		else
			i = i + 1
		end
	end
	return result
end

function LPokerUtils.getAllTrio(cardsData , tzz)
	if #(cardsData) < 3 then return {} , cardsData end
	local cards = LPokerUtils.numToObj(cardsData)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	local bomb = LPokerUtils.getAllBomb(cardsData, 0)
	for i=1,len - 2 do
		if cards[i].value == cards[i+2].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1]) ,LPokerUtils.objToNum(cards[i+2])}
			-- 三张任何一张都不能是bomb中的
			local isThereInBomb = isInBomb(tmp[1], bomb) or isInBomb(tmp[2], bomb) or isInBomb(tmp[3], bomb)
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if tmptzz > tzz and not isThereInBomb then
				table.insert(result, {cards = tmp , tzz = tmptzz})
				table.insert(usedCards, tmp[1])
				table.insert(usedCards, tmp[2])
				table.insert(usedCards, tmp[3])
			end
		end
	end

	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end

	return result , remainCards
end

function LPokerUtils.getAllTrioEx(cardsData , tzz)
	if #(cardsData) < 3 then return {} , cardsData end
	local cards = LPokerUtils.numToObj(cardsData)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	local bomb = LPokerUtils.getAllBomb(cardsData, 0)
	for i=1, len - 2 do
		if cards[i].value == cards[i+2].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1]) ,LPokerUtils.objToNum(cards[i+2])}
			-- 三张任何一张都不能是bomb中的
			local isThereInBomb = isInBomb(tmp[1], bomb) or isInBomb(tmp[2], bomb) or isInBomb(tmp[3], bomb)
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if tmptzz > tzz and not isThereInBomb then
				table.insert(result , {cards = tmp , tzz = tmptzz})
				table.insert(usedCards ,tmp[1])
				table.insert(usedCards ,tmp[2])
				table.insert(usedCards ,tmp[3])
			end
		end
	end
	
	if #result == 0 then
		result = LPokerUtils.getBombAndKokePair(cardsData , tzz)
	end

	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end

	return result , remainCards
end

function LPokerUtils.getAllTrioWithSingle(cardsData , tzz)
	if #(cardsData) < 4 then return {} end
	local trios , remainCards = LPokerUtils.getAllTrio(cardsData , 0)
	local bomb , remainCards = LPokerUtils.getAllBomb(cardsData , 0)
	local result = {}
	local tag = false
	for _,tmp in ipairs(trios) do
		local singleCard = nil
		if remainCards == nil or #(remainCards) == 0 then
			local i = 1
			while singleCard == nil  do
				if not(LPokerUtils.numToObj(tmp.cards[1]).value == 
					LPokerUtils.numToObj(cardsData[i]).value) then
					singleCard = cardsData[i]
				end
				i = i + 1
			end
		else
			local ret = nil
			ret = LPokerUtils.getAllSingleEx(remainCards , 0)

			if ret ~= nil and #ret > 0 then
				for i=1, #ret do
					local tt = {}
					tt.tzz = tmp.tzz
					tt.cards = {}
					table.insert(tt.cards , tmp.cards[1])
					table.insert(tt.cards , tmp.cards[2])
					table.insert(tt.cards , tmp.cards[3])

					tt.cards[4] = ret[i].cards[1]
					tt.tzz = LPokerUtils.getCardsTypeValue(tt.cards)
					if tt.tzz > tzz then
						tag = true
						table.insert(result , tt)
					end
				end

			else
				singleCard = remainCards[1]
			end
			
		end

		if tag == false  then
			tmp.cards[4] = singleCard
			tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
			if tmp.tzz > tzz then
				table.insert(result , tmp)
			end
		end
	end
	return result
end

-- 飞机带对
function LPokerUtils.getAllTrioWithPair(cardsData , tzz)
	if #(cardsData) < 5 then return {} end
	local result = { }
	local trios , remainCards = LPokerUtils.getAllTrio(cardsData , 0)
	local onepairs = LPokerUtils.getAllOnePair(remainCards , 0)
	if onepairs and #onepairs > 0 then
		for _,tmp in ipairs(trios) do
			local onepair = {}
			for _,tmponepair in ipairs(onepairs) do
				if not(LPokerUtils.numToObj(tmp.cards[1]).value == 
					LPokerUtils.numToObj(tmponepair.cards[1]).value) then 
					-- onepair = tmponepair
					table.insert(onepair, tmponepair)
					-- break
				end
			end
			if #onepair == 0 then break end
			for i = 1, #onepair do
				local tt ={}
				tt.tzz = tmp.tzz
				tt.cards = {}
				table.insert(tt.cards , tmp.cards[1])
				table.insert(tt.cards , tmp.cards[2])
				table.insert(tt.cards , tmp.cards[3])

				table.insert(tt.cards , onepair[i].cards[1])
				table.insert(tt.cards , onepair[i].cards[2])
				tt.tzz = LPokerUtils.getCardsTypeValue(tt.cards)
				if tt.tzz > tzz then
					table.insert(result , tt)
				end
			end

		end
	end
	if #result == 0 then
		if #onepairs == 0 then 
			onepairs = LPokerUtils.getAllOnePair(cardsData , 0) 
		end 
		for _,tmp in ipairs(trios) do
			local onepair = nil
			for _,tmponepair in ipairs(onepairs) do
				if not(LPokerUtils.numToObj(tmp.cards[1]).value == 
					LPokerUtils.numToObj(tmponepair.cards[1]).value) then 
					onepair = tmponepair
					break
				end
			end
			if onepair == nil then break end
			table.insert(tmp.cards , onepair.cards[1])
			table.insert(tmp.cards , onepair.cards[2])
			tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
			if tmp.tzz > tzz then
				table.insert(result , tmp)
			end
		end
	end
	return result
end

function LPokerUtils.getMyBomb(cards)
	if #cards < 2 then return {} end
	table.sort(cards)
	local result = {}
	local i, n = 1, #cards
	while i <= n - 3 do
		if cards[i]//10 == cards[i+3]//10 then
			table.insert(result, {cards[i], cards[i+1], cards[i+2], cards[i+3]})
			i = i + 4
		else
			i = i + 1
		end
	end
	if cards[n]==170 and cards[n-1]==160 then
		table.insert(result, {160, 170})
	end
	return result
end

-- tzz:特征值
function LPokerUtils.getAllBomb(cardsData , tzz)
	if #(cardsData) < 4 then return {} , cardsData end
	local cards = LPokerUtils.numToObj(cardsData)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	for i=1,len - 3 do
		if cards[i].value == cards[i+3].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1]) ,LPokerUtils.objToNum(cards[i+2]),LPokerUtils.objToNum(cards[i+3])}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if tmptzz > tzz then
				table.insert(result , {cards = tmp , tzz = tmptzz})
				table.insert(usedCards ,tmp[1])
				table.insert(usedCards ,tmp[2])
				table.insert(usedCards ,tmp[3])
				table.insert(usedCards ,tmp[4])
			end
		end
	end
	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end
	return result , remainCards
end

function LPokerUtils.getAllBombEx(cardsData , tzz)
	if #(cardsData) < 4 then return {} , cardsData end
	local cards = LPokerUtils.numToObj(cardsData)
	table.sort(cards , LPokerUtils.sortRise())
	local result = { }
	local usedCards = { }
	local remainCards = { }
	local len = #(cards)
	for i=1,len - 3 do
		if cards[i].value == cards[i+3].value then
			local tmp = { LPokerUtils.objToNum(cards[i]) , LPokerUtils.objToNum(cards[i+1]) ,LPokerUtils.objToNum(cards[i+2]),LPokerUtils.objToNum(cards[i+3])}
			local tmptzz = LPokerUtils.getCardsTypeValue(tmp)
			if tmptzz > tzz then
				table.insert(result , {cards = tmp , tzz = tmptzz})
				table.insert(usedCards ,tmp[1])
				table.insert(usedCards ,tmp[2])
				table.insert(usedCards ,tmp[3])
				table.insert(usedCards ,tmp[4])
			end
		end
	end
	local jokePair = LPokerUtils.getAllJokePair(cardsData)
	if #jokePair > 0 then
		table.insert(result , jokePair[1])
	end
	for i,v in ipairs(cardsData) do
		if not xtable.contains(usedCards , v) and not xtable.contains(remainCards , v) then
			table.insert(remainCards , v)
		end
	end
	return result , remainCards
end

function LPokerUtils.getMyKing(cards)
	local result = {}
	for _,c in pairs(cards) do
		if c >= 160 then
			table.insert(result, {c})
		end
	end
	return result
end

function LPokerUtils.getAllJokePair(cardsData)
	local blackjoke,redjoke = false,false
	for _,v in ipairs(cardsData) do
		if v == 160 then
			blackjoke = true
		end
		if v == 170 then
			redjoke = true
		end
	end
	if blackjoke and redjoke then
		return {{cards = {160,170} , tzz = 51010004}}
	end
	return {}
end

function LPokerUtils.getAllFourWithSingle(cardsData , tzz)
	if #(cardsData) < 5 then return {} end
	local bomb , remainCards = LPokerUtils.getAllBomb(cardsData , 0)
	local result = {}
	for _,tmp in ipairs(bomb) do
		local singleCard = nil
		if remainCards == nil or #(remainCards) == 0 then
			local i = 1
			while singleCard == nil  do
				if not(LPokerUtils.numToObj(tmp.cards[1]).value == 
					LPokerUtils.numToObj(cardsData[i]).value) then
					singleCard = cardsData[i]
				end
				i = i + 1
			end
		else
			singleCard = remainCards[1]
		end

		tmp.cards[5] = singleCard
		tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
		if tmp.tzz > tzz then
			table.insert(result , tmp)
		end
	end
	return result
end

function LPokerUtils.getAllFourWithTwoSingle(cardsData , tzz)
	if #(cardsData) < 6 then return {} end
	local bomb , remainCards = LPokerUtils.getAllBomb(cardsData , 0)
	local result = {}
	-- 给每个bomb配两单
	for _,tmp in ipairs(bomb) do
		local singleCards = { }
		--找到多组bomb时没有单牌了，想要配成4带两单，只能去拆bomb
		if remainCards == nil or #(remainCards) == 0 then
			local i = 1
			while #(singleCards) < 2 and i <= #tmp.cards do
				if not(LPokerUtils.numToObj(tmp.cards[1]).value == 
					LPokerUtils.numToObj(cardsData[i]).value) then
					table.insert(singleCards , cardsData[i])
				end
				i = i + 1
			end
		else
			if #remainCards >= 2 then
				-- 剩余牌中拿两单
				local tmp = LPokerUtils.getAllSingle(remainCards, 0)
				local tmp2 = {}
				for _,v in pairs(tmp) do
					table.insert(tmp2, v.cards[1])
				end
				table.sort(tmp2)
				if tmp2[#tmp2] == 170 and tmp2[#tmp2 - 1] == 160 then
					table.remove(tmp2)
					table.remove(tmp2)
				end
				if #tmp2 >= 2 then
					for k,v in pairs(tmp2) do
						table.insert(singleCards, v)
					end
				else
					--	todo 这里 有一个莫名奇妙的问题
					return {}
				end
			else
				-- 不够了
				return nil
			end
		end

		table.insert(tmp.cards, singleCards[1])
		table.insert(tmp.cards, singleCards[2])
		tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
		if tmp.tzz > tzz then
			table.insert(result , tmp)
		end
	end
	return result
end

function LPokerUtils.getMySingleStraight(cards)
	if #cards < 5 then return {} end
	local v2c = {}
	for _,c in ipairs(cards) do
		local v = c//10
		v2c[v] = v2c[v] or {}
		table.insert(v2c[v], c)
	end
	local result = {}
	local i = 3
	while i <= 10 do
		if v2c[i] and v2c[i+1] and v2c[i+2] and v2c[i+3] and v2c[i+4] then
			local t = {}
			for j=0,4 do
				table.insert(t, table.remove(v2c[i+j]))
				if #v2c[i+j]==0 then
					v2c[i+j] = nil
				end
			end
			table.insert(result, t)
		else
			i = i + 1
		end
	end
	return result
end

function LPokerUtils.getAllSingleStraight(cardsData , tzz)
	if #(cardsData) < 5 then return {} end

	table.sort(cardsData , function(a , b)
		return a < b
	end)

	local a , b , c = LPokerUtils.explodeValue(tzz)
	local cards,cards_value_ = { } , {}

	for _,v in ipairs(cardsData) do
		local value = math.floor(v / 10)
		if not(xtable.contains(cards_value_ , value)) then
			table.insert(cards , v)
			table.insert(cards_value_ , value)
		end
	end
	cards = LPokerUtils.numToObj(cards)
	local len = #(cards)

	if tzz == 0 then
		for i=len,5,-1 do
			a,b,c = 21,i,0
			local min_tzz = LPokerUtils.calculateValue(a , b , c)
			local tmp = LPokerUtils.getAllSingleStraight(cardsData , min_tzz)
			if not(tmp == nil) and #(tmp) > 0 then
				return tmp
			end
		end
		return {}
	end

	if len >= b then
		local result = { }
		for i=1,len - b + 1 do
			local tmp = { }
			tmp.cards = { }
			for j=0,b-1 do
				table.insert(tmp.cards , LPokerUtils.objToNum(cards[i+j]))
			end
			if LPokerUtils.isSingleStraight(tmp.cards) then
				tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
				if tmp.tzz > tzz then
					table.insert(result , tmp)
				end
			end
		end
		return result
	else 
		return {}
	end
end

function LPokerUtils.getMyPairStraight(cards)
	if #cards < 6 then return {} end
	local v2c = {}
	for _,c in ipairs(cards) do
		local v = c//10
		v2c[v] = v2c[v] or {}
		table.insert(v2c[v], c)
	end
	local result = {}
	local i = 3
	while i <= 12 do
		if v2c[i] and v2c[i+1] and v2c[i+2] and #v2c[i]>=2 and #v2c[i+1]>=2 and #v2c[i+2]>=2 then
			local t = {}
			for j=0,2 do
				table.insert(t, table.remove(v2c[i+j]))
				table.insert(t, table.remove(v2c[i+j]))
			end
			table.insert(result, t)
		else
			i = i + 1
		end
	end
	return result
end

function LPokerUtils.getAllPairStraight(cardsData , tzz)
	if #(cardsData) < 6 then return {} end

	local a , b , c = LPokerUtils.explodeValue(tzz)
	local allpairs = LPokerUtils.getAllOnePair(cardsData , 0)

	table.sort(allpairs , function(a , b)
		return a.cards[1] < b.cards[1]
	end)

	local len = #(allpairs)

	if tzz == 0 then
		for i=len,3,-1 do
			a,b,c = 22,i,0
			local min_tzz = LPokerUtils.calculateValue(a , b , c)
			local tmp = LPokerUtils.getAllPairStraight(cardsData , min_tzz)
			if not(tmp == nil) and #(tmp) > 0 then
				return tmp
			end
		end
		return {}
	end
	if len >= b then
		local result = { }
		for i=1,len - b + 1 do
			local tmp = { }
			tmp.cards = { }
			for j=0,b-1 do
				table.insert(tmp.cards , allpairs[i+j].cards[1])
				table.insert(tmp.cards , allpairs[i+j].cards[2])
			end
			if LPokerUtils.isPairStraight(tmp.cards) then
				tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
				if tmp.tzz > tzz then
					table.insert(result , tmp)
				end
			end
		end
		return result
	else 
		return {}
	end
end

function LPokerUtils.getAllTrioStraight(cardsData , tzz)
	if #(cardsData) < 6 then return {} end


	local a , b , c = LPokerUtils.explodeValue(tzz)
	local alltrio = LPokerUtils.getAllTrio(cardsData , 0)
	table.sort(alltrio , function(a , b)
		return a.cards[1] > b.cards[1]
	end)


	local len = #(alltrio)
	if tzz == 0 then
		for i=len,2,-1 do
			a,b,c = 23,i,0
			local min_tzz = LPokerUtils.calculateValue(a , b , c)
			local tmp = LPokerUtils.getAllTrioStraight(cardsData , min_tzz)
			if not(tmp == nil) and #(tmp) > 0 then
				return tmp
			end
		end
		return {}
	end
	if len >= b then
		local result = { }
		for i=1,len - b + 1 do
			local tmp = { }
			tmp.cards = { }
			for j=0,b-1 do
				table.insert(tmp.cards , alltrio[i+j].cards[1])
				table.insert(tmp.cards , alltrio[i+j].cards[2])
				table.insert(tmp.cards , alltrio[i+j].cards[3])
			end
			if LPokerUtils.isTrioStraight(tmp.cards) then
				tmp.tzz = LPokerUtils.getCardsTypeValue(tmp.cards)
				if tmp.tzz > tzz then
					table.insert(result , tmp)
				end
			end
		end
		return result
	else 
		return {}
	end
end

function LPokerUtils.getAllTrioStraightWithSingle(cardsData, tzz)
	local result = { }

	local aa , bb , cc = LPokerUtils.explodeValue(tzz)
	aa = PokerType.trioStraight
	local tzzTri = LPokerUtils.calculateValue(aa , bb , cc)
	if tzz == 0 then
		tzzTri = 0
	end

	local alltriostraigh = LPokerUtils.getAllTrioStraight(cardsData , tzzTri)
	local allsingle = {}--LPokerUtils.getAllSingle(cardsData, 0)

	local len = #alltriostraigh
	if len == 0 then
		return result
	end

	for i, v in ipairs(alltriostraigh) do
		local tzz = LPokerUtils.getCardsTypeValue(alltriostraigh[i].cards)
		local a , b , c = LPokerUtils.explodeValue(tzz)
		allsingle = LPokerUtils.getSingleCards(cardsData , alltriostraigh[i])

		if #allsingle >= b then
			for j = 1, b do
				table.insert(alltriostraigh[i].cards, allsingle[j])
			end
			alltriostraigh[i].tzz = LPokerUtils.getCardsTypeValue(alltriostraigh[i].cards)
			table.insert(result, alltriostraigh[i])
		end
	end

	return result 
end

function LPokerUtils.getSingleCards(cardsData , triostraigh)
	local result = {}
	local resultV = {}
	local tzz = LPokerUtils.getCardsTypeValue(triostraigh.cards)
	local a , b , c = LPokerUtils.explodeValue(tzz)
	local bomb = LPokerUtils.getAllBomb(cardsData , 0)
	local allsingle = LPokerUtils.getAllSingleEx(cardsData, 0)-- LPokerUtils.getAllSingle(cardsData, 0)
	if #allsingle > 0 then
		for i,v in ipairs(allsingle) do
			table.insert(result, v.cards[1])
			local value = LPokerUtils.numToObj(v.cards[1])
			table.insert(resultV, value.value)
		end
		if #allsingle >=  b then
			return result
		end
	end

	for i,v in ipairs(cardsData) do
		if not isInBomb(v, bomb) then
			local tag = false
			for k,vv in pairs(triostraigh.cards) do
				if v == vv then
					tag = true
				end
			end
			if tag == false then
					local value = LPokerUtils.numToObj(v)
					if not xtable.contains(resultV, value.value) then
						table.insert(result, v)
						table.insert(resultV, value.value)
					end
					if #result >= b then
						return result
					end
			end
		end
	end
	return result
end


function LPokerUtils.getAllTrioStraightWithPair(cardsData , tzz)
	local result = { }
	if #cardsData < 6 then
		return result
	end
	local aa , bb , cc = LPokerUtils.explodeValue(tzz)
	aa = PokerType.trioStraight
	local tzzTri = LPokerUtils.calculateValue(aa , bb , cc)

	if tzz == 0 then
		tzzTri = 0
	end

	local alltriostraigh = LPokerUtils.getAllTrioStraight(cardsData , tzzTri)

	local len = #alltriostraigh
	if len == 0 then
		return result
	end

	local pair = LPokerUtils.getAllOnlyPair(cardsData , tzz)


	for i,v in ipairs(alltriostraigh) do
		local tzz = LPokerUtils.getCardsTypeValue(alltriostraigh[i].cards)
		local a , b , c = LPokerUtils.explodeValue(tzz)
		if #pair >= b then
			for j = 1, b do
				table.insert(alltriostraigh[i].cards, pair[j].cards[1])
				table.insert(alltriostraigh[i].cards, pair[j].cards[2])
			end
			table.insert(result, alltriostraigh[i])
		end
	end

	if #result == 0 then
		result = LPokerUtils.getBombAndKokePair(cardsData , tzz)
	end
	if #result == 0 then
		local allPair = LPokerUtils.getAllOnePair(cardsData , tzz)
		for i,v in ipairs(alltriostraigh) do
			local tzz = LPokerUtils.getCardsTypeValue(alltriostraigh[i].cards)
			local a , b , c = LPokerUtils.explodeValue(tzz)
			if #allPair >= 2*b then
				local num = 0
				for j=1, #allPair do
					
					if not xtable.contains(alltriostraigh[i].cards, allPair[j].cards[1]) then
						if num < b then
							table.insert(alltriostraigh[i].cards, allPair[j].cards[1])
						    table.insert(alltriostraigh[i].cards, allPair[j].cards[2])
						    num = num + 1
						end
					end
				end
				if num >= b then
					table.insert(result, alltriostraigh[i])
				end
			end
		end
	end

	return result

end

--[[
	比较大小
	curCards 当前的牌
	lastCards 上一个玩家出的牌，可为空

	返回值 ： -1 表示牌比上家小
			0 表示不符合牌型规则
			1 符合出牌规则
			-100 上家的牌不符合牌型规则（游戏bug）
]]
function LPokerUtils.compareCards(curCards , lastCards)
	local tzz1 = LPokerUtils.getCardsTypeValue(curCards)
	if lastCards == nil then
		if tzz1 > 0 then
			return 1
		end
		return 0
	end

	local tzz2 = LPokerUtils.getCardsTypeValue(lastCards)
	if tzz2 == 0 then
		-- print("上家的牌不符合牌型规则。")
		return -100
	end
	return LPokerUtils.compareTZZ(tzz1 , tzz2)
end


--[[
	比较特征值
	返回 可以出牌返回1 牌小返回-1 牌型不符返回0
]]
function LPokerUtils.compareTZZ(tzz1 , tzz2)
	local a1,b1,c1 = LPokerUtils.explodeValue(tzz1)
	local a2,b2,c2 = LPokerUtils.explodeValue(tzz2)
	if a1 == PokerType.jokePair then
		return 1
	end

	if a1 == a2 and b1 == b2 then
		if c1 > c2 then
			return 1
		else 
			return -1
		end
	end

	if not(a1 == a2) and a1 == PokerType.bomb then
		if a1 > a2 then
			return 1
		else 
			return -1
		end
	end

	if not(a1 == a2) or not(b1 == b2) then
		return 0 
	end
end


--[[
	获取牌型特征值
]]
function LPokerUtils.getCardsTypeValue(cards)
	

	local cardsType = LPokerUtils.getTypeOfCards(cards)

	if cardsType == PokerType.single then
		return LPokerUtils.getSingleTypeValue(cards)

	elseif cardsType == PokerType.jokePair then
		return LPokerUtils.getJokePairTypeValue(cards)

	elseif cardsType == PokerType.onePair then
		return LPokerUtils.getOnPairTypeValue(cards)

	elseif cardsType == PokerType.trio then
		return LPokerUtils.getThreeOfaKindTypeValue(cards)
	
	elseif cardsType == PokerType.bomb then
		return LPokerUtils.getFourOfaKindTypeValue(cards)

	elseif cardsType == PokerType.trioWithSingle then
		return LPokerUtils.getThreeWithSingleTypeValue(cards)

	elseif cardsType == PokerType.trioWithPair then
		return LPokerUtils.getThreeWithPairTypeValue(cards)

	elseif cardsType == PokerType.fourWithSingle then
		return LPokerUtils.getFourWithSingleTypeValue(cards)

	elseif cardsType == PokerType.fourWithTwoSingle then
		return LPokerUtils.getFourWithTwoSingleTypeValue(cards)

	elseif cardsType == PokerType.fourWithTwoPair then
		return LPokerUtils.getFourWithTwoPairTypeValue(cards)

	elseif cardsType == PokerType.singleStraight then
		return LPokerUtils.getSingleStraightTypeValue(cards)

	elseif cardsType == PokerType.pairStraight then
		return LPokerUtils.getPairStraightTypeValue(cards)

	elseif cardsType == PokerType.trioStraight then
		return LPokerUtils.getThreeStraightTypeValue(cards)

	elseif cardsType == PokerType.trioStraightWithSingle then
		return LPokerUtils.getThreeStraightWithSingleTypeValue(cards)

	elseif cardsType == PokerType.trioStraightWithPair then
		return LPokerUtils.getThreeStraightWithPairTypeValue(cards)

	elseif cardsType == PokerType.fourStraight then
		return LPokerUtils.getFourStraightTypeValue(cards)

	elseif cardsType == PokerType.fourWithSingle then
		return LPokerUtils.getFourWithSingleTypeValue(cards)

	elseif cardsType == PokerType.fourStraightWithTwoSingle then
		return LPokerUtils.getFourStraightWithTwoSingleTypeValue(cards)

	elseif cardsType == PokerType.fourStraightWithTwoPair then
		return LPokerUtils.getFourStraightWithTwoPairTypeValue(cards)
	end
	
	return 0
end

--[[
	获取单张的特征值
]]
function LPokerUtils.getSingleTypeValue(cards)
	local a = PokerType.single
	local b = 1
	local c = math.floor(cards[1] / 10)
	return LPokerUtils.calculateValue(a , b , c)
end

--[[
	获取王对的特征值
]]
function LPokerUtils.getJokePairTypeValue(cards)
	local a = PokerType.jokePair
	local b = 1
	local c = 0
	return LPokerUtils.calculateValue(a , b , c)
end

--[[
	获取对子的特征值
]]
function LPokerUtils.getOnPairTypeValue(cards)
	local a = PokerType.onePair
	local b = 1
	local c = math.floor(cards[1] / 10)
	return LPokerUtils.calculateValue(a , b , c)
end

--[[
	获取三张的特征值
]]
function LPokerUtils.getThreeOfaKindTypeValue(cards)
	local a = PokerType.trio
	local b = 1
	local c = math.floor(cards[1] / 10)
	return LPokerUtils.calculateValue(a , b , c)
end

--[[
	获取炸弹的特征值
]]
function LPokerUtils.getFourOfaKindTypeValue(cards)
	local a = PokerType.bomb
	local b = 1
	local c = math.floor(cards[1] / 10)
	return LPokerUtils.calculateValue(a , b , c)
end

-- 获取三带单的特征值
function LPokerUtils.getThreeWithSingleTypeValue(cards)
	local a = PokerType.trioWithSingle
	local b = 1
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-2 do
		if cards[i].value == cards[i+2].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取三带对的特征值
function LPokerUtils.getThreeWithPairTypeValue(cards)
	local a = PokerType.trioWithPair
	local b = 1
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-2 do
		if cards[i].value == cards[i+2].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四带单的特征值
function LPokerUtils.getFourWithSingleTypeValue(cards)
	local a = PokerType.fourWithSingle
	local b = 1
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四带两单的特征值
function LPokerUtils.getFourWithTwoSingleTypeValue(cards)
	local a = PokerType.fourWithTwoSingle
	local b = 1
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四带对的特征值
function LPokerUtils.getFourWithTwoPairTypeValue(cards)
	local a = PokerType.fourWithTwoPair
	local b = 1
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取单顺的特征值
function LPokerUtils.getSingleStraightTypeValue(cards)
	local a = PokerType.singleStraight
	local b = #(cards)
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	c = cards[1].value
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取双顺的特征值
function LPokerUtils.getPairStraightTypeValue(cards)
	local a = PokerType.pairStraight
	local b = #(cards) / 2
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
 	c = cards[1].value
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取三顺的特征值
function LPokerUtils.getThreeStraightTypeValue(cards)
	local a = PokerType.trioStraight
	local b = #(cards) / 3
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
 	c = cards[1].value
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取三顺带单（飞机）的特征值
function LPokerUtils.getThreeStraightWithSingleTypeValue(cards)
	local a = PokerType.trioStraightWithSingle
	local b = #(cards) / 4
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-2 do
		if cards[i].value == cards[i+2].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取三顺带对的特征值
function LPokerUtils.getThreeStraightWithPairTypeValue(cards)
	local a = PokerType.trioStraightWithPair
	local b = #(cards) / 5
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-2 do
		if cards[i].value == cards[i+2].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四顺（航天飞机）的特征值
function LPokerUtils.getFourStraightTypeValue(cards)
	local a = PokerType.fourStraight
	local b = #(cards) / 4
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
 	c = cards[1].value
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四顺带单的特征值
function LPokerUtils.getFourWithSingleTypeValue(cards)
	local a = PokerType.fourStraightWithSingle
	local b = #(cards) / 5
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四带两单的特征值
function LPokerUtils.getFourStraightWithTwoSingleTypeValue(cards)
	local a = PokerType.fourStraightWithTwoSingle
	local b = #(cards) / 6
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

--获取四带两对的特征值
function LPokerUtils.getFourStraightWithTwoPairTypeValue(cards)
	local a = PokerType.fourStraightWithTwoPair
	local b = #(cards) / 8
	local c 
	cards = LPokerUtils.numToObj(cards)
	table.sort(cards , LPokerUtils.sortRise())
	for i=1,#(cards)-3 do
		if cards[i].value == cards[i+3].value then
			c = cards[i].value
		end
	end
	return LPokerUtils.calculateValue(a , b ,c)
end

-- 计算特征值
function LPokerUtils.calculateValue(a , b , c)
	local fixValue = 4 -- 预留
	return a * 1000000 + b * 10000 + c * 10 + fixValue
end

-- 分解特征值
function LPokerUtils.explodeValue(value)
	local a , b , c

	a , value =  math.modf(value / 1000000)
	value = value * 100000
	b , value = math.modf(value  / 1000)
	value = value * 1000
	c = math.modf(value)

	return a , b , c
end

--[[
	获取牌型
	0为不符合牌型规则
]]
function LPokerUtils.getTypeOfCards(cards)
	if LPokerUtils.isSingle(cards) then
		return PokerType.single

	elseif LPokerUtils.isJokePair(cards) then
		return PokerType.jokePair

	elseif LPokerUtils.isOnePair(cards) then
		return PokerType.onePair

	elseif LPokerUtils.isTrio(cards) then
		return PokerType.trio

	elseif LPokerUtils.isTrioWithSingle(cards) then
		return PokerType.trioWithSingle

	elseif LPokerUtils.isTrioWithPair(cards) then
		return PokerType.trioWithPair

	elseif LPokerUtils.isFourOfaKind(cards) then
		return PokerType.bomb

--	elseif LPokerUtils.isFourWithOnePair(cards) then
--		return PokerType.fourWithOnePair

	elseif LPokerUtils.isFourWithTwoSingle(cards) then
		return PokerType.fourWithTwoSingle

	elseif LPokerUtils.isFourWithTwoPair(cards) then
		return PokerType.fourWithTwoPair

	elseif LPokerUtils.isSingleStraight(cards) then
		return PokerType.singleStraight

	elseif LPokerUtils.isPairStraight(cards) then
		return PokerType.pairStraight

	elseif LPokerUtils.isTrioStraight(cards) then
		return PokerType.trioStraight

	elseif LPokerUtils.isTrioStraightWithSingle(cards) then
		return PokerType.trioStraightWithSingle

	elseif LPokerUtils.isTrioStraightWithPair(cards) then
		return PokerType.trioStraightWithPair

	elseif LPokerUtils.isFourStraight(cards) then
		return PokerType.fourStraight

	elseif LPokerUtils.isFourStraightWithSingle(cards) then
		return PokerType.fourStraightWithSingle

	elseif LPokerUtils.isFourStraightWithTwoSingle(cards) then
		return PokerType.fourStraightWithTwoSingle

	elseif LPokerUtils.isFourStraightWithTwoPair(cards) then
		return PokerType.fourStraightWithTwoPair

	else
		return 0
	end
end

-- 
function LPokerUtils.isSingle(cards)
	return #(cards) == 1
end

-- 是否为王对
function LPokerUtils.isJokePair(cards)
	if #(cards) == 2 then
		cards = LPokerUtils.numToObj(cards)
		if cards[1].value == cards[2].value and 
			cards[1].value == 16 then
			return true
		end
	end
	return false
end

-- 是否为一对
function LPokerUtils.isOnePair(cards)
	if #(cards) == 2 then
		cards = LPokerUtils.numToObj(cards)
		if cards[1].value == cards[2].value and 
			cards[1].value < 16 then
			return true
		end
	end
	return false
end

-- 是否为三条
function LPokerUtils.isTrio(cards)
	if #(cards) == 3 then
		cards = LPokerUtils.numToObj(cards)
		if cards[1].value == cards[2].value and 
			cards[2].value == cards[3].value then
			return true
		end
	end
	return false
end

-- 是否为三带一
function LPokerUtils.isTrioWithSingle(cards)
	if #(cards) == 4 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		if cards[1].value == cards[2].value then
			if cards[1].value == cards[3].value and
			 not(cards[3].value == cards[4].value) then
				return true
			end
		else 
			if cards[2].value == cards[3].value and
			 cards[2].value == cards[4].value then
				return true
			end
		end
	end
	return false
end

-- 是否是大小王
function LPokerUtils.isKing(cardObj)
	return cardObj.value == 16
end

-- 是否为三带对
function LPokerUtils.isTrioWithPair(cards)
	if #(cards) == 5 then
		cards = LPokerUtils.numToObj(cards)
		
		table.sort(cards , LPokerUtils.sortRise())
		if cards[1].value == cards[2].value and 
					cards[2].value == cards[3].value then
			if cards[4].value == cards[5].value and not (LPokerUtils.isKing(cards[4]) or LPokerUtils.isKing(cards[5])) and
				not(cards[3].value == cards[4].value) then
				return true
			end
		elseif cards[3].value == cards[4].value and  cards[5].value == cards[4].value then
			if cards[1].value == cards[2].value and 
				not (LPokerUtils.isKing(cards[1]) or LPokerUtils.isKing(cards[2])) and
				not(cards[3].value == cards[2].value) then
					return true
			end
		end
	end
	return false
end

-- 是否为四条（炸弹）
function LPokerUtils.isFourOfaKind(cards)
	if #(cards) == 4 then
		cards = LPokerUtils.numToObj(cards)
		if cards[1].value == cards[2].value and 
			cards[2].value == cards[3].value and 
			cards[3].value == cards[4].value then
			return true
		end
	end
	return false
end

-- 是否为四带单
function LPokerUtils.isFourWithSingle(cards)
	if #(cards) == 5 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		if cards[1].value == cards[4].value and 
			not(cards[5].value == cards[4].value) then
			return true
		elseif cards[2].value == cards[5].value and 
			not(cards[1].value == cards[2].value) then
			return true
		end
	end
	return false
end

-- 是否为四带一对
function LPokerUtils.isFourWithOnePair(cards)
	if #(cards) == 6 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		if cards[1].value == cards[4].value and 
			not(cards[5].value == cards[4].value) and 
			cards[5].value == cards[6].value then
			return true
		elseif cards[3].value == cards[6].value and 
			not(cards[3].value == cards[2].value) and 
			cards[1].value == cards[2].value then
			return true
		end
	end
	return false
end

-- 是否为四带两单
function LPokerUtils.isFourWithTwoSingle(cards)
	local jk = LPokerUtils.getAllJokePair(cards)
	if jk and #jk > 0 then
		return false
	end
	if #(cards) == 6 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		if cards[1].value == cards[4].value and 
			not(cards[5].value == cards[4].value) then--and 
--			not(cards[5].value == cards[6].value) then
			return true
		elseif cards[2].value == cards[5].value and 
			not(cards[1].value == cards[2].value) and 
			not(cards[1].value == cards[6].value) then
			return true
		elseif cards[3].value == cards[6].value and 
			not(cards[3].value == cards[2].value) then--and 
--			not(cards[1].value == cards[2].value) then
			return true
		end
	end
	return false
end

-- 是否为四带两对
function LPokerUtils.isFourWithTwoPair(cards)
	if LPokerUtils.isFourStraight(cards) then
		return false
	end
	if #(cards) == 8 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		if 		cards[1].value == cards[4].value and 
				cards[5].value == cards[6].value and
				cards[7].value == cards[8].value then
			return true
		elseif 	cards[3].value == cards[6].value and 
				cards[1].value == cards[2].value and
				cards[7].value == cards[8].value then
			return true
		elseif 	cards[5].value == cards[8].value and 
				cards[1].value == cards[2].value and
				cards[3].value == cards[4].value then
			return true
		end
	end
	return false
end

-- 是否为单顺
function LPokerUtils.isSingleStraight(cards)
	local len = #(cards)
	if len > 4 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		for i,v in ipairs(cards) do
			if i > 1 then
				if not(cards[i].value - cards[i-1].value == 1 and 
					cards[i].value < 15) then
					return false
				end
			end
		end
		return true
	end

	return false
end

-- 是否为双顺
function LPokerUtils.isPairStraight(cards)
	local len = #(cards)
	if not(len / 2 == math.floor(len / 2)) then
		return false
	end
	if len > 5 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		for i=1,len-2,2 do
			if not(cards[i].value == cards[i+1].value and 
				cards[i].value + 1 == cards[i+2].value and
				cards[i+2].value < 15) then
				return false
			end
		end
		return true
	end

	return false
end

-- 是否为三顺
function LPokerUtils.isTrioStraight(cards)
	local len = #(cards)
	if not(len / 3 == math.floor(len / 3)) then
		return false
	end
	if len > 5 then
		cards = LPokerUtils.numToObj(cards)
		table.sort(cards , LPokerUtils.sortRise())
		for i=1,len-3,3 do
			if not(cards[i].value == cards[i+2].value and 
				cards[i].value + 1 == cards[i+3].value and
				cards[i].value + 1 == cards[i+5].value and
				cards[i+3].value < 15) then
				return false
			end
		end
		return true
	end

	return false
end

-- 是否为三顺带单牌
function LPokerUtils.isTrioStraightWithSingle(cards)

	local len = #(cards)
	if not(len / 4 == math.floor(len / 4)) then
		return false
	end
	if len > 7 then
		local group1 = { } -- 三张的牌
		local group2 = { } -- 散牌	
		cards = LPokerUtils.numToObj(cards)
		local index_of_group = {}
		table.sort(cards , LPokerUtils.sortRise())
		local i = 1
		while i < len do
			if i < len - 1 and (cards[i].value == cards[i+2].value)then
				table.insert(group1 , cards[i])
				table.insert(group1 , cards[i+1])
				table.insert(group1 , cards[i+2])
				table.insert(index_of_group , i)
				table.insert(index_of_group , i+1)
				table.insert(index_of_group , i+2)
				i = i + 3
			else
				i = i + 1
			end

		end

		local temp = {}
		local temp2 = {}
		if #group1/3 > len/4 then
			local idx = 1 + (3*(len/4-1))
			if (group1[idx].value - group1[1].value) ~= (len/4 - 1) then
				for i=4,#(group1) do
					table.insert(temp, group1[i])
					table.insert(temp2, index_of_group[i])
				end
			else
				for i=1,#(group1) - 3 do
					table.insert(temp, group1[i])
					table.insert(temp2, index_of_group[i])
				end
			end

			group1 = {}
			group1 = temp
			index_of_group = {}
			index_of_group = temp2
		end

		for i=1,#(cards) do
			local tag = true
			for j,v in ipairs(index_of_group) do

				if v == i then
				 	tag = false
				end
			end
			if tag == true then
				table.insert(group2 , cards[i])
			end

		end
		
		if LPokerUtils.isTrioStraight(LPokerUtils.objToNum(group1))  then
			if #(group1) / 3 == #(group2) then
				return true
			end
		end
	end
	return false
end

-- 是否为三顺带对
function LPokerUtils.isTrioStraightWithPair(cards)
	local len = #(cards)
	if not(len / 5 == math.floor(len / 5)) then
		return false
	end

	if len > 9 then
		local group1 = { } -- 三张的牌
		local group2 = { } -- 散牌	
		cards = LPokerUtils.numToObj(cards)
		local index_of_group = {}
		table.sort(cards , LPokerUtils.sortRise())
		for i=1,len do
			if i < len - 1 and (cards[i].value == cards[i+2].value)then
				table.insert(group1 , cards[i])
				table.insert(group1 , cards[i+1])
				table.insert(group1 , cards[i+2])
				table.insert(index_of_group , i)
				table.insert(index_of_group , i+1)
				table.insert(index_of_group , i+2)
			end
		end
		for i=1,#(cards) do
			local tag = true
			for j,v in ipairs(index_of_group) do

				if v == i then
				 	tag = false
				end
			end
			if tag == true then
				table.insert(group2 , cards[i])
			end

		end

		if LPokerUtils.isTrioStraight(LPokerUtils.objToNum(group1))  then
			if #(group1) / 3 == #(group2)  / 2 then
				table.sort(group2 , LPokerUtils.sortRise())
				for i=1,#(group2)-1,2 do
					if not(group2[i].value == group2[i+1].value) then
						return false
					end
				end
				return true
			end
		end
	end
	return false
end




-- 是否为四顺（航天飞机，不带牌）
function LPokerUtils.isFourStraight(cards)
	return false
end

-- 是否为四顺带单（航天飞机）
function LPokerUtils.isFourStraightWithSingle(cards)
	return false
end

-- 是否为四顺带两单（航天飞机）
function LPokerUtils.isFourStraightWithTwoSingle(cards)
	return false
end

function LPokerUtils.isFourStraightWithTwoPair(cards)
	return false
end

--[[
 牌值121方块Q -> 牌对象(类型1，值12)
 支持单张和多张
]]
function LPokerUtils.numToObj(num)
	if type(num) == "number" then
		local card = { }
		card.value = math.floor(num / 10)
		card.type = num - card.value * 10 
		-- 大小王
		if num == 160 then
			card.type = 5
			card.value = 16
		end
		if num == 170 then
			card.type = 6
			card.value = 16
		end

		return card
	elseif type(num) == "table" then
		local cards = { }
		for i=1,#(num) do
			cards[i] = LPokerUtils.numToObj(num[i])
		end
		return cards
	else
		return
	end
end

function LPokerUtils.objToNum(obj)
	if not (obj.type and obj.value) then
		local cards = { }
		for i=1,#(obj) do
			cards[i] = LPokerUtils.objToNum(obj[i])
		end
		return cards
	else
		local card = obj.type + obj.value * 10
		if obj.type == 5 and obj.value == 16 then
			card = 160
		elseif obj.type == 6 and obj.value == 16 then
			card = 170
		end
		return card
	end
end

function LPokerUtils.sortRise()
	return function(a , b)
		if a.value == b.value then
			return a.type < b.type
		end
		return a.value < b.value
	end
end

function LPokerUtils.sortDescent()
	return function(a , b)
		if a.value == b.value then
			return a.type > b.type
		end
		return a.value > b.value
	end
end

function LPokerUtils.sort_tzz(t)
	table.sort(t, function(a,b)
			return a.tzz > b.tzz
		end)
end

function LPokerUtils.sort_type(t)
	table.sort(t, function(a,b)
			if a._type == b._type then
				return a.score < b.score
			else
				return a._type > b._type
			end
		end)
end

function LPokerUtils.get_point_nums(cards)
	--返回key 点数  value 数量
	local ret = {}
	for _,v in pairs(cards) do
		if not ret[v.value] then
			ret[v.value] = 1
		else
			ret[v.value] = ret[v.value] + 1
		end
	end
	return ret
end

--找出单牌(左边没有右边也没有的) 2 和 鬼牌直接定为单牌
function LPokerUtils.get_single_cards(cards)
	--找到的单牌
	local single_cards = {}
	--找完后剩下的牌
	local remain_cards = {}
	for k,v in pairs(cards) do
		if k < 14 and not cards[k-1] and not cards[k+1] then
			single_cards[k] = v
		elseif k == 14 and not cards[k-1] then
			single_cards[k] = v
		elseif k >= 15 then
			single_cards[k] = v
		else
			remain_cards[k] = v
		end
	end
	--remain_cards 暂时没用
	return single_cards,remain_cards
end



----计分
local BASE_TYPE_SCORE = 0
local MAX_TYPE_SCORE = 15
function LPokerUtils.get_base_score(c)
	return c//10 + (- 10)
end

function LPokerUtils.get_base_cards(cards)
	local cards_Obj = LPokerUtils.numToObj(cards)
	local print_cards = LPokerUtils.get_point_nums(cards_Obj)
	local max_card = 0
	for k,v in pairs(print_cards) do
		if v >= 3 and max_card < k then
			max_card = k
		end
	end
	for k,v in pairs(cards_Obj) do
		if v.value == max_card then
			return v.value * 10 + v.type
		end
	end
end

function LPokerUtils.get_single_score(cards)
	return LPokerUtils.get_base_score(cards[1])
end

function LPokerUtils.get_joke_pair_score(cards)
	return MAX_TYPE_SCORE + 7
end

function LPokerUtils.get_on_pair_score(cards)
	return LPokerUtils.get_base_score(cards[1]) + 2
end

function LPokerUtils.get_trio_score(cards)
	local c = LPokerUtils.get_base_cards(cards)
	return LPokerUtils.get_base_score(c) + 2
end

function LPokerUtils.get_bomb_score(cards)
	return LPokerUtils.get_base_score(cards[1]) + 8 + 7
end

function LPokerUtils.get_four_single_score(cards)
	local c = LPokerUtils.get_base_cards(cards)
	return (LPokerUtils.get_base_score(c) + 8 + 1) // 2
end

function LPokerUtils.single_straight(cards)
	return LPokerUtils.get_base_score(cards[#cards]) + 3
end

function LPokerUtils.pair_straight(cards)
	return LPokerUtils.get_base_score(cards[#cards]) + 3
end

function LPokerUtils.trio_straight(cards)
	local c = LPokerUtils.get_base_cards(cards)
	return LPokerUtils.get_base_score(c) + 3
end

function LPokerUtils.get_cards_score(cards)
	local cardsType = LPokerUtils.getTypeOfCards(cards)
	--print("cardsType分值为:",inspect(cardsType))
	if cardsType == PokerType.single then
		return LPokerUtils.get_single_score(cards)
	elseif cardsType == PokerType.jokePair then
		return LPokerUtils.get_joke_pair_score(cards)

	elseif cardsType == PokerType.onePair then
		return LPokerUtils.get_on_pair_score(cards)

	elseif cardsType == PokerType.trio then
		return LPokerUtils.get_trio_score(cards)
	
	elseif cardsType == PokerType.bomb then
		return LPokerUtils.get_bomb_score(cards)

	elseif cardsType == PokerType.trioWithSingle then
		return LPokerUtils.get_trio_score(cards)

	elseif cardsType == PokerType.trioWithPair then
		return LPokerUtils.get_trio_score(cards)

	elseif cardsType == PokerType.fourWithSingle then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.fourWithTwoSingle then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.fourWithTwoPair then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.singleStraight then
		return LPokerUtils.single_straight(cards)

	elseif cardsType == PokerType.pairStraight then
		return LPokerUtils.pair_straight(cards)

	elseif cardsType == PokerType.trioStraight then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.trioStraightWithSingle then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.trioStraightWithPair then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.fourStraight then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.fourStraightWithTwoSingle then
		return LPokerUtils.get_four_single_score(cards)

	elseif cardsType == PokerType.fourStraightWithTwoPair then
		return LPokerUtils.get_four_single_score(cards)
	end
	
end

function LPokerUtils.free_value(nums)
	for k,v in pairs(nums) do
		if v == 0 then
			nums[k] = nil
		end
	end
end

function LPokerUtils.del_cards_value(nums,cards)
	for _,v in pairs(cards) do
		if nums[v] then
			nums[v] = nums[v] - 1
		end
	end
end

--nums 牌    num ：长度    index 最大：99 最小：1
function LPokerUtils.get_single_straight(nums,num,index)
	if not num then
		num = 5
	end

	local ret = {}
	for k,v in pairs(nums) do
		if v then
			for i=k,k+num - 1 do
				if not nums[i] then
					ret = {}
					break
				end
				table.insert(ret,i)
			end
			if #ret == num then

				break
			end
		end
	end
	if next(ret) == nil then
		return
	else
		return ret
	end
end
--local x = LPokerUtils.get_cards_score{151,152,153,154,122,123}
--print("牌型分值为:",inspect(x))
--[[
local cards = {41,42,54,61,64,74,83,93,103,114,121,122,123,141,144,151,152,153,160,124}
local cards_Obj = LPokerUtils.numToObj(cards)
print(inspect(cards_Obj))
local cards_nums =LPokerUtils.get_point_nums(cards_Obj)
print(inspect(cards_nums))
local single_cards,remain_cards = LPokerUtils.get_single_cards(cards_nums)

--剩下牌里面去掉炸弹
local bombs = {}
for k,v in pairs(remain_cards) do
	if v == 4 then
		table.insert(bombs,k)

		remain_cards[k] = remain_cards[k] - 4
	end
end
LPokerUtils.free_value(remain_cards)

local x = LPokerUtils.get_single_straight(remain_cards,5)
LPokerUtils.del_cards_value(remain_cards,x)
LPokerUtils.free_value(remain_cards)

print("bombs",inspect(bombs))
print(inspect(single_cards))
print("remain_cards",inspect(remain_cards))

print("---------------")
--local x = LPokerUtils.getHintCardsType(cards,0,2)
--local x,y,z,a = LPokerUtils.getAllSingle(cards)
print(inspect(x))
print(inspect(y))
print(inspect(z))
print(inspect(a))
]]