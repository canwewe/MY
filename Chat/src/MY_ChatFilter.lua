MY_ChatFilter = {}
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Chat/lang/")
local MY_ChatFilter = MY_ChatFilter
local MAX_CHAT_RECORD = 10
local MAX_UUID_RECORD = 10
MY_ChatFilter.bFilterDuplicate           = true   -- 屏蔽重复聊天
MY_ChatFilter.bFilterDuplicateIgnoreID   = false  -- 不同玩家重复聊天也屏蔽
MY_ChatFilter.bFilterDuplicateContinuous = true   -- 仅屏蔽连续的重复聊天
MY_ChatFilter.bFilterDuplicateAddonTalk  = true   -- 屏蔽UUID相同的插件消息
RegisterCustomData("MY_ChatFilter.bFilterDuplicate")
RegisterCustomData("MY_ChatFilter.bFilterDuplicateIgnoreID")
RegisterCustomData("MY_ChatFilter.bFilterDuplicateContinuous")
RegisterCustomData("MY_ChatFilter.bFilterDuplicateAddonTalk")

MY_ChatFilter.tApplyDuplicateChannels = {
	["MSG_SYS"           ] = false,
	["MSG_NORMAL"        ] = true,
	["MSG_PARTY"         ] = false,
	["MSG_MAP"           ] = true,
	["MSG_BATTLE_FILED"  ] = true,
	["MSG_GUILD"         ] = true,
	["MSG_GUILD_ALLIANCE"] = true,
	["MSG_SCHOOL"        ] = true,
	["MSG_WORLD"         ] = true,
	["MSG_TEAM"          ] = false,
	["MSG_CAMP"          ] = true,
	["MSG_GROUP"         ] = true,
	["MSG_WHISPER"       ] = false,
	["MSG_SEEK_MENTOR"   ] = true,
	["MSG_FRIEND"        ] = false,
}
for k, _ in pairs(MY_ChatFilter.tApplyDuplicateChannels) do
	RegisterCustomData("MY_ChatFilter.tApplyDuplicateChannels." .. k)
end

MY.HookChatPanel("MY_ChatFilter", function(h, szChannel, szMsg, dwTime)
	-- 插件消息UUID过滤
	if MY_ChatFilter.bFilterDuplicateAddonTalk then
		local me = GetClientPlayer()
		local tSay = me.GetTalkData()
		if not h.MY_tDuplicateUUID then
			h.MY_tDuplicateUUID = {}
		elseif tSay[1] and tSay[1].type == "eventlink" then
			local data = MY.Json.Decode(tSay[1].linkinfo)
			if data and data.uuid then
				local szUUID = data.uuid
				if szUUID then
					for k, uuid in pairs(h.MY_tDuplicateUUID) do
						if uuid == szUUID then
							return ''
						end
					end
					table.insert(h.MY_tDuplicateUUID, 1, szUUID)
					local nCount = #h.MY_tDuplicateUUID - MAX_UUID_RECORD
					if nCount > 0 then
						for i = nCount, 1, -1 do
							table.remove(h.MY_tDuplicateUUID)
						end
					end
				end
			end
		end
	end
	-- 重复内容刷屏屏蔽（系统频道除外）
	if MY_ChatFilter.bFilterDuplicate
	and MY_ChatFilter.tApplyDuplicateChannels[szChannel] then
		-- 计算过滤记录
		local szText = GetPureText(szMsg)
		if MY_ChatFilter.bFilterDuplicateIgnoreID then
			local nCount = 1
			while nCount > 0 do
				szText, nCount = szText:gsub('^%[[^%[%]]+%]', '')
			end
		end
		-- 判断是否需要过滤
		if not h.MY_tDuplicateLog then
			h.MY_tDuplicateLog = {}
		elseif szText == "" then
			-- 纯表情纯链接就不屏蔽了
		elseif MY_ChatFilter.bFilterDuplicateContinuous then
			if h.MY_tDuplicateLog[1] == szText then
				return ''
			end
			h.MY_tDuplicateLog[1] = szText
		else
			for i, szRecord in ipairs(h.MY_tDuplicateLog) do
				if szRecord == szText then
					return ''
				end
			end
			table.insert(h.MY_tDuplicateLog, 1, szText)
			local nCount = #h.MY_tDuplicateLog - MAX_CHAT_RECORD
			if nCount > 0 then
				for i = nCount, 1, -1 do
					table.remove(h.MY_tDuplicateLog)
				end
			end
		end
	end
end)

MY.RegisterPanel("MY_Duplicate_Chat_Filter", _L["duplicate chat filter"], _L['Chat'],
"ui/Image/UICommon/yirong3.UITex|104", {255,255,0,200}, {OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30

	ui:append("WndCheckBox", {
		text = _L['filter duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicate,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicate = bCheck
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		text = _L['filter duplicate chat ignore id'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateIgnoreID,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateIgnoreID = bCheck
		end,
	})
	y = y + 30

	ui:append("WndCheckBox", {
		text = _L['only filter continuous duplicate chat'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateContinuous,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateContinuous = bCheck
		end,
	})
	y = y + 30

	ui:append("WndComboBox", {
		x = x, y = y, w = 330, h = 25,
		menu = function()
			local t = {}
			for szChannelID, bFilter in pairs(MY_ChatFilter.tApplyDuplicateChannels) do
				table.insert(t, {
					szOption = g_tStrings.tChannelName[szChannelID],
					bCheck = true, bChecked = bFilter,
					rgb = GetMsgFontColor(szChannelID, true),
					fnAction = function()
						MY_ChatFilter.tApplyDuplicateChannels[szChannelID] = not MY_ChatFilter.tApplyDuplicateChannels[szChannelID]
					end,
				})
			end
			return t
		end,
		text = _L['select duplicate channels'],
	})
	y = y + 50

	ui:append("WndCheckBox", {
		text = _L['filter duplicate addon message'],
		x = x, y = y, w = 400,
		checked = MY_ChatFilter.bFilterDuplicateAddonTalk,
		oncheck = function(bCheck)
			MY_ChatFilter.bFilterDuplicateAddonTalk = bCheck
		end,
	})
	y = y + 30
end})
