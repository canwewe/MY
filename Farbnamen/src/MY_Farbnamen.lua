--
-- 聊天窗口名称染色插件
-- By 茗伊@双梦镇@荻花宫
-- ZhaiYiMing.CoM
-- 2014年5月19日05:07:02
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Farbnamen/lang/")
local _SUB_ADDON_FOLDER_NAME_ = "Farbnamen"
local XML_LINE_BREAKER = XML_LINE_BREAKER
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
---------------------------------------------------------------
-- 设置和数据
---------------------------------------------------------------
MY_Farbnamen = MY_Farbnamen or {
    bEnabled = true,
}
RegisterCustomData("Account\\MY_Farbnamen.bEnabled")
local SZ_CONFIG_PATH = "config/PLAYER_FORCE_COLOR/$uid.$lang.jx3dat"
local SZ_CACHE_PATH = "cache/PLAYER_INFO/$server.$lang.jx3dat"
local Config_Default = {
    nMaxCache = 2000,
    tForceColor = MY.LoadLUAData("config/PLAYER_FORCE_COLOR.jx3dat") or {
        [FORCE_TYPE.JIANG_HU ] = {255, 255, 255}, -- 江湖
        [FORCE_TYPE.SHAO_LIN ] = {255, 178, 95 }, -- 少林
        [FORCE_TYPE.WAN_HUA  ] = {196, 152, 255}, -- 万花
        [FORCE_TYPE.TIAN_CE  ] = {255, 111, 83 }, -- 天策
        [FORCE_TYPE.CHUN_YANG] = {89 , 224, 232}, -- 纯阳
        [FORCE_TYPE.QI_XIU   ] = {255, 129, 176}, -- 七秀
        [FORCE_TYPE.WU_DU    ] = {55 , 147, 255}, -- 五毒
        [FORCE_TYPE.TANG_MEN ] = {121, 183, 54 }, -- 唐门
        [FORCE_TYPE.CANG_JIAN] = {214, 249, 93 }, -- 藏剑
        [FORCE_TYPE.GAI_BANG ] = {205, 133, 63 }, -- 丐帮
        [FORCE_TYPE.MING_JIAO] = {240, 70 , 96 }, -- 明教
        [FORCE_TYPE.CANG_YUN ] = {180, 60 , 0  }, -- 苍云
        [FORCE_TYPE.CHANG_GE ] = {100, 250, 180}, -- 长歌
    },
}
local Config = clone(Config_Default)
local TongCache = MY.InfoCache("cache/PLAYER_INFO/$server/TONG/<SEG>.$lang.jx3dat", 2, 3000)
local InfoCache = (function()
    local aCache, tCache = {}, setmetatable({}, { __mode = "v" }) -- high speed L1 CACHE
    local tInfos, tInfoVisit, tInfoModified = {}, {}, {}
    local tCrossServerInfos = {}
    local tName2ID, tName2IDVisit, tName2IDModified = {}, {}, {}
    local SZ_DATA_PATH = "cache/PLAYER_INFO/$server/DAT2/%d.$lang.jx3dat"
    local SZ_N2ID_PATH = "cache/PLAYER_INFO/$server/N2ID/%d.$lang.jx3dat"
    return setmetatable({}, {
        __index = function(t, k)
            if IsRemotePlayer(UI_GetClientPlayerID())
            and tCrossServerInfos[k] then
                return tCrossServerInfos[k]
            end
            -- if hit in L1 CACHE
            if tCache[k] then
                -- Log("PLAYER INFO L1 HIT " .. k)
                return tCache[k]
            end
            -- read player info from saved data
            if type(k) == "string" then -- szName
                local nSegID = string.byte(k) or 0
                if not tName2ID[nSegID] then
                    tName2ID[nSegID] = MY.LoadLUAData(SZ_N2ID_PATH:format(nSegID)) or {}
                end
                tName2IDVisit[nSegID] = GetTime()
                k = tName2ID[nSegID][k]
            end
            if type(k) == "number" then -- dwID
                local nSegID = string.char(string.byte(k, 1, 3))
                if not tInfos[nSegID] then
                    tInfos[nSegID] = MY.LoadLUAData(SZ_DATA_PATH:format(nSegID)) or {}
                end
                tInfoVisit[nSegID] = GetTime()
                return tInfos[nSegID][k]
            end
        end,
        __newindex = function(t, k, v)
            if type(k) == "number" then -- dwID, tInfo
                if IsRemotePlayer(k) then
                    tCrossServerInfos[k] = v
                    tCrossServerInfos[v[2]] = v
                else
                    local bUpdated
                    -- read from L1 CACHE
                    local tInfo = tCache[k]
                    local nSegID = string.char(string.byte(k, 1, 3))
                     -- read from DataBase if L1 CACHE not hit
                    if not tInfo then
                        if not tInfos[nSegID] then
                            tInfos[nSegID] = MY.LoadLUAData(SZ_DATA_PATH:format(nSegID)) or {}
                        end
                        tInfo = tInfos[nSegID][k]
                        tInfoVisit[nSegID] = GetTime()
                    end
                    -- judge if info has been updated and need to be saved
                    if tInfo then
                        -- dwForceID
                        if v[6] == nil then
                            v[6] = tInfo[6]
                        end
                        -- check if cached value has changed
                        for kk, _ in ipairs(tInfo) do
                            if v[kk] ~= tInfo[kk] then
                                bUpdated = true
                                break
                            end
                        end
                    else
                        -- dwForceID
                        if v[6] == nil then
                            v[6] = ""
                        end
                        bUpdated = true
                    end
                    -- save player info
                    -- update L1 CACHE
                    if bUpdated or not tCache[k] then
                        if #aCache > 3000 then
                            tremove(aCache, 1)
                        end
                        tinsert(aCache, v)
                        tCache[k] = v
                        tCache[v[2]] = v
                    end
                    -- update DataBase
                    if bUpdated then
                        -- save info to DataBase
                        if not tInfos[nSegID] then
                            tInfos[nSegID] = MY.LoadLUAData(SZ_DATA_PATH:format(nSegID)) or {}
                        end
                        tInfos[nSegID][k] = v
                        tInfoVisit[nSegID] = GetTime()
                        tInfoModified[nSegID] = GetTime()
                        -- save szName to dwID indexing to DataBase
                        local nSegID = string.byte(v[2]) or 0
                        if not tName2ID[nSegID] then
                            tName2ID[nSegID] = MY.LoadLUAData(SZ_N2ID_PATH:format(nSegID)) or {}
                        end
                        if tName2ID[nSegID][v[2]] ~= k then
                            tName2ID[nSegID][v[2]] = k
                            tName2IDModified[nSegID] = GetTime()
                        end
                        tName2IDVisit[nSegID] = GetTime()
                    end
                end
            end
        end,
        __call = function(t, cmd, arg0, arg1, ...)
            if cmd == "clear" then
                -- clear all data file
                tInfos, tInfoVisit, tInfoModified = {}, {}, {}
                tName2ID, tName2IDModified = {}, {}
                for nSegID = 0, 99 do
                    if IsFileExist(MY.GetLUADataPath(SZ_DATA_PATH:format(nSegID))) then
                        MY.SaveLUAData(SZ_DATA_PATH:format(nSegID), nil)
                    end
                end
                for nSegID = 0, 255 do
                    if IsFileExist(MY.GetLUADataPath(SZ_N2ID_PATH:format(nSegID))) then
                        MY.SaveLUAData(SZ_N2ID_PATH:format(nSegID), nil)
                    end
                end
            elseif cmd == "save" then
                local dwTime = arg0
                local nCount = arg1
                local bCollect = arg2
                -- save info data
                for nSegID, dwLastVisitTime in pairs(tInfoVisit) do
                    if not dwTime or dwTime > dwLastVisitTime then
                        if nCount then
                            if nCount == 0 then
                                return true
                            end
                            nCount = nCount - 1
                        end
                        if tInfoModified[nSegID] then
                            MY.SaveLUAData(SZ_DATA_PATH:format(nSegID), tInfos[nSegID], nil, false, "1")
                        else
                            MY.Debug({"INFO Unloaded: " .. nSegID}, "MY_FARBNAMEN", MY_DEBUG.LOG)
                        end
                        if bCollect then
                            tInfos[nSegID] = nil
                        end
                        tInfoVisit[nSegID] = nil
                        tInfoModified[nSegID] = nil
                    end
                end
                -- save name index
                for nSegID, dwLastVisitTime in pairs(tName2IDVisit) do
                    if not dwTime or dwTime > dwLastVisitTime then
                        if nCount then
                            if nCount == 0 then
                                return true
                            end
                            nCount = nCount - 1
                        end
                        if tName2IDModified[nSegID] then
                            MY.SaveLUAData(SZ_N2ID_PATH:format(nSegID), tName2ID[nSegID])
                        else
                            MY.Debug({"N2ID Unloaded: " .. nSegID}, "MY_FARBNAMEN", MY_DEBUG.LOG)
                        end
                        if bCollect then
                            tName2ID[nSegID] = nil
                        end
                        tName2IDVisit[nSegID] = nil
                        tName2IDModified[nSegID] = nil
                    end
                end
            end
        end
    })
end)()
local _MY_Farbnamen = {
    tForceString = {},
    tRoleType    = {
        [1] = _L['man'],
        [2] = _L['woman'],
        [5] = _L['boy'],
        [6] = _L['girl'],
    },
    tCampString  = {},
    tCrossServerPlayerCache = {},
    aPlayerQueu = {},
}
for k, v in pairs(g_tStrings.tForceTitle) do
    _MY_Farbnamen.tForceString[k] = v
end
for k, v in pairs(g_tStrings.STR_GUILD_CAMP_NAME) do
    _MY_Farbnamen.tCampString[k] = v
end
setmetatable(_MY_Farbnamen.tForceString, { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tRoleType,    { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tCampString,  { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
-- 插入聊天内容的 HOOK （过滤、加入时间 ）
MY.HookChatPanel("MY_FARBNAMEN", function(h, szChannel, szMsg, dwTime)
    return szMsg, h:GetItemCount()
end, function(h, aParam, szChannel, szMsg, dwTime)
    if MY_Farbnamen.bEnabled then
        for i = h:GetItemCount() - 1, aParam[1] or 0, -1 do
            MY_Farbnamen.Render(h:Lookup(i))
        end
    end
end, function(h)
    for i = h:GetItemCount() - 1, 0, -1 do
        MY_Farbnamen.Render(h:Lookup(i))
    end
end)
-- 开放的名称染色接口
-- (userdata) MY_Farbnamen.Render(userdata namelink)    处理namelink染色 namelink是一个姓名Text元素
-- (string) MY_Farbnamen.Render(string szMsg)           格式化szMsg 处理里面的名字
MY_Farbnamen.Render = function(szMsg)
    if type(szMsg) == 'string' then
        -- <text>text="[就是个阵眼]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=515</text><text>text="说：" font=10 r=255 g=255 b=255 </text><text>text="[茗伊]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=771</text><text>text="\n" font=10 r=255 g=255 b=255 </text>
        local xml = MY.Xml.Decode(szMsg)
        if xml then
            for _, ele in ipairs(xml) do
                if ele[''].name and ele[''].name:sub(1, 9) == 'namelink_' then
                    local szName = string.gsub(ele[''].text, '[%[%]]', '')
                    local tInfo = MY_Farbnamen.GetAusName(szName)
                    if tInfo then
                        ele[''].r = tInfo.rgb[1]
                        ele[''].g = tInfo.rgb[2]
                        ele[''].b = tInfo.rgb[3]
                    end
                    ele[''].eventid = 82803
                    ele[''].script = (ele[''].script or '') .. '\nthis.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end'
                end
            end
            szMsg = MY.Xml.Encode(xml)
        end
        -- szMsg = string.gsub( szMsg, '<text>([^<]-)text="([^<]-)"([^<]-name="namelink_%d-"[^<]-)</text>', function (szExtra1, szName, szExtra2)
        --     szName = string.gsub(szName, '[%[%]]', '')
        --     local tInfo = MY_Farbnamen.GetAusName(szName)
        --     if tInfo then
        --         szExtra1 = string.gsub(szExtra1, '[rgb]=%d+', '')
        --         szExtra2 = string.gsub(szExtra2, '[rgb]=%d+', '')
        --         szExtra1 = string.gsub(szExtra1, 'eventid=%d+', '')
        --         szExtra2 = string.gsub(szExtra2, 'eventid=%d+', '')
        --         return string.format(
        --             '<text>%stext="[%s]"%s eventid=883 script="this.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end" r=%d g=%d b=%d</text>',
        --             szExtra1, szName, szExtra2, tInfo.rgb[1], tInfo.rgb[2], tInfo.rgb[3]
        --         )
        --     end
        -- end)
    elseif type(szMsg) == 'table' and type(szMsg.GetName) == 'function' and szMsg:GetName():sub(1, 8) == 'namelink' then
        local namelink = szMsg
        local ui = MY.UI(namelink):hover(MY_Farbnamen.ShowTip, HideTip, true)
        local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
        local tInfo = MY_Farbnamen.GetAusName(szName)
        if tInfo then
            ui:color(tInfo.rgb)
        end
    end
    return szMsg
end
-- 显示Tip
MY_Farbnamen.ShowTip = function(namelink)
    local x, y, w, h = 0, 0, 0, 0
    if type(namelink) ~= "table" then
        namelink = this
    end
    if not namelink then
        return
    end
    local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
    x, y = namelink:GetAbsPos()
    w, h = namelink:GetSize()
    
    local tInfo = MY_Farbnamen.GetAusName(szName)
    if tInfo then
        local tTip = {}
        -- author info
        if tInfo.dwID and tInfo.szName and tInfo.szName == MY.GetAddonInfo().tAuthor[tInfo.dwID] then
            tinsert(tTip, GetFormatText(_L['mingyi plugins'], 8, 255, 95, 159))
            tinsert(tTip, GetFormatText(' ', 136, 255, 95, 159))
            tinsert(tTip, GetFormatText(_L['[author]'], 8, 0, 255, 0))
            tinsert(tTip, XML_LINE_BREAKER)
        end
        -- 名称 等级
        tinsert(tTip, GetFormatText(('%s(%d)'):format(tInfo.szName, tInfo.nLevel), 136))
        -- 是否同队伍
        if UI_GetClientPlayerID() ~= tInfo.dwID and MY.IsParty(tInfo.dwID) then
            tinsert(tTip, GetFormatText(_L['[teammate]'], nil, 0, 255, 0))
        end
        tinsert(tTip, XML_LINE_BREAKER)
        -- 称号
        if tInfo.szTitle and #tInfo.szTitle > 0 then
            tinsert(tTip, GetFormatText('<' .. tInfo.szTitle .. '>', 136))
            tinsert(tTip, XML_LINE_BREAKER)
        end
        -- 帮会
        if tInfo.szTongID and #tInfo.szTongID > 0 then
            tinsert(tTip, GetFormatText('[' .. tInfo.szTongID .. ']', 136))
            tinsert(tTip, XML_LINE_BREAKER)
        end
        -- 门派 体型 阵营
        tinsert(tTip, GetFormatText(
            _MY_Farbnamen.tForceString[tInfo.dwForceID] .. _L.STR_SPLIT_DOT ..
            _MY_Farbnamen.tRoleType[tInfo.nRoleType]    .. _L.STR_SPLIT_DOT ..
            _MY_Farbnamen.tCampString[tInfo.nCamp], 136
        ))
        tinsert(tTip, XML_LINE_BREAKER)
        -- 随身便笺
        if MY_Anmerkungen and MY_Anmerkungen.GetPlayerNote then
            local tPlayerNote = MY_Anmerkungen.GetPlayerNote(tInfo.dwID)
            if tPlayerNote then
                tinsert(tTip, GetFormatText(tPlayerNote.szContent, 136))
                tinsert(tTip, XML_LINE_BREAKER)
            end
        end
        -- 调试信息
        if IsCtrlKeyDown() then
            tinsert(tTip, XML_LINE_BREAKER)
            tinsert(tTip, GetFormatText(_L("Player ID: %d", tInfo.dwID), 102))
        end
        -- 显示Tip
        OutputTip(tconcat(tTip), 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
    end
end
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
-- 通过szName获取信息
function MY_Farbnamen.Get(szKey)
    local info = InfoCache[szKey]
    if info then
        return {
            dwID      = info[1] or info.i,
            szName    = info[2] or info.n,
            dwForceID = info[3] or info.f,
            nRoleType = info[4] or info.r,
            nLevel    = info[5] or info.l,
            szTitle   = info[6] or info.t,
            nCamp     = info[7] or info.c,
            szTongID  = TongCache[info[8] or info.g] or "",
            rgb       = Config.tForceColor[info[3] or info.f] or {255, 255, 255}
        }
    end
end
function MY_Farbnamen.GetAusName(szName)
    return MY_Farbnamen.Get(szName)
end
-- 通过dwID获取信息
function MY_Farbnamen.GetAusID(dwID)
    MY_Farbnamen.AddAusID(dwID)
    return MY_Farbnamen.Get(dwID)
end
-- 保存指定dwID的玩家
function MY_Farbnamen.AddAusID(dwID)
    local player = GetPlayer(dwID)
    if not player or not player.szName or player.szName == "" then
        return false
    else
        InfoCache[player.dwID] = {
            player.dwID,
            player.szName,
            player.dwForceID or -1,
            player.nRoleType or -1,
            player.nLevel or -1,
            player.nX ~= 0 and player.szTitle or nil,
            player.nCamp or -1,
            player.dwTongID or -1,
        }
        local dwTongID = player.dwTongID
        if dwTongID and dwTongID ~= 0 then
            local szTong = GetTongClient().ApplyGetTongName(dwTongID, 254)
            if szTong and szTong ~= "" then
                TongCache[dwTongID] = szTong
            end
        end
        return true
    end
end
-- 保存用户设置
function _MY_Farbnamen.SaveCustomData()
    local t = {}
    t.tForceColor = {}
    for dwForceID, tCol in pairs(Config.tForceColor) do
        if not IsSameData(tCol, Config_Default[dwForceID]) then
            t.tForceColor[dwForceID] = tCol
        end
    end
    MY.Sys.SaveLUAData(SZ_CONFIG_PATH, t)
end
-- 加载用户配置
function _MY_Farbnamen.LoadCustomData()
    local t = MY.Sys.LoadLUAData(SZ_CONFIG_PATH) or {}
    if t.tForceColor then
        for k, v in pairs(t.tForceColor) do
            Config.tForceColor[k] = v
        end
    end
end

-- 加载旧版本缓存数据
function MY_Farbnamen.LoadData()
    -- 读取数据文件
    local data = MY.LoadLUAData(SZ_CACHE_PATH)
    -- 如果是Json格式的数据 则解码
    if type(data) == "string" then
        data = MY.Json.Decode(data) or {}
    end
    -- 解析数据
    if data then
        local nMaxCache = data.nMaxCache     -- 最大缓存数量
        local aCached   = data.aCached       -- 兼容旧版数据
        
        -- 处理老版本数据
        if aCached then
            for _, p in ipairs(aCached) do
                InfoCache[p.dwID] = {
                    i = p.dwID     ,
                    f = p.dwForceID,
                    n = p.szName   ,
                    r = p.nRoleType,
                    l = p.nLevel   ,
                    t = p.szTitle  ,
                    c = p.nCamp    ,
                    g = p.szTongID ,
                }
            end
        end
        MY.SaveLUAData(SZ_CACHE_PATH, nil)
    end
end

function MY_Farbnamen.GetForceRgb(nForce)
    return Config.tForceColor[nForce] or Config_Default.tForceColor[nForce] or {255, 255, 255}
end

--------------------------------------------------------------
-- 菜单
--------------------------------------------------------------
MY_Farbnamen.GetMenu = function()
    local t = {
        szOption = _L["Farbnamen"],
        fnAction = function()
            MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
        end,
        bCheck = true,
        bChecked = MY_Farbnamen.bEnabled
    }
    table.insert(t, {
        szOption = _L['customize color'],
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    for nForce, szForce in pairs(_MY_Farbnamen.tForceString) do
        table.insert(t[#t], {
            szOption = szForce,
            rgb = Config.tForceColor[nForce],
            bColorTable = true,
            fnChangeColor = function(_,r,g,b)
                Config.tForceColor[nForce] = {r,g,b}
                _MY_Farbnamen.SaveCustomData()
            end,
        })
    end
    table.insert(t[#t], { bDevide = true })
    table.insert(t[#t], {
        szOption = _L['load default setting'],
        fnAction = function()
            Config.tForceColor = clone(Config_Default.tForceColor)
            _MY_Farbnamen.SaveCustomData()
        end,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    table.insert(t, {
        szOption = _L["reset data"],
        fnAction = function()
            InfoCache("clear")
            MY.Sysmsg({_L['cache data deleted.']}, _L['Farbnamen'])
        end,
        fnDisable = function()
            return not MY_Farbnamen.bEnabled
        end,
    })
    return t
end
MY.RegisterPlayerAddonMenu('MY_Farbenamen', MY_Farbnamen.GetMenu)
MY.RegisterTraceButtonMenu('MY_Farbenamen', MY_Farbnamen.GetMenu)
--------------------------------------------------------------
-- 注册事件
--------------------------------------------------------------
local function OnPlayerEnter(dwID)
    if MY_Farbnamen.bEnabled then
        local nRetryCount = 0
        MY.BreatheCall(500, function()
            if MY_Farbnamen.AddAusID(dwID) or nRetryCount > 5 then
                return 0
            end
            nRetryCount = nRetryCount + 1
        end)
    end
end
MY.RegisterEvent("PEEK_OTHER_PLAYER", function()
    if arg0 == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
        OnPlayerEnter(arg1)
    end
end)
MY.RegisterEvent("PLAYER_ENTER_SCENE", function() OnPlayerEnter(arg0) end)
MY.RegisterInit('MY_FARBNAMEN_DATA', MY_Farbnamen.LoadData)
MY.RegisterInit('MY_FARBNAMEN_CUSTOMDATA', _MY_Farbnamen.LoadCustomData)
MY.RegisterExit('MY_FARBNAMEN_CACHE', function() InfoCache("save") end)
MY.BreatheCall('MY_FARBNAMEN_CACHE', 20000, function()
    if InfoCache("save", GetTime() - 60000, 1, true) then
        MY.BreatheCall('MY_FARBNAMEN_CACHE', 60, true)
    end
end)
MY.RegisterExit('MY_FARBNAMEN_TONG_CACHE', function() TongCache("save") end)
MY.BreatheCall('MY_FARBNAMEN_TONG_CACHE', 20000, function()
    if TongCache("save", GetTime() - 60000, 1, true) then
        MY.BreatheCall('MY_FARBNAMEN_TONG_CACHE', 60, true)
    end
end)
MY.RegisterEvent("ON_GET_TONG_NAME_NOTIFY", function() TongCache[arg1] = arg2 end)
