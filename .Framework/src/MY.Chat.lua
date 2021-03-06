-----------------------------------------------
-- @Desc  : 茗伊插件
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-08-13 22:25:44
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
-----------------------------------------------
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
MY = MY or {}
MY.Chat = MY.Chat or {}
local _C, _L = {tPeekPlayer = {}}, MY.LoadLangPack()
local EMPTY_TABLE = SetmetaReadonly({})

-- 海鳗里面抠出来的
-- 聊天复制并发布
MY.Chat.RepeatChatLine = function(hTime)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	MY.Chat.CopyChatLine(hTime)
	local tMsg = edit:GetTextStruct()
	if #tMsg == 0 then
		return
	end
	local nChannel, szName = EditBox_GetChannel()
	if MY.CanTalk(nChannel) then
		GetClientPlayer().Talk(nChannel, szName or "", tMsg)
		edit:ClearText()
	end
end

-- 聊天删除行
MY.Chat.RemoveChatLine = function(hTime)
	local nIndex   = hTime:GetIndex()
	local hHandle  = hTime:GetParent()
	local nCount   = hHandle:GetItemCount()
	local bCurrent = true
	for i = nIndex, nCount - 1 do
		local hItem = hHandle:Lookup(nIndex)
		if hItem:GetType() == "Text" and
		(hItem:GetName() == 'timelink' or
		 hItem:GetName() == 'copylink' or
		 hItem:GetName() == 'copy') then
		-- timestrap found
			if not bCurrent then
			-- is not current timestrap
				break
			end
		else -- current timestrap ended
			bCurrent = false
		end -- remove until next timestrap
		hHandle:RemoveItem(hItem)
	end
	hHandle:FormatAllItemPos()
end

-- 聊天表情初始化
_C.nMaxEmotionLen = 0
_C.InitEmotion = function()
	if not _C.tEmotion then
		local t = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			local t1 = {
				nFrame = tLine.nFrame,
				dwID   = tLine.dwID or (10000 + i),
				szCmd  = tLine.szCommand,
				szType = tLine.szType,
				szImageFile = tLine.szImageFile or 'ui/Image/UICommon/Talk_face.UITex'
			}
			t[t1.dwID] = t1
			t[t1.szCmd] = t1
			t[t1.szImageFile..','..t1.nFrame..','..t1.szType] = t1
			_C.nMaxEmotionLen = math.max(_C.nMaxEmotionLen, wstring.len(t1.szCmd))
		end
		_C.tEmotion = t
	end
end

-- 获取聊天表情列表
-- typedef emo table
-- (emo[]) MY.Chat.GetEmotion()                             -- 返回所有表情列表
-- (emo)   MY.Chat.GetEmotion(szCommand)                    -- 返回指定Cmd的表情
-- (emo)   MY.Chat.GetEmotion(szImageFile, nFrame, szType)  -- 返回指定图标的表情
MY.Chat.GetEmotion = function(arg0, arg1, arg2)
	_C.InitEmotion()
	local t
	if not arg0 then
		t = _C.tEmotion
	elseif not arg1 then
		t = _C.tEmotion[arg0]
	elseif arg2 then
		arg0 = string.gsub(arg0, '\\\\', '\\')
		t = _C.tEmotion[arg0..','..arg1..','..arg2]
	end
	return clone(t)
end

-- 获取复制聊天行Text
MY.Chat.GetCopyLinkText = function(szText, rgbf)
	szText = szText or _L[' * ']
	rgbf   = rgbf   or { f = 10 }
	
	return GetFormatText(szText, rgbf.f, rgbf.r, rgbf.g, rgbf.b, 82691,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnCopyLClick\nthis.OnItemMButtonDown=MY.Chat.LinkEventHandler.OnCopyMClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnCopyRClick\nthis.OnItemMouseEnter=MY.Chat.LinkEventHandler.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.Chat.LinkEventHandler.OnCopyMouseLeave",
		"copylink")
end

-- 获取复制聊天行Text
MY.Chat.GetTimeLinkText = function(rgbfs, dwTime)
	if not dwTime then
		dwTime = GetCurrentTime()
	end
	rgbfs = rgbfs or { f = 10 }
	return GetFormatText(
		MY.Sys.FormatTime(rgbfs.s or '[hh:mm.ss]', dwTime),
		rgbfs.f, rgbfs.r, rgbfs.g, rgbfs.b, 82691,
		"this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnCopyLClick\nthis.OnItemMButtonDown=MY.Chat.LinkEventHandler.OnCopyMClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnCopyRClick\nthis.OnItemMouseEnter=MY.Chat.LinkEventHandler.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.Chat.LinkEventHandler.OnCopyMouseLeave",
		"timelink"
	)
end

-- 复制聊天行
MY.Chat.CopyChatLine = function(hTime, bTextEditor)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if bTextEditor then
		edit = MY.UI.OpenTextEditor():find(".WndEdit"):raw(1)
	end
	if not edit then
		return
	end
	Station.Lookup("Lowest2/EditBox"):Show()
	edit:ClearText()
	local h, i, bBegin, bContent = hTime:GetParent(), hTime:GetIndex(), nil, false
	-- loop
	for i = i + 1, h:GetItemCount() - 1 do
		local p = h:Lookup(i)
		if p:GetType() == "Text" then
			local szName = p:GetName()
			if szName ~= "timelink" and szName ~= "copylink" and szName ~= "msglink" and szName ~= "time" then
				local szText, bEnd = p:GetText(), false
				if not bTextEditor and StringFindW(szText, "\n") then
					szText = StringReplaceW(szText, "\n", "")
					bEnd = true
				end
				bContent = true
				if szName == "itemlink" then
					edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
				elseif szName == "iteminfolink" then
					edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
				elseif string.sub(szName, 1, 8) == "namelink" then
					if bBegin == nil then
						bBegin = false
					end
					edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
				elseif szName == "questlink" then
					edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
				elseif szName == "recipelink" then
					edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == "enchantlink" then
					edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
				elseif szName == "skilllink" then
					local o = clone(p.skillKey)
					o.type, o.text = "skill", szText
					edit:InsertObj(szText, o)
				elseif szName =="skillrecipelink" then
					edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
				elseif szName =="booklink" then
					edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
				elseif szName =="achievementlink" then
					edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
				elseif szName =="designationlink" then
					edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
				elseif szName =="eventlink" then
					if szText and #szText > 0 then -- 过滤插件消息
						edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
					end
				else
					if bBegin == false then
						for _, v in ipairs({g_tStrings.STR_TALK_HEAD_WHISPER, g_tStrings.STR_TALK_HEAD_SAY, g_tStrings.STR_TALK_HEAD_SAY1, g_tStrings.STR_TALK_HEAD_SAY2 }) do
							local nB, nE = StringFindW(szText, v)
							if nB then
								szText, bBegin = string.sub(szText, nB + nE), true
								edit:ClearText()
							end
						end
					end
					if szText ~= "" and (table.getn(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
						edit:InsertText(szText)
					end
				end
				if bEnd then
					break
				end
			elseif bTextEditor and bContent and (szName == "timelink" or szName == "copylink" or szName == "msglink" or szName == "time") then
				break
			end
		elseif p:GetType() == "Image" or p:GetType() == "Animate" then
			local dwID = tonumber((p:GetName():gsub("^emotion_", "")))
			if dwID then
				local emo = MY.Chat.GetEmotion(dwID)
				if emo then
					edit:InsertObj(emo.szCmd, { type = "emotion", text = emo.szCmd, id = emo.dwID })
				end
			end
		end
	end
	Station.SetFocusWindow(edit)
end

MY.Chat.LinkEventHandler = {
	OnNameLClick = function(hT)
		if not hT then
			hT = this
		end
		if IsCtrlKeyDown() then
			MY.Chat.CopyChatItem(hT)
		elseif IsShiftKeyDown() then
			MY.SetTarget(TARGET.PLAYER, MY.UI(hT):text())
		elseif IsAltKeyDown() then
			if MY_Farbnamen and MY_Farbnamen.Get then
				local info = MY_Farbnamen.Get(MY.UI(hT):text():gsub("[%[%]]", ""))
				if info then
					_C.tPeekPlayer[info.dwID] = true
					ViewInviteToPlayer(info.dwID)
				end
			end
		else
			MY.SwitchChat(MY.UI(hT):text())
			local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
			if edit then
				Station.SetFocusWindow(edit)
			end
		end
	end,
	OnNameRClick = function(hT)
		if not hT then
			hT = this
		end
		PopupMenu((function()
			return MY.Game.GetTargetContextMenu(TARGET.PLAYER, (MY.UI(hT):text():gsub('[%[%]]', '')))
		end)())
	end,
	OnCopyLClick = function(hT)
		MY.Chat.CopyChatLine(hT or this, IsCtrlKeyDown())
	end,
	OnCopyMClick = function(hT)
		MY.Chat.RemoveChatLine(hT or this)
	end,
	OnCopyRClick = function(hT)
		MY.Chat.RepeatChatLine(hT or this)
	end,
	OnCopyMouseEnter = function(hT)
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szText = GetFormatText(_L['LClick to copy to editbox.\nMClick to remove this line.\nRClick to repeat this line.'], 136)
		OutputTip(szText, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
	end,
	OnCopyMouseLeave = function(hT)
		HideTip()
	end,
	OnItemLClick = function(hT)
		OnItemLinkDown(hT or this)
	end,
	OnItemRClick = function(hT)
		if IsCtrlKeyDown() then
			MY.Chat.CopyChatItem(hT or this)
		end
	end,
}
MY.RegisterEvent("PEEK_OTHER_PLAYER", function()
	if not _C.tPeekPlayer[arg1] then
		return
	end
	if arg0 == PEEK_OTHER_PLAYER_RESPOND.INVALID then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Invalid player ID!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.FAILED then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Peek other player failed!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.CAN_NOT_FIND_PLAYER then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Can not find player to peek!'])
	elseif arg0 == PEEK_OTHER_PLAYER_RESPOND.TOO_FAR then
		OutputMessage("MSG_ANNOUNCE_RED", _L['Player is too far to peek!'])
	end
	_C.tPeekPlayer[arg1] = nil
end)
-- 绑定link事件响应
-- (userdata) MY.Chat.RenderLink(userdata link)                   处理link的各种事件绑定 namelink是一个超链接Text元素
-- (userdata) MY.Chat.RenderLink(userdata element, userdata link) 处理element的各种事件绑定 数据源是link
-- (string) MY.Chat.RenderLink(string szMsg)                      格式化szMsg 处理里面的超链接 添加时间相应
-- link   : 一个超链接Text元素
-- element: 一个可以挂鼠标消息响应的UI元素
-- szMsg  : 格式化的UIXML消息
MY.Chat.RenderLink = function(argv, argv2)
	if type(argv) == 'string' then -- szMsg
		local xmls = MY.Xml.Decode(argv)
		if xmls then
			for i, xml in ipairs(xmls) do
				if xml and xml['.'] == "text" and xml[''] and xml[''].name then
					local name, script = xml[''].name, xml[''].script
					if script then
						script = script .. '\n'
					else
						script = ''
					end
					
					if name:sub(1, 8) == 'namelink' then
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnNameLClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnNameRClick'
					elseif name == 'copy' or name == 'copylink' or name == 'timelink' then
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnCopyLClick\nthis.OnItemMButtonDown=MY.Chat.LinkEventHandler.OnCopyMClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnCopyRClick\nthis.OnItemMouseEnter=MY.Chat.LinkEventHandler.OnCopyMouseEnter\nthis.OnItemMouseLeave=MY.Chat.LinkEventHandler.OnCopyMouseLeave'
					else
						script = script .. 'this.bMyChatRendered=true\nthis.OnItemLButtonDown=MY.Chat.LinkEventHandler.OnItemLClick\nthis.OnItemRButtonDown=MY.Chat.LinkEventHandler.OnItemRClick'
					end
					
					if #script > 0 then
						xml[''].eventid = 82803
						xml[''].script = script
					end
				end
			end
			argv = MY.Xml.Encode(xmls)
		end
	elseif type(argv) == 'table' and type(argv.GetName) == 'function' then
		if argv.bMyChatRendered then
			return
		end
		local link = MY.UI(argv)
		local name = link:name()
		if name:sub(1, 8) == 'namelink' then
			link:click(function() MY.Chat.LinkEventHandler.OnNameLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnNameRClick(argv2) end)
		elseif name == 'copy' or name == 'copylink' then
			link:click(function() MY.Chat.LinkEventHandler.OnCopyLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnCopyRClick(argv2) end)
		else
			link:click(function() MY.Chat.LinkEventHandler.OnItemLClick(argv2) end,
					   function() MY.Chat.LinkEventHandler.OnItemRClick(argv2) end)
		end
		argv.bMyChatRendered = true
	end
	
	return argv
end

-- 复制Item到输入框
MY.Chat.CopyChatItem = function(p)
	local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
	if not edit then
		return
	end
	if p:GetType() == "Text" then
		local szText, szName = p:GetText(), p:GetName()
		if szName == "itemlink" then
			edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
		elseif szName == "iteminfolink" then
			edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
		elseif string.sub(szName, 1, 8) == "namelink" then
			edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
		elseif szName == "questlink" then
			edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
		elseif szName == "recipelink" then
			edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == "enchantlink" then
			edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
		elseif szName == "skilllink" then
			local o = clone(p.skillKey)
			o.type, o.text = "skill", szText
			edit:InsertObj(szText, o)
		elseif szName =="skillrecipelink" then
			edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
		elseif szName =="booklink" then
			edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
		elseif szName =="achievementlink" then
			edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
		elseif szName =="designationlink" then
			edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
		elseif szName =="eventlink" then
			edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
		end
		Station.SetFocusWindow(edit)
	end
end

--解析消息
MY.Chat.FormatContent = function(szMsg)
	local t = {}
	for n, w in string.gfind(szMsg, "<(%w+)>(.-)</%1>") do
		if w then
			table.insert(t, w)
		end
	end
	-- Output(t)
	local t2 = {}
	for k, v in pairs(t) do
		if not string.find(v, "name=") then
			if string.find(v, "frame=") then
				local n = string.match(v, "frame=(%d+)")
				local p = string.match(v, 'path="(.-)"')
				local emo = MY.Chat.GetEmotion(p, n, 'image')
				if emo then
					table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			elseif string.find(v, "group=") then
				local n = string.match(v, "group=(%d+)")
				local p = string.match(v, 'path="(.-)"')
				local emo = MY.Chat.GetEmotion(p, n, 'animate')
				if emo then
					table.insert(t2, {type = "emotion", text = emo.szCmd, innerText = emo.szCmd, id = emo.dwID})
				end
			else
				--普通文字
				local s = string.match(v, "\"(.*)\"")
				table.insert(t2, {type= "text", text = s, innerText = s})
			end
		else
			--物品链接
			if string.find(v, "name=\"itemlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {type = "item", text = "["..name.."]", innerText = name, item = userdata})
			--物品信息
			elseif string.find(v, "name=\"iteminfolink\"") then
				local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)")
				table.insert(t2, {type = "iteminfo", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index})
			--姓名
			elseif string.find(v, "name=\"namelink_%d+\"") then
				local name = string.match(v,"%[(.-)%]")
				table.insert(t2, {type = "name", text = "["..name.."]", innerText = "["..name.."]", name = name})
			--任务
			elseif string.find(v, "name=\"questlink\"") then
				local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
				table.insert(t2, {type = "quest", text = "["..name.."]", innerText = name, questid = userdata})
			--生活技艺
			elseif string.find(v, "name=\"recipelink\"") then
				local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "recipe", text = "["..name.."]", innerText = name, craftid = craft, recipeid = recipe})
			--技能
			elseif string.find(v, "name=\"skilllink\"") then
				local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
				local skillKey = {}
				for w in string.gfind(skillinfo, "(.-)%,") do
					local k, v  = string.match(w, "(.-)=(%w+)")
					skillKey[k] = v
				end
				skillKey.text = "["..name.."]"
				skillKey.innerText = "["..name.."]"
				table.insert(t2, skillKey)
			--称号
			elseif string.find(v, "name=\"designationlink\"") then
				local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.bPrefix=(.-)")
				table.insert(t2, {type = "designation", text = "["..name.."]", innerText = name, id = id, prefix = fix})
			--技能秘籍
			elseif string.find(v, "name=\"skillrecipelink\"") then
				local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.dwLevel=(%d+)")
				table.insert(t2, {type = "skillrecipe", text = "["..name.."]", innerText = name, id = id, level = level})
			--书籍
			elseif string.find(v, "name=\"booklink\"") then
				local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)\\%s*this.nBookRecipeID=(%d+)")
				table.insert(t2, {type = "book", text = "["..name.."]", innerText = name, version = version, tabtype = tab, index = index, bookinfo = id})
			--成就
			elseif string.find(v, "name=\"achievementlink\"") then
				local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
				table.insert(t2, {type = "achievement", text = "["..name.."]", innerText = name, id = id})
			--强化
			elseif string.find(v, "name=\"enchantlink\"") then
				local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\%s*this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
				table.insert(t2, {type = "enchant", text = "["..name.."]", innerText = name, proid = pro, craftid = craft, recipeid = recipe})
			--事件
			elseif string.find(v, "name=\"eventlink\"") then
				local name, na, info = string.match(v,'text="(.-)".-script="this.szName=\\"(.-)\\"\\%s*this.szLinkInfo=\\"(.-)\\"')
				table.insert(t2, {type = "eventlink", text = name, innerText = name, name = na, linkinfo = info or ""})
			end
		end
	end
	return t2
end

-- 判断某个频道能否发言
-- (bool) MY.CanTalk(number nChannel)
MY.Chat.CanTalk = function(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end
MY.CanTalk = MY.Chat.CanTalk

-- get channel header
_C.tTalkChannelHeader = {
	[PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
	[PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
	[PLAYER_TALK_CHANNEL.TEAM] = "/p ",
	[PLAYER_TALK_CHANNEL.RAID] = "/t ",
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
	[PLAYER_TALK_CHANNEL.TONG] = "/g ",
	[PLAYER_TALK_CHANNEL.SENCE] = "/y ",
	[PLAYER_TALK_CHANNEL.FORCE] = "/f ",
	[PLAYER_TALK_CHANNEL.CAMP] = "/c ",
	[PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
-- 切换聊天频道
-- (void) MY.SwitchChat(number nChannel)
-- (void) MY.SwitchChat(string szHeader)
-- (void) MY.SwitchChat(string szName)
MY.Chat.SwitchChat = function(nChannel)
	local szHeader = _C.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		if string.sub(nChannel, 1, 1) == "/" then
			if nChannel == '/cafk' or nChannel == '/catr' then
				SwitchChatChannel(nChannel)
				MY.Chat.Talk(nil, nChannel, nil, nil, nil, true)
				Station.Lookup("Lowest2/EditBox"):Show()
				Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
			else
				SwitchChatChannel(nChannel.." ")
			end
		else
			SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
		end
	end
end
MY.SwitchChat = MY.Chat.SwitchChat

-- parse faceicon in talking message
MY.Chat.ParseFaceIcon = function(t)
	_C.InitEmotion()
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "emotion" then
				v.type = "text"
			end
			table.insert(t2, v)
		else
			local szText = v.text
			local szLeft = ''
			while szText and #szText > 0 do
				local szFace, dwFaceID = nil, nil
				local nPos = StringFindW(szText, "#")
				if not nPos then
					szLeft = szLeft .. szText
					szText = ''
				else
					szLeft = szLeft .. string.sub(szText, 1, nPos - 1)
					szText = string.sub(szText, nPos)
					for i = math.min(_C.nMaxEmotionLen, wstring.len(szText)), 2, -1 do
						local szTest = wstring.sub(szText, 1, i)
						local emo = MY.Chat.GetEmotion(szTest)
						if emo then
							szFace, dwFaceID = szTest, emo.dwID
							szText = szText:sub(szFace:len() + 1)
							break
						end
					end
					if szFace then -- emotion cmd matched
						if #szLeft > 0 then
							table.insert(t2, { type = "text", text = szLeft })
							szLeft = ''
						end
						if MY.Sys.GetLang() ~= 'vivn' then
							table.insert(t2, { type = "emotion", text = szFace, id = dwFaceID })
						else
							table.insert(t2, { type = "text", text = szFace })
						end
					elseif nPos then -- find '#' but not match emotion
						szLeft = szLeft .. szText:sub(1, 1)
						szText = szText:sub(2)
					end
				end
			end
			if #szLeft > 0 then
				table.insert(t2, { type = "text", text = szLeft })
				szLeft = ''
			end
		end
	end
	return t2
end
-- parse name in talking message
MY.Chat.ParseName = function(t)
	local me = GetClientPlayer()
	local tar = MY.GetObject(me.GetTarget())
	for i, v in ipairs(t) do
		if v.type == "text" then
			v.text = string.gsub(v.text, "%$zj", '[' .. me.szName .. ']')
			if tar then
				v.text = string.gsub(v.text, "%$mb", '[' .. tar.szName .. ']')
			end
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "name" then
				v = { type = "text", text = "["..v.name.."]" }
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szName = nil
				local nPos1, nPos2 = string.find(v.text, '%[[^%[%]]+%]', nOff)
				if not nPos1 then
					nPos1 = nLen
				else
					szName = string.sub(v.text, nPos1 + 1, nPos2 - 1)
					nPos1 = nPos1 - 1
				end
				if nPos1 >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos1) })
					nOff = nPos1 + 1
				end
				if szName then
					table.insert(t2, { type = "name", text = '[' .. szName .. ']', name = szName })
					nOff = nPos2 + 1
				end
			end
		end
	end
	return t2
end
MY.Chat.tSensitiveWord = {
	'   ',
	' '  .. g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE,
	'  ' .. g_tStrings.STR_ONE_CHINESE_SPACE,
	g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE,
	g_tStrings.STR_ONE_CHINESE_SPACE .. g_tStrings.STR_ONE_CHINESE_SPACE .. ' ',
	g_tStrings.STR_ONE_CHINESE_SPACE .. '  ',
}
-- anti sensitive word shielding in talking message
MY.Chat.ParseAntiSWS = function(t)
	local tSensitiveWord = MY.Chat.tSensitiveWord
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type == "text" then
			local szText = v.text
			while szText and #szText > 0 do
				local nSensitiveWordEndLen = 1 -- 最后一个字符（要裁剪掉的字符）大小
				local nSensitiveWordEndPos = #szText + 1
				for _, szSensitiveWord in ipairs(tSensitiveWord) do
					local _, nEndPos = wstring.find(szText, szSensitiveWord)
					if nEndPos and nEndPos < nSensitiveWordEndPos then
						local nSensitiveWordLenW = wstring.len(szSensitiveWord)
						nSensitiveWordEndLen = string.len(wstring.sub(szSensitiveWord, nSensitiveWordLenW, nSensitiveWordLenW))
						nSensitiveWordEndPos = nEndPos
					end
				end
				
				table.insert(t2, {
					type = "text",
					text = string.sub(szText, 1, nSensitiveWordEndPos - nSensitiveWordEndLen)
				})
				szText = string.sub(szText, nSensitiveWordEndPos + 1 - nSensitiveWordEndLen)
			end
		else
			table.insert(t2, v)
		end
	end
	return t2
end

-- 发布聊天内容
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape, [boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape[boolean bSaveDeny, [boolean bPushToChatBox] ] ])
-- szTarget       -- 密聊的目标角色名
-- szText         -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- nChannel       -- *可选* 聊天频道，PLAYER_TALK_CHANNLE.*，默认为近聊
-- bNoEscape      -- *可选* 不解析聊天内容中的表情图片和名字，默认为 false
-- bSaveDeny      -- *可选* 在聊天输入栏保留不可发言的频道内容，默认为 false
-- bPushToChatBox -- *可选* 仅推送到聊天框，默认为 false
-- 特别注意：nChannel, szText 两者的参数顺序可以调换，战场/团队聊天频道智能切换
MY.Chat.Talk = function(nChannel, szText, szUUID, bNoEscape, bSaveDeny, bPushToChatBox)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		return MY.Sysmsg({szText}, '')
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		tSay = {{ type = "text", text = szText}}
	end
	if not bNoEscape then
		tSay = MY.Chat.ParseFaceIcon(tSay)
		tSay = MY.Chat.ParseName(tSay)
	end
	tSay = MY.Chat.ParseAntiSWS(tSay)
	if MY.IsShieldedVersion() then
		local nLen = 0
		for i, v in ipairs(tSay) do
			if nLen <= 64 then
				nLen = nLen + MY.String.LenW(v.text or v.name or '')
				if nLen > 64 then
					if v.text then v.text = MY.String.SubW(v.text, 1, 64 - nLen ) end
					if v.name then v.name = MY.String.SubW(v.name, 1, 64 - nLen ) end
					for j=#tSay, i+1, -1 do
						table.remove(tSay, j)
					end
				end
			end
		end
	end
	if bPushToChatBox or (bSaveDeny and not MY.CanTalk(nChannel)) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			edit:InsertObj(v.text, v)
		end
		-- change to this channel
		MY.SwitchChat(nChannel)
		-- set focus
		Station.SetFocusWindow(edit)
	else
		if not tSay[1]
		or tSay[1].name ~= ""
		or tSay[1].type ~= "eventlink" then
			table.insert(tSay, 1, {
				type = "eventlink", name = "",
				linkinfo = MY.Json.Encode({
					via = "MY",
					uuid = szUUID and tostring(szUUID),
				})
			})
		end
		me.Talk(nChannel, szTarget, tSay)
	end
end
MY.Talk = MY.Chat.Talk

_C.tMsgMonitorFun = {}
-- Register:   MY.Chat.RegisterMsgMonitor(string szKey, function fnAction, table tChannels)
--             MY.Chat.RegisterMsgMonitor(function fnAction, table tChannels)
-- Unregister: MY.Chat.RegisterMsgMonitor(string szKey)
MY.Chat.RegisterMsgMonitor = function(arg0, arg1, arg2)
	local szKey, fnAction, tChannels
	local tp0, tp1, tp2 = type(arg0), type(arg1), type(arg2)
	if tp0 == 'string' and tp1 == 'function' and tp2 == 'table' then
		szKey, fnAction, tChannels = arg0, arg1, arg2
	elseif tp0 == 'function' and tp1 == 'table' then
		fnAction, tChannels = arg0, arg1
	elseif tp0 == 'string' and tp1 == 'nil' then
		szKey = arg0
	end
	
	if szKey and _C.tMsgMonitorFun[szKey] then
		UnRegisterMsgMonitor(_C.tMsgMonitorFun[szKey].fn)
		_C.tMsgMonitorFun[szKey] = nil
	end
	if fnAction and tChannels then
		_C.tMsgMonitorFun[szKey] = { fn = function(szMsg, nFont, bRich, r, g, b, szChannel)
			-- filter addon comm.
			if StringFindW(szMsg, "eventlink") and StringFindW(szMsg, _L["Addon comm."]) then
				return
			end
			fnAction(szMsg, nFont, bRich, r, g, b, szChannel)
		end, ch = tChannels }
		RegisterMsgMonitor(_C.tMsgMonitorFun[szKey].fn, _C.tMsgMonitorFun[szKey].ch)
	end
end
MY.RegisterMsgMonitor = MY.Chat.RegisterMsgMonitor

_C.tHookChat = {}
-- HOOK聊天栏
-- 注：如果fnOnActive存在则没有激活的聊天栏不会执行fnBefore、fnAfter
--     同时在聊天栏切换时会触发fnOnActive
MY.Chat.HookChatPanel = function(szKey, fnBefore, fnAfter, fnOnActive)
	if type(szKey) == "function" then
		szKey, fnBefore, fnAfter, fnOnActive = GetTickCount(), szKey, fnBefore, fnAfter
		while _C.tHookChat[szKey] do
			szKey = szKey + 0.1
		end
	end
	if fnBefore or fnAfter or fnOnActive then
		_C.tHookChat[szKey] = {
			fnBefore = fnBefore, fnAfter = fnAfter, fnOnActive = fnOnActive
		}
	else
		_C.tHookChat[szKey] = nil
	end
end
MY.HookChatPanel = MY.Chat.HookChatPanel

_C.OnChatPanelActive = function(h)
	for szKey, hc in pairs(_C.tHookChat) do
		if type(hc.fnOnActive) == "function" then
			local status, err = pcall(hc.fnOnActive, h)
			if not status then
				MY.Debug({err}, 'HookChatPanelOnActive#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

_C.OnChatPanelNamelinkLButtonDown = function(...)
	this.__MY_OnItemLButtonDown(...)
	MY.Chat.LinkEventHandler.OnNameLClick(...)
end

_C.OnChatPanelAppendItemFromString = function(h, szMsg, szChannel, dwTime, nR, nG, nB, ...)
	local bActived = h:GetRoot():Lookup('CheckBox_Title'):IsCheckBoxChecked()
	-- deal with fnBefore
	for szKey, hc in pairs(_C.tHookChat) do
		hc.param = EMPTY_TABLE
		-- if fnBefore exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnBefore) == "function" and (bActived or not hc.fnOnActive) then
			-- try to execute fnBefore and get return values
			local result = { pcall(hc.fnBefore, h, szChannel, szMsg, dwTime, nR, nG, nB, ...) }
			-- when fnBefore execute succeed
			if result[1] then
				-- remove execute status flag
				table.remove(result, 1)
				if type(result[1]) == "string" then
					szMsg = result[1]
				end
				-- remove returned szMsg
				table.remove(result, 1)
				-- the rest is fnAfter param
				hc.param = result
			end
		end
	end
	local nIndex = h:GetItemCount()
	-- call ori append
	h:_AppendItemFromString_MY(szMsg, szChannel, dwTime, nR, nG, nB, ...)
	-- hook namelink lbutton down
	for i = h:GetItemCount() - 1, nIndex, -1 do
		local hItem = h:Lookup(i)
		if hItem:GetName():find("^namelink_%d+$") then
			hItem.bMyChatRendered = true
			if hItem.OnItemLButtonDown then
				hItem.__MY_OnItemLButtonDown = hItem.OnItemLButtonDown
				hItem.OnItemLButtonDown = _C.OnChatPanelNamelinkLButtonDown
			else
				hItem.OnItemLButtonDown = MY.Chat.LinkEventHandler.OnNameLClick
			end
		end
	end
	-- deal with fnAfter
	for szKey, hc in pairs(_C.tHookChat) do
		-- if fnAfter exist and ChatPanel[i] actived or fnOnActive not defined
		if type(hc.fnAfter) == "function" and (bActived or not hc.fnOnActive) then
			local status, err = pcall(hc.fnAfter, h, hc.param, szChannel, szMsg, dwTime, nR, nG, nB, ...)
			if not status then
				MY.Debug({err}, 'HookChatPanel.After#' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end

_C.Hook = {}
_C.Hook.Reg = function(i)
	local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
	-- local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
	-- if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
	if h and not h._AppendItemFromString_MY then
		h:GetRoot():Lookup('CheckBox_Title').OnCheckBoxCheck = function()
			_C.OnChatPanelActive(h)
		end
		h._AppendItemFromString_MY = h.AppendItemFromString
		h.AppendItemFromString = _C.OnChatPanelAppendItemFromString
	end
end
_C.Hook.Unreg = function(i)
	local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
	if h and h._AppendItemFromString_MY then
		h.AppendItemFromString = _C._AppendItemFromString_MY
		h._AppendItemFromString_MY = nil
	end
end

MY.RegisterEvent("CHAT_PANEL_INIT", function ()
	for i = 1, 10 do
		_C.Hook.Reg(i)
	end
end)
MY.RegisterEvent("CHAT_PANEL_OPEN", function(event) _C.Hook.Reg(arg0) end)

MY.RegisterReload("ChatPanelHook", function ()
	for i = 1, 10 do
		_C.Hook.Reg(i)
	end
end)
MY.RegisterExit("ChatPanelUnhook", function ()
	for i = 1, 10 do
		_C.Hook.Unreg(i)
	end
end)
