-- h3u.lua
-- my personal utilities
-- author: H3Chr
h3u = {}
h3u.version = 1.109
h3u.updateCount = 0
h3u.isUpdateError = false
h3u.updater = function(throwWhenUpdateError)
    throwWhenUpdateError = throwWhenUpdateError or false
    local ver_str = string.format('v.%2.3f', h3u.version)
    local ltv = ac.load('h3u.latestVersion') or ''
    local ltv_num = tonumber(string.sub(ltv, 3, -1))
    h3u.curpath = ac.dirname()..'\\h3u.lua'
    if (h3u.isUpdateError) then
        local mes = 'h3u.lua Update Failed.\nCopy the file manually by running this on command prompt:'
        -- ac.error(h3u.newpath)
        ac.error('COPY '..h3u.newpath..' '..h3u.curpath)
        ac.error(mes..'\n')
        if (throwWhenUpdateError) then
            error(mes..'\n'..h3u.newpath)
        end
        
    else
        if ((string.startsWith(ltv, 'v.') == false) or (ltv_num < h3u.version)) then
            ac.store('h3u.latestVersion', ver_str)
            ac.store('h3u.latestFilepath', h3u.curpath)
        else
            h3u.updateCount = h3u.updateCount + 1
            if (ltv_num > h3u.version) then
                h3u.newpath = ac.load('h3u.latestFilepath')
                if (h3u.updateCount >= 300) then
                    h3u.isUpdateError = true
                else
                    h3u.bkppath = (h3u.curpath..'_'..ver_str..'_bkp')
                    local ret
                    ac.warn('h3u.lua New version '..ltv..' is available. Updating...')
                    ret = os.execute('COPY '..h3u.curpath..' '..h3u.bkppath, 1000, true) -- backup current versin file ---
                    if (ret == -1) then
                        ac.error('h3u.lua Updater: Backup Failed.\n'..h3u.curpath..' -> '..h3u.bkppath)
                    end
                    ret = os.execute('COPY '..h3u.newpath..' '..h3u.curpath, 1000, true) -- copy new version
                    if (ret == -1) then
                        ac.error('h3u.lua Updater: Update Failed.\n'..h3u.newpath..' -> '..h3u.curpath)
                    end
                    -- error('New version '..ltv..' is available.')
                end
            end
        end
    end
end
h3u.updater()
ac.warn('h3u.lua library: ver'..h3u.version)
--------

h3u.replayFrame = (ac.getSim().isReplayActive) and ac.getSim().replayCurrentFrame or ac.getSim().replayFrames

function h3u.isNan(val)
    return (val ~= val)
end

function h3u.bool2num(boolean)
    return boolean and 1 or 0
end

function h3u.rateLimit(valFrom, valTo, up, dn, dt)
    if (valFrom < valTo) then
        return math.min(valFrom + up*dt, valTo)
    elseif (valFrom > valTo) then
        return math.max(valFrom + dn*dt, valTo)
    end
    return valFrom
end

function h3u.rateLimitVec(vecFrom, vecTo, rate, dt)
    local vecDiff = (vecTo - vecFrom)
    local vecDiffLen = vecDiff:length()
    return vecFrom + math.min(dt*rate, vecDiffLen)*vecDiff:normalize()
end

function h3u.sigmoid(x)
    if ((x == 1.0) or (x == 0.0)) then return x end
    return (math.tanh(x*6 - 3) + 1)/2
end

function h3u.normal_dist(x)
    return math.exp(-(x^2)/2)/math.sqrt(2*math.pi)
end

function h3u.log_normal_dist(x, sigma_2, mu)
    local ln = math.log(x, math.exp(1))
    local exp = -((ln - mu)^2)/(2*sigma_2)
    local root = 2*math.pi*sigma_2
    return math.exp(exp)/(math.sqrt(root)*x)
end

function h3u.softplus(x)
    return math.log(1 + math.exp(x), math.exp(1))
end

function h3u.mish(x)
    return x*math.tanh(h3u.softplus(x))
end

function h3u.doubleProportional(x, aPlus, aMinus)
    return (x >= 0) and aPlus*x or aMinus*x
end

function h3u.inRectRange(point, rect_v1, rect_v2)
    return (point.x >= rect_v1.x) and (point.y >= rect_v1.y) and (point.x <= rect_v2.x) and (point.y <= rect_v2.y)
end

function h3u.rotateVec2(vec, radians)
    local newX = vec.x*math.cos(radians) + vec.y*math.sin(radians)
    local newY = -vec.x*math.sin(radians) + vec.y*math.cos(radians)
    return vec2(newX, newY)
end

function h3u.addForceSafe(position, posLocal, force, forceLocal)
    position = ((position ~= nil) and (position == position)) and position or vec3()
    force = ((force ~= nil) and (force == force)) and force or vec3()
    return ac.addForce(position, posLocal, force, forceLocal)
end

function h3u.setWingGainSafe(wingIndex, cdGain, clGain)
    cdGain = ((cdGain ~= nil) and (cdGain == cdGain)) and cdGain or vec3()
    clGain = ((clGain ~= nil) and (clGain == clGain)) and clGain or vec3()
    return ac.setWingGain(wingIndex, cdGain, clGain)
end

function h3u.getTextFromData(filename, carIndex)
    local ini = ac.getFolder(ac.FolderID.ContentCars) .. '\\' .. ac.getCarID(carIndex) .. '\\data\\'..filename
    local acd = ac.getFolder(ac.FolderID.ContentCars) .. '\\' .. ac.getCarID(carIndex) .. '\\data.acd'
    if (io.exists(acd)) then
        return ac.readDataFile(ini)
    else
        return io.open(ini, 'r'):read('a')
    end
end


local function getIndexFromName(name)
    local ind = -1
    for i = 0, ac.getJoystickCount() - 1 do
        ind = i
        -- ac.log('  '..ac.getJoystickName(i).."==?"..name)
        if (ac.getJoystickName(i) == name) then
        break
        end
    end
    return ind
end

  
function h3u.getLut(lutText, carIndex)
    local ret = {}
    local lutString = ''
    local sep = ''

    if (lutText == nil) then
        ret = {{0, 0}}
    else
        if (string.find(lutText, '([-%d_]+)=([-%d_]+)') == nil) then
            lutString = h3u.getTextFromData(lutText, carIndex)
            sep = '|'
        else
            lutString = lutText
            sep = '='
        end
        -- LUT左側の数字は昇順前提。←が守られなかった場合は以降すべて読み飛ばされる アセコル本体もこうだったはず(未確認)
        local a_max_hist = nil
        for a, b in string.gmatch(lutString, '([-%d.]+)'..sep..'([-%d.]+)') do
            if (a_max_hist == nil or a_max_hist < tonumber(a)) then
                a_max_hist = tonumber(a)
                table.insert(ret, {tonumber(a), tonumber(b)})
            else
                break
            end
        end
    end
    return ret
end

function h3u.calcLut(lutData, x)
    local lutXi1, lutXi2
    local range_l = 1
    local range_w = math.max(#lutData - range_l, 0)
    if (lutData == nil or #lutData == 0) then
        lutData = {{0, 0}}
    end
    -- ac.log(lutData, range_w)
    for i = 1, #lutData do
        local range_m = math.round(range_l + 0.5*range_w)
        -- ac.log('calcLut', i, x, range_m, lutData[range_m][1])
        if (x == lutData[range_m][1]) then
            -- ac.log('center end')
            lutXi1 = range_m
            lutXi2 = range_m
            break
        elseif (x < lutData[range_m][1]) then -- 半分より左
            range_w = 0.5*range_w
            if (range_w < 1) then
                -- ac.log('left end')
                lutXi1 = math.clamp(range_m - 1, 1, #lutData)
                lutXi2 = range_m
                break
            end
        else
            range_l = range_m
            range_w = 0.5*range_w
            if (range_w < 1) then
                -- ac.log('right end')
                lutXi1 = range_m
                lutXi2 = math.clamp(range_m + 1, 1, #lutData)
                break
            end
        end
    end

    -- sanity
    -- if not (x >= lutData[lutXi1][1] and x <= lutData[lutXi2][1]) then
    --     ac.log('OOR?????')
    -- end

    -- ac.log(lutXi1, lutXi2)
    -- ac.log(x, lutData[lutXi1][1], lutData[lutXi2][1])
    if (lutXi1 == lutXi2) then
        return lutData[lutXi1][2]
    else
        local xn = (x - lutData[lutXi1][1])/(lutData[lutXi2][1] - lutData[lutXi1][1])
        return math.lerp(lutData[lutXi1][2], lutData[lutXi2][2], xn)
    end
end


function h3u.index2color(i)
    return rgbm(0.6 + 0.4*math.sin(2*0.667*math.pi + i), 0.6 + 0.4*math.sin(0*0.667*math.pi + i), 0.6 + 0.4*math.sin(1*0.667*math.pi + i), 1)
end

function h3u.complementaryColor(baseColor)
    local max = math.max(baseColor.r, baseColor.g, baseColor.b)
    local min = math.min(baseColor.r, baseColor.g, baseColor.b)
    return rgbm(max + min - baseColor.r, max + min - baseColor.g, max + min - baseColor.b, baseColor.mult)
end

function h3u.calcDynamicControllerInputAero(inputName, carIndex)
    local out = 0
    local car = ac.getCar(carIndex)
    --LONG LATG BRAKE0-1 GAS0-1 STEER-1+1 SPEED HEADLIGHTS SCRIPT_*
    if (inputName == 'ONE') then out = 1
    elseif (inputName == 'LONG') then out = car.acceleration.z/car.mass
    elseif (inputName == 'LATG') then out = car.acceleration.x/car.mass
    elseif (inputName == 'BRAKE') then out = car.brake
    elseif (inputName == 'GAS') then out = car.gas
    elseif (inputName == 'STEER') then out = car.steer/car.steerLock
    elseif (inputName == 'SPEED') then out = car.speedKmh
    elseif (inputName == 'HEADLIGHTS') then out = (car.headlightsActive) and 1 or 0
    elseif (string.find(inputName, 'SCRIPT_%d')) then
        local n = tonumber(string.match(inputName, 'SCRIPT_(%d)'))
        out = ac.getCarPhysics(carIndex).scriptControllerInputs[n]
    end
    return out
end


function h3u.CustomFunc_loadCarIni(file, carIndex, section) -- empty by default, overwrite by users
end
function h3u.loadCarIni(file, carIndex)
    local ret = {}
    local text = h3u.getTextFromData(file..'.ini', carIndex)
    -- ac.log(text)
    for a, b in ipairs(string.split(text, '[')) do
        -- ac.log(b)
        local txtTilSecEnd = string.match(b, '.-%]')
        -- ac.log(txtTilSecEnd)
        if (txtTilSecEnd ~= nil) then
            local section = string.sub(txtTilSecEnd, 1, -2)
            ret[section] = {}
            for line in string.gmatch(b, '.-\n') do
                for c, d, e in string.gmatch(line, '([%w_]+)=([-%w_., %(%)|=]+).-\n') do
                    local commaN = string.len(d) - string.len(string.gsub(d, ',', ''))
                    -- ac.log(section, c, d, commaN)
                    if (commaN == 0) then
                        ret[section][c] = d
                    else
                        ret[section][c] = {}
                        local leftOfComma = ''
                        local rightOfComma = d
                        for i = 1, commaN do
                            local commaI = string.find(rightOfComma, ',')
                            leftOfComma = string.sub(rightOfComma, 1, commaI - 1)
                            rightOfComma = string.sub(rightOfComma, commaI + 1, string.len(rightOfComma))
                            ret[section][c][i] = leftOfComma
                            -- ac.log(left, i, leftOfComma)
                        end
                        ret[section][c][commaN + 1] = rightOfComma
                        -- ac.log(left, commaN + 1, rightOfComma)
                    end
                end
            end
            h3u.CustomFunc_loadCarIni(file, carIndex, section)
        end
    end
    return ret
end



function h3u.vecs2angle(look, side, up)
    local ga = vec3()
    local a = vec3(0, 0, 0)
    local b = vec3(0, 0, 0)
    local c = vec3(0, 0, 0)
    local d = vec3(0, 0, 0)
    local buf0 = 0
    local buf1 = 0
    a = vec3(0, 1, 0)
    b = look
    ga.x = math.acos((a.x*b.x + a.y*b.y + a.z*b.z) / math.sqrt((a.x^2 + a.y^2 + a.z^2)*(b.x^2 + b.y^2 + b.z^2)))

    a = vec3(1, 0, 0)
    b = look
    c = vec3(0, 0, 1)
    d = look
    buf0 = (a.x*b.x + a.y*b.y + a.z*b.z) / math.sqrt((a.x^2 + a.y^2 + a.z^2)*(b.x^2 + b.y^2 + b.z^2))
    buf1 = (c.x*d.x + c.y*d.y + c.z*d.z) / math.sqrt((c.x^2 + c.y^2 + c.z^2)*(d.x^2 + d.y^2 + d.z^2))
    ga.y = math.atan2(buf0, buf1)

    a = vec3(0, 1, 0)
    b = side
    c = vec3(0, 1, 0)
    d = up
    buf0 = (a.x*b.x + a.y*b.y + a.z*b.z) / math.sqrt((a.x^2 + a.y^2 + a.z^2)*(b.x^2 + b.y^2 + b.z^2))
    buf1 = (c.x*d.x + c.y*d.y + c.z*d.z) / math.sqrt((c.x^2 + c.y^2 + c.z^2)*(d.x^2 + d.y^2 + d.z^2))
    ga.z = math.atan2(buf0, buf1)
    return ga
end

function h3u.angle2vecs(ga)
    local look = vec3()
    local side = vec3()
    local up = vec3()

    local qz = quat.fromAngleAxis(-ga.z, vec3(0, 0, 1))
    local qx = quat.fromAngleAxis(ga.x - 0.5*math.pi, vec3(1, 0, 0))
    local qy = quat.fromAngleAxis(ga.y, vec3(0, 1, 0))
    
    look = vec3(0, 0, 1):rotate(qz):rotate(qx):rotate(qy)
    side = vec3(1, 0, 0):rotate(qz):rotate(qx):rotate(qy)
    up = vec3(0, 1, 0):rotate(qz):rotate(qx):rotate(qy)
    return look, side, up
end

function h3u.carOffs2global(car, coor_offest)
    local gp_car = car.position
    local ga_car = h3u.vecs2angle(car.look, car.side, car.up)
    local coor_offset_rot = 1*coor_offest
    coor_offset_rot:rotate(quat.fromAngleAxis(ga_car.z, vec3(0, 0, 1)))
    coor_offset_rot:rotate(quat.fromAngleAxis(ga_car.x - 0.5*math.pi, vec3(1, 0, 0)))
    coor_offset_rot:rotate(quat.fromAngleAxis(ga_car.y, vec3(0, 1, 0)))
    local gp_tgt = gp_car + coor_offset_rot
    return gp_tgt
end
function h3u.globalOffs2car(car, coor_global)
    local gp_car = car.position
    local ga_car = h3u.vecs2angle(car.look, car.side, car.up)
    local coor_global_rot = 1*coor_global - gp_car
    coor_global_rot:rotate(quat.fromAngleAxis(-ga_car.y, vec3(0, 1, 0)))
    coor_global_rot:rotate(quat.fromAngleAxis(-ga_car.x + 0.5*math.pi, vec3(1, 0, 0)))
    coor_global_rot:rotate(quat.fromAngleAxis(-ga_car.z, vec3(0, 0, 1)))
    local gp_tgt = coor_global_rot
    return gp_tgt
end
function h3u.globalOffs2cam(coor_global)
    local gp_cam = ac.getCameraPosition()
    local ga_cam = h3u.vecs2angle(ac.getCameraForward(), ac.getCameraSide(), ac.getCameraUp())
    local coor_offset_rot = 1*coor_global - gp_cam
    coor_offset_rot:rotate(quat.fromAngleAxis(-ga_cam.z, vec3(0, 0, 1)))
    coor_offset_rot:rotate(quat.fromAngleAxis(-ga_cam.x + 0.5*math.pi, vec3(1, 0, 0)))
    coor_offset_rot:rotate(quat.fromAngleAxis(-ga_cam.y, vec3(0, 1, 0)))
    local gp_tgt = coor_offset_rot
    return gp_tgt
end


function h3u.drawCMStyleTab(dt, pos, fontSize, listTabParent, isRightAlign, isSeparator, tblColors, useMouseWheel)
    isRightAlign = isRightAlign or false
    local isR0 = isRightAlign and -1 or 0
    local isR1 = isRightAlign and -1 or 1
    local wheelPosP1 = pos
    local wheelPosP2 = pos
    listTabParent.tabTransition = math.applyLag(listTabParent.tabTransition or 0, 1, 0.9, dt)
    ui.pushDWriteFont('Segoe UI;Weight=Bold')
    local range1 = isRightAlign and #listTabParent.tabs or 1
    local range2 = isRightAlign and 1 or #listTabParent.tabs
    for i = range1, range2, isR1 do
        local name = listTabParent.tabs[i]
        ui.dwriteText(name, fontSize, rgbm(1, 1, 1, 0))
        local size = ui.itemRectSize()
        ui.setCursor(pos + vec2(isR0, 0)*size)
        if (ui.invisibleButton('tab'..name, size) and (i ~= listTabParent.tabCur)) then
            listTabParent.tabOld = listTabParent.tabCur
            listTabParent.tabCur = i
            listTabParent.tabTransition = 0
        end
        local color = ui.itemHovered() and tblColors[2] or tblColors[3]
        color = (i == listTabParent.tabCur) and tblColors[1] or color
        ui.setCursor(pos + vec2(isR0, 0)*size)
        ui.dwriteTextAligned(name, fontSize, -1, -1, size, true, color)
        wheelPosP2 = pos + vec2(isR1, 1)*size
        pos = pos + isR1*vec2(size.x + 20, 0)
        if (isSeparator and (i < #listTabParent.tabs)) then
            ui.sameLine(0, -10)
            ui.pushDWriteFont('Segoe UI')
            ui.dwriteTextAligned('|', fontSize, -1, -1, vec2(20, 20), true, tblColors[3])
            ui.popDWriteFont()
        end
    end
    if (isRightAlign) then
        local b = wheelPosP1
        wheelPosP1 = vec2(wheelPosP2.x, wheelPosP1.y)
        wheelPosP2 = vec2(b.x, wheelPosP2.y)
    end
    if (useMouseWheel and ui.windowHovered() and ui.rectHovered(wheelPosP1, wheelPosP2) and (ui.mouseWheel() ~= 0)) then
        listTabParent.tabOld = listTabParent.tabCur
        listTabParent.tabCur = (listTabParent.tabCur - ui.mouseWheel() - 1)%#listTabParent.tabs + 1
        listTabParent.tabTransition = 0
    end
    ui.popDWriteFont()
    return pos
end

function h3u.drawConfigGammaGraph(pos, size, loi, cfg, tblColors)
    ui.drawRectFilled(pos, pos + size, rgbm(1, 1, 1, 0.1)*tblColors[2])
    ui.drawLine(pos + vec2(0.1, 0.5)*size, pos + vec2(0.9, 0.5)*size, rgbm(1, 1, 1, 0.3)*tblColors[1], 1)
    ui.drawLine(pos + vec2(0.5, 0.1)*size, pos + vec2(0.5, 0.9)*size, rgbm(1, 1, 1, 0.3)*tblColors[1], 1)
    ui.pathClear()
    ui.pathLineTo(pos + vec2(0, 1)*size)
    for ix = 0, 100 do
        local iNumN = 0.01*ix
        --app.calcAnalog(alti.axisRawCur, loi.valInit, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get())
        ui.pathLineTo(pos + size*vec2(iNumN, 1 - app.config.calcAnalog(iNumN, loi.valInit, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get())))
    end
    ui.pathStroke(tblColors[3], false, 1)
end

function h3u.drawCMStyleConfigBlock(itemBase, blockWidth, blockGap, cfgParent, nCont, iAlter, tblColors)
    local uis = ac.getUI()
    local loi = cfgParent.list[cfgParent.contsT[nCont]]
    local alti = loi.alterInput[iAlter]
    local cfg = loi.config[iAlter]
    local iscfg = loi.isConfigurating[iAlter]
    local colAccAct = (loi.curInputIndex == iAlter) and uis.accentColor or tblColors[3]
    local yMax = 0
    local pos, size, smallText, mainText, textStyle, flag, val, bol
    local halfWidth = 0.5*(blockWidth - blockGap)
    local function drawButtonText(posButton, sizeButton, smallText, mainText, textStyle)
        local pos_ = posButton + vec2(10, 4)
        local size_ = sizeButton - vec2(20, 12)
        if (textStyle == 0) then
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos_)
            ui.dwriteTextAligned(mainText, 20, -1, 0, size_, false, tblColors[2])
            ui.popDWriteFont()
        else
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos_)
            ui.dwriteTextAligned(smallText, 13, -1, -1, size_, false, (loi.curInputIndex == iAlter) and tblColors[2] or tblColors[3])
            ui.popDWriteFont()
            ui.pushDWriteFont('Segoe UI;Weight=Bold')
            ui.setCursor(pos_)
            ui.dwriteTextAligned(mainText, 20, -1, 1, size_, false, (loi.curInputIndex == iAlter) and tblColors[1] or tblColors[3])
            ui.popDWriteFont()
        end
    end

    if (cfg.configType:get() == 1) then -- analog single axis
        pos = itemBase + vec2(10, 10)
        size = vec2(blockWidth, 50)
        ui.pushDWriteFont('Segoe UI')
        ui.setCursor(pos)
        ui.dwriteTextAligned('Axis', 13, -1, -1, size, false, tblColors[3])
        ui.popDWriteFont()

        pos = pos + vec2(0, 10 + blockGap)
        ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti.axisRawCur, 1)*size, rgbm(1, 1, 1, 1)*colAccAct)

        ui.setCursor(pos)
        local flag = (iscfg.up or iscfg.dn) and ui.ButtonFlags.Active or ui.ButtonFlags.None
        if (ui.button(string.format('##Button%s%dAnalog', nCont, iAlter), size, flag)) then
            iscfg.up = not iscfg.up
            iscfg.dn = iscfg.up
        end

        smallText = cfg.axisDeviceSuperName:get()
        mainText = 'Axis '..cfg.axisNum:get()
        textStyle = 1
        drawButtonText(pos, size, smallText, mainText, textStyle)

        local tMaxMin = {'Min', 'Max'}
        for iMaxMin, nMaxMin in ipairs(tMaxMin) do
            pos = itemBase + vec2(10 + 0.5*(iMaxMin - 1)*(blockWidth + blockGap), 5)
            size = vec2(halfWidth, 50)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            -- ui.dwriteTextAligned(tUpDnFull[iUpDn], 13, -1, -1, size, false, tblColors[3])
            ui.popDWriteFont()

            pos = pos + vec2(0, 10 + 1.5*blockGap)
            size = vec2(halfWidth, 50)

            pos = pos + vec2(0, size.y + blockGap)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            ui.dwriteTextAligned(nMaxMin..' Range', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
            ui.popDWriteFont()

            pos = pos + vec2(0, 10 + blockGap)
            ui.setCursor(pos)
            ui.setNextItemWidth(halfWidth)
            val, bol = ui.slider(string.format('##Slider%s%d%s', nCont, iAlter, nMaxMin), 100*cfg['axis'..nMaxMin]:get(), 0, 100, '%.1f%%', 2)
            if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                val = (iMaxMin == 2) and 100 or 0
            end
            cfg['axis'..nMaxMin]:set(0.01*val)

            pos = pos + vec2(0, 22 + blockGap)
            if (iMaxMin == 1) then
                ui.pushDWriteFont('Segoe UI')
                ui.setCursor(pos)
                ui.dwriteTextAligned('Gamma', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
                ui.popDWriteFont()
                pos = pos + vec2(0, 10 + blockGap)
                size = vec2(halfWidth, 40)
                ui.setCursor(pos)
                ui.setNextItemWidth(halfWidth)
                val, bol = ui.slider(string.format('##Slider%s%dGamma', nCont, iAlter), cfg.axisGamma:get(), 0, 10, '%.3f', 1)
                if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                    val = 1
                end
                if (ui.itemHovered()) then
                    local p = vec2(20, 20)
                    local s = vec2(220, 160)
                    ui.tooltip(function(); ui.setCursor(p); ui.dummy(s); h3u.drawConfigGammaGraph(p, s, loi, cfg, {tblColors[2], tblColors[2], colAccAct}); ui.text('Right click to reset.\nPress Shift to move precisely.'); end)
                end
                cfg.axisGamma:set(val)

            elseif (iMaxMin == 2) then
                -- pos = pos + vec2(0, 10 + blockGap)
                -- ui.setCursor(pos)
                -- if (ui.checkbox(string.format('##Check%s%dAnalogInvert', nCont, iAlter), cfg.axisInvert:get())) then
                --     cfg.axisInvert:set(not cfg.axisInvert:get())
                -- end
                -- ui.sameLine(0, -1)
                -- ui.text('Invert')
            end
            pos = pos + vec2(0, 20 + blockGap)
            ui.setCursor(pos)
            yMax = math.max(yMax, ui.getCursor().y)
        end
    elseif (cfg.configType:get() == 2) then -- digital
        local tUpDn = {'dn', 'up'}
        local tUpDnFull = {'Decrese', 'Increse'}
        for iUpDn, nUpDn in ipairs(tUpDn) do
            pos = itemBase + vec2(10 + 0.5*(iUpDn - 1)*(blockWidth + blockGap), 10)
            size = vec2(halfWidth, 50)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            ui.dwriteTextAligned(tUpDnFull[iUpDn], 13, -1, -1, size, false, tblColors[3])
            ui.popDWriteFont()

            pos = pos + vec2(0, 10 + blockGap)
            size = vec2(halfWidth, 50)
            ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti[nUpDn..'ContRaw'], 1)*size, rgbm(1, 1, 1, 1)*colAccAct)

            ui.setCursor(pos)
            flag = (iscfg[nUpDn]) and ui.ButtonFlags.Active or ui.ButtonFlags.None
            if (ui.button(string.format('##Button%s%dDigital'..nUpDn, nCont, iAlter), size, flag)) then
                iscfg[nUpDn] = not iscfg[nUpDn]
                iscfg[tUpDn[#tUpDn - iUpDn + 1]] = false
            end
            if (cfg[nUpDn..'InputType']:get() == 2) then
                smallText = 'Keyboard'
                mainText = 'Key '..cfg[nUpDn..'ContNum']:get()
                textStyle = 1
            elseif (cfg[nUpDn..'InputType']:get() == 3) then
                smallText = cfg[nUpDn..'DeviceSuperName']:get()
                mainText = string.format('POV %d: %s', cfg[nUpDn..'ContNum']:get(), h3u.dPadName[cfg[nUpDn..'DpadDir']:get()])
                textStyle = 1
            elseif (cfg[nUpDn..'InputType']:get() == 4) then
                smallText = cfg[nUpDn..'DeviceSuperName']:get()
                mainText = 'Button '..cfg[nUpDn..'ContNum']:get()
                textStyle = 1
            else
                smallText = ''
                mainText = 'Not set'
                textStyle = 0
            end
            drawButtonText(pos, size, smallText, mainText, textStyle)

            pos = pos + vec2(0, size.y + blockGap)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            ui.dwriteTextAligned(tUpDnFull[iUpDn]..' Rate', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
            ui.popDWriteFont()

            pos = pos + vec2(0, 10 + blockGap)
            ui.setCursor(pos)
            ui.setNextItemWidth(halfWidth)
            val, bol = ui.slider(string.format('##Slider%s%d%sRate', nCont, iAlter, nUpDn), 100*cfg[nUpDn..'Rate']:get(), 10, 1000, '%.1f%%/s', 2)
            if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                val = 100
            end
            cfg[nUpDn..'Rate']:set(0.01*val)

            pos = pos + vec2(0, 22 + blockGap)
            if (iUpDn == 1) then
                ui.pushDWriteFont('Segoe UI')
                ui.setCursor(pos)
                ui.dwriteTextAligned('Reset', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
                ui.popDWriteFont()

                pos = pos + vec2(0, 10 + blockGap)
                if (cfg.rstConfigType:get() == 1) then
                    size = vec2(halfWidth, 50)
                    ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti.rstPressed and 1 or 0, 1)*size, rgbm(1, 1, 1, 1)*colAccAct)    
                    ui.setCursor(pos)
                    flag = (iscfg.rst) and ui.ButtonFlags.Active or ui.ButtonFlags.None
                    if (ui.button(string.format('##Button%s%dDigitalReset', nCont, iAlter), size, flag)) then
                        iscfg.rst = not iscfg.rst
                    end
                    smallText = cfg.rstDeviceSuperName:get()
                    mainText = 'Axis '..cfg.rstContNum:get()
                    textStyle = 1
                    drawButtonText(pos, size, smallText, mainText, textStyle)
                    pos = pos + vec2(0, 20 + blockGap)
                else
                    size = vec2(halfWidth, 40)
                    ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti.rstPressed and 1 or 0, 1)*size, rgbm(1, 1, 1, 1)*colAccAct)    
                    ui.setCursor(pos)
                    flag = (iscfg.rst) and ui.ButtonFlags.Active or ui.ButtonFlags.None
                    if (ui.button(string.format('##Button%s%dDigitalReset', nCont, iAlter), size, flag)) then
                        iscfg.rst = not iscfg.rst
                    end
                    pos = pos - 0.5*vec2(10, 10)
                    size = size + vec2(10, 10)
                    smallText = ''
                    mainText = 'Not set'
                    textStyle = 0
                    if (cfg.rstConfigType:get() == 2) then
                        if (cfg.rstInputType:get() == 2) then
                            smallText = 'Keyboard'
                            mainText = 'Key '..cfg.rstContNum:get()
                            textStyle = 1
                        elseif (cfg.rstInputType:get() == 3) then
                            smallText = cfg.rstDeviceSuperName:get()
                            mainText = string.format('POV %d: %s', cfg.rstContNum:get(), h3u.dPadName[cfg.rstDpadDir:get()])
                            textStyle = 1
                        elseif (cfg.rstInputType:get() == 4) then
                            smallText = cfg.rstDeviceSuperName:get()
                            mainText = 'Button '..cfg.rstContNum:get()
                            textStyle = 1
                        end
                    end
                    drawButtonText(pos, size, smallText, mainText, textStyle)
                    pos = pos + vec2(0, size.y + blockGap)
                end
            elseif ((iUpDn == 2) and (cfg.rstConfigType:get() == 1)) then
                ui.pushDWriteFont('Segoe UI')
                ui.setCursor(pos)
                ui.dwriteTextAligned('Reset Threshold', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
                ui.popDWriteFont()
                pos = pos + vec2(0, 10 + blockGap)
                
                ui.setCursor(pos)
                ui.setNextItemWidth(halfWidth)
                val, bol = ui.slider(string.format('##Slider%s%dResetThresh', nCont, iAlter), 100*cfg['rstThresh']:get(), 0, 100, '%.1f%%', 1)
                if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                    val = 50
                end
                cfg['rstThresh']:set(0.01*val)
                pos = pos + vec2(0, 18 + blockGap)

                ui.setCursor(pos)
                if (ui.checkbox(string.format('##Check%s%dResetInvert', nCont, iAlter), cfg.rstInvert:get())) then
                    cfg.rstInvert:set(not cfg.rstInvert:get())
                end
                ui.sameLine(0, -1)
                ui.text('Invert')
                pos = pos + vec2(0, 20 + blockGap)

            end
            ui.setCursor(pos)
            yMax = math.max(yMax, ui.getCursor().y)
        end
    elseif ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then -- dual axis
        local tAxis = {'axis', 'axis2'}
        local tAxisFull = {'Axis #1', 'Axis #2'}
        local tAxisCfg = {'up', 'dn'}
        for iAxis, nAxis in ipairs(tAxis) do
            pos = itemBase + vec2(10 + 0.5*(iAxis - 1)*(blockWidth + blockGap), 10)
            local width = 0.5*(blockWidth - blockGap)
            size = vec2(width, 50)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            ui.dwriteTextAligned(tAxisFull[iAxis], 13, -1, -1, size, false, tblColors[3])
            ui.popDWriteFont()

            pos = pos + vec2(0, 10 + blockGap)
            size = vec2(width, 50)
            ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti[nAxis..'RawCur'], 1)*size, rgbm(1, 1, 1, 1)*colAccAct)

            ui.setCursor(pos)
            local flag = (iscfg[tAxisCfg[iAxis]]) and ui.ButtonFlags.Active or ui.ButtonFlags.None
            if (ui.button(string.format('##Button%s%d%s', nCont, iAlter, tAxisFull[iAxis]), size, flag)) then
                iscfg[tAxisCfg[iAxis]] = not iscfg[tAxisCfg[iAxis]]
            end

            if (cfg[nAxis..'DeviceSuperName']:get() ~= '') then
                smallText = cfg[nAxis..'DeviceSuperName']:get()
                mainText = 'Axis '..cfg[nAxis..'Num']:get()
                textStyle = 1
            else
                smallText = ''
                mainText = 'Not set'
                textStyle = 0
            end
            drawButtonText(pos, size, smallText, mainText, textStyle)

            pos = pos + vec2(0, size.y + blockGap)
            local tMaxMin = {'Min', 'Max'}
            for iMaxMin, nMaxMin in ipairs(tMaxMin) do
                ui.pushDWriteFont('Segoe UI')
                ui.setCursor(pos)
                ui.dwriteTextAligned(nMaxMin..' Range', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
                ui.popDWriteFont()

                pos = pos + vec2(0, 10 + blockGap)
                ui.setCursor(pos)
                ui.setNextItemWidth(width)
                val, bol = ui.slider(string.format('##Slider%s%d%s%s', nCont, iAlter, nAxis, nMaxMin), 100*cfg[nAxis..nMaxMin]:get(), 0, 100, '%.1f%%', 2)
                if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                    val = (iMaxMin == 2) and 100 or 0
                end
                cfg[nAxis..nMaxMin]:set(0.01*val)

                pos = pos + vec2(0, 11 + blockGap)
            end
            pos = pos + vec2(0, 11)
            ui.pushDWriteFont('Segoe UI')
            ui.setCursor(pos)
            ui.dwriteTextAligned('Gamma', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
            ui.popDWriteFont()
            pos = pos + vec2(0, 10 + blockGap)
            size = vec2(width, 40)
            ui.setCursor(pos)
            ui.setNextItemWidth(width)
            val, bol = ui.slider(string.format('##Slider%s%d%sGamma', nCont, iAlter, nAxis), cfg[nAxis..'Gamma']:get(), 0, 10, '%.3f', 1)

            if (ui.itemHovered()) then
                local p = vec2(20, 20)
                local s = vec2(220, 160)
                ui.tooltip(function(); ui.setCursor(p); ui.dummy(s); h3u.drawConfigGammaGraph(p, s, loi, cfg, {tblColors[2], tblColors[2], colAccAct}); ui.text('Right click to reset.\nPress Shift to move precisely.'); end)
            end
            if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
                val = 1
            end
            cfg[nAxis..'Gamma']:set(val)
            
            -- pos = pos + vec2(0, 22 + blockGap)
            -- ui.setCursor(pos)
            -- if (ui.checkbox(string.format('##Check%s%d%sInvert', nCont, iAlter, nAxis), cfg[nAxis..'Invert']:get())) then
            --     cfg[nAxis..'Invert']:set(not cfg[nAxis..'Invert']:get())
            -- end
            -- ui.sameLine(0, -1)
            -- ui.text('Invert')

            if (iAxis == 1) then
                pos = pos + vec2(0, 22 + blockGap)
            elseif (iAxis == 2) then
                pos = pos + vec2(0, 22 + blockGap)
            end
            ui.setCursor(pos)
            yMax = math.max(yMax, ui.getCursor().y)
        end
    else
        pos = itemBase + vec2(blockGap, 20 + blockGap)
        size = vec2(blockWidth, 50)
        ui.setCursor(pos)
        local flag = (iscfg.up or iscfg.dn) and ui.ButtonFlags.Active or ui.ButtonFlags.None
        if (ui.button(string.format('##Button%s%dEmpty', nCont, iAlter), size, flag)) then
            iscfg.up = not iscfg.up
            iscfg.dn = iscfg.up
        end

        smallText = ''
        mainText = 'Click to assign'
        textStyle = 0
        drawButtonText(pos, size, smallText, mainText, textStyle)
        pos = pos + vec2(0, size.y + blockGap)
        ui.setCursor(pos)
        yMax = math.max(yMax, ui.getCursor().y)
    end


    
    pos = vec2(itemBase.x + 10, yMax)
    local posBuf = pos
    ui.pushDWriteFont('Segoe UI')
    ui.setCursor(pos)
    ui.dwriteTextAligned('Bind', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
    ui.popDWriteFont()
    
    pos = pos + vec2(0, 10 + blockGap)
    if (cfg.bindConfigType:get() == 1) then
        size = vec2(halfWidth, 50)
        ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti.bindValid and 1 or 0, 1)*size, rgbm(1, 1, 1, 1)*colAccAct)    
        ui.setCursor(pos)
        flag = (iscfg.bind) and ui.ButtonFlags.Active or ui.ButtonFlags.None
        if (ui.button(string.format('##Button%s%dBind', nCont, iAlter), size, flag)) then
            iscfg.bind = not iscfg.bind
        end
        smallText = cfg.bindDeviceSuperName:get()
        mainText = 'Axis '..cfg.bindContNum:get()
        textStyle = 1
        drawButtonText(pos, size, smallText, mainText, textStyle)
        pos = pos + vec2(0, 20 + blockGap)
    else
        size = vec2(halfWidth, 40)
        ui.drawRectFilled(pos + vec2(0, size.y - 4), pos + vec2(alti.bindValid and 1 or 0, 1)*size, rgbm(1, 1, 1, 1)*colAccAct)    
        ui.setCursor(pos)
        flag = (iscfg.bind) and ui.ButtonFlags.Active or ui.ButtonFlags.None
        if (ui.button(string.format('##Button%s%dBind', nCont, iAlter), size, flag)) then
            iscfg.bind = not iscfg.bind
        end
        pos = pos - 0.5*vec2(10, 10)
        size = size + vec2(10, 10)
        smallText = ''
        mainText = 'Not set'
        textStyle = 0
        if (cfg.bindConfigType:get() == 2) then
            if (cfg.bindInputType:get() == 2) then
                smallText = 'Keyboard'
                mainText = 'Key '..cfg.bindContNum:get()
                textStyle = 1
            elseif (cfg.bindInputType:get() == 3) then
                smallText = cfg.bindDeviceSuperName:get()
                mainText = string.format('POV %d: %s', cfg.bindContNum:get(), h3u.dPadName[cfg.bindDpadDir:get()])
                textStyle = 1
            elseif (cfg.bindInputType:get() == 4) then
                smallText = cfg.bindDeviceSuperName:get()
                mainText = 'Button '..cfg.bindContNum:get()
                textStyle = 1
            end
        end
        drawButtonText(pos, size, smallText, mainText, textStyle)
        pos = pos + vec2(0, size.y + blockGap)
    end
    ui.setCursor(pos)
    yMax = math.max(yMax, ui.getCursor().y)

    if (cfg.bindConfigType:get() == 1) then
        pos = posBuf + vec2(halfWidth + blockGap, 0)
        ui.pushDWriteFont('Segoe UI')
        ui.setCursor(pos)
        ui.dwriteTextAligned('Bind Threshold', 13, -1, -1, size, false, tblColors[3])--tUpDnFull[iUpDn]
        ui.popDWriteFont()
        pos = pos + vec2(0, 10 + blockGap)
        
        ui.setCursor(pos)
        ui.setNextItemWidth(halfWidth)
        val, bol = ui.slider(string.format('##Slider%s%dBindThresh', nCont, iAlter), 100*cfg['bindThresh']:get(), 0, 100, '%.1f%%', 1)
        if (ui.itemHovered() and uis.isMouseRightKeyClicked) then
            val = 50
        end
        cfg['bindThresh']:set(0.01*val)
        pos = pos + vec2(0, 18 + blockGap)

        ui.setCursor(pos)
        if (ui.checkbox(string.format('##Check%s%dBindInvert', nCont, iAlter), cfg.bindInvert:get())) then
            cfg.bindInvert:set(not cfg.bindInvert:get())
        end
        ui.sameLine(0, -1)
        ui.text('Invert')
        pos = pos + vec2(0, 20 + blockGap)

        ui.setCursor(pos)
        yMax = math.max(yMax, ui.getCursor().y)
    end



    local opts = {}
    local isAnalog = (cfg.configType:get() == 1) or (cfg.configType:get() == 3) or (cfg.configType:get() == 4)
    if (cfg.configType:get() == 1) then opts[#opts + 1] = {'Invert axis', 'axisInvert'} end
    if (true) then opts[#opts + 1] = {'Relative control', 'isRelative'} end
    if ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then opts[#opts + 1] = {'Invert axis #1', 'axisInvert'} end
    if ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then opts[#opts + 1] = {'Invert axis #2', 'axis2Invert'} end
    if (isAnalog) then opts[#opts + 1] = {'Dual Axis / average', 'configType', 3} end
    if (isAnalog) then opts[#opts + 1] = {'Dual Axis / difference', 'configType', 4} end
    -- additional
    for _, tblOpt in ipairs(loi.cfgAdditionalOpts) do
        if (type(tblOpt[3]) == 'boolean') then
            opts[#opts + 1] = {tblOpt[2], tblOpt[1]}
        end
    end

    if (#opts >= 1) then
        pos = vec2(itemBase.x + 10, yMax)
        ui.pushDWriteFont('Segoe UI')
        ui.setCursor(pos)
        ui.dwriteTextAligned((#opts >= 2) and 'Options' or 'Option', 13, -1, -1, size, false, tblColors[3])
        ui.popDWriteFont()
        pos = pos + vec2(0, 10 + blockGap)
    end

    local optSize = vec2()
    for iOpt, tOpt in ipairs(opts) do
        local nameOpt = tOpt[1]
        local cfgNOpt = tOpt[2]

        -- pos = pos + vec2(0, 1)*optSize + vec2(0, blockGap)
        if (true or (pos + vec2(1, 0)*(optSize + blockGap)).x > (itemBase.x + blockWidth)) then
            pos = vec2(itemBase.x + 20, pos.y + optSize.y + blockGap)
        else
            pos = pos + vec2(optSize.x + blockGap, 0)
        end

        ui.setCursor(pos)
        if (cfgNOpt == 'configType') then
            local checked = (cfg[cfgNOpt]:get() == tOpt[3])
            if (ui.checkbox(string.format('##Check%s%d%s%d', nCont, iAlter, cfgNOpt, tOpt[3]), checked)) then
                if (checked) then
                    cfg[cfgNOpt]:set(1)
                else
                    cfg[cfgNOpt]:set(tOpt[3])
                end
            end
            ui.sameLine(0, -1)
            ui.text(nameOpt)
            optSize = vec2(halfWidth, 20)
        else
            if (ui.checkbox(string.format('##Check%s%d%s', nCont, iAlter, cfgNOpt), cfg[cfgNOpt]:get())) then
                cfg[cfgNOpt]:set(not cfg[cfgNOpt]:get())
            end
            ui.sameLine(0, -1)
            ui.text(nameOpt)
            optSize = vec2(halfWidth, 20)
        end
    end
    ui.text()
    yMax = math.max(yMax, ui.getCursor().y)
    return yMax
end

--
h3u.drawOrder = {}
h3u.drawOrder.new = function()
    local obj = {}
    obj.que = {}
    obj.add = function(self, orderFromSmall, func, funcArgsList)
        self.que[#self.que + 1] = {}
        self.que[#self.que]['ord'] = orderFromSmall
        self.que[#self.que]['func'] = func
        self.que[#self.que]['args'] = funcArgsList
        -- self.que[#self.que]['isDrawed'] = false
    end
    obj.draw = function(self)
        local function cmpfunc(a, b)
            return a['ord'] <  b['ord']
        end
        local q = self.que
        table.sort(q, cmpfunc)
        for i = 1, #q do
            q[i]['func'](q[i]['args'])
        end
    end
    return obj
end
--

h3u.oscillo = {}
h3u.oscillo.new = function(datai, name, channels, min, size, grid, keepAspectRatio)
    local obj = {}
    obj.datai = datai
    obj.name = name
    obj.channels = channels
    obj.min = min
    obj.size = size
    obj.grid = grid
    obj.keepAspectRatio = keepAspectRatio
    obj.dcs = {}
    obj.lastPoses = {}
    obj.lastColors = {}
    ac.store(string.format('Oscilloscope.%d.name', datai), name)
    ac.store(string.format('Oscilloscope.%d.xMin', datai), min.x)
    ac.store(string.format('Oscilloscope.%d.xSize', datai), size.x)
    ac.store(string.format('Oscilloscope.%d.yMin', datai), min.y)
    ac.store(string.format('Oscilloscope.%d.ySize', datai), size.y)
    ac.store(string.format('Oscilloscope.%d.xGrid', datai), grid.x)
    ac.store(string.format('Oscilloscope.%d.yGrid', datai), grid.y)
    ac.store(string.format('Oscilloscope.%d.channelsCount', datai), channels)
    ac.store(string.format('Oscilloscope.%d.keepAspectRatio', datai), keepAspectRatio or false)
    
    obj.beginPathLine = function(self, ch)
        self.dcs[ch] = 1
    end
    obj.pathLineTo = function(self, ch, pos, color)
        pos = pos or self.lastPoses[ch]
        color = color or self.lastColors[ch]
        if (self.dcs[ch] == 1) then
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.x', self.datai, ch, self.dcs[ch]), pos.x)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.y', self.datai, ch, self.dcs[ch]), pos.y)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.r', self.datai, ch, self.dcs[ch]), color.r)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.g', self.datai, ch, self.dcs[ch]), color.g)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.b', self.datai, ch, self.dcs[ch]), color.b)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.m', self.datai, ch, self.dcs[ch]), 0*color.mult)
            self.dcs[ch] = self.dcs[ch] + 1
        end
        if (self.dcs[ch] > 1) then
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.x', self.datai, ch, self.dcs[ch]), pos.x)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.y', self.datai, ch, self.dcs[ch]), pos.y)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.r', self.datai, ch, self.dcs[ch]), color.r)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.g', self.datai, ch, self.dcs[ch]), color.g)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.b', self.datai, ch, self.dcs[ch]), color.b)
            ac.store(string.format('Oscilloscope.%d.%d.data.%d.m', self.datai, ch, self.dcs[ch]), color.mult)
            self.dcs[ch] = self.dcs[ch] + 1
        end
        self.lastPoses[ch] = pos
        self.lastColors[ch] = color
    end
    obj.endPathLine = function(self, ch)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.x', self.datai, ch, self.dcs[ch]), self.lastPoses[ch].x)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.y', self.datai, ch, self.dcs[ch]), self.lastPoses[ch].y)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.r', self.datai, ch, self.dcs[ch]), self.lastColors[ch].r)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.g', self.datai, ch, self.dcs[ch]), self.lastColors[ch].g)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.b', self.datai, ch, self.dcs[ch]), self.lastColors[ch].b)
        ac.store(string.format('Oscilloscope.%d.%d.data.%d.m', self.datai, ch, self.dcs[ch]), self.lastColors[ch].mult)
        ac.store(string.format('Oscilloscope.%d.%d.dataCount', self.datai, ch), self.dcs[ch])
        self.dcs[ch] = 0
    end
    return obj
end

h3u.MSDmodel = {}
h3u.MSDmodel.new = function(m, s, d, disLimit, neutral)
    local obj = {}
    obj.m = m
    obj.s = s
    obj.d = d
    obj.disLimit = disLimit
    obj.neutral = neutral
    obj.dis = neutral -- displacement
    obj.stop = function(self)
        self.force = 0*self.neutral
        self.vel = 0*self.neutral
        self.acc = 0*self.neutral
        return self
    end
    obj.reset = function(self)
        self.force = 0*self.neutral
        self.vel = 0*self.neutral
        self.acc = 0*self.neutral
        self.dis = self.neutral
        return self
    end
    obj.update = function(self, force_ext, dt)
        force_ext = force_ext or (self.isVec3 and vec3() or 0)
        self.force = force_ext + self.s*(self.neutral - self.dis) - self.d*self.vel
        self.acc = self.force/self.m
        self.vel = self.vel + dt*self.acc
        self.dis = self.dis + dt*self.vel
        if (self.disLimit ~= nil) then
            if (type(self.dis) == 'number') then
                self.dis = self.disLimit*math.clamp((self.dis - self.neutral)/self.disLimit, -1, 1) + self.neutral
            else
                local disDivLim = (self.dis - self.neutral)/self.disLimit
                self.dis = self.disLimit*math.saturate(disDivLim:length())*math.normalize(disDivLim) + self.neutral
            end
        end
        if (self.dis ~= self.dis) then
            self:reset()
        end
        return self
    end
    obj:reset()
    return obj
end


h3u.PIDcontroller = {}
h3u.PIDcontroller.new = function(kp, ki, kd, init_out)
    local obj = {}
    obj.diff = 0
    obj.output = init_out
    obj.out_dn = nil
    obj.out_up = nil
    obj.p = 0
    obj.i = 0
    obj.d = 0
    obj.kp = kp
    obj.ki = ki
    obj.kd = kd
    obj.susi = 1
    obj.i_dn = nil
    obj.i_up = nil
    obj.setISustain = function(self, sustain_I)
        self.susi = sustain_I
        return self
    end
    obj.setIClamp = function(self, downLimit, upLimit)
        self.out_dn = downLimit
        self.out_up = upLimit
        return self
    end
    obj.setOutClamp = function(self, downLimit, upLimit)
        self.out_dn = downLimit
        self.out_up = upLimit
        return self
    end
    obj.update = function(self, input, dt)
        local dtGain = dt
        self.diff = dtGain*(input - self.output)
        self.p = self.kp*self.diff
        local i_cand = self.ki*self.diff + self.susi*self.i
        self.i = math.clamp(i_cand, self.i_dn or i_cand, self.i_up or i_cand)
        self.d = self.kd*self.diff - self.d
        local out_cand = self.p + self.i + self.d
        self.output = math.clamp(out_cand, self.out_dn or out_cand, self.out_up or out_cand)
        return self.output
    end
    return obj
end


h3u.cubicSpline = {}
h3u.cubicSpline.new = function()
    local obj = {}
    obj.num = 0
    obj.a = {}
    obj.b = {}
    obj.c = {}
    obj.d = {}
    obj.px = {}

    obj.tdma = function(self, n, a, b, c, d)
        for i = 2, n do
            local w = a[i] / b[i - 1]
            b[i] = b[i] - c[i - 1]*w
            d[i] = d[i] - d[i - 1]*w
        end
    
        d[n - 1] = d[n - 1] / b[n - 1]
        for i = n - 1, 1, -1 do
            d[i] = (d[i] - d[i + 1]*c[i])/b[i]
        end
    end

    obj.set = function(self, n, x, y)
        self.num = n
        self.a = {}
        self.b = {}
        self.c = {}
        self.d = {}
        self.px = {}
        local h = {}

        for i = 1, n - 1 do
            h[i] = x[i + 1] - x[i]
        end

        for i = 1, n do
            self.d[i] = y[i]
            self.px[i] = x[i]
        end

        local w = {}

        self.b[1] = 0
        self.b[n] = 0
        self.a[1] = 0
        self.a[n] = 0
        w[1] = 1
        w[n] = 1
        self.c[1] = 0
        self.c[n] = 0

        for i = 2, n - 1 do
            self.b[i] = 3 * ((self.d[i + 1] - self.d[i]) / h[i] - (self.d[i] - self.d[i - 1]) / h[i - 1])
            self.a[i] = h[i - 1]
            w[i] = 2 * (h[i - 1] + h[i])
            self.c[i] = h[i]
        end

        self:tdma(n, self.a, w, self.c, self.b)

        for i = 1, n - 1 do
            self.a[i] = (self.b[i + 1] - self.b[i]) / (3 * h[i])
            self.c[i] = (self.d[i + 1] - self.d[i]) / h[i] - h[i] * (self.b[i + 1] + 2 * self.b[i]) / 3
        end
    end

    obj.calc = function(self, x)
        local i
        for i = 1, self.num - 1 do
            if self.px[i] <= x and x <= self.px[i + 1] then
                -- ac.error('cubicSpline.calc.for.i', i)
                break
            end
        end
        -- ac.error('cubicSpline.calc.dx.i', i)
        local dx = x - self.px[i]
        return ((self.a[i]*dx + self.b[i])*dx + self.c[i])*dx + self.d[i]
    end
    return obj
end

--
h3u.dPadName = {}
h3u.dPadName[0] = '↑'
h3u.dPadName[9000] = '→'
h3u.dPadName[18000] = '↓'
h3u.dPadName[27000] = '←'

h3u.getJoystickSuperName = function(i)
    if (ac.getJoystickName(i) ~= nil) then
        return ac.getJoystickName(i)
        -- return string.format('%d: %s', i, ac.getJoystickName(i))
    else
        return nil
    end
end

h3u.joySuperNameToIndex = {}
h3u.joySuperNameToIndexUpdate = function()
    for i = 1, ac.getJoystickCount() + 1 do
        if (h3u.getJoystickSuperName(i) ~= nil) then
            h3u.joySuperNameToIndex[h3u.getJoystickSuperName(i)] = i
        end
    end
end

h3u.contCfgSys = {}
h3u.contCfgSys.new = function(id, tblSetConts, tblThresh, alterInputCount)
    local obj = {}
    local loi, n
    obj.conts = tblSetConts[1]
    obj.valInits = tblSetConts[2]
    obj.valDefaults = tblSetConts[3]
    obj.isRelatives = tblSetConts[4]
    obj.cfgAdditionalOpts = tblSetConts[5] or {}
    obj.alterInputCount = alterInputCount
    obj.dPadThresh = tblThresh[1]
    obj.alterChangeThresh = tblThresh[2]
    obj.configThresh = tblThresh[3]
    obj.contsT = {} -- name to number
    for i, v in ipairs(obj.conts) do
        obj.contsT[v] = i
    end
    obj.list = {}
    for _, contName in ipairs(obj.conts) do
        local contIndex = obj.contsT[contName]
        obj.list[contIndex] = {}
        loi = obj.list[contIndex]
        loi.valInit = obj.valInits[contIndex]
        loi.valDefault = obj.valDefaults[contIndex]
        loi.isBool = (loi.valInit == (not not loi.valInit)) or (loi.valDefault == (not not loi.valDefault))
        loi.valContN = loi.valInit
        loi.valFinN = loi.valInit
        loi.rstPressed = false
        loi.isOverwrite = false
        loi.isAvailable = false
        loi.curInputIndex = 0 -- not actived for initial
        loi.cfgAdditionalOpts = obj.cfgAdditionalOpts[contIndex] or {}
        loi.alterInput = {}
        loi.isConfigurating = {}
        loi.config = {}
        for altInput = 1, obj.alterInputCount do
            loi.alterInput[altInput] = {}
            local alti = loi.alterInput[altInput]
            alti.axisRawCur = loi.valDefault
            alti.axisRawDelta = 0
            alti.axis2RawCur = loi.valDefault
            alti.axis2RawDelta = 0
            alti.upContRaw = 0
            alti.dnContRaw = 0
            alti.rstPressed = false
            alti.bindValid = false
    
            loi.isConfigurating[altInput] = {}
            local iscfg = loi.isConfigurating[altInput]
            iscfg.up = false
            iscfg.dn = false
            iscfg.rst = false
            iscfg.bind = false
    
            loi.config[altInput] = {}
            local cfg = loi.config[altInput]
            -- configType 0: not assigned 1: single axis 2: digital buttons 3: dual axis, average 4: dual axis, difference
            n = 'configType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            -- cfg[n]:set(0)
            n = 'axisDeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'axisNum'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'axisMax'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)
            n = 'axisMin'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'axisInvert'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), false)
            n = 'axisGamma'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)
            n = 'boolThresh'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), obj.alterChangeThresh)
    
            n = 'axis2DeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'axis2Num'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'axis2Max'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)
            n = 'axis2Min'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'axis2Invert'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), false)
            n = 'axis2Gamma'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)
            
            n = 'upInputType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'upDeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'upContNum'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'upDpadDir'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'upRate'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)
    
            n = 'dnInputType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'dnDeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'dnContNum'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'dnDpadDir'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'dnRate'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 1)

            n = 'bindConfigType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'bindInputType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'bindDeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'bindContNum'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'bindDpadDir'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'bindThresh'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0.5)
            n = 'bindInvert'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), false)
    
            n = 'rstConfigType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'rstInputType'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'rstDeviceSuperName'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), '')
            n = 'rstContNum'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'rstDpadDir'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0)
            n = 'rstThresh'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), 0.5)
            n = 'rstInvert'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), false)

            n = 'isRelative'; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), obj.isRelatives[contIndex])

            -- additional
            for _, tblOpt in ipairs(loi.cfgAdditionalOpts) do
                n = tblOpt[1]; cfg[n] = ac.storage(string.format('%s-%d-%d-%s', id, contIndex, altInput, n), tblOpt[3])
            end
        end
    end    
    obj.configWaiterList = {}
    obj.configWaiterList.keys = {}
    obj.configWaiterList.dpads = {}
    obj.configWaiterList.btns = {}
    obj.configWaiterList.axes = {}
    obj.configEnd = function()
        for _, contName in ipairs(obj.conts) do
            local contIndex = obj.contsT[contName]
            loi = obj.list[contIndex]
            for altInput = 1, obj.alterInputCount do
                local iscfg = loi.isConfigurating[altInput]
                iscfg.up = false
                iscfg.dn = false
                iscfg.rst = false
            end
        end
    end
    obj.calcAnalog = function(inputN, default, min, max, gamma, invert)
        local v = inputN
        -- 上限が1、valInitが0になるようにスケール
        v = 1 - (1 - v)/(1 - default)
        local lowest = 1 - 1/(1 - default) -- v = 0
        -- max/min range, gamma
        v = math.sign(v)*(math.lerpInvSat(math.abs(v), min, max)^gamma)
        -- 0~1にスケール
        v = 1 - (1 - v)/(1 - lowest)
        -- invert
        v = invert and 1 - v or v
        return v
    end
    obj.getInputRaw = function(inputType, deviceSuperName, contNum, dpadDir)
        if (inputType == 2) then
            return ac.isKeyDown(contNum) and 1 or 0
        elseif (inputType == 3) then
            local dpadValue = ac.getJoystickDpadValue(h3u.joySuperNameToIndex[deviceSuperName], contNum)
            local dpadDelta = dpadValue - dpadDir
            local dPadJdg = (dpadValue ~= -1)
            dPadJdg = dPadJdg and ((math.abs(dpadDelta) <= obj.dPadThresh) or (dpadDelta >= (36000 - obj.dPadThresh)))
            return (dPadJdg) and 1 or 0
        elseif (inputType == 4) then
            return ac.isJoystickButtonPressed(h3u.joySuperNameToIndex[deviceSuperName], contNum) and 1 or 0
        elseif (inputType == 5) then
            return 0.5 + 0.5*ac.getJoystickAxisValue(h3u.joySuperNameToIndex[deviceSuperName], contNum)
        end
        return 0
    end

    local carPlayer = ac.getCar(0)
    obj.update = function(self, dt, funIsAvailable, funIsOverwrite, funOverwriteVal, funLoopFinal) -- fun: contIndex, contName, loi
        h3u.joySuperNameToIndexUpdate()

        self.isMainConfigurating_old = self.isMainConfigurating or false
        self.isrstConfigurating_old = self.isrstConfigurating or false
        self.isBindConfigurating_old = self.isBindConfigurating or false
        self.isMainConfigurating = false
        self.isrstConfigurating = false
        self.isBindConfigurating = false
        for _, contName in ipairs(self.conts) do
            local contIndex = self.contsT[contName]
            for altInput = 1, self.alterInputCount do
                loi = self.list[contIndex].isConfigurating[altInput]
                if (loi.up or loi.dn) then
                    self.isMainConfigurating = true
                elseif (loi.rst) then
                    self.isrstConfigurating = true
                elseif (loi.bind) then
                    self.isBindConfigurating = true
                end
            end
        end
        self.isMainConfiguratingStart = self.isMainConfigurating and not self.isMainConfigurating_old
        self.isrstConfiguratingStart = self.isrstConfigurating and not self.isrstConfigurating_old
        self.isBindConfiguratingStart = self.isBindConfigurating and not self.isBindConfigurating_old

        -- Configurater
        --self.configWaiterList
        if (self.isMainConfiguratingStart or self.isrstConfiguratingStart or self.isBindConfiguratingStart) then -- start edge
            for iKey = 0, 128 do
                self.configWaiterList.keys[iKey + 1] = self.configWaiterList.keys[iKey + 1] or {}
                self.configWaiterList.keys[iKey + 1].current = ui.keyboardButtonDown(iKey) and 1 or 0
            end
            for iJoy = 0, ac.getJoystickCount() do
                if (ac.getJoystickName(iJoy) ~= nil) then
                    self.configWaiterList.dpads[iJoy + 1] = self.configWaiterList.dpads[iJoy + 1] or {}
                    for iDpad = 0, ac.getJoystickDpadsCount(iJoy) do
                        self.configWaiterList.dpads[iJoy + 1][iDpad + 1] = self.configWaiterList.dpads[iJoy + 1][iDpad + 1] or {}
                        self.configWaiterList.dpads[iJoy + 1][iDpad + 1].configStart = (ac.getJoystickDpadValue(iJoy, iDpad))
                    end
                    self.configWaiterList.btns[iJoy + 1] = self.configWaiterList.btns[iJoy + 1] or {}
                    for iBtn = 0, ac.getJoystickButtonsCount(iJoy) do
                        self.configWaiterList.btns[iJoy + 1][iBtn + 1] = self.configWaiterList.btns[iJoy + 1][iBtn + 1] or {}
                        self.configWaiterList.btns[iJoy + 1][iBtn + 1].current = ac.isJoystickButtonPressed(iJoy, iBtn) and 1 or 0
                    end
                    self.configWaiterList.axes[iJoy + 1] = self.configWaiterList.axes[iJoy + 1] or {}
                    for iAxis = 0, ac.getJoystickAxisCount(iJoy) do
                        self.configWaiterList.axes[iJoy + 1][iAxis + 1] = self.configWaiterList.axes[iJoy + 1][iAxis + 1] or {}
                        self.configWaiterList.axes[iJoy + 1][iAxis + 1].configStart = ac.getJoystickAxisValue(iJoy, iAxis)
                    end
                end
            end
        elseif (self.isMainConfigurating or self.isrstConfigurating or self.isBindConfigurating) then
            local inputType = 0
            local inputDevice = 0
            local inputContNum = 0
            local inputDpadDir = 0
            for iKey = 0, 128 do
                loi = self.configWaiterList.keys[iKey + 1]
                loi.old = loi.current
                loi.current = ui.keyboardButtonDown(iKey) and 1 or 0
                loi.delta = loi.current - loi.old
                if (loi.delta >= self.configThresh) then
                    if (iKey == 46) then -- delete
                        inputType = 1
                    elseif (iKey == 27) then -- escape
                        self.configEnd()
                    else
                        inputType = 2
                        inputContNum = iKey
                    end
                end
            end
            for iJoy = 0, ac.getJoystickCount() do
                if (ac.getJoystickName(iJoy) ~= nil) then
                    for iDpad = 0, ac.getJoystickDpadsCount(iJoy) do
                        loi = self.configWaiterList.dpads[iJoy + 1][iDpad + 1]
                        loi.current = ac.getJoystickDpadValue(iJoy, iDpad)
                        loi.delta = loi.current - loi.configStart
                        if (((math.abs(loi.delta) >= 4500) or (loi.configStart == -1)) and (loi.current ~= -1)) then
                            inputType = 3
                            inputDevice = iJoy
                            inputContNum = iDpad
                            inputDpadDir = (math.round(loi.current/9000)*9000)%36000
                        end
                    end
                    for iBtn = 0, ac.getJoystickButtonsCount(iJoy) do
                        loi = self.configWaiterList.btns[iJoy + 1][iBtn + 1]
                        loi.old = loi.current
                        loi.current = ac.isJoystickButtonPressed(iJoy, iBtn) and 1 or 0
                        loi.delta = loi.current - loi.old
                        if (loi.delta >= self.configThresh) then -- press only
                            inputType = 4
                            inputDevice = iJoy
                            inputContNum = iBtn
                        end
                    end
                    -- if (self.isMainConfigurating) then
                    for iAxis = 0, ac.getJoystickAxisCount(iJoy) do
                        loi = self.configWaiterList.axes[iJoy + 1][iAxis + 1]
                        loi.current = ac.getJoystickAxisValue(iJoy, iAxis)
                        loi.delta = loi.current - loi.configStart
                        if (math.abs(loi.delta) >= self.configThresh) then
                            inputType = 5
                            inputDevice = iJoy
                            inputContNum = iAxis
                        end
                    end
                    -- end
                end
            end
            if (inputType >= 1) then
                for _, contName in ipairs(self.conts) do
                    local contIndex = self.contsT[contName]
                    loi = self.list[contIndex]
                    for altInput = 1, self.alterInputCount do
                        local iscfg = self.list[contIndex].isConfigurating[altInput]
                        local cfg = loi.config[altInput]
                        if (iscfg.up or iscfg.dn) then
                            if (inputType == 1) then
                                if (iscfg.up and iscfg.dn) then
                                    n = 'configType'; cfg[n]:set(0)
                                elseif (iscfg.up) then
                                    n = 'upInputType'; cfg[n]:set(0)
                                else
                                    n = 'dnInputType'; cfg[n]:set(0)
                                end
                                inputType = 0
                                iscfg.up = false
                                iscfg.dn = false
                            elseif (inputType == 5) then
                                n = 'configType'
                                local isSingleAxis = (cfg[n]:get() == 1)
                                local isDualAxis = (cfg[n]:get() == 3) or (cfg[n]:get() == 4)
                                if (not isSingleAxis and not isDualAxis) then
                                    n = 'configType'; cfg[n]:set(1)
                                end
                                if (isDualAxis) then
                                    if (iscfg.up) then
                                        n = 'axisDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                        n = 'axisNum'; cfg[n]:set(inputContNum)
                                        inputType = 0
                                        iscfg.up = false
                                    else
                                        n = 'axis2DeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                        n = 'axis2Num'; cfg[n]:set(inputContNum)
                                        inputType = 0
                                        iscfg.dn = false
                                    end
                                else
                                    n = 'axisDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                    n = 'axisNum'; cfg[n]:set(inputContNum)
                                    inputType = 0
                                    iscfg.up = false
                                    iscfg.dn = false
                                end
                            elseif ((inputType >= 2) or (inputType <= 4)) then
                                if (iscfg.up) then
                                    n = 'configType'; cfg[n]:set(2)
                                    n = 'upInputType'; cfg[n]:set(inputType)
                                    n = 'upDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                    n = 'upContNum'; cfg[n]:set(inputContNum)
                                    if (inputType == 3) then
                                        n = 'upDpadDir'; cfg[n]:set(inputDpadDir)
                                    end
                                    if (iscfg.dn) then
                                        n = 'dnInputType'; cfg[n]:set(0)
                                    end
                                    inputType = 0
                                    iscfg.up = false
                                else
                                    n = 'configType'; cfg[n]:set(2)
                                    n = 'dnInputType'; cfg[n]:set(inputType)
                                    n = 'dnDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                    n = 'dnContNum'; cfg[n]:set(inputContNum)
                                    if (inputType == 3) then
                                        n = 'dnDpadDir'; cfg[n]:set(inputDpadDir)
                                    end
                                    inputType = 0
                                    iscfg.dn = false
                                end
                            end
                        elseif (iscfg.rst) then
                            if (inputType == 1) then
                                n = 'rstConfigType'; cfg[n]:set(0)
                            else
                                if (inputType == 5) then
                                    n = 'rstConfigType'; cfg[n]:set(1)
                                else
                                    n = 'rstConfigType'; cfg[n]:set(2)
                                end
                                n = 'rstInputType'; cfg[n]:set(inputType)
                                n = 'rstDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                n = 'rstContNum'; cfg[n]:set(inputContNum)
                                if (inputType == 3) then
                                    n = 'rstDpadDir'; cfg[n]:set(inputDpadDir)
                                end
                            end
                            inputType = 0
                            iscfg.rst = false
                        elseif (iscfg.bind) then
                            if (inputType == 1) then
                                n = 'bindConfigType'; cfg[n]:set(0)
                            else
                                if (inputType == 5) then
                                    n = 'bindConfigType'; cfg[n]:set(1)
                                else
                                    n = 'bindConfigType'; cfg[n]:set(2)
                                end
                                n = 'bindInputType'; cfg[n]:set(inputType)
                                n = 'bindDeviceSuperName'; cfg[n]:set(h3u.getJoystickSuperName(inputDevice))
                                n = 'bindContNum'; cfg[n]:set(inputContNum)
                                if (inputType == 3) then
                                    n = 'bindDpadDir'; cfg[n]:set(inputDpadDir)
                                end
                            end
                            inputType = 0
                            iscfg.bind = false
                        end
                    end
                end
            end
        end
        -- Get input for all alterInputs & Decide alterInput
        for _, contName in ipairs(self.conts) do
            local contIndex = self.contsT[contName]
            loi = self.list[contIndex]
            for altInput = 1, self.alterInputCount do
                local alti = loi.alterInput[altInput]
                local cfg = loi.config[altInput]
                alti.bindPressed = false
                alti.otherBindPressed = false
                alti.bindValid = true
                -- bind
                if (cfg.bindConfigType:get() == 1) then
                    local v = self.getInputRaw(cfg.bindInputType:get(), cfg.bindDeviceSuperName:get(), cfg.bindContNum:get(), cfg.bindDpadDir:get())
                    if (cfg.bindInvert:get()) then
                        alti.bindPressed = (v < cfg.bindThresh:get())
                    else
                        alti.bindPressed = (v > cfg.bindThresh:get())
                    end
                    alti.bindValid = alti.bindPressed
                elseif (cfg.bindConfigType:get() == 2) then
                    alti.bindPressed = (self.getInputRaw(cfg.bindInputType:get(), cfg.bindDeviceSuperName:get(), cfg.bindContNum:get(), cfg.bindDpadDir:get()) == 1)
                    alti.bindValid = alti.bindPressed
                else
                    -- check other bind of conts and alts 
                    for _, contName2 in ipairs(self.conts) do
                        local contIndex2 = self.contsT[contName2]
                        local loi2 = self.list[contIndex2]
                        for altInput2 = 1, self.alterInputCount do
                            if ((contName == contName2) and (altInput == altInput2)) then
                                break
                            end
                            local alti2 = loi2.alterInput[altInput2]
                            local cfg2 = loi2.config[altInput2]

                            local hasBind = (cfg2.bindConfigType:get() >= 1)
                            local axisSame = (cfg.axisDeviceSuperName:get() == cfg2.axisDeviceSuperName:get()) and (cfg.axisNum:get() == cfg2.axisNum:get())
                            local axis2Same = (cfg.axis2DeviceSuperName:get() == cfg2.axis2DeviceSuperName:get()) and (cfg.axis2Num:get() == cfg2.axis2Num:get())
                            local axisSameCross = (cfg.axisDeviceSuperName:get() == cfg2.axis2DeviceSuperName:get()) and (cfg.axisNum:get() == cfg2.axis2Num:get())
                            local axis2SameCross = (cfg.axis2DeviceSuperName:get() == cfg2.axisDeviceSuperName:get()) and (cfg.axis2Num:get() == cfg2.axisNum:get())
                            
                            local upDpadDirSame = (cfg.upInputType:get() == 3) and (cfg.upDpadDir:get() == cfg2.upDpadDir:get()) or true
                            local upSame = (cfg.upInputType:get() == cfg2.upInputType:get()) and (cfg.upDeviceSuperName:get() == cfg2.upDeviceSuperName:get()) and (cfg.upContNum:get() == cfg2.upContNum:get()) and upDpadDirSame

                            local dnDpadDirSame = (cfg.dnInputType:get() == 3) and (cfg.dnDpadDir:get() == cfg2.dnDpadDir:get()) or true
                            local dnSame = (cfg.dnInputType:get() == cfg2.dnInputType:get()) and (cfg.dnDeviceSuperName:get() == cfg2.dnDeviceSuperName:get()) and (cfg.dnContNum:get() == cfg2.dnContNum:get()) and dnDpadDirSame

                            local rstDpadDirSame = (cfg.rstInputType:get() == 3) and (cfg.rstDpadDir:get() == cfg2.rstDpadDir:get()) or true
                            local rstSame = (cfg.rstInputType:get() == cfg2.rstInputType:get()) and (cfg.rstDeviceSuperName:get() == cfg2.rstDeviceSuperName:get()) and (cfg.rstContNum:get() == cfg2.rstContNum:get()) and rstDpadDirSame
                            if (cfg.configType:get() == 1) then -- single axis
                                if (cfg2.configType:get() == 1) then -- other single axis
                                    alti.otherBindPressed = alti.otherBindPressed or (hasBind and alti2.bindValid and axisSame)
                                elseif ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then -- other dual axis
                                    alti.otherBindPressed = alti.otherBindPressed or (hasBind and alti2.bindValid and (axisSame or axis2Same))
                                end
                            elseif ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then -- dual axis
                                if (cfg2.configType:get() == 1) then -- other single axis
                                    alti.otherBindPressed = alti.otherBindPressed or (hasBind and alti2.bindPressed and axisSame)
                                elseif ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then -- other dual axis
                                    alti.otherBindPressed = alti.otherBindPressed or (hasBind and alti2.bindPressed and (axisSame or axis2Same))
                                end
                            elseif (cfg.configType:get() == 2) then
                                -- if (cfg.upInputType:get() == 3) then -- dpad
                                -- else
                                -- end
                            end
                        end
                    end
                    alti.bindValid = not alti.otherBindPressed
                end

                if (cfg.configType:get() == 1) then
                    alti.axisRawCur = self.getInputRaw(5, cfg.axisDeviceSuperName:get(), cfg.axisNum:get(), nil)
                    alti.axisRawBind = alti.bindValid and alti.axisRawCur or loi.valDefault
                    alti.axisRawStart = alti.axisRawStart or alti.axisRawBind
                    alti.axisRawDelta = alti.axisRawStart - alti.axisRawBind
                    if (math.abs(alti.axisRawDelta) >= self.alterChangeThresh) then
                        loi.curInputIndex = altInput
                        for alt2Input = 1, self.alterInputCount do
                            local alt2i = loi.alterInput[alt2Input]
                            alt2i.axisRawStart = alt2i.axisRawCur
                        end
                    end
                elseif ((cfg.configType:get() == 3) or (cfg.configType:get() == 4)) then
                    alti.axisRawCur = self.getInputRaw(5, cfg.axisDeviceSuperName:get(), cfg.axisNum:get(), nil)
                    alti.axisRawBind = alti.bindValid and alti.axisRawCur or loi.valDefault
                    alti.axis2RawCur = self.getInputRaw(5, cfg.axis2DeviceSuperName:get(), cfg.axis2Num:get(), nil)
                    alti.axis2RawBind = alti.bindValid and alti.axis2RawCur or loi.valDefault
                    alti.axisRawStart = alti.axisRawStart or alti.axisRawBind
                    alti.axis2RawStart = alti.axis2RawStart or alti.axis2RawBind
                    alti.axisRawDelta = alti.axisRawStart - alti.axisRawBind
                    alti.axis2RawDelta = alti.axis2RawStart - alti.axis2RawBind
                    if ((math.abs(alti.axisRawDelta) >= self.alterChangeThresh) or (math.abs(alti.axis2RawDelta) >= self.alterChangeThresh)) then
                        loi.curInputIndex = altInput
                        for alt2Input = 1, self.alterInputCount do
                            local alt2i = loi.alterInput[alt2Input]
                            alt2i.axisRawStart = alt2i.axisRawCur
                            alt2i.axis2RawStart = alt2i.axis2RawCur
                        end
                    end
                elseif (cfg.configType:get() == 2) then
                    alti.upContRaw = self.getInputRaw(cfg.upInputType:get(), cfg.upDeviceSuperName:get(), cfg.upContNum:get(), cfg.upDpadDir:get())
                    alti.dnContRaw = self.getInputRaw(cfg.dnInputType:get(), cfg.dnDeviceSuperName:get(), cfg.dnContNum:get(), cfg.dnDpadDir:get())
                    alti.upContBind = alti.bindValid and alti.upContRaw or 0
                    alti.dnContBind = alti.bindValid and alti.dnContRaw or 0
                    if ((alti.upContBind >= self.alterChangeThresh) or (alti.dnContBind >= self.alterChangeThresh)) then
                        loi.curInputIndex = altInput
                        for alt2Input = 1, self.alterInputCount do
                            local alt2i = loi.alterInput[alt2Input]
                            alt2i.axisRawStart = alt2i.axisRawCur
                        end
                    end
                    -- reset
                    if (cfg.rstConfigType:get() == 1) then
                        local v = self.getInputRaw(cfg.rstInputType:get(), cfg.rstDeviceSuperName:get(), cfg.rstContNum:get(), cfg.rstDpadDir:get())
                        if (cfg.rstInvert:get()) then
                            alti.rstPressed = (v < cfg.rstThresh:get())
                        else
                            alti.rstPressed = (v > cfg.rstThresh:get())
                        end
                    elseif (cfg.rstConfigType:get() == 2) then
                        alti.rstPressed = (self.getInputRaw(cfg.rstInputType:get(), cfg.rstDeviceSuperName:get(), cfg.rstContNum:get(), cfg.rstDpadDir:get()) == 1)
                    else
                        alti.rstPressed = false
                    end
                    if (alti.rstPressed) then
                        loi.valContN = loi.valDefault
                    end
                    loi.rstPressed = alti.rstPressed
                end
            end
        end

        -- Current Control
        for _, contName in ipairs(self.conts) do
            local contIndex = self.contsT[contName]
            loi = self.list[contIndex]
            local alti = loi.alterInput[loi.curInputIndex]
            local cfg = loi.config[loi.curInputIndex]
            loi.isAvailable = funIsAvailable(contIndex, contName, loi)
            loi.isOverwrite = funIsOverwrite(contIndex, contName, loi)
            if ((cfg ~= nil)) then
                if (cfg.configType:get() == 1) then
                    if (cfg.isRelative:get()) then
                        loi.valContN = loi.valContN + 2*dt*(self.calcAnalog(alti.axisRawBind, loi.valDefault, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get()) - 0.5)
                    else
                        loi.valContN = self.calcAnalog(alti.axisRawBind, loi.valDefault, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get())
                    end
                    ac.warn(contName, alti.axisRawBind)
                elseif (cfg.configType:get() == 3) then
                    local axis1 = self.calcAnalog(alti.axisRawBind, loi.valDefault, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get())
                    local axis2 = self.calcAnalog(alti.axis2RawBind, loi.valDefault, cfg.axis2Min:get(), cfg.axis2Max:get(), cfg.axis2Gamma:get(), cfg.axis2Invert:get())
                    if (cfg.isRelative:get()) then
                        loi.valContN = loi.valContN + 2*dt*(0.5*(axis1 + axis2) - 0.5)
                    else
                        loi.valContN = 0.5*(axis1 + axis2)
                    end
                elseif (cfg.configType:get() == 4) then
                    local axis1 = self.calcAnalog(alti.axisRawBind, loi.valDefault, cfg.axisMin:get(), cfg.axisMax:get(), cfg.axisGamma:get(), cfg.axisInvert:get())
                    local axis2 = self.calcAnalog(alti.axis2RawBind, loi.valDefault, cfg.axis2Min:get(), cfg.axis2Max:get(), cfg.axis2Gamma:get(), cfg.axis2Invert:get())
                    if (cfg.isRelative:get()) then
                        loi.valContN = loi.valContN + 2*dt*(0.5*(axis2 - axis1) - 0.5)
                    else
                        loi.valContN = 0.5*(axis2 - axis1) + 0.5
                    end
                elseif (cfg.configType:get() == 2) then
                    if (alti.rstPressed) then
                        -- loi.valContN = loi.valInit
                    elseif (cfg.isRelative:get()) then
                        loi.valContN = h3u.rateLimit(loi.valContN, loi.valContN + alti.upContRaw - alti.dnContRaw, cfg.upRate:get(), -cfg.dnRate:get(), dt)
                    else
                        if ((alti.upContRaw <= self.alterChangeThresh) and (alti.dnContRaw <= self.alterChangeThresh)) then -- ReturnToZero
                            loi.valContN = h3u.rateLimit(loi.valContN, loi.valDefault, cfg.dnRate:get(), -cfg.dnRate:get(), dt)
                        else
                            loi.valContN = h3u.rateLimit(loi.valContN, alti.upContRaw - alti.dnContRaw, cfg.upRate:get(), -cfg.upRate:get(), dt)
                        end
                    end
                end
                loi.valContN = math.saturate(loi.valContN)
                loi.valFinN = loi.valContN
            end
            if (loi.isOverwrite) then
                loi.valFinN = funOverwriteVal(contIndex, contName, loi)
            end
            funLoopFinal(contIndex, contName, loi)
        end
    end
    return obj
end




-- 
h3u.whoAmI = 0
function h3u.generateUnqData(car_or_cphys)
    local str = ''
    local n = car_or_cphys.rpm
    str = str..n..','
    local v3 = car_or_cphys.localVelocity
    str = str..v3.x..','..v3.y..','..v3.z..','
    v3 = car_or_cphys.localAngularVelocity
    str = str..v3.x..','..v3.y..','..v3.z..','
    return str
end
function h3u.truncateUnqData(unqdata_str)
    local splitted = string.split(unqdata_str, ',')
    local ret = {}
    for i, v in ipairs(splitted) do
        ret[i] = tonumber(splitted[i])
    end
    return ret
end

function h3u.recogWhoAmI_fromList(mydata, list)
    local trMydata = h3u.truncateUnqData(mydata)
    local trUnqdata = {}
    for iList, unq in ipairs(list) do
        trUnqdata[iList] = h3u.truncateUnqData(unq)
    end
    -- 先に偏差の平均をとっておく
    local avgSqDiff = {}
    for iData, val in ipairs(trMydata) do
        avgSqDiff[iData] = 0
        for iList = 1, #trUnqdata do
            local diff = val - trUnqdata[iList][iData]
            avgSqDiff[iData] = avgSqDiff[iData] + diff^2
        end
        avgSqDiff[iData] = avgSqDiff[iData]/#trUnqdata
    end
    -- リスト(車)ごとに偏差度=偏差/偏差の平均 をもとめる
    -- 小さいほうが近似度が高いので、最小のリストのインデックスを求める
    local MinimumDiff = math.huge
    local iMinimumDiff = #trUnqdata
    local diffEval = {}
    for iList = 1, #trUnqdata do
        diffEval[iList] = 0
        for iData, val in ipairs(trMydata) do
            local diff = val - trUnqdata[iList][iData]
            diffEval[iList] = diffEval[iList] + (diff^2)/avgSqDiff[iData]
        end
        if (diffEval[iList] < MinimumDiff) then
            MinimumDiff = diffEval[iList]
            iMinimumDiff = iList
        end
    end
    return iMinimumDiff
end

-- function h3u.recogWhoAmI_fromStored()
--     local sim = ac.getSim()
--     local listCarUnq = {}
--     for icar = 0, sim.carsCount - 1 do
--         local ccar = ac.getCar(icar)
--         listCarUnq[icar] = h3u.generateUnqData(ccar)
--         --ac.load('h3u.whoAmI.'..icar)
--     end
--     -- ac.log(h3u.recogWhoAmI_fromList(myUnqData, listCarUnq) - 1)
-- end

function h3u.recogWhoAmI_carPhys()
    local sim = ac.getSim()
    local phys = ac.accessCarPhysics()
    local myUnqData = h3u.generateUnqData(phys)
    -- generate unique data list for each cars
    local listCarUnq = {}
    for icar = 0, sim.carsCount - 1 do
        local ccar = ac.getCar(icar)
        listCarUnq[icar + 1] = h3u.generateUnqData(ccar)
    end
    -- match
    h3u.whoAmI = h3u.recogWhoAmI_fromList(myUnqData, listCarUnq) - 1 -- 0-started
    -- store to shared area
    ac.store('h3u.whoAmI.'..h3u.whoAmI, myUnqData)
end

