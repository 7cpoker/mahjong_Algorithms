local M = {}

require "landlord_poker"
local inspect = require "inspect"

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
  local cards = {41,42,54,61,64,74,83,93,103,114,121,122,123,141,144,151,152,153,160,124}--set--{123, 82, 62, 124, 61, 122, 153, 144, 64, 52, 84, 34, 114, 31, 121, 53, 103}
  local set_t = table_copy_table(cards)
  local cards_Obj = LPokerUtils.numToObj(set_t)
  local cards_nums =LPokerUtils.get_point_nums(cards_Obj)
  local single_cards,remain_cards = LPokerUtils.get_single_cards(cards_nums)
  --第一步拆分完成
  --把拆分出来的牌从手牌中分出来
  --local separate_cards = M.separate_card(set_t,single_cards)
  print(inspect(single_cards))


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



function M.dorp(t,c)
    for i,v in ipairs(t) do
        if v == c then
            return table.remove(t,i)
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

function M.separate_card(set,cards)
  local ret = {}
  for k,v in pairs(M.get_origin_data(set,cards)) do
    table.insert(ret,M.dorp(set,v)) 
  end

  return ret
end

--M.split()
local x = {
  [3] = 3,
  [4] = 2,
  [5] = 2,
  [6] = 1,
  [8] = 2,
  [9] = 2,
  [10] = 2,
  [11] = 2,
  [12] = 2
}

for k,v in pairs(x) do
    if not v then
      break
    end
    print(k,v)
end