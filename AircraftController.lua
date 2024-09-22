app = {}
require('h3u')

app.conts = {'Pitch', 'Roll', 'Yaw', 'Pitch Trim', 'Roll Trim', 'Yaw Trim', 'Flap', 'Spoiler', 'Air Brake', 'Wheel Brake', 'Throttle #1', 'Throttle #2', 'Throttle #3', 'Throttle #4'}
app.valInits = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, 0, 1, 0, 0, 0, 0}
app.valDefaults = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0}
app.isRelatives = {false, false, false, true, true, true, true, true, true, true, true, true, true, true}
app.throttleCountMax = 4
app.alterInputCount = 3

local uis = ac.getUI()
local sim = ac.getSim()

local tblSetConts = {app.conts, app.valInits, app.valDefaults, app.isRelatives}
local tblThresh = {4500, 0.25, 0.25}
app.config = h3u.contCfgSys.new('cfg', tblSetConts, tblThresh, app.alterInputCount)

local n, loi
--------
local carPlayer = ac.getCar(0)
function script.update(dt)
    local share_key_header = 'car'..sim.focusedCar..'.'
    app.isAircraft = (ac.load(share_key_header..'isAircraft') == 1) or false
    app.enginesCount = math.min(ac.load(share_key_header..'aircraftEnginesCount') or 1, app.throttleCountMax)

    local funIsAvailable = function(contIndex, contName, loi)
        return ac.load(share_key_header..'aircraft.isAvailable.'..contName) or false
    end
    local funIsOverwrite = function(contIndex, contName, loi)
        return ac.load(share_key_header..'aircraft.isAuto.'..contName) or false
    end
    local funOverwriteVal = function(contIndex, contName, loi)
        return ac.load(share_key_header..'aircraft.autoVal.'..contName)
    end
    local funLoopFinal = function(contIndex, contName, loi)
        ac.store('aircraft.cont.'..contName, loi.valContN)
    end
    app.config:update(dt, funIsAvailable, funIsOverwrite, funOverwriteVal, funLoopFinal)

    h3u.updater(true)
end

--------
function script.windowMain(dt)
    local colWhite = rgbm(1, 1, 1, 1)
    local colAGray = rgbm(0.8, 0.8, 0.8, 0.3)
    local colABlack2 = rgbm(0, 0, 0, 0.5)
    local colABlack = rgbm(0, 0, 0, 0.3)
    local r1r = 0.99
    local r2r = 0.12
    local margin = 5
    local sizec = 150*vec2(1, 1)
    local base = vec2(200, 10)
    local pos, size, center
    local n, i
    local t = {'Flap', 'Spoiler', 'Air Brake', 'Wheel Brake'}
    local w = 0
    for _, n in ipairs(t) do
        i = app.config.contsT[n]
        if (app.config.list[i].isAvailable) then
            w = w + 24 + margin
        end
    end
    local function linearIndicator(leftTop, size, indWidth, margin, contVal, contName, curInputIndex, isAuto)
        local slideW = size.x - 2*margin.x
        ui.setCursor(leftTop)
        ui.dummy(size)
        ui.drawRectFilled(leftTop, leftTop + size, colABlack)
        for i = 0.25, 0.75, 0.5 do
            ui.drawLine(leftTop + vec2(margin.x + slideW*i, 2*margin.y), leftTop + vec2(margin.x + slideW*i, size.y - 2*margin.y), colAGray, 1)
        end
        ui.drawLine(leftTop + vec2(margin.x + slideW*0.5, 1*margin.y), leftTop + vec2(margin.x + slideW*0.5, size.y - 1*margin.y), colAGray, 1)
        
        ui.setCursor(leftTop)
        ui.textAligned(contName, vec2(0.5, 0.5), size, false)
        local size2 = vec2(indWidth, size.y - 2*margin.y)
        local leftTop2 = leftTop + margin + vec2(contVal*(slideW - indWidth), 0)
        ui.drawRectFilled(leftTop2, leftTop2 + size2, rgbm(1, 1, 1, 0.8)*uis.accentColor)
        ui.drawRect(leftTop2 - vec2(1, 1), leftTop2 + size2 + vec2(1, 1), colABlack2, 0, 0, 1)
        return leftTop2, size2
    end
    local function linearIndicatorVertical(leftTop, size, indWidth, margin, contVal, contName, curInputIndex, isAuto)
        ui.beginRotation()
        local leftTop2o, size2o = linearIndicator(leftTop + 0.5*vec2(-size.y + size.x, size.y - size.x), vec2(size.y, size.x), indWidth, margin, contVal, contName, curInputIndex, isAuto)
        local center = leftTop + 0.5*size
        local leftTop2r = h3u.rotateVec2(leftTop2o - center, 0.5*math.pi) + center
        local size2r = h3u.rotateVec2(size2o - 0*center, 0.5*math.pi) + 0*center
        local leftTop2v = leftTop2r + vec2(0, 1)*size2r
        local size2v = vec2(1, -1)*size2r
        ui.endRotation(180)
        return leftTop2v, size2v
    end

    ui.pushFont(ui.Font.Small)
    pos = base - vec2(0.5, 0)*sizec - app.enginesCount*vec2(24 + margin) - margin
    size = vec2(base.x - pos.x + 0.5*sizec.x + w + margin, sizec.y + 24 + 3*margin)
    ui.drawRectFilled(pos, pos + size, colABlack)
    ui.setCursor(pos)
    ui.dummy(size)

    size = sizec
    pos = base - vec2(0.5, 0)*sizec
    center = pos + 0.5*size
    ui.setCursor(pos)
    ui.dummy(size)
    ui.drawRectFilled(pos, pos + size, colABlack)
    local rBase = 0.5*math.min(size.x, size.y)
    local margin2 = 3
    local r1 = r1r*rBase
    local r2 = r2r*rBase
    local center2 = center + (r1 - margin - r2)*vec2((2*app.config.list[app.config.contsT['Roll']].valFinN - 1) or 0, (2*app.config.list[app.config.contsT['Pitch']].valFinN - 1) or 0)
    ui.drawLine(center + vec2(-r1 + margin2, 0), center + vec2(r1 - margin2, 0), colAGray, 1)
    ui.drawLine(center + vec2(0, -r1 + margin2), center + vec2(0, r1 - margin2), colAGray, 1)
    for angS = 0, 270, 90 do
        ui.pathClear()
        ui.pathArcTo(center, r1 - 2*margin2, math.rad(angS + 4), math.rad(angS + 86), 9)
        ui.pathStroke(colAGray, false, 1)
        ui.pathClear()
        ui.pathArcTo(center, 0.5*r1 - 1*margin2, math.rad(angS + 8), math.rad(angS + 82), 9)
        ui.pathStroke(colAGray, false, 1)
    end
    ui.drawCircleFilled(center2, r2, rgbm(1, 1, 1, 0.8)*uis.accentColor, 18)
    ui.drawCircle(center2, r2 + 1, colABlack2, 36, 1)
    
    local s1 = app.config.list[i].isOverwrite and 'A' or ((app.config.list[app.config.contsT['Pitch']].curInputIndex == 0) and '-' or app.config.list[i].curInputIndex)
    local s2 = app.config.list[i].isOverwrite and 'A' or ((app.config.list[app.config.contsT['Roll']].curInputIndex == 0) and '-' or app.config.list[i].curInputIndex)
    local s = (s1 == s2) and s1 or s1..'/'..s2
    ui.pushDWriteFont('Segoe UI;Weight=Bold')
    ui.setCursor(center2 - r2)
    ui.dwriteTextAligned(s, 12, 0, 0, 2*r2, false, rgbm(0.8, 0.8, 0.8, 1))
    ui.popDWriteFont()

    n = 'Yaw'
    i = app.config.contsT[n]
    pos = pos + vec2(0, size.y + margin)
    size = vec2(size.x, 24)
    local lt2, s2 = linearIndicator(pos, size, 16, vec2(2, 2), app.config.list[i].valFinN, n, app.config.list[i].curInputIndex, app.config.list[i].isAuto)
    s = app.config.list[i].isOverwrite and 'A' or ((app.config.list[i].curInputIndex == 0) and '-' or app.config.list[i].curInputIndex)
    ui.pushDWriteFont('Segoe UI;Weight=Bold')
    ui.setCursor(lt2)
    ui.dwriteTextAligned(s, 12, 0, 0, s2, false, rgbm(0.8, 0.8, 0.8, 1))
    ui.popDWriteFont()

    ui.setCursor(pos + vec2(0, 28))
    pos = pos + vec2(size.x + margin, -size.x - margin)
    size = vec2(size.y, size.x + 24 + margin)
    for _, n in ipairs(t) do
        i = app.config.contsT[n]
        if (app.config.list[i].isAvailable) then
            lt2, s2 = linearIndicatorVertical(pos, size, 16, vec2(2, 2), 1 - app.config.list[i].valFinN, n, app.config.list[i].curInputIndex, app.config.list[i].isAuto)
            s = app.config.list[i].isOverwrite and 'A' or ((app.config.list[i].curInputIndex == 0) and '-' or app.config.list[i].curInputIndex)
            ui.pushDWriteFont('Segoe UI;Weight=Bold')
            ui.setCursor(lt2)
            ui.dwriteTextAligned(s, 12, 0, 0, s2, false, rgbm(0.8, 0.8, 0.8, 1))
            ui.popDWriteFont()
            pos = pos + vec2(size.x + margin, 0)
        end
    end

    pos = base - vec2(0.5, 0)*sizec
    for iEng = app.enginesCount, 1, -1 do
        pos = pos - vec2(size.x + margin, 0)
        n = 'Throttle #'..iEng
        i = app.config.contsT[n]
        lt2, s2 = linearIndicatorVertical(pos, size, 16, vec2(2, 2), app.config.list[i].valFinN, n, app.config.list[i].curInputIndex, app.config.list[i].isAuto)
        s = app.config.list[i].isOverwrite and 'A' or ((app.config.list[i].curInputIndex == 0) and '-' or app.config.list[i].curInputIndex)
        ui.pushDWriteFont('Segoe UI;Weight=Bold')
        ui.setCursor(lt2)
        ui.dwriteTextAligned(s, 12, 0, 0, s2, false, rgbm(0.8, 0.8, 0.8, 1))
        ui.popDWriteFont()
    end

    -- leftTop = center - sizec*vec2(0.5, 0.5) - size*vec2(0, 1) + vec2(size.y + 8, 0)
    

    ui.popFont()
end

--------
app.uiSettings = {}
app.uiSettings.tabs = {'App', 'Configuration'}
app.uiSettings.tabCur = 1
app.uiSettings.tabOld = 0
app.uiSettings.tabTransition = 0
app.uiSettings.Configuration = {}
app.uiSettings.Configuration.tabs = {'All', 'Main Control Surfaces', 'Other controls', 'Trims', 'Throttles'}
app.uiSettings.Configuration.tabCur = 1
app.uiSettings.Configuration.tabOld = 0
app.uiSettings.Configuration.tabTransition = 0
function script.windowSettings(dt)
    local colWhite = rgbm(1, 1, 1, 1)
    local colLightGray = rgbm(0.8, 0.8, 0.8, 1)
    local colGray = rgbm(0.6, 0.6, 0.6, 1)
    local colDarkGray = rgbm(0.4, 0.4, 0.4, 1)
    local colBlack = rgbm(0, 0, 0, 1)
    local color
    local base = vec2(20, 30)
    local size = vec2()
    local pos = vec2()
    local blockWidth = (ui.windowSize().x - 280)/3
    local blockGap = 10
    local transOffset = 50*vec2(1 - app.uiSettings.tabTransition, 0)
    local val, bol
    local function drawTabApp()
        base = base + transOffset + vec2(20, 50)
        ui.setCursor(base)
        ui.text('There is nothing to show in here...')
    end
    local function drawTabConfiguration()
        local smallText
        local mainText
        local textStyle
        local flag
        local itemBase
        local yMax = 0
        

        base = vec2(40, 70)
        pos = base + transOffset
        local tblColors = {colWhite, colGray, colDarkGray}
        pos = h3u.drawCMStyleTab(dt, pos, 18, app.uiSettings.Configuration, false, false, tblColors, true)

        pos = base + vec2(180, 40)
        ui.pushDWriteFont('Segoe UI')
        for iAlter, nAlter in ipairs({'Primary', 'Secondary', 'Tertiary'}) do
            ui.setCursor(transOffset + pos + vec2((iAlter - 1)*(blockWidth + blockGap), 0))
            ui.dwriteTextAligned(nAlter, 16, -1, -1, vec2(blockWidth, 30), false, colLightGray)
        end
        ui.popDWriteFont()
        base = base + vec2(-20, 70)
        ui.drawLine(transOffset + base, transOffset + vec2(ui.windowSize().x - base.x, base.y), colDarkGray)
        
        size = ui.windowSize() - base - vec2(20, 20)
        -- ui.drawRectFilled(base, base + size, rgbm(0, 0, 0, 0.5))
        base = base + vec2(10, 10)
        size = ui.windowSize() - base - vec2(20, 20)
        ui.setCursor(transOffset + base)
        ui.beginChild('tid', size)
        ui.pushStyleVarAlpha(app.uiSettings.tabTransition*app.uiSettings.Configuration.tabTransition)

        local tConts = app.config.conts
        if (app.uiSettings.Configuration.tabCur == 2) then
            tConts = {app.config.conts[1], app.config.conts[2], app.config.conts[3]}
        elseif (app.uiSettings.Configuration.tabCur == 3) then
            tConts = {app.config.conts[7], app.config.conts[8], app.config.conts[9], app.config.conts[10]}
        elseif (app.uiSettings.Configuration.tabCur == 4) then
            tConts = {app.config.conts[4], app.config.conts[5], app.config.conts[6]}
        elseif (app.uiSettings.Configuration.tabCur == 5) then
            tConts = {app.config.conts[11], app.config.conts[12], app.config.conts[13], app.config.conts[14]}
        end
        for iCont, nCont in ipairs(tConts) do
            loi = app.config.list[app.config.contsT[nCont]]
            ui.pushDWriteFont('Segoe UI;Weight=Bold')
            -- base = vec2(50 - 50*(app.uiSettings.Configuration.tabTransition), 400*(iCont - 1))
            base = vec2(50 - 50*(app.uiSettings.Configuration.tabTransition), yMax)
            pos = base
            size = vec2(180, 40)
            ui.setCursor(pos)
            ui.dwriteTextAligned(nCont, 22, -1, -1, size, false, colLightGray)
            ui.popDWriteFont()
            ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + size, rgbm(1, 1, 1, 0.2)*colBlack)
            ui.drawRectFilled(pos + vec2(0, size.y - 4) + vec2(loi.valDefault, 0)*size, pos + vec2(loi.valContN, 1)*size, uis.accentColor)
            
            for iAlter, nAlter in ipairs({'Primary', 'Secondary', 'Tertiary'}) do
                itemBase = base + vec2(180 + (iAlter - 1)*(blockWidth + blockGap), (iCont - 1)*blockGap)
                local tblColors = {colWhite, colLightGray, colLightGray}
                app.uiSettings.Configuration.configBlockPos = app.uiSettings.Configuration.configBlockPos or {}
                app.uiSettings.Configuration.configBlockPos[iCont] = app.uiSettings.Configuration.configBlockPos[iCont] or {}
                app.uiSettings.Configuration.configBlockPos[iCont][iAlter] = app.uiSettings.Configuration.configBlockPos[iCont][iAlter] or {}
                app.uiSettings.Configuration.configBlockPos[iCont][iAlter][1] = app.uiSettings.Configuration.configBlockPos[iCont][iAlter][1] or vec2()
                app.uiSettings.Configuration.configBlockPos[iCont][iAlter][2] = app.uiSettings.Configuration.configBlockPos[iCont][iAlter][2] or vec2()
                local p1 = app.uiSettings.Configuration.configBlockPos[iCont][iAlter][1]
                local p2 = app.uiSettings.Configuration.configBlockPos[iCont][iAlter][2]
                if (ui.windowHovered() and ui.rectHovered(p1, p2)) then
                    ui.drawRectFilled(p1, p2, rgbm(1, 1, 1, 0.1))
                end
                if (iAlter == loi.curInputIndex) then
                    ui.drawRect(p1, p2, rgbm(1, 1, 1, 0.5)*uis.accentColor, 0, 0, 2)
                    ui.pushDWriteFont('Segoe UI;Weight=Bold')
                    ui.setCursor(p1 + vec2(blockGap))
                    ui.dwriteTextAligned('Active', 14, 1, -1, p2 - p1 - 1.5*vec2(blockGap), false, rgbm(1, 1, 1, 0.8)*uis.accentColor)
                    ui.popDWriteFont()
                end
                local y = h3u.drawCMStyleConfigBlock(itemBase, blockWidth, blockGap, app.config, nCont, iAlter, tblColors)
                yMax = math.max(yMax, y)
                app.uiSettings.Configuration.configBlockPos[iCont][iAlter][1] = itemBase + 0.5*vec2(blockGap, blockGap)
                app.uiSettings.Configuration.configBlockPos[iCont][iAlter][2] = itemBase + 0.5*vec2(blockGap, blockGap) + vec2(blockWidth, yMax - itemBase.y) + vec2(blockGap, 0)
            end
        end
        ui.text('')
        ui.endChild()
    end
    base = vec2(20, 30)
    pos = base
    size = vec2(200, 30)
    ui.pushDWriteFont('Segoe UI')
    ui.setCursor(pos)
    ui.dwriteTextAligned('Aircraft Controller', 24, -1, 0, size, false, colLightGray)
    ui.popDWriteFont()

    -- top tab
    pos = vec2(ui.windowSize().x - 20, 30)
    local tblColors = {colWhite, colGray, colDarkGray}
    pos = h3u.drawCMStyleTab(dt, pos, 18, app.uiSettings, true, true, tblColors, true)
    

    ui.pushStyleVarAlpha(app.uiSettings.tabTransition)
    if (app.uiSettings.tabCur == 1) then
        drawTabApp()
    elseif (app.uiSettings.tabCur == 2) then
        drawTabConfiguration()
    end
end
