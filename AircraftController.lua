app = {}
require('h3u')

local tblConts = {}
tblConts[#tblConts + 1] = {'Pitch', 0.5, 0.5, false}
tblConts[#tblConts + 1] = {'Roll', 0.5, 0.5, false}
tblConts[#tblConts + 1] = {'Yaw', 0.5, 0.5, false}
tblConts[#tblConts + 1] = {'Pitch Trim', 0.5, 0.5, true}
tblConts[#tblConts + 1] = {'Roll Trim', 0.5, 0.5, true}
tblConts[#tblConts + 1] = {'Yaw Trim', 0.5, 0.5, true}
tblConts[#tblConts + 1] = {'Flap', 0, 0, true}
tblConts[#tblConts + 1] = {'Spoiler', 0, 0, true}
tblConts[#tblConts + 1] = {'Air Brake', 0, 0, true}
tblConts[#tblConts + 1] = {'Wheel Brake', 1, 0, true}
tblConts[#tblConts + 1] = {'Throttle #1', 0, 0, true}
tblConts[#tblConts + 1] = {'Throttle #2', 0, 0, true}
tblConts[#tblConts + 1] = {'Throttle #3', 0, 0, true}
tblConts[#tblConts + 1] = {'Throttle #4', 0, 0, true}
tblConts[#tblConts + 1] = {'Wheel Steering', 0.5, 0.5, false}
app.conts = {}
app.valInits = {}
app.valDefaults = {}
app.isRelatives = {}
for i, t in ipairs(tblConts) do
    app.conts[i] = t[1]
    app.valInits[i] = t[2]
    app.valDefaults[i] = t[3]
    app.isRelatives[i] = t[4]
end

-- app.conts = {'Pitch', 'Roll', 'Yaw', 'Pitch Trim', 'Roll Trim', 'Yaw Trim', 'Flap', 'Spoiler', 'Air Brake', 'Wheel Brake', 'Throttle #1', 'Throttle #2', 'Throttle #3', 'Throttle #4'}
-- app.valInits = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, 0, 1, 0, 0, 0, 0}
-- app.valDefaults = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0}
-- app.isRelatives = {false, false, false, true, true, true, true, true, true, true, true, true, true, true}
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

    
    -- for i = 0, ac.getJoystickCount() - 1 do
    --     -- ac.log(i, ac.getJoystickName(i), ac.getJoystickProductGUID(i), ac.getJoystickInstanceGUID(i), ac.getJoystickAxisValue(i, 0))
    --     ac.log(i, ac.getJoystickName(i))
    --     for j = 0, ac.getJoystickAxisCount(i) do
    --         ac.log('  '..ac.getJoystickAxisValue(i, j))
    --     end
    -- end
    -- show ac functions
    -- local text = ''
    -- for k, v in pairs(ac) do
    --     if (type(v) == 'function') then
    --         text = text..k..'\n'
    --     end
    -- end
    -- ac.log(text)
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
            tConts = {app.config.conts[7], app.config.conts[8], app.config.conts[9], app.config.conts[10], app.config.conts[15]}
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

----
local inst = nil
local screenSize = ac.getUI().windowSize
function script.windowInstruments(dt)
    local car = ac.getCar(sim.focusedCar)
    local share_key_header = 'car'..sim.focusedCar..'.'
    if (inst == nil) then
        inst = {}
        inst.aircraftVS0MS = ac.load(share_key_header..'aircraftVS0MS') or 0
        inst.aircraftVS1MS = ac.load(share_key_header..'aircraftVS1MS') or 40/h3u.unitMSToKt(1)
        inst.aircraftVFEMS = ac.load(share_key_header..'aircraftVFEMS') or 190/h3u.unitMSToKt(1)
        inst.aircraftVNOMS = ac.load(share_key_header..'aircraftVNOMS') or 130/h3u.unitMSToKt(1)
        inst.aircraftVNEMS = ac.load(share_key_header..'aircraftVNEMS') or 160/h3u.unitMSToKt(1)
        inst.accelerationReplayable = h3u.replayable.new(true, vec3())
        local rRef = 0.5*math.min(screenSize.x, screenSize.y)
        inst.ecShadow = ui.ExtraCanvas(math.min(screenSize.x, screenSize.y)*vec2(1, 1), 2)
        local function drawEc()
            for i = 1, 100 do
                ui.drawCircle(0.5*inst.ecShadow:size(), rRef*0.01*i, rgbm(0, 0, 0, (0.01*i)^20), 72, 0.01*rRef)
            end
        end
        inst.ecShadow:update(drawEc)
    end
    inst.windDirectionRad = 0.01745*sim.windDirectionDeg
    inst.airVelocity = 0.2778*sim.windSpeedKmh*vec3(math.sin(inst.windDirectionRad), 0, math.cos(inst.windDirectionRad))
    inst.isAircraft = (ac.load(share_key_header..'isAircraft') == 1) or false
    inst.isAircraftEnginesCount = ac.load(share_key_header..'isAircraftEnginesCount') or 1
    inst.isAircraftPreferGlassCockpit = (ac.load(share_key_header..'isAircraftPreferGlassCockpit') == 1) or false
    inst.isAircraftPreferSlavicUnit = (ac.load(share_key_header..'isAircraftPreferSlavicUnit') == 1) or false
    inst.aircraftVS0MS = ac.load(share_key_header..'aircraftVS0MS') or inst.aircraftVS0MS
    inst.aircraftVS1MS = ac.load(share_key_header..'aircraftVS1MS') or inst.aircraftVS1MS
    inst.aircraftVFEMS = ac.load(share_key_header..'aircraftVFEMS') or inst.aircraftVFEMS
    inst.aircraftVNOMS = ac.load(share_key_header..'aircraftVNOMS') or inst.aircraftVNOMS
    inst.aircraftVNEMS = ac.load(share_key_header..'aircraftVNEMS') or inst.aircraftVNEMS
    
    inst.aircraftUnitVelocityFunc = (inst.isAircraftPreferSlavicUnit) and h3u.unitMSToKmh or h3u.unitMSToKt
    inst.aircraftUnitAltitudeFunc = (inst.isAircraftPreferSlavicUnit) and h3u.funcDummy or h3u.unitMeterToFt
    inst.aircraftUnitDistanceFunc = (inst.isAircraftPreferSlavicUnit) and h3u.funcDummy or h3u.unitMeterToNM
    
    inst.pitch = h3u.vecs2angle(car.look, car.side, car.up).x - 0.5*math.pi
    inst.roll = h3u.vecs2angle(car.look, car.side, car.up).z
    inst.yaw = h3u.vecs2angle(car.look, car.side, car.up).y
    inst.acceleration = inst.accelerationReplayable:update(car.acceleration)
    inst.gForceWithGravity = inst.acceleration + h3u.globalOffs2car(car, vec3(0, 1, 0) + car.position)
    inst.downG = inst.gForceWithGravity.y
    inst.compass = car.compass
    inst.turnRateDeg = math.deg(car.localAngularVelocity.y) - 0.5*math.deg(car.localAngularVelocity.z)
    inst.slipSkidDeg = math.deg(math.atan2(inst.downG, inst.acceleration.x)) - 90
    inst.velocityWithAir = car.velocity + inst.airVelocity
    inst.localVelocityWithAir = h3u.globalOffs2car(car, inst.velocityWithAir + car.position)
    inst.alphaRad = math.atan2(inst.localVelocityWithAir.y, inst.localVelocityWithAir.z + 1)
    inst.betaRad = math.atan2(inst.localVelocityWithAir.x, inst.localVelocityWithAir.z + 1)
    inst.alphaDeg = math.deg(inst.alphaRad)
    inst.betaDeg = math.deg(inst.betaRad)
    inst.altitude = car.altitude - sim.baseAltitude
    inst.climbRate = car.velocity.y
    inst.temp_air = 273.15 + sim.ambientTemperature
    inst.dens_air = 1.293*(1 - 0.0065*inst.altitude/(inst.temp_air + 0.0065*inst.altitude))^5.257
    inst.pres_air = 101325*(1 - 0.0065*inst.altitude/(inst.temp_air + 0.0065*inst.altitude))^5.257

    inst.aircraftIASMS = inst.localVelocityWithAir.z*inst.dens_air/1.293
    inst.aircraftCASMS = inst.aircraftIASMS/math.cos(inst.alphaRad)/math.cos(inst.betaRad)
    inst.aircraftTASMS = inst.localVelocityWithAir.z/math.cos(inst.alphaRad)/math.cos(inst.betaRad)
    inst.aircraftGSMS = car.velocity*vec3(1, 0, 1):length()

    local windowOffset = vec2(10, 20)
    local windowSize = ui.windowSize() - vec2(20, 20) - windowOffset
    -- ui.drawRectFilled(vec2(0, 0), windowSize, rgbm(0, 0, 0, 0.2))
    -- ui.drawRectFilled(windowOffset, windowOffset + windowSize, rgbm(1, 0, 0, 0.2))

    local itemSizeMin = 120
    local windowAspectR = windowSize.x/windowSize.y
    local gridCount = vec2(math.clamp(math.floor(windowSize.x/itemSizeMin), 1, 6), math.clamp(math.floor(windowSize.y/itemSizeMin), 1, 6))
    if (windowAspectR >= 2.5) and (gridCount >= vec2(6, 1)) then
        gridCount = vec2(6, 1)
    elseif (gridCount >= vec2(3, 2)) then
        gridCount = vec2(3, 2)
    end
    local itemSize = math.min(windowSize.x/gridCount.x, windowSize.y/gridCount.y)
    local gridSize = itemSize*gridCount
    local gridCenter = 0.5*(windowSize + gridSize) + windowOffset
    local gridLeftTop = 0.5*(windowSize - gridSize) + windowOffset


    ----
    ---
    local function drawAnalogGauge(dt, center, rBase, valCur, valMin, valMax, gamma, 
        needleColor, textType, funcText, textSize, 
        angDegStart, angDegDur, tickIntervalPxMin, textIntervalPxMin, 
        tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors)

        local lw, r, col
        local tickInterval = valMax
        local textInterval = valMax
        local valRange = valMax - valMin
        local function calcAngDeg(val)
            return angDegStart + angDegDur*math.saturate((val - valMin)/valRange)^gamma
        end

        if (tblRangeColors) then
            for _, tblRangeColor in ipairs(tblRangeColors) do
                local angDeg1 = calcAngDeg(tblRangeColor[3])
                local angDeg2 = calcAngDeg(tblRangeColor[4])
                local r1 = tblRangeColor[1]
                local r2 = tblRangeColor[2]
                lw = math.abs(r2 - r1)*rBase
                r = rBase*r1 - 0.5*lw
                ui.pathClear()
                ui.pathArcTo(center, r, math.rad(angDeg1), math.rad(angDeg2), math.max(0.2*math.abs(angDeg2 - angDeg1), 1))
                ui.pathStroke(tblRangeColor[5], false, lw)
            end
        end
        --
        for i, v in ipairs(tblTickInterval) do
            local pxInterval = math.abs(2*math.pi*rBase/360*angDegDur/valRange*v)
            if (pxInterval >= tickIntervalPxMin) and (valRange%v == 0) then
                tickInterval = v
                break
            end
        end
        for i, v in ipairs(tblTextInterval) do
            local pxInterval = math.abs(2*math.pi*rBase/360*angDegDur/valRange*v)
            if (pxInterval >= textIntervalPxMin) then
                textInterval = v
                break
            end
        end
        --
        -- ui.beginOutline()
        for iVal = valMin, valMax, tickInterval do
            local ang = calcAngDeg(iVal)
            local r1, r2
            for _, tblTick in ipairs(tblTicks) do
                if (iVal%tblTick[1] == 0) or (iVal == valMin) or (iVal == valMax) then
                    r1 = rBase*tblTick[2]
                    r2 = rBase*tblTick[3]
                    lw = tblTick[5]
                    col = tblTick[6]
                    local p1 = center + r1*vec2(math.cos(math.rad(ang)), math.sin(math.rad(ang)))
                    local p2 = center + r2*vec2(math.cos(math.rad(ang)), math.sin(math.rad(ang)))
                    ui.drawLine(p1, p2, col, lw)
                    if ((iVal%textInterval == 0) and (iVal >= (valMin + textInterval)) and (iVal <= (valMax - textInterval))) or (iVal == valMin) or (iVal == valMax) then
                        local angVec = vec2(math.cos(math.rad(ang)), math.sin(math.rad(ang)))
                        local r3 = rBase*tblTick[4] - 0.6*textSize
                        local p3 = center + r3*angVec
                        local text, tSizeGain = funcText(iVal)
                        tSizeGain = tSizeGain or 1
                        local tSizeVec = vec2(#text, 1)
                        ui.setCursor(p3 - 0.5*tSizeGain*textSize*tSizeVec)
                        if (textType == 1) then
                            ui.beginRotation()
                            ui.dwriteTextAligned(text, tSizeGain*textSize, 0, 0, tSizeGain*textSize*tSizeVec, false, col)
                            ui.endRotation(-ang, vec2(0, 0))
                        elseif (textType == 2) then
                            local len = 3*#text
                            h3u.drawDwriteTextCurved(text, textSize, col, center, r3, ang - 0.5*len - 180, ang + 0.5*len - 180, 0)
                        else
                            ui.dwriteTextAligned(text, tSizeGain*textSize, 0, 0, tSizeGain*textSize*tSizeVec, false, col)
                        end
                    end
                    break
                end
            end
        end
        -- ui.endOutline(rgbm(0, 0, 0, 0.5), 1)
        
        ui.beginOutline()
        ui.pathClear()
        for _, needleShape in ipairs(tblNeedleShape) do
            local r = rBase*needleShape[1]
            local ang = calcAngDeg(valCur) + 20*needleShape[2]/rBase
            ui.pathLineTo(center + r*vec2(math.cos(math.rad(ang)), math.sin(math.rad(ang))))
        end
        ui.pathFillConvex(needleColor)
        ui.endOutline(rgbm(0, 0, 0, 0.5), 1.5)
    end
    local function drawAttitude(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        if (inst.attitude == nil) then
            inst.attitude = {}
        end
        local colBlue = rgbm(0.2, 0.5, 0.8, 1)
        local colBrown = rgbm(0.5, 0.3, 0.1, 1)
        local ecScale = 1.5
        inst.attitude.ec = inst.attitude.ec or ui.ExtraCanvas(ecScale*screenSize*vec2(1, 1), 2)
        local ecSize = inst.attitude.ec:size()

        
        r = 0.8*rRef
        local function drawEc(dt)
            local center = 0.5*ecSize
            local deg2Pt = 0.07*r*ecScale
            local rRef = rRef*ecScale
            local r = r*ecScale
            ui.drawRectFilled(vec2(0, 1)*(center + deg2Pt*math.deg(-inst.pitch)), ecSize, colBrown)
            ui.drawRectFilled(vec2(0, 0), vec2(1, 0)*ecSize + vec2(0, 1)*(center + deg2Pt*math.deg(-inst.pitch)), colBlue)
            -- ui.beginOutline()
            ui.drawLine(vec2(0, 1)*(center + deg2Pt*math.deg(-inst.pitch)), vec2(1, 0)*ecSize + vec2(0, 1)*(center + deg2Pt*math.deg(-inst.pitch)), rgbm(0.8, 0.8, 0.8, 1), 0.05*rRef)
            -- ui.endOutline(rgbm(0, 0, 0, 0.3), 1.5)

            ui.pushDWriteFont('Segoe UI;Weight=Semibold')
            local angCenter = math.deg(inst.pitch)
            local pitchRangeL = math.clamp(10*math.floor(0.1*angCenter - 3), -180, 180)
            local pitchRangeH = math.clamp(10*math.ceil(0.1*angCenter + 3), -180, 180)
            for iPitch = pitchRangeL, pitchRangeH, 2.5 do
                local iPitchD = iPitch
                if (iPitch == 0) then
                    -- lw = 0.04*rRef
                    -- col = rgbm(0.8, 0.8, 0.8, 1)
                    -- local y = deg2Pt*(iPitch - angCenter)
                    -- local x = r + 1
                    -- ui.beginOutline()
                    -- ui.drawLine(center + vec2(-1, 1)*vec2(x, y), center + vec2(x, y), col, lw)
                    -- ui.endOutline(rgbm(0, 0, 0, 0.2), 1)
                else
                    if (math.abs(iPitch) > 90) then
                        iPitchD = -math.sign(iPitch)*(180 - math.abs(iPitch))
                    end
                    if (iPitch%10 == 0) then
                        lw = 0.04*rRef
                        col = rgbm(0.8, 0.8, 0.8, 1)
                        fontSize = 0.25*rRef
                        wh = fontSize*vec2(2, 1)
                        local y = deg2Pt*(iPitch - angCenter)
                        local x = 0.4*r
                        local y2 = y + 0.1*r*math.sign(-iPitchD)
                        ui.drawLine(center + vec2(-1, 1)*vec2(x, y), center + vec2(x, y), col, lw)
                        ui.setCursor(center + vec2(-1, 1)*vec2(x, y) - vec2(1.2, 0.5)*wh)
                        ui.dwriteTextAligned(math.abs(iPitchD), fontSize, 1, 0, wh, true, col)
                        ui.setCursor(center + vec2(x, y) - vec2(-0.2, 0.5)*wh)
                        ui.dwriteTextAligned(math.abs(iPitchD), fontSize, -1, 0, wh, true, col)
                    elseif (iPitch%5 == 0) then
                        lw = 0.04*rRef
                        col = rgbm(0.8, 0.8, 0.8, 0.7)
                        local y = deg2Pt*(iPitch - angCenter)
                        local x = 0.2*r
                        ui.drawLine(center + vec2(-1, 1)*vec2(x, y), center + vec2(x, y), col, lw)
                    end
                end
            end
            ui.popDWriteFont()
        end
        inst.attitude.ec:clear()
        inst.attitude.ec:update(drawEc)
        
        if (not inst.isAircraftPreferSlavicUnit) then
            ui.beginRotation()
        end
        ui.beginTextureShade(inst.attitude.ec)
        ui.drawCircleFilled(centerRef, r, rgbm(1, 1, 1, 1), 36)
        ui.endTextureShade(centerRef - r*vec2(1, 1), centerRef + r*vec2(1, 1), 0.5*(1 - 2*rRef/ecSize*ecScale), 0.5*(1 + 2*rRef/ecSize*ecScale))
        if (not inst.isAircraftPreferSlavicUnit) then
            ui.endPivotRotation(math.deg(inst.roll) + 90, centerRef)
        end
        
        lw = 0.02*rRef
        -- ui.beginTextureShade(inst.ecShadow)
        ui.drawCircle(centerRef, r - 0.0*lw, rgbm(0, 0, 0, 0.5), 36, lw)
        -- ui.endTextureShade(centerRef - r*vec2(1, 1), centerRef + r*vec2(1, 1))

        if (inst.isAircraftPreferSlavicUnit) then
            ui.beginRotation()
        end
        lw = 0.05*rRef
        col = rgbm(0.9, 0.9, 0.9, 1)
        ui.beginOutline()
        ui.pathClear()
        ui.pathLineTo(centerRef + r*vec2(-0.7, 0))
        ui.pathLineTo(centerRef + r*vec2(-0.4, 0))
        ui.pathLineTo(centerRef + r*vec2(-0.2, 0.2))
        ui.pathLineTo(centerRef + r*vec2(0, 0))
        ui.pathLineTo(centerRef + r*vec2(0.2, 0.2))
        ui.pathLineTo(centerRef + r*vec2(0.4, 0))
        ui.pathLineTo(centerRef + r*vec2(0.7, 0))
        ui.pathStroke(col, false, lw)
        
        ui.pathClear()
        ui.pathLineTo(centerRef + r*vec2(-0.01, -0.98))
        ui.pathLineTo(centerRef + r*vec2(0.01, -0.98))
        ui.pathLineTo(centerRef + r*vec2(0.15, -0.7))
        ui.pathLineTo(centerRef + r*vec2(0.13, -0.68))
        ui.pathLineTo(centerRef + r*vec2(-0.13, -0.68))
        ui.pathLineTo(centerRef + r*vec2(-0.15, -0.7))
        ui.pathFillConvex(col)
        ui.endOutline(rgbm(0, 0, 0, 0.2), 2)
        if (inst.isAircraftPreferSlavicUnit) then
            ui.endPivotRotation(-math.deg(inst.roll) + 90, centerRef)
        end

        
        if (not inst.isAircraftPreferSlavicUnit) then
            ui.beginRotation()
        end
        lw = 0.2*rRef
        r = rRef - 0.5*lw
        -- ui.beginOutline()
        -- ui.pathClear()
        -- ui.pathArcTo(centerRef, r, 0, math.pi, 18)
        -- ui.pathStroke(colBrown, false, lw)
        -- ui.pathClear()
        -- ui.pathArcTo(centerRef, r, math.pi, 2*math.pi, 18)
        -- ui.pathStroke(colBlue, false, lw)
        -- ui.endOutline(rgbm(0, 0, 0, 0.1), 1)

        local r2, lw2
        for iAng = -180, 180, 10 do
            local v = vec2(math.cos(math.rad(iAng - 90)), math.sin(math.rad(iAng - 90)))
            if (math.abs(iAng) == 90) then
                lw2 = 0.05*rRef
                r2 = 0.2*rRef
                ui.drawLine(centerRef + (r - 0.5*lw)*v, centerRef + (r - 0.5*lw + r2)*v, rgbm(0.8, 0.8, 0.8, 1), lw2)
            elseif (math.abs(iAng) <= 90) then
                if (iAng%30 == 0) then
                    lw2 = 0.04*rRef
                    r2 = 0.13*rRef
                    ui.drawLine(centerRef + (r - 0.5*lw)*v, centerRef + (r - 0.5*lw + r2)*v, rgbm(0.8, 0.8, 0.8, 1), lw2)
                elseif (math.abs(iAng) <= 30) then
                    lw2 = 0.03*rRef
                    r2 = 0.07*rRef
                    ui.drawLine(centerRef + (r - 0.5*lw)*v, centerRef + (r - 0.5*lw + r2)*v, rgbm(0.8, 0.8, 0.8, 1), lw2)
                end
            else
                if (iAng%30 == 0) then
                    lw2 = 0.03*rRef
                    r2 = 0.07*rRef
                    ui.drawLine(centerRef + (r - 0.5*lw)*v, centerRef + (r - 0.5*lw + r2)*v, rgbm(0.8, 0.8, 0.8, 1), lw2)
                end
            end
        end
        if (not inst.isAircraftPreferSlavicUnit) then
            ui.endPivotRotation(math.deg(inst.roll) + 90, centerRef)
        end
    end
    local function drawAirspeed(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        r = 0.8*rRef
        ui.pushDWriteFont('Segoe UI;Weight=Semibold')
        
        local angDur = 300
        local angStart = -60
        local vne = inst.aircraftUnitVelocityFunc(inst.aircraftVNEMS)
        local maxStep = ((inst.isAircraftPreferSlavicUnit) and 5 or 1)*((vne >= 500) and 300 or 50)
        local rangeMin = 0
        local rangeMax = maxStep*math.ceil(vne/maxStep + 0)
        wh = vec2(1, 0.32)*rRef
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y - 0.98*rRef)
        fontSize = 0.15*rRef
        text = 'AIRSPEED'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y + 0.1*rRef)
        text = (inst.isAircraftPreferSlavicUnit) and 'KM/H' or 'KTS'
        if (rangeMax >= 1000) then
            text = 'x100'..text
        end
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        local tblNeedleShape = {}
        tblNeedleShape[#tblNeedleShape + 1] = {0.94, -2}
        tblNeedleShape[#tblNeedleShape + 1] = {0.95, 0}
        tblNeedleShape[#tblNeedleShape + 1] = {0.94, 2}
        tblNeedleShape[#tblNeedleShape + 1] = {-0.1, -200}
        tblNeedleShape[#tblNeedleShape + 1] = {-0.2, 0}
        tblNeedleShape[#tblNeedleShape + 1] = {-0.1, 200}
        local tblTicks = {}
        tblTicks[#tblTicks + 1] = {1000, 1, 0.85, 0.8, 4, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {100, 1, 0.85, 0.8, 3, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {50, 1, 0.9, 0.8, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {20, 1, 0.9, 0.8, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {1, 1, 0.93, 0.8, 2, rgbm(0.9, 0.9, 0.9, 0)}
        local tblTickInterval = {25, 50, 100, 200, 500, 1000}
        local tblTextInterval = {50, 100, 200, 500, 1000}
        local tblRangeColors = {}
        tblRangeColors[#tblRangeColors + 1] = {0.95, 0.85, vne, rangeMax, rgbm(1, 0.2, 0.2, 0.8)}
        tblRangeColors[#tblRangeColors + 1] = {0.95, 0.85, inst.aircraftUnitVelocityFunc(inst.aircraftVNOMS), vne, rgbm(1, 1, 0.2, 0.8)}
        tblRangeColors[#tblRangeColors + 1] = {0.95, 0.85, inst.aircraftUnitVelocityFunc(inst.aircraftVS1MS), inst.aircraftUnitVelocityFunc(inst.aircraftVNOMS), rgbm(0.2, 0.9, 0.2, 0.8)}
        tblRangeColors[#tblRangeColors + 1] = {1, 0.95, inst.aircraftUnitVelocityFunc(inst.aircraftVS0MS), inst.aircraftUnitVelocityFunc(inst.aircraftVFEMS), rgbm(0.9, 0.9, 0.9, 0.8)}
        local funcText = function(val)
            return string.format('%d', ((rangeMax >= 500) and 0.01 or 1)*val)
        end
        if (inst.isAircraftPreferSlavicUnit) then
            tblTicks = {}
            tblTicks[#tblTicks + 1] = {1000, 1, 0.85, 0.8, 4, rgbm(0.9, 0.9, 0.9, 1)}
            tblTicks[#tblTicks + 1] = {200, 1, 0.85, 0.8, 3, rgbm(0.9, 0.9, 0.9, 1)}
            tblTicks[#tblTicks + 1] = {100, 1, 0.9, 0.8, 2, rgbm(0.9, 0.9, 0.9, 1)}
            tblTicks[#tblTicks + 1] = {1, 1, 0.93, 0.8, 2, rgbm(0.9, 0.9, 0.9, 0)}
            tblTickInterval = {100, 200, 500, 1000}
            tblTextInterval = {100, 200, 500, 1000}
        end
        xy = centerRef
        drawAnalogGauge(dt, xy, 0.98*rRef, inst.aircraftUnitVelocityFunc(inst.aircraftIASMS), rangeMin, rangeMax, 1, 
            rgbm(1, 1, 1, 1), 0, funcText, 0.25*rRef, 
            angStart, angDur, 6, 30, 
            tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
        )


        ui.popDWriteFont()
    end
    local function drawAltitude(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        r = 0.8*rRef
        ui.pushDWriteFont('Segoe UI;Weight=Semibold')
        
        local angDur = 360
        local angStart = -90
        local rangeMin = 0
        local rangeMax = 1000
        local altDisp = inst.aircraftUnitAltitudeFunc(inst.altitude)

        fontSize = 0.2*rRef
        wh = vec2(5, 1)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y - 0.45*rRef)
        text = 'ALT'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        fontSize = 0.15*rRef
        wh = vec2(5, 1)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y + 0.25*rRef)
        text = 'x100 '..((inst.isAircraftPreferSlavicUnit) and 'M' or 'FT')
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        
        fontSize = 0.25*rRef
        wh = vec2(0.6, 1)*fontSize
        -- ui.beginScale()
        ui.drawRectFilled(centerRef - vec2(2.7, 0.7)*wh, centerRef + vec2(2.7, 0.7)*wh, rgbm(0, 0, 0, 0))
        ui.pushClipRect(centerRef - vec2(2.7, 0.7)*wh, centerRef + vec2(2.7, 0.7)*wh)
        local xyBase, valBase, valSub
        for iDigit = 1, 5 do
            local iDigit2 = (iDigit <= 3) and iDigit or 3
            valBase = math.floor(altDisp*10^(-5 + iDigit))%10
            valSub = altDisp*10^(-5 + iDigit2)%1
            xyBase = centerRef + vec2(iDigit - 3.5, -0.5)*wh
            for iVert = 1, 5 do
                local th = 1 - 10^(-3 + iDigit2)
                local valSub2 = (valSub >= th) and 10^(3 - iDigit2)*(valSub - th) or 0
                xy = xyBase + vec2(0, -iVert + 3 + valSub2)*wh
                text = (valBase + iVert - 3)%10
                if (iDigit >= 4) then
                    text = 0
                end
                local a = 0.5 + 0.5*math.cos(0.5*math.pi*math.saturate(math.abs(iVert - 3 - valSub2)))
                col = rgbm(1, 1, 1, a)
                if (a >= 0.1) then
                    -- ui.beginOutline()
                    ui.setCursor(xy)
                    ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)
                    -- ui.endOutline(rgbm(0, 0, 0, 0.01 + 0.49*a), 1)
                end
            end
        end
        ui.popClipRect()
        -- ui.beginOutline()
        ui.drawRect(centerRef - vec2(2.7, 0.7)*wh, centerRef + vec2(2.7, 0.7)*wh, rgbm(0.8, 0.8, 0.8, 1), 0, 0, 0.025*rRef)
        -- ui.endOutline(rgbm(0, 0, 0, 0.5), 1)
        -- ui.endScale(vec2(1.0, 1))

        local tblNeedleShape = {}
        tblNeedleShape[#tblNeedleShape + 1] = {0.8, -15}
        tblNeedleShape[#tblNeedleShape + 1] = {0.95, 0}
        tblNeedleShape[#tblNeedleShape + 1] = {0.8, 15}
        tblNeedleShape[#tblNeedleShape + 1] = {0.6, 10}
        tblNeedleShape[#tblNeedleShape + 1] = {0.6, -10}
        local tblTicks = {}
        tblTicks[#tblTicks + 1] = {100, 1, 0.85, 0.85, 4, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {10, 1, 0.9, 0.85, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {1, 1, 0.93, 0.85, 2, rgbm(0.9, 0.9, 0.9, 0)}
        local tblTickInterval = {20, 100}
        local tblTextInterval = {100}
        local tblRangeColors = {}
        local funcText = function(val)
            if (val == rangeMax) then
                return ''
            else
                return string.format('%d', 0.01*val)
            end
        end
        xy = centerRef
        drawAnalogGauge(dt, xy, 0.98*rRef, inst.aircraftUnitAltitudeFunc(inst.altitude)%rangeMax, rangeMin, rangeMax, 1, 
            rgbm(1, 1, 1, 1), 0, funcText, 0.25*rRef, 
            angStart, angDur, 6, 20, 
            tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
        )


        ui.popDWriteFont()
    end
    local function drawHeading(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        r = 0.8*rRef
        ui.pushDWriteFont('Segoe UI;Weight=Semibold')
        
        local angDur = 360
        local angStart = -90 - inst.compass%360
        local rangeMin = 0
        local rangeMax = 360

        local tblNeedleShape = {}
        local tblTicks = {}
        tblTicks[#tblTicks + 1] = {30, 1, 0.85, 0.85, 4, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {10, 1, 0.9, 0.85, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {5, 1, 0.95, 0.85, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {1, 1, 0.93, 0.85, 2, rgbm(0.9, 0.9, 0.9, 0)}
        local tblTickInterval = {5, 10, 30}
        local tblTextInterval = {30}
        local tblRangeColors = {}
        local funcText = function(val)
            if (val == rangeMax) then
                return ''
            elseif (val == 0) then
                return 'N'
            elseif (val == 90) then
                return 'E'
            elseif (val == 180) then
                return 'S'
            elseif (val == 270) then
                return 'W'
            else
                return string.format('%d', 0.1*val), 0.8
            end
        end
        xy = centerRef
        drawAnalogGauge(dt, xy, 0.92*rRef, inst.compass%360, rangeMin, rangeMax, 1, 
            rgbm(1, 1, 1, 1), 1, funcText, 0.22*rRef, 
            angStart, angDur, 6, 20, 
            tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
        )
        col = rgbm(0.9, 0.5, 0.2, 1)
        ui.beginOutline()
        for iAng = -45, 225, 45 do
            local v
            ui.pathClear()
            v = vec2(math.cos(math.rad(iAng + 0.5)), math.sin(math.rad(iAng + 0.5)))
            ui.pathLineTo(xy + 0.85*rRef*v)
            v = vec2(math.cos(math.rad(iAng - 0.5)), math.sin(math.rad(iAng - 0.5)))
            ui.pathLineTo(xy + 0.85*rRef*v)
            ui.pathArcTo(xy, 0.98*rRef, math.rad(iAng - 4), math.rad(iAng + 4), 3)
            ui.pathFillConvex(col)
        end
        ui.endOutline(rgbm(0, 0, 0, 0.5), 1.5)
        local tblPathPlane = {}
        tblPathPlane[#tblPathPlane + 1] = vec2(0, -0.98)
        tblPathPlane[#tblPathPlane + 1] = vec2(0, -0.7)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.08, -0.4)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.1, -0.2)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.5, 0.1)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.5, 0.25)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.1, 0.1)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.08, 0.3)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.2, 0.45)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.2, 0.6)
        tblPathPlane[#tblPathPlane + 1] = vec2(0.05, 0.5)
        tblPathPlane[#tblPathPlane + 1] = vec2(0, 0.6)
        ui.beginOutline()
        ui.pathClear()
        for iTbl = 1, #tblPathPlane do
            ui.pathLineTo(xy + rRef*tblPathPlane[iTbl])
        end
        for iTbl = #tblPathPlane, 1, -1 do
            ui.pathLineTo(xy + vec2(-1, 1)*rRef*tblPathPlane[iTbl])
        end
        ui.pathSmoothStroke(col, true, 0.03*rRef)
        ui.endOutline(rgbm(0, 0, 0, 0.5), 1.5)


        ui.popDWriteFont()
    end
    local function drawVerticalSpeed(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        r = 0.8*rRef
        ui.pushDWriteFont('Segoe UI;Weight=Semibold')
        
        fontSize = 0.16*rRef
        wh = vec2(5, 2.5)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y - 0.42*rRef)
        text = 'VERTICAL\nSPEED'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        fontSize = 0.14*rRef
        wh = vec2(10, 1)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y + 0.2*rRef)
        text = 'x1000 '..((inst.isAircraftPreferSlavicUnit) and 'M' or 'FT')..'/MIN'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        inst.climbRatePerMin = math.applyLag(inst.climbRatePerMin or inst.aircraftUnitAltitudeFunc(inst.climbRate)*60, inst.aircraftUnitAltitudeFunc(inst.climbRate)*60, 0.5, dt)
        local angDur = 75
        local angStart = 270
        local rangeMin = 2000
        local rangeMax = 4000
        local tblNeedleShape = {}
        local tblTicks = {}
        tblTicks[#tblTicks + 1] = {1000, 1, 0.85, 0.85, 4, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {500, 1, 0.92, 0.85, 3, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {100, 1, 0.9, 0.85, 2, rgbm(0.9, 0.9, 0.9, 1)}
        tblTicks[#tblTicks + 1] = {1, 1, 0.93, 0.85, 2, rgbm(0.9, 0.9, 0.9, 0)}
        local tblTickInterval = {500, 1000}
        local tblTextInterval = {1000}
        local tblRangeColors = {}
        local funcText = function(val)
            if (val == 500) then
                return 'UP', 0.6
            elseif (val == -500) then
                return 'DN', 0.6
            elseif (val%1000 == 0) then
                return string.format('%d', 0.001*math.abs(val))
            else
                return ''
            end
        end
        xy = centerRef
        for iLayer = 1, 2 do
            if (iLayer == 2) then
                tblTicks = {}
            end
            --
            angDur = 70
            angStart = 20
            rangeMin = -6000
            rangeMax = -3000
            tblNeedleShape = {}
            if (iLayer == 2) and (inst.climbRatePerMin < rangeMax) then
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, -10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.95, 0}
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, 10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, 30}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, -30}
            end
            funcText = function(val)
                if (val == rangeMax) then
                    return ''
                elseif (val == 500) then
                    return 'UP', 0.6
                elseif (val == -500) then
                    return 'DN', 0.6
                elseif (val%1000 == 0) then
                    return string.format('%d', 0.001*math.abs(val))
                else
                    return ''
                end
            end
            drawAnalogGauge(dt, xy, 0.98*rRef, inst.climbRatePerMin, rangeMin, rangeMax, 1, 
                rgbm(1, 1, 1, 1), 0, funcText, 0.25*rRef, 
                angStart, angDur, 13, 20, 
                tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
            )
            --
            angStart = 270
            rangeMin = 3000
            rangeMax = 6000
            tblNeedleShape = {}
            if (iLayer == 2) and (inst.climbRatePerMin > rangeMin) then
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, -10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.95, 0}
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, 10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, 30}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, -30}
            end
            funcText = function(val)
                if (val == rangeMin) then
                    return ''
                elseif (val == 500) then
                    return 'UP', 0.6
                elseif (val == -500) then
                    return 'DN', 0.6
                elseif (val%1000 == 0) then
                    return string.format('%d', 0.001*math.abs(val))
                else
                    return ''
                end
            end
            drawAnalogGauge(dt, xy, 0.98*rRef, inst.climbRatePerMin, rangeMin, rangeMax, 1, 
                rgbm(1, 1, 1, 1), 0, funcText, 0.25*rRef, 
                angStart, angDur, 13, 20, 
                tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
            )
            --
            angDur = 180
            angStart = 90
            rangeMin = -3000
            rangeMax = 3000
            tblNeedleShape = {}
            if (iLayer == 2) and (inst.climbRatePerMin >= rangeMin) and (inst.climbRatePerMin <= rangeMax) then
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, -10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.95, 0}
                tblNeedleShape[#tblNeedleShape + 1] = {0.8, 10}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, 30}
                tblNeedleShape[#tblNeedleShape + 1] = {0.3, -30}
            end
            if (iLayer == 1) then
                tblTickInterval = {100, 500, 1000}
                tblTextInterval = {500, 1000}
            end
            funcText = function(val)
                if (val == 500) then
                    return 'UP', 0.6
                elseif (val == -500) then
                    return 'DN', 0.6
                elseif (val%1000 == 0) then
                    return string.format('%d', 0.001*math.abs(val))
                else
                    return ''
                end
            end
            drawAnalogGauge(dt, xy, 0.98*rRef, inst.climbRatePerMin, rangeMin, rangeMax, 1, 
                rgbm(1, 1, 1, 1), 0, funcText, 0.25*rRef, 
                angStart, angDur, 13, 20, 
                tblNeedleShape, tblTicks, tblTickInterval, tblTextInterval, tblRangeColors
            )
        end

        ui.popDWriteFont()
    end
    local function drawTurnCoordinator(centerRef, rRef)
        local xy, wh, center, r, lw, text, fontSize, col
        r = 0.8*rRef
        ui.pushDWriteFont('Segoe UI;Weight=Semibold')
        center = centerRef
        

        fontSize = 0.12*rRef
        wh = vec2(12, 2.5)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y - 0.4*rRef)
        text = 'TURN COORDINATOR'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, -1, wh, false, col)

        fontSize = 0.16*rRef
        wh = vec2(12, 1)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y + 0.52*rRef)
        text = '2 MIN.'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, 0, wh, false, col)

        fontSize = 0.09*rRef
        wh = vec2(15, 2.5)*fontSize
        xy = vec2(centerRef.x - 0.5*wh.x, centerRef.y + 0.1*rRef)
        text = 'NO PITCH INFORMATION'
        col = rgbm(0.8, 0.8, 0.8, 0.7)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 0, -1, wh, false, col)

        r = 2*rRef
        local angSlipSkidDeg = 30
        local centerSlipSkid = centerRef + vec2(0, -0.8)*r
        local thickSlipSkid = 0.1*r
        local slipSkidLim = math.clamp(inst.slipSkidDeg, -0.5*angSlipSkidDeg, 0.5*angSlipSkidDeg)
        inst.slipSkid_flt = math.applyLag(inst.slipSkid_flt or slipSkidLim, slipSkidLim, 0.95, dt)
        -- ui.beginOutline()
        ui.pathClear()
        ui.pathArcTo(centerSlipSkid, r, math.rad(-0.5*angSlipSkidDeg + 90), math.rad(0.5*angSlipSkidDeg + 90), 2*angSlipSkidDeg)
        ui.pathStroke(rgbm(0.8, 0.8, 0.8, 1), false, thickSlipSkid)
        ui.pathClear()
        ui.pathArcTo(centerSlipSkid + r*vec2(math.cos(math.rad(0.5*angSlipSkidDeg + 90)), math.sin(math.rad(0.5*angSlipSkidDeg + 90))), 0.5*thickSlipSkid, math.rad(0.5*angSlipSkidDeg + 280), math.rad(0.5*angSlipSkidDeg + 90), 36)
        ui.pathFillConvex(rgbm(0.8, 0.8, 0.8, 1))
        ui.pathClear()
        ui.pathArcTo(centerSlipSkid + r*vec2(math.cos(math.rad(-0.5*angSlipSkidDeg + 90)), math.sin(math.rad(-0.5*angSlipSkidDeg + 90))), 0.5*thickSlipSkid, math.rad(-0.5*angSlipSkidDeg + 90), math.rad(-0.5*angSlipSkidDeg - 90), 36)
        ui.pathFillConvex(rgbm(0.8, 0.8, 0.8, 1))

        ui.pathClear()
        ui.pathArcTo(centerSlipSkid, r - 0.5*thickSlipSkid, math.rad(-0.5*angSlipSkidDeg + 90), math.rad(0.5*angSlipSkidDeg + 90), 2*angSlipSkidDeg)
        ui.pathArcTo(centerSlipSkid + r*vec2(math.cos(math.rad(0.5*angSlipSkidDeg + 90)), math.sin(math.rad(0.5*angSlipSkidDeg + 90))), 0.5*thickSlipSkid, math.rad(0.5*angSlipSkidDeg + 280), math.rad(0.5*angSlipSkidDeg + 90), 36)
        ui.pathArcTo(centerSlipSkid, r + 0.5*thickSlipSkid, math.rad(0.5*angSlipSkidDeg + 90), math.rad(-0.5*angSlipSkidDeg + 90), 2*angSlipSkidDeg)
        ui.pathArcTo(centerSlipSkid + r*vec2(math.cos(math.rad(-0.5*angSlipSkidDeg + 90)), math.sin(math.rad(-0.5*angSlipSkidDeg + 90))), 0.5*thickSlipSkid, math.rad(-0.5*angSlipSkidDeg + 90), math.rad(-0.5*angSlipSkidDeg - 90), 36)
        ui.pathStroke(rgbm(0.8, 0.8, 0.8, 1), true, 0.03*rRef)
        -- ui.endOutline(rgbm(0, 0, 0, 0.2), 1.5)

        local ang = 4
        local p1 = centerSlipSkid + (r - 0.5*thickSlipSkid - 0.015*rRef)*vec2(math.cos(math.rad(ang + 90)), math.sin(math.rad(ang + 90)))
        local p2 = centerSlipSkid + (r + 0.5*thickSlipSkid + 0.015*rRef)*vec2(math.cos(math.rad(ang + 90)), math.sin(math.rad(ang + 90)))
        ui.drawLine(p1, p2, rgbm(0, 0, 0, 0.8), 0.02*rRef)
        ang = -4
        p1 = centerSlipSkid + (r - 0.5*thickSlipSkid - 0.015*rRef)*vec2(math.cos(math.rad(ang + 90)), math.sin(math.rad(ang + 90)))
        p2 = centerSlipSkid + (r + 0.5*thickSlipSkid + 0.015*rRef)*vec2(math.cos(math.rad(ang + 90)), math.sin(math.rad(ang + 90)))
        ui.drawLine(p1, p2, rgbm(0, 0, 0, 0.8), 0.02*rRef)

        ui.beginOutline()
        ui.drawCircleFilled(centerSlipSkid + r*vec2(math.cos(math.rad(inst.slipSkid_flt + 90)), math.sin(math.rad(inst.slipSkid_flt + 90))), 0.5*thickSlipSkid, rgbm(0.1, 0.1, 0.1, 1), 72)
        ui.endOutline(rgbm(0, 0, 0, 0.2), 1)

        r = 0.8*rRef
        -- outer
        local lw2 = 0.2*rRef
        local r2 = r + 0.5*lw2
        lw = 0.02*rRef
        ui.drawCircle(centerRef, r - 0.0*lw, rgbm(0, 0, 0, 0.5), 36, lw)

        
        ui.beginRotation()
        lw = 0.05*rRef
        col = rgbm(0.9, 0.9, 0.9, 1)
        ui.beginOutline()
        ui.drawCircleFilled(center, 0.15*r, col, 72)
        ui.drawLine(center + r*vec2(-1, 0), center + r*vec2(1, 0), col, 0.08*r)
        ui.drawLine(center + r*vec2(-0.4, -0.15), center + r*vec2(0.4, -0.15), col, 0.08*r)
        ui.drawLine(center + r*vec2(0, -0.3), center + r*vec2(0, 0), col, 0.08*r)
        ui.endOutline(rgbm(0, 0, 0, 0.2), 2)
        local turnRateDegLmt = 10*(2*h3u.sigmoid(inst.turnRateDeg/10 + 0.5) - 1)
        inst.turnRateDeg_flt = math.applyLag(inst.turnRateDeg_flt or turnRateDegLmt, turnRateDegLmt, 0.95, dt)
        ui.endPivotRotation(inst.turnRateDeg_flt*25/3 + 90, center)
        
        -- ui.drawCircle(center, r2, rgbm(0, 0, 0, 0.5), 72, lw2)
        for iAng = -180, 180, 5 do
            local v = vec2(math.cos(math.rad(iAng - 90)), math.sin(math.rad(iAng - 90)))
            if (math.abs(iAng) == 115) then
                lw = 0.04*rRef
                ui.drawLine(center + 1.01*(r2 - 0.5*lw2)*v, center + 0.98*(r2 + 0.5*lw2)*v, rgbm(0.8, 0.8, 0.8, 1), lw)
            end
        end
        
        fontSize = 0.16*rRef
        wh = vec2(1, 1)*fontSize
        local v = vec2(math.cos(math.rad(145)), math.sin(math.rad(145)))
        xy = center + (r2 - 0*0.5*lw2)*v - 0.5*wh
        text = 'L'
        col = rgbm(0.8, 0.8, 0.8, 1)
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, 1, 1, wh, false, col)
        v = vec2(math.cos(math.rad(35)), math.sin(math.rad(35)))
        xy = center + (r2 - 0*0.5*lw2)*v - 0.5*wh
        text = 'R'
        ui.setCursor(xy)
        ui.dwriteTextAligned(text, fontSize, -1, 1, wh, false, col)

        lw = 0.05*rRef
        ui.drawLine(center + (r2 - 0.5*lw2)*vec2(1, 0), center + (r2 + 0.5*lw2)*vec2(1, 0), rgbm(0.8, 0.8, 0.8, 1), lw)
        ui.drawLine(center + (r2 - 0.5*lw2)*vec2(-1, 0), center + (r2 + 0.5*lw2)*vec2(-1, 0), rgbm(0.8, 0.8, 0.8, 1), lw)

        ui.popDWriteFont()
    end
    ----
    local tblDraw = {}
    tblDraw[#tblDraw + 1] = drawAttitude
    tblDraw[#tblDraw + 1] = drawAirspeed
    tblDraw[#tblDraw + 1] = drawAltitude
    tblDraw[#tblDraw + 1] = drawHeading
    tblDraw[#tblDraw + 1] = drawVerticalSpeed
    tblDraw[#tblDraw + 1] = drawTurnCoordinator

    if (gridCount == vec2(3, 2)) then
        tblDraw[1] = drawAirspeed
        tblDraw[2] = drawAttitude
        tblDraw[3] = drawAltitude
        tblDraw[4] = drawTurnCoordinator
        tblDraw[5] = drawHeading
        tblDraw[6] = drawVerticalSpeed
    elseif (gridCount == vec2(6, 1)) then
        tblDraw[1] = drawTurnCoordinator
        tblDraw[2] = drawAirspeed
        tblDraw[3] = drawAttitude
        tblDraw[4] = drawHeading
        tblDraw[5] = drawAltitude
        tblDraw[6] = drawVerticalSpeed
    end

    
    -- ui.pushDWriteFont('DIN Medium.ttf')
    local drawFuncIndex = 1
    for y = 1, gridCount.y do
        for x = 1, gridCount.x do
            local centerRef = gridLeftTop + itemSize*vec2(x - 0.5, y - 0.5)
            local rRef = 0.5*(itemSize - 10)
            -- ui.drawRectFilled(gridLeftTop + itemSize*vec2(x - 1, y - 1), gridLeftTop + itemSize*vec2(x, y), rgbm(0.15*x, 0.3*y, 0, 0.3))
            ui.drawCircleFilled(centerRef, rRef, rgbm(0, 0, 0, 0.5), 36)
            if (tblDraw[drawFuncIndex] ~= nil) then
                tblDraw[drawFuncIndex](centerRef, rRef)
            end
            drawFuncIndex = drawFuncIndex + 1
        end
    end
    -- ui.popDWriteFont()
end