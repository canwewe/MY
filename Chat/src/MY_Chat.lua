local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Chat/lang/")
local CHAT_TIME = {
    HOUR_MIN = 1,
    HOUR_MIN_SEC = 2,
}
-- init vars
MY_Chat = MY_Chat or {}
local _Cache = {
    ['tChannels'] = {
        {name="Radio_Say",      title=_L["SAY"],      head={string=g_tStrings.HEADER_SHOW_SAY,          code="/s "}, channel=PLAYER_TALK_CHANNEL.NEARBY       , color={255, 255, 255}},--˵
        {name="Radio_Map",      title=_L["MAP"],      head={string=g_tStrings.HEADER_SHOW_MAP,          code="/y "}, channel=PLAYER_TALK_CHANNEL.SENCE        , color={255, 126, 126}},--��
        {name="Radio_World",    title=_L["WORLD"],    head={string=g_tStrings.HEADER_SHOW_WORLD,        code="/h "}, channel=PLAYER_TALK_CHANNEL.WORLD        , color={252, 204, 204}},--��
        {name="Radio_Party",    title=_L["PARTY"],    head={string=g_tStrings.HEADER_SHOW_CHAT_PARTY,   code="/p "}, channel=PLAYER_TALK_CHANNEL.TEAM         , color={140, 178, 253}},--��
        {name="Radio_Team",     title=_L["TEAM"],     head={string=g_tStrings.HEADER_SHOW_TEAM,         code="/t "}, channel=PLAYER_TALK_CHANNEL.RAID         , color={ 73, 168, 241}},--��
        {name="Radio_Battle",   title=_L["BATTLE"],   head={string=g_tStrings.HEADER_SHOW_BATTLE_FIELD, code="/b "}, channel=PLAYER_TALK_CHANNEL.BATTLE_FIELD , color={255, 126, 126}},--ս
        {name="Radio_Tong",     title=_L["FACTION"],  head={string=g_tStrings.HEADER_SHOW_CHAT_FACTION, code="/g "}, channel=PLAYER_TALK_CHANNEL.TONG         , color={  0, 200,  72}},--��
        {name="Radio_School",   title=_L["SCHOOL"],   head={string=g_tStrings.HEADER_SHOW_SCHOOL,       code="/f "}, channel=PLAYER_TALK_CHANNEL.FORCE        , color={  0, 255, 255}},--��
        {name="Radio_Camp",     title=_L["CAMP"],     head={string=g_tStrings.HEADER_SHOW_CAMP,         code="/c "}, channel=PLAYER_TALK_CHANNEL.CAMP         , color={155, 230,  58}},--��
        {name="Radio_Friend",   title=_L["FRIEND"],   head={string=g_tStrings.HEADER_SHOW_FRIEND,       code="/o "}, channel=PLAYER_TALK_CHANNEL.FRIENDS      , color={241, 114, 183}},--��
        {name="Radio_Alliance", title=_L["ALLIANCE"], head={string=g_tStrings.HEADER_SHOW_CHAT_ALLIANCE,code="/a "}, channel=PLAYER_TALK_CHANNEL.TONG_ALLIANCE, color={178, 240, 164}},--��
    },
}
MY_Chat.bLockPostion = false
MY_Chat.anchor = { x=10, y=-60, s="BOTTOMLEFT", r="BOTTOMLEFT" }
MY_Chat.bEnableBalloon = true
MY_Chat.bChatCopy = true
MY_Chat.bBlockWords = false
MY_Chat.tBlockWords = {}
MY_Chat.bChatTime = true
MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
MY_Chat.bChatCopyAlwaysShowMask = false
MY_Chat.bChatCopyAlwaysWhite = false

MY_Chat.tChannel = {
    ["Radio_Say"] = true,
    ["Radio_Map"] = true,
    ["Radio_World"] = true,
    ["Radio_Party"] = true,
    ["Radio_Team"] = true,
    ["Radio_Battle"] = true,
    ["Radio_Tong"] = true,
    ["Radio_School"] = true,
    ["Radio_Camp"] = true,
    ["Radio_Friend"] = true,
    ["Radio_Alliance"] = true,
    ["Check_Away"] = true,
    ["Check_Busy"] = true,
}
-- register settings
RegisterCustomData("Account\\MY_Chat.bLockPostion")
RegisterCustomData("Account\\MY_Chat.postion")
RegisterCustomData("Account\\MY_Chat.bEnableBalloon")
RegisterCustomData("Account\\MY_Chat.bChatCopy")
RegisterCustomData("Account\\MY_Chat.bBlockWords")
RegisterCustomData("Account\\MY_Chat.tBlockWords")
RegisterCustomData("Account\\MY_Chat.bChatTime")
RegisterCustomData("Account\\MY_Chat.nChatTime")
RegisterCustomData("Account\\MY_Chat.bChatCopyAlwaysShowMask")
RegisterCustomData("Account\\MY_Chat.bChatCopyAlwaysWhite")
for k, _ in pairs(MY_Chat.tChannel) do RegisterCustomData("Account\\MY_Chat.tChannel."..k) end

MY_Chat.OnFrameDragEnd = function() this:CorrectPos() MY_Chat.anchor = GetFrameAnchor(this) end

-- open window
MY_Chat.frame = Wnd.OpenWindow("Interface\\MY\\Chat\\ui\\Chat.ini", "MY_Chat")
-- load settings
MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
MY_Chat.UpdateAnchor = function() MY_Chat.frame:SetPoint(MY_Chat.anchor.s, 0, 0, MY_Chat.anchor.r, MY_Chat.anchor.x, MY_Chat.anchor.y) MY_Chat.frame:CorrectPos() end
MY_Chat.UpdateAnchor()
MY.RegisterEvent( "UI_SCALED", MY_Chat.UpdateAnchor )

--------------------------------------------------------------
-- chat balloon
--------------------------------------------------------------
function MY_Chat.AppendBalloon(dwID, szMsg)
    local handle = MY_Chat.frame:Lookup("", "Handle_TotalBalloon")
    local hBalloon = handle:Lookup("Balloon_" .. dwID)
    if not hBalloon then
        handle:AppendItemFromIni("Interface\\MY\\Chat\\ui\\Chat.ini", "Handle_Balloon", "Balloon_" .. dwID)
        hBalloon = handle:Lookup(handle:GetItemCount() - 1)
        hBalloon.dwID = dwID
    end
    hBalloon.nTime = GetTime()
    hBalloon.nAlpha = 255
    local hwnd = hBalloon:Lookup("Handle_Content")
    hwnd:Show()
    local r, g, b = GetMsgFontColor("MSG_PARTY")
    -- szMsg = MY_Chat.EmotionPanel_ParseBallonText(szMsg, r, g, b)
    hwnd:Clear()
    hwnd:SetSize(300, 131)
    hwnd:AppendItemFromString(szMsg)
    hwnd:FormatAllItemPos()
    hwnd:SetSizeByAllItemSize()
    MY_Chat.AdjustBalloonSize(hBalloon, hwnd)
    MY_Chat.ShowBalloon(dwID, hBalloon, hwnd)
end

function MY_Chat.ShowBalloon(dwID, hBalloon, hwnd)
    local handle = Station.Lookup("Normal/Teammate", "")
    local nCount = handle:GetItemCount()
    for i = 0, nCount - 1 do
        local hI = handle:Lookup(i)
        if hI.dwID == dwID then
            local x,y = hI:GetAbsPos()
            local w, h = hwnd:GetSize()
            hBalloon:SetAbsPos(x + 205, y - h - 2)
            MY.UI(hBalloon):alpha(0):fadeIn(500)
            MY.DelayCall("MY_Chat_Balloon_"..dwID, function()
                MY.UI(hBalloon):fadeOut(500)
            end, 5000)
        end
    end
end

function MY_Chat.AdjustBalloonSize(hBalloon, hwnd)
    local w, h = hwnd:GetSize()
    w, h = w + 20, h + 20
    local image1 = hBalloon:Lookup("Image_Bg1")
    image1:SetSize(w, h)

    local image2 = hBalloon:Lookup("Image_Bg2")
    image2:SetRelPos(w * 0.8 - 16, h - 4)
    hBalloon:SetSize(10000, 10000)
    hBalloon:FormatAllItemPos()
    hBalloon:SetSizeByAllItemSize()
end

function MY_Chat.OnSay(szMsg, dwID, nChannel)
    local player = GetClientPlayer()
    if not player then return end
    if dwID == player.dwID then return end
    if nChannel ~= PLAYER_TALK_CHANNEL.TEAM and nChannel ~= PLAYER_TALK_CHANNEL.RAID then return end
    if player.IsInParty() then
        local hTeam = GetClientTeam()
        if not hTeam then return end
        if hTeam.nGroupNum > 1 then
            return
        end
        local hGroup = hTeam.GetGroupInfo(0)
        for k, v in pairs(hGroup.MemberList) do
            if v == dwID then
                MY_Chat.AppendBalloon(dwID, szMsg, false)
            end
        end
    end
end
MY.RegisterEvent("PLAYER_SAY",function()
    if MY_Chat.bEnableBalloon then
        MY_Chat.OnSay(arg0, arg1, arg2)
    end
end)

--------------------------------------------------------------
-- reinit ui
--------------------------------------------------------------
MY_Chat.ReInitUI = function()
    -- clear
    MY.UI(MY_Chat.frame):find(".WndCheckBox"):remove()
    MY.UI(MY_Chat.frame):find(".WndRadioBox"):remove()
    -- reinit
    local i = 0
    -- init ui
    for _, v in ipairs(_Cache.tChannels) do
        if MY_Chat.tChannel[v.name] then
            i = i + 1
            MY.UI(MY_Chat.frame):append(v.name,"WndRadioBox"):children("#"..v.name):width(20):text(v.title):font(197):color(v.color):pos(i*30+15,25):check(function()
                -- Switch Chat Channel Here
                MY.SwitchChat(v.channel)
                Station.SetFocusWindow("Lowest2/EditBox/Edit_Input")
                MY.UI(this):check(false)
            end):find(".Text"):pos(4,-18):width(20)
        end
    end
    
    if MY_Chat.tChannel.Check_Away then
        i = i + 1
        MY.UI(MY_Chat.frame):append("Check_Away","WndCheckBox"):children("#Check_Away"):width(25):text(_L["AWAY"]):pos(i*30+15,25):check(function()
            MY.SwitchChat("/afk")
        end, function()
            MY.SwitchChat("/cafk")
        end):find(".Text"):pos(5,-16):width(25):font(197)
    end
    
    if MY_Chat.tChannel.Check_Busy then
        i = i + 1
        MY.UI(MY_Chat.frame):append("Check_Busy","WndCheckBox"):children("#Check_Busy"):width(25):text(_L["BUSY"]):pos(i*30+15,25):check(function()
            MY.SwitchChat("/atr")
        end, function()
            MY.SwitchChat("/catr")
        end):find(".Text"):pos(5,-16):width(25):font(197)
    end
    
    MY.UI(MY_Chat.frame):find('#Image_Bar'):width(i*30+35)
end

--------------------------------------------------------------
-- init
--------------------------------------------------------------
MY.RegisterInit(function()
    MY_Chat.ReInitUI()
    
    MY.UI(MY_Chat.frame):children("#Btn_Option"):menu(function()
        local t = {
            {
                szOption = _L["about..."],
                fnAction = function()
                    local t = {
                        szName = "MY_Chat_About",
                        szMessage = _L["Mingyi Plugins - Chatpanel\nThis plugin is developed by Zhai YiMing @ derzh.com."],
                        {szOption = g_tStrings.STR_HOTKEY_SURE,fnAction = function() end},
                    }
                    MessageBox(t)
                end,
            }, {
                bDevide = true
            }, {
                szOption = _L["lock postion"],
                bCheck = true,
                bChecked = MY_Chat.bLockPostion,
                fnAction = function()
                    MY_Chat.bLockPostion = not MY_Chat.bLockPostion
                    MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
                end
            }, {
                szOption = _L["team balloon"],
                bCheck = true,
                bChecked = MY_Chat.bEnableBalloon,
                fnAction = function()
                    MY_Chat.bEnableBalloon = not MY_Chat.bEnableBalloon
                end
            }, {
                szOption = _L["chat copy"],
                bCheck = true,
                bChecked = MY_Chat.bChatCopy,
                fnAction = function()
                    MY_Chat.bChatCopy = not MY_Chat.bChatCopy
                end,
                {
                    szOption = _L['always show *'],
                    bCheck = true,
                    bChecked = MY_Chat.bChatCopyAlwaysShowMask,
                    fnAction = function()
                        MY_Chat.bChatCopyAlwaysShowMask = not MY_Chat.bChatCopyAlwaysShowMask
                    end,
                }, {
                szOption = _L['always be white'],
                bCheck = true,
                bChecked = MY_Chat.bChatCopyAlwaysWhite,
                fnAction = function()
                    MY_Chat.bChatCopyAlwaysWhite = not MY_Chat.bChatCopyAlwaysWhite
                end,
                },
            }, {
                szOption = _L["chat filter"],
                bCheck = true,
                bChecked = MY_Chat.bBlockWords,
                fnAction = function()
                    MY_Chat.bBlockWords = not MY_Chat.bBlockWords
                end, {
                    szOption = _L['keyword manager'],
                    fnAction = function()
                        local muDel
                        local AddListItem = function(muList, szText)
                            local i = muList:hdl(1):children():count()
                            local muItem = muList:append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):hdl(1):children():last()
                            local hHandle = muItem:raw(1)
                            hHandle.Value = szText
                            local hText = muItem:children("#Text_Default"):pos(10, 2):text(szText or ""):raw(1)
                            muItem:children("#Image_Bg"):image("UI/Image/Common/TextShadow.UITex",5):alpha(0):hover(function(bIn)
                                if hHandle.Selected then return nil end
                                if bIn then
                                    MY.UI(this):fadeIn(100)
                                else
                                    MY.UI(this):fadeTo(500,0)
                                end
                            end):click(function(nButton)
                                if nButton == MY.Const.Event.Mouse.RBUTTON then
                                    hHandle.Selected = true
                                    PopupMenu({{
                                        szOption = _L["delete"],
                                        fnAction = function()
                                            muDel:click()
                                        end,
                                    }})
                                else
                                    hHandle.Selected = not hHandle.Selected
                                end
                                if hHandle.Selected then
                                    MY.UI(this):image("UI/Image/Common/TextShadow.UITex",2)
                                else
                                    MY.UI(this):image("UI/Image/Common/TextShadow.UITex",5)
                                end
                            end)
                        end
                        local ui = MY.UI.CreateFrame("MY_Chat_KeywordManager"):text(_L["keyword manager"])
                        ui:append("Image_Spliter", "Image"):find("#Image_Spliter"):pos(-10,25):size(360, 10):image("UI/Image/UICommon/Commonpanel.UITex",42)
                        local muEditBox = ui:append("WndEditBox_Keyword", "WndEditBox"):find("#WndEditBox_Keyword"):pos(0,0):size(170, 25)
                        local muList = ui:append("WndScrollBox_KeywordList", "WndScrollBox"):find("#WndScrollBox_KeywordList"):handleStyle(3):pos(0,30):size(340, 380)
                        -- add
                        ui:append("WndButton_Add", "WndButton"):find("#WndButton_Add"):pos(180,0):width(80):text(_L["add"]):click(function()
                            local szText = muEditBox:text()
                            muEditBox:text("")
                            for i, v in ipairs(MY_Chat.tBlockWords) do
                                if v==szText then return nil end
                            end
                            table.insert(MY_Chat.tBlockWords, szText)
                            AddListItem(muList, szText)
                        end)
                        -- del
                        muDel = ui:append("WndButton_Del", "WndButton"):find("#WndButton_Del"):pos(260,0):width(80):text(_L["delete"]):click(function()
                            muList:hdl(1):children():each(function(ui)
                                if this.Selected then
                                    for i=#MY_Chat.tBlockWords, 1, -1 do
                                        if MY_Chat.tBlockWords[i]==this.Value then
                                            table.remove(MY_Chat.tBlockWords, i)
                                        end
                                    end
                                    ui:remove()
                                end
                            end)
                        end)
                        -- insert data to ui
                        for i, v in ipairs(MY_Chat.tBlockWords) do
                            AddListItem(muList, v)
                        end
                    end,
                }
            }, {
                szOption = _L["chat time"],
                bCheck = true,
                bChecked = MY_Chat.bChatTime,
                fnAction = function()
                    MY_Chat.bChatTime = not MY_Chat.bChatTime
                end, {
                    szOption = _L['hh:mm'],
                    bMCheck = true,
                    bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN,
                    fnAction = function()
                        MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN
                    end,
                },{
                    szOption = _L['hh:mm:ss'],
                    bMCheck = true,
                    bChecked = MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC,
                    fnAction = function()
                        MY_Chat.nChatTime = CHAT_TIME.HOUR_MIN_SEC
                    end,
                }
            }, {
                bDevide = true
            }
        }
        local tChannel = { szOption = _L['channel setting'] }
        for _, v in ipairs(_Cache.tChannels) do
            table.insert(tChannel, {
                szOption = v.title, bCheck = true, bChecked = MY_Chat.tChannel[v.name], rgb = v.color,
                fnAction = function() MY_Chat.tChannel[v.name] = not MY_Chat.tChannel[v.name] MY_Chat.ReInitUI() end,
            })
        end
        table.insert(tChannel, {
            szOption = _L['AWAY'], bCheck = true, bChecked = MY_Chat.tChannel['Check_Away'],
            fnAction = function() MY_Chat.tChannel['Check_Away'] = not MY_Chat.tChannel['Check_Away'] MY_Chat.ReInitUI() end,
        })
        table.insert(tChannel, {
            szOption = _L['BUSY'], bCheck = true, bChecked = MY_Chat.tChannel['Check_Busy'],
            fnAction = function() MY_Chat.tChannel['Check_Busy'] = not MY_Chat.tChannel['Check_Busy'] MY_Chat.ReInitUI() end,
        })
        table.insert(t, tChannel)
        return t
    end)
    -- load settings
    MY_Chat.frame:EnableDrag(not MY_Chat.bLockPostion)
end)

-- hook chat panel
MY.HookChatPanel("MY_Chat", function(h, szMsg)
    -- chat filter
    if MY_Chat.bBlockWords then
        local t = MY.Chat.FormatContent(szMsg)
        local szText = ""
        for k, v in ipairs(t) do
            if v.text ~= "" then
                if v.type == "text" or v.type == "faceicon" then
                    szText = szText .. v.text
                end
            end
        end
        for _,szWord in ipairs(MY_Chat.tBlockWords) do
            if string.find(szText, MY.String.PatternEscape(szWord)) then
                return ""
            end
        end
    end
    -- save animiate group into name
    if MY_Chat.bChatTime or MY_Chat.bChatCopy then
        szMsg = string.gsub(szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")
    end
    
    return szMsg, h:GetItemCount()
end, function(h, szMsg, i)
    if (MY_Chat.bChatTime or MY_Chat.bChatCopy) and i then
        -- chat time
        local h2 = h:Lookup(i)
        if h2 and h2:GetType() == "Text" then
            local r, g, b = h2:GetFontColor()
            if r == 255 and g == 255 and b == 0 then
                return
            end
            
            -- create timestrap text
            local szTime = ""
            if MY_Chat.bChatCopy and (MY_Chat.bChatCopyAlwaysShowMask or not MY_Chat.bChatTime) then
                local _r, _g, _b = r, g, b
                if MY_Chat.bChatCopyAlwaysWhite then
                    _r, _g, _b = 255, 255, 255
                end
                szTime = GetFormatText(_L["*"], 10, _r, _g, _b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "copylink")
            elseif MY_Chat.bChatCopyAlwaysWhite then
                r, g, b = 255, 255, 255
            end
            if MY_Chat.bChatTime then
                local t =TimeToDate(GetCurrentTime())
                if MY_Chat.nChatTime == CHAT_TIME.HOUR_MIN_SEC then
                    szTime = szTime .. GetFormatText(string.format("[%02d:%02d:%02d]", t.hour, t.minute, t.second), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "timelink")
                else
                    szTime = szTime .. GetFormatText(string.format("[%02d:%02d]", t.hour, t.minute), 10, r, g, b, 515, "this.OnItemLButtonDown=function() MY.Chat.CopyChatLine(this) end\nthis.OnItemRButtonDown=function() MY.Chat.RepeatChatLine(this) end", "timelink")
                end
            end
            -- insert timestrap text
            h:InsertItemFromString(i, false, szTime)
        end
    end
end)