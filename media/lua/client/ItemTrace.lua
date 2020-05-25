--
-- Created by IntelliJ IDEA.
-- User: ProjectSky
-- Date: 2016/12/18
-- Time: 3:01
-- Add inventory item Tag
--

local ItemTrace = {}
ItemTrace.NAME = "Item Tag";
ItemTrace.AUTHOR = "ProjectSky";
ItemTrace.VERSION = "0.0.7";

print("Mod Loaded: " .. ItemTrace.NAME .. " by " .. ItemTrace.AUTHOR .. " (v" .. ItemTrace.VERSION .. ")");

-- 此函数用来将数据保存至modData，_I _O 是为了尽量缩减字符数量，且尽量避免命名冲突，减少保存的数据大小
-- @param item
function ItemTrace.loadData(item)
	if item:getModData()['_I'] == nil or item:getModData()['_O'] == nil then
		item:getModData()['_I'] = getCurrentUserSteamID()
		item:getModData()['_O'] = getOnlineUsername()
  end
end

-- 此函数用来处理大容量和高负重率容器
-- @param item
function ItemTrace.HandleItem(item)
  if item:getCategory() == "Container" then -- 如果接受的物品参数为容器则进行下一步处理
    if item:getFullType() == "Hydrocraft.HCWagonoxen" then -- 牛车？将其容量设置为300
      item:setCapacity(300);
    end
    if item:getWeightReduction() >= 80 then -- 如果容器负重率 >= 80则将其设置为80
      item:setWeightReduction(80);
    end
  end
end

-- 此函数用来处理大容量和高负重率容器。目前并不可靠，而且标记地面物品似乎没有必要，后期可能会弃用
function ItemTrace.HandleFloorItem()
  local cell = getWorld():getCell()
  local char = getPlayer()
  local x = char:getX()
  local y = char:getY()
  local z = char:getZ()
  for dy = -1, 1 do --有时候玩家脚下的物品比较远会出现无法标记的情况，稍微扩大一点范围即可解决
    for dx = -1, 1 do
      local sq = cell:getGridSquare(x + dx, y + dy, z)
      if sq ~= nil then
        for i = sq:getObjects():size(), 1, -1 do
          local obj = sq:getObjects():get(i - 1)
          if instanceof(obj, 'IsoWorldInventoryObject') then
            ItemTrace.loadData(obj:getItem())
          end
        end
      end
    end
  end
end

-- 此函数用来判断是否激活插件
-- @return true or false
function ItemTrace.IsActive()
  local GameMode = getCore():getGameMode()
  local SteamMode = getSteamModeActive()
  if GameMode == "Multiplayer" and SteamMode then --是多人且Steam模式激活，返回true
    return true
    else
    Events.OnPlayerMove.Remove(ItemTrace.HandleFloorItem) --不是多人模式则移除OnPlayerMove事件回调，返回false
    return false
  end
end

-- 此函数调用ISToolTipInv.render方法
local render = ISToolTipInv.render
function ISToolTipInv:render()
  if not ItemTrace.IsActive() then
    render(self)
    return
  end
  local modData = self.item:getModData()
  local inventory = getPlayer():getInventory()
  local items = inventory:getItems()
  for i = 0, items:size() - 1 do
    --ItemTrace.HandleItem(items:get(i))
    --ItemTrace.loadData(items:get(i))
    if items:get(i):getCategory() == "Container" then --判断是否容器
      if items:get(i):getInventory():contains(self.item) then --判断物品是否存在于玩家库存中，防止标记非玩家库存内的物品。
        ItemTrace.HandleItem(self.item)
        ItemTrace.loadData(self.item)
      end
    end
  end
  
  
  if inventory:contains(self.item) then
    ItemTrace.HandleItem(self.item) --仅标记鼠标选中的物品（假设玩家有1000个钉子，如果都打上标记不仅没有必要还会占用非常多的资源，如果仅标记选中物品则可以节省不少资源）
    ItemTrace.loadData(self.item)
  end
  
  
  local owner_text = getText("Tooltip_item_Owner")
  local id_text = getText("Tooltip_item_ID")
  if modData["_O"] ~= nil then
    owner_text = owner_text .. modData["_O"]
  end
  if modData["_I"] ~= nil then
    id_text = id_text .. modData["_I"]
  end
  local old = self.item:getTooltip()
  if owner_text ~= getText("Tooltip_item_Owner") or id_text ~= getText("Tooltip_item_ID") then
    --if self.item:getModule() == "ORGM" then -- ORGM的提示框有点问题，不能按照文字宽带自动调整，待后期解决
    --  self.item:setTooltip(owner_text .. "\n" .. id_text)
    --else
    self.item:setTooltip(owner_text .. "\n" .. id_text)
    --end
  end
  render(self)
  self.item:setTooltip(old)
end

Events.OnPlayerMove.Add(ItemTrace.HandleFloorItem)