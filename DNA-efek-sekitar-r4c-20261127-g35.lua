-- DNA R4: local, bounded observation around PandaTalon. No HTTP, scoring or attribution.
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local target = Players:FindFirstChild('PandaTalon')
assert(target, 'PandaTalon tidak ditemukan di server')
local playerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
assert(not playerGui:FindFirstChild('DNA_EFFECT_R4'), 'Panel R4 sudah terbuka')
local screen = Instance.new('ScreenGui')
screen.Name = 'DNA_EFFECT_R4'; screen.ResetOnSpawn = false; screen.Parent = playerGui
local frame = Instance.new('Frame'); frame.Size = UDim2.new(0,380,0,230)
frame.Position = UDim2.new(0,15,0,100); frame.BackgroundColor3 = Color3.fromRGB(20,25,35); frame.Parent = screen
local start = Instance.new('TextButton'); start.Size = UDim2.new(0.65,0,0,32)
start.Text = 'R4c: Mulai 60 detik'; start.Parent = frame
local close = Instance.new('TextButton'); close.Size = UDim2.new(0.35,0,0,32)
close.Position = UDim2.new(0.65,0,0,0); close.Text = 'Tutup R4'; close.Parent = frame
local label = Instance.new('TextLabel'); label.Position = UDim2.new(0,5,0,35)
label.Size = UDim2.new(1,-10,1,-40); label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(230,235,245); label.TextSize = 12
label.TextWrapped = true; label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top; label.Parent = frame
label.Text = 'OFF. Radius 25 studs. Kedekatan BUKAN bukti pemilik. Hasil: Roblox Output [DNA R4].'
local active, dead, untilTime = false, false, 0
local links, watched, lines = {}, {}, {}
local count, skipped, watchedCount = 0, 0, 0
local perSecond = 0 -- retained for reset compatibility
local outputQueue, queueHead, queueTail = {}, 1, 0
local scanComplete, watchRejected, recordRejected = false, 0, 0
local function queueLine(text)
    queueTail=queueTail+1; outputQueue[queueTail]=text
end
local effects = {ParticleEmitter=true, PointLight=true, SpotLight=true, SurfaceLight=true,
    Beam=true, Trail=true, Fire=true, Smoke=true, Sparkles=true, Highlight=true}
local function targetRoot()
    local c = target.Character
    return c and c:FindFirstChild('HumanoidRootPart')
end
local function position(object)
    local node = object
    for _=1,12 do
        if not node then return nil end
        if node:IsA('Attachment') then return node.WorldPosition end
        if node:IsA('BasePart') then return node.Position end
        node=node.Parent
    end
    return nil
end
local function near(object)
    local root=targetRoot(); local p=position(object)
    return root and p and (root.Position-p).Magnitude<=25
end
local function clean(s) return tostring(s):gsub('[\r\n]',' '):sub(1,700) end
local function emit(kind, text)
    if not active then return end
    local control = kind=='START' or kind=='STOP' or kind=='SCAN' or kind=='SCAN_DONE' or kind=='ERROR'
    if count>=6000 and not control then
        skipped=skipped+1; recordRejected=recordRejected+1; return
    end
    count=count+1
    local line=string.format('%.2fs | %s | %s',60-(untilTime-os.clock()),kind,clean(text))
    queueLine('[DNA R4C] '..os.date('!%Y-%m-%dT%H:%M:%SZ')..' | '..line)
    table.insert(lines,line); if #lines>7 then table.remove(lines,1) end
    label.Text='PandaTalon | '..count..' catatan; dilewati '..skipped..'\n'..table.concat(lines,'\n')
end
local function owner(object)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character and object:IsDescendantOf(p.Character) then return p.Name end
    end
    return 'outside-character; nearby only, owner unknown'
end
local function detail(object)
    local text=object.ClassName..' | '..object:GetFullName()..' | owner='..owner(object)
    for _,key in ipairs({'Enabled','Texture','Color','Brightness','Range','Rate','TimeScale','Transparency'}) do
        local ok,value=pcall(function() return object[key] end)
        if ok then text=text..' | '..key..'='..tostring(value) end
    end
    return text
end
local function watch(object, initial)
    if dead or not active or watched[object] or not effects[object.ClassName] then return end
    if not near(object) then return end
    if watchedCount>=400 then skipped=skipped+1; watchRejected=watchRejected+1; return end
    watched[object]=true; watchedCount=watchedCount+1
    emit(initial and 'BASELINE' or 'EFFECT_ADDED',detail(object))
    for _,key in ipairs({'Enabled','Color','Brightness','Range','Rate','Texture','TimeScale','Transparency'}) do
        local ok,signal=pcall(function() return object:GetPropertyChangedSignal(key) end)
        if ok then table.insert(links,signal:Connect(function()
            if active and near(object) then emit('CHANGED '..key,detail(object)) end
        end)) end
    end
    table.insert(links,object.Destroying:Connect(function()
        if active and near(object) then emit('DESTROYING',detail(object)) end
    end))
end
local function stop()
    if active then
        emit('STOP','scanComplete='..tostring(scanComplete)..'; watched='..watchedCount..'; watchLimitRejected='..watchRejected..'; recordLimitRejected='..recordRejected..'; observations only, no verified activator. Output queue will finish printing.')
    end
    active=false
    for _,c in ipairs(links) do c:Disconnect() end
    links={}; watched={}; start.Text='R4c: Mulai 60 detik'
end
start.Activated:Connect(function()
    if active then stop(); return end
    if not targetRoot() then label.Text='Karakter PandaTalon belum siap.'; return end
    if queueHead<=queueTail then label.Text='Tunggu antrean Output selesai, lalu klik Mulai lagi.'; return end
    count,skipped,watchedCount,perSecond=0,0,0,0; lines={}; watched={}
    scanComplete,watchRejected,recordRejected=false,0,0
    untilTime=os.clock()+60; active=true; start.Text='Hentikan R4'
    emit('START','Radius 25 studs; target=PandaTalon. Nearby effects are NOT attribution.')
    table.insert(links,Workspace.DescendantAdded:Connect(function(object)
        local ok,err=pcall(watch,object,false)
        if not ok then emit('ERROR',err) end
    end))
    local thisRun = untilTime
    task.spawn(function()
        local objects=Workspace:GetDescendants()
        emit('SCAN','Workspace objects='..#objects..'; scanning all in yielding batches; watching at most 400 effects')
        if target.Character then
            for _,object in ipairs(target.Character:GetDescendants()) do
                local ok,err=pcall(watch,object,true)
                if not ok then emit('ERROR',err) end
            end
        end
        for i=1,#objects do
            if not active or dead or untilTime~=thisRun then return end
            local ok,err=pcall(watch,objects[i],true)
            if not ok then emit('ERROR',err) end
            if i%250==0 then task.wait() end
        end
        scanComplete=true
        emit('SCAN_DONE','Initial workspace list scanned='..#objects..'; watched effects='..watchedCount..'; watchLimitRejected='..watchRejected..'; recordLimitRejected='..recordRejected)
    end)
end)
close.Activated:Connect(function() stop(); screen:Destroy() end)
screen.Destroying:Connect(function() dead=true; stop() end)
-- Output throttling delays printing, not event capture; timestamps are capture times.
task.spawn(function()
    while not dead or queueHead<=queueTail do
        for _=1,15 do
            if queueHead>queueTail then break end
            local text=outputQueue[queueHead]
            outputQueue[queueHead]=nil; queueHead=queueHead+1
            print(text)
        end
        if queueHead>queueTail then outputQueue={}; queueHead=1; queueTail=0 end
        task.wait(0.1)
    end
end)
task.spawn(function()
    while not dead do
        task.wait(0.5)
        if active and os.clock()>=untilTime then stop() end
    end
end)
