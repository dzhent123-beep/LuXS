-- luxxs | LocalScript -> StarterPlayer > StarterPlayerScripts
-- Ключ: best | Открыть/закрыть: иконка Lx или RightShift
-- Без Drawing: всё на Instance (Frame / Highlight / Trail / Part)

-- безопасный parent для инжекторов (Delta и др.)
local function GUIParent()
	local lpl = game:GetService("Players").LocalPlayer
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	ok, h = pcall(function()
		local g = game:GetService("CoreGui")
		local t = Instance.new("Folder") t.Parent = g t:Destroy()
		return g
	end)
	if ok and h then return h end
	return lpl:WaitForChild("PlayerGui")
end
local GUIP = GUIParent()

local function __lx_main()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local cam = Workspace.CurrentCamera
local KEY = "best"

local conns = {}
local function on(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function rc(o, r) mk("UICorner", { CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0) }, o) end
local function tw(o, t, p, st, dir)
	TweenService:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p):Play()
end

-- настройки (всё выключено по умолчанию)
local S = {
	box = false, boxMode = "2D", boxColor = "Белый",
	name = false, skeleton = false, skelColor = "Белый",
	chams = false, chamsColor = "Красный",
	glow = false, glowColor = "Циан",
	health = false, dist = false, tracers = false, team = true,
	aim = false, aimFov = false, fov = 140, aimMode = "Плавный", speed = 8,
	aimBone = "Head", aimKey = "ПКМ",
	fly = false, flySpeed = 60, noclip = false,
	wings = "Нет", trail = false, trailColor = "Радуга",
	fpsShow = false, fps = 240,
	fullbright = false, camFov = false, camFovV = 90, cross = false,
	alpha = 0.08, scale = 0.9, hue = 0.125, fpsFake = false, tpPos = "Позади", tpSmooth = false, tpTime = .6,
}

do -- под экран телефона
	local vp = cam.ViewportSize
	S.scale = math.clamp(math.min(vp.X / 900, vp.Y / 500, .9), .45, 1.2)
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then S.aimKey = "Всегда" end
end
local function aimCenter()
	if UIS.TouchEnabled and not UIS.MouseEnabled then return cam.ViewportSize / 2 end
	return UIS:GetMouseLocation()
end

local COLORS = { "Зелёный", "Красный", "Синий", "Фиолетовый", "Розовый", "Жёлтый", "Циан", "Белый", "Радуга" }
local CMAP = {
	["Зелёный"] = C(70, 235, 130), ["Красный"] = C(255, 70, 70), ["Синий"] = C(70, 130, 255),
	["Фиолетовый"] = C(170, 90, 255), ["Розовый"] = C(255, 100, 190), ["Жёлтый"] = C(255, 215, 70),
	["Циан"] = C(70, 230, 240), ["Белый"] = C(240, 240, 240),
}
local function col(n, off)
	if n == "Радуга" then return Color3.fromHSV((tick() * 0.25 + (off or 0)) % 1, 0.75, 1) end
	return CMAP[n] or C(255, 255, 255)
end

-- акцент меню (меняется в настройках, всё привязанное обновляется)
local accent = Color3.fromHSV(S.hue, 0.75, 1)
local accB, refs, panels = {}, {}, {}
local function A(o, p) o[p] = accent accB[#accB + 1] = { o, p } return o end
local function setHue(h)
	S.hue = h
	accent = Color3.fromHSV(h, 0.75, 1)
	for _, b in ipairs(accB) do b[1][b[2]] = accent end
	for _, f in ipairs(refs) do f() end
end

-- мягкое свечение из кругов (замена радиального градиента)
local function glowBlob(parent, cx, cy, r, steps, tr)
	for i = steps, 1, -1 do
		local d = 2 * r * i / steps
		local f = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(d, d), BackgroundTransparency = tr or .96, BorderSizePixel = 0 }, parent)
		rc(f) A(f, "BackgroundColor3")
	end
end

for _, n in ipairs({ "lx_ui", "lx_esp", "lx_err" }) do local o = GUIP:FindFirstChild(n) if o then o:Destroy() end end
local oldHl = Workspace:FindFirstChild("lx_hl") if oldHl then oldHl:Destroy() end
pcall(function() RunService:UnbindFromRenderStep("lx_aim") end)
local gui = mk("ScreenGui", { Name = "lx_ui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, GUIP)
local espGui = mk("ScreenGui", { Name = "lx_esp", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50 }, gui.Parent)
local hlFolder = mk("Folder", { Name = "lx_hl" }, Workspace)

-- линия из Frame (замена Drawing)
local function newLine(par)
	return mk("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, BackgroundColor3 = C(255, 255, 255), Visible = false }, par)
end
local function setLine(f, a, b, th)
	local d = b - a
	f.Size = UDim2.fromOffset(d.Magnitude, th)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.Visible = true
end

------------------------------------------------------------------ ESP
local ESP = {}
-- свой ли игрок (по Team, запасной вариант — TeamColor)
local function isMate(plr)
	if not S.team or plr == lp then return false end
	if plr.Team and lp.Team then return plr.Team == lp.Team end
	return not plr.Neutral and not lp.Neutral and plr.TeamColor == lp.TeamColor and plr.TeamColor ~= BrickColor.new("White")
end
local C8, E12 = {}, {}
for xi = 0, 1 do for yi = 0, 1 do for zi = 0, 1 do
	C8[xi * 4 + yi * 2 + zi + 1] = Vector3.new(xi == 1 and 2 or -2, yi == 1 and 2.7 or -3.2, zi == 1 and 1 or -1)
end end end
for a = 0, 7 do for _, bit in ipairs({ 1, 2, 4 }) do
	if bit32.band(a, bit) == 0 then E12[#E12 + 1] = { a + 1, a + bit + 1 } end
end end
local P15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local P6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }

local function makeEsp(plr)
	if plr == lp or ESP[plr] then return end
	local o = {}
	o.root = mk("Folder", {}, espGui)
	o.b2 = mk("Frame", { BackgroundTransparency = 1, Visible = false }, o.root)
	o.b2s = mk("UIStroke", { Thickness = 1.5 }, o.b2)
	o.b3 = {} for i = 1, 12 do o.b3[i] = newLine(o.root) end
	o.sk = {} for i = 1, 14 do o.sk[i] = newLine(o.root) end
	o.tr = newLine(o.root)
	o.nm = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, 1), Size = UDim2.fromOffset(140, 14), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C(255, 255, 255), TextStrokeTransparency = .4, Visible = false }, o.root)
	o.ds = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, 0), Size = UDim2.fromOffset(80, 12), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C(220, 220, 220), TextStrokeTransparency = .5, Visible = false }, o.root)
	o.hb = mk("Frame", { BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = .4, BorderSizePixel = 0, Visible = false }, o.root)
	o.hf = mk("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, o.hb)
	o.hl = mk("Highlight", { Enabled = false, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, hlFolder)
	ESP[plr] = o
end
local function dropEsp(plr)
	local o = ESP[plr]
	if o then o.root:Destroy() o.hl:Destroy() ESP[plr] = nil end
end
local function hideGui(o)
	o.b2.Visible = false o.nm.Visible = false o.ds.Visible = false o.hb.Visible = false o.tr.Visible = false
	for i = 1, 12 do o.b3[i].Visible = false end
	for i = 1, 14 do o.sk[i].Visible = false end
end
local function hideAll(o) hideGui(o) o.hl.Enabled = false end

local function updEsp(plr, o, t)
	local ch = plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 or isMate(plr) then hideAll(o) return end

	local en = S.chams or S.glow
	o.hl.Enabled = en
	if en then
		o.hl.Adornee = ch
		o.hl.FillColor = col(S.chamsColor)
		o.hl.OutlineColor = col(S.glowColor)
		o.hl.FillTransparency = S.chams and .45 or 1
		o.hl.OutlineTransparency = S.glow and (.1 + .25 * (math.sin(t * 3) * .5 + .5)) or 1
	end

	local pos = hrp.Position
	local c, vis = cam:WorldToViewportPoint(pos)
	if not vis then hideGui(o) return end
	local top = cam:WorldToViewportPoint(pos + Vector3.new(0, 2.7, 0))
	local bot = cam:WorldToViewportPoint(pos - Vector3.new(0, 3.2, 0))
	local h = math.abs(bot.Y - top.Y)
	local w = h * .55
	local cx = c.X
	local bc = col(S.boxColor)

	local b2 = S.box and S.boxMode == "2D"
	o.b2.Visible = b2
	if b2 then
		o.b2.Position = UDim2.fromOffset(cx - w / 2, top.Y)
		o.b2.Size = UDim2.fromOffset(w, h)
		o.b2s.Color = bc
	end

	if S.box and S.boxMode == "3D" then
		local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
		local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
		local pts, ok = {}, true
		for i = 1, 8 do
			local v = cam:WorldToViewportPoint((base * CFrame.new(C8[i])).Position)
			if v.Z <= 0 then ok = false break end
			pts[i] = Vector2.new(v.X, v.Y)
		end
		for k, e in ipairs(E12) do
			local ln = o.b3[k]
			if ok then setLine(ln, pts[e[1]], pts[e[2]], 1.5) ln.BackgroundColor3 = bc else ln.Visible = false end
		end
	else
		for k = 1, 12 do o.b3[k].Visible = false end
	end

	o.nm.Visible = S.name
	if S.name then o.nm.Position = UDim2.fromOffset(cx, top.Y - 3) o.nm.Text = plr.Name end

	o.ds.Visible = S.dist
	if S.dist then
		o.ds.Position = UDim2.fromOffset(cx, bot.Y + 2)
		o.ds.Text = math.floor((cam.CFrame.Position - pos).Magnitude) .. "m"
	end

	o.hb.Visible = S.health
	if S.health then
		local f = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		o.hb.Position = UDim2.fromOffset(cx - w / 2 - 6, top.Y)
		o.hb.Size = UDim2.fromOffset(3, h)
		o.hf.Size = UDim2.fromScale(1, f)
		o.hf.BackgroundColor3 = Color3.fromHSV(f * .33, .8, 1)
	end

	local sc = col(S.skelColor)
	local list = ch:FindFirstChild("UpperTorso") and P15 or P6
	for k = 1, 14 do
		local ln, pr = o.sk[k], S.skeleton and list[k]
		local drawn = false
		if pr then
			local a, b = ch:FindFirstChild(pr[1]), ch:FindFirstChild(pr[2])
			if a and b then
				local va, vb = cam:WorldToViewportPoint(a.Position), cam:WorldToViewportPoint(b.Position)
				if va.Z > 0 and vb.Z > 0 then
					setLine(ln, Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), 1.5)
					ln.BackgroundColor3 = sc
					drawn = true
				end
			end
		end
		if not drawn then ln.Visible = false end
	end

	if S.tracers then
		local vp = cam.ViewportSize
		setLine(o.tr, Vector2.new(vp.X / 2, vp.Y), Vector2.new(cx, bot.Y), 1.2)
		o.tr.BackgroundColor3 = bc
	else
		o.tr.Visible = false
	end
end

for _, p in ipairs(Players:GetPlayers()) do makeEsp(p) end
on(Players.PlayerAdded, makeEsp)
on(Players.PlayerRemoving, dropEsp)

------------------------------------------------------------------ AIM
local aimHold = false
on(UIS.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then aimHold = true end end)
on(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then aimHold = false end end)

local BONES = {
	Head = { "Head" }, Chest = { "UpperTorso", "Torso" }, Torso = { "HumanoidRootPart" },
	Legs = { "LeftLowerLeg", "Left Leg", "LeftUpperLeg" },
}
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function aimPart(ch)
	for _, n in ipairs(BONES[S.aimBone]) do
		local p = ch:FindFirstChild(n)
		if p then return p end
	end
end
local function visible(part, ch)
	rp.FilterDescendantsInstances = { lp.Character, ch }
	local o = cam.CFrame.Position
	return Workspace:Raycast(o, part.Position - o, rp) == nil -- сквозь стены не целимся
end
local function target()
	local m = aimCenter()
	local best, bd = nil, S.fov
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr ~= lp and plr.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not isMate(plr) then
			local part = aimPart(ch)
			if part then
				local v, onScr = cam:WorldToViewportPoint(part.Position)
				if onScr then
					local d = (Vector2.new(v.X, v.Y) - m).Magnitude
					if d < bd and visible(part, ch) then best, bd = part, d end
				end
			end
		end
	end
	return best
end

local fovRing = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 1, Visible = false }, espGui)
rc(fovRing)
A(mk("UIStroke", { Thickness = 1.5, Transparency = .15 }, fovRing), "Color")

RunService:BindToRenderStep("lx_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
	cam = Workspace.CurrentCamera
	if S.camFov then cam.FieldOfView = S.camFovV end
	if S.aim and (S.aimKey == "Всегда" or aimHold) then
		local t = target()
		if t then
			local goal = CFrame.lookAt(cam.CFrame.Position, t.Position)
			local a = S.aimMode == "Резкий" and 1 or math.clamp(dt * S.speed, 0, 1)
			cam.CFrame = cam.CFrame:Lerp(goal, a)
		end
	end
end)

------------------------------------------------------------------ MOVE / WORLD
local function hrpHum()
	local ch = lp.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end

local bv
local function stopFly() if bv then bv:Destroy() bv = nil end end
local function flyStep()
	local hrp, hum = hrpHum()
	if not S.fly or not hrp or not hum then stopFly() return end
	if not bv or bv.Parent ~= hrp then
		stopFly()
		bv = mk("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, hrp)
	end
	local mv = hum.MoveDirection
	local look = cam.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local fwd = flat.Magnitude > 0 and mv:Dot(flat.Unit) or 0
	local dir = mv + Vector3.new(0, look.Y * fwd, 0)
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
	bv.Velocity = dir * S.flySpeed
end

on(RunService.Stepped, function()
	if S.noclip and lp.Character then
		for _, p in ipairs(lp.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

local L0
local function fullbright(v)
	if v then
		L0 = L0 or { Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.FogEnd }
		Lighting.Brightness = 2 Lighting.ClockTime = 14
		Lighting.Ambient = C(170, 170, 170) Lighting.OutdoorAmbient = C(170, 170, 170) Lighting.FogEnd = 1e6
	elseif L0 then
		Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.FogEnd = unpack(L0)
		L0 = nil
	end
end

local cross = {}
for i = 1, 4 do cross[i] = A(mk("Frame", { AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, Visible = false }, espGui), "BackgroundColor3") end
local function crossStep()
	for i, f in ipairs(cross) do
		f.Visible = S.cross
		if S.cross then
			local horiz = i <= 2
			local s = (i % 2 == 1) and -1 or 1
			f.Size = horiz and UDim2.fromOffset(9, 2) or UDim2.fromOffset(2, 9)
			f.Position = horiz and UDim2.new(.5, s * 8, .5, 0) or UDim2.new(.5, 0, .5, s * 8)
		end
	end
end

local fpsLbl = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(220, 20), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = .5, Visible = false }, espGui)
A(fpsLbl, "TextColor3")
local fa, fc = 0, 0

local function applyFpsCap()
	pcall(function() setfpscap(S.fps) end) -- работает только там, где есть setfpscap
end

------------------------------------------------------------------ КРЫЛЬЯ / ТРЕЙЛ
local wingModel, wingJ
local function clearWings() if wingModel then wingModel:Destroy() wingModel, wingJ = nil, nil end end

local function wingStep(t)
	if not wingJ then return end
	local sp = S.wings == "Ангел" and 3 or 4
	local sn = math.sin(t * sp)
	for _, j in ipairs(wingJ) do
		j.w.C0 = CFrame.new(j.side * .45, .7, .55) * CFrame.Angles(0, -j.side * (.5 + sn * .3), 0) * CFrame.Angles(0, 0, j.side * sn * .1)
	end
end

local function buildWings(kind)
	clearWings()
	if kind == "Нет" then return end
	local ch = lp.Character
	local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
	if not torso then return end
	wingModel = mk("Model", { Name = "lx_wings" }, ch)
	wingJ = {}
	local angel = kind == "Ангел"
	local V = Vector3.new
	local gold = C(255, 214, 120)
	local NEON, PLASTIC, METAL = Enum.Material.Neon, Enum.Material.SmoothPlastic, Enum.Material.Metal

	for side = -1, 1, 2 do
		local root = mk("Part", { Size = V(.2, .2, .2), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true }, wingModel)
		wingJ[#wingJ + 1] = { w = mk("Weld", { Part0 = torso, Part1 = root }, root), side = side }

		-- позиция в системе крыла (для левого зеркалим)
		local function rel(ox, oy, z, a, off)
			if side == 1 then return CFrame.new(ox, oy, z) * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(off, 0, 0) end
			return CFrame.new(-ox, oy, z) * CFrame.Angles(0, 0, -math.rad(a)) * CFrame.new(-off, 0, 0)
		end
		local function part(cf, size, color, mat, ellipse, ball)
			local p = mk("Part", { Size = size, Color = color, Material = mat, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true, CastShadow = false }, wingModel)
			if ellipse then mk("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, p) end
			if ball then p.Shape = Enum.PartType.Ball end
			mk("Weld", { Part0 = root, Part1 = p, C0 = cf }, p)
			return p
		end

		if angel then
			local PR = { { 85, 2.2 }, { 68, 3.0 }, { 52, 3.7 }, { 36, 4.2 }, { 20, 4.4 }, { 4, 4.3 }, { -12, 3.9 }, { -28, 3.3 }, { -44, 2.6 } }
			local CV = { { 80, 1.6 }, { 64, 2.1 }, { 48, 2.5 }, { 32, 2.8 }, { 16, 3.0 }, { 0, 2.9 }, { -16, 2.6 }, { -32, 2.1 } }
			local SM = { { 75, 1.0 }, { 55, 1.3 }, { 35, 1.5 }, { 15, 1.6 }, { -5, 1.5 }, { -25, 1.2 } }
			for i, f in ipairs(PR) do
				local k = (i - 1) / (#PR - 1)
				part(rel(.2, 0, 0, f[1], f[2] / 2), V(f[2], .95, .05), C(255, 255, 255):Lerp(C(255, 238, 196), k), NEON, true)
				part(rel(.2, 0, .035, f[1], f[2] / 2), V(f[2] * .96, .05, .05), gold, NEON)
			end
			for i, f in ipairs(CV) do
				part(rel(.2, 0, .07, f[1], f[2] / 2), V(f[2], .8, .05), C(255, 255, 255):Lerp(C(255, 244, 215), (i - 1) / (#CV - 1)), NEON, true)
			end
			for _, f in ipairs(SM) do
				part(rel(.2, 0, .12, f[1], f[2] / 2), V(f[2], .6, .05), C(255, 252, 240), NEON, true)
			end
			part(rel(0, 0, .04, 78, 1.4), V(2.8, .2, .12), gold, NEON)
			part(CFrame.new(0, 0, .04), V(.4, .4, .4), gold, NEON, false, true)
		else
			local arm = 72
			local Wx, Wy = 2.4 * math.cos(math.rad(arm)), 2.4 * math.sin(math.rad(arm))
			local FN = { { 80, 2.4 }, { 56, 4.2 }, { 32, 5.0 }, { 8, 4.6 }, { -16, 3.4 } }
			local dark, red = C(26, 22, 28), C(255, 40, 50)
			part(rel(0, 0, 0, arm, 1.2), V(2.4, .26, .22), dark, METAL)
			part(CFrame.new(0, 0, 0), V(.5, .5, .5), dark, METAL, false, true)
			for i = 1, #FN - 1 do
				local a1, b1 = FN[i], FN[i + 1]
				local mid, d = (a1[1] + b1[1]) / 2, math.rad(a1[1] - b1[1])
				local len = math.min(a1[2], b1[2]) * .82
				part(rel(Wx, Wy, -.02, mid, len / 2), V(len, len * math.sin(d / 2) * 1.9, .04), C(95, 10, 20), PLASTIC, true)
			end
			part(rel(0, -.3, -.03, -38, 1.7), V(3.4, 2.6, .04), C(70, 8, 16), PLASTIC, true)
			for _, f in ipairs(FN) do
				part(rel(Wx, Wy, 0, f[1], f[2] / 2), V(f[2], .14, .14), dark, METAL)
				part(rel(Wx, Wy, 0, f[1], f[2]), V(.32, .32, .32), red, NEON, false, true)
			end
		end
	end
	wingStep(tick())
end

local trail
local function clearTrail() if trail then trail.Attachment0:Destroy() trail.Attachment1:Destroy() trail:Destroy() trail = nil end end
local function buildTrail()
	clearTrail()
	local hrp = hrpHum()
	if not hrp then return end
	local a0 = mk("Attachment", { Position = Vector3.new(0, 1.2, 0) }, hrp)
	local a1 = mk("Attachment", { Position = Vector3.new(0, -1.2, 0) }, hrp)
	trail = mk("Trail", {
		Attachment0 = a0, Attachment1 = a1, Lifetime = .7, MinLength = .05, LightEmission = 1, FaceCamera = true,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .1), NumberSequenceKeypoint.new(1, 1) }),
		WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	}, hrp)
end
local function trailStep()
	if not trail then return end
	if S.trailColor == "Радуга" then
		local h = (tick() * .25) % 1
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(h, .75, 1)),
			ColorSequenceKeypoint.new(.5, Color3.fromHSV((h + .15) % 1, .75, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV((h + .3) % 1, .75, 1)),
		})
	else
		trail.Color = ColorSequence.new(col(S.trailColor))
	end
end

on(lp.CharacterAdded, function(c)
	c:WaitForChild("HumanoidRootPart", 5)
	task.wait(.4)
	if S.wings ~= "Нет" then buildWings(S.wings) end
	if S.trail then buildTrail() end
end)

------------------------------------------------------------------ ОКНО ВХОДА
local icon, setOpen, isOpen -- объявлены ниже
local keyBlur
do -- экран ключа (локали внутри, чтобы не упереться в лимит)

local ov = mk("Frame", { Name = "key", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(5, 6, 5), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true }, gui)
keyBlur = mk("BlurEffect", { Size = 0 }, Lighting)
local kc = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(440, 190), BackgroundTransparency = 1 }, ov)
mk("UIScale", { Scale = math.clamp(cam.ViewportSize.X / 520, .55, 1) }, kc)

local rule = A(mk("Frame", { Position = UDim2.fromOffset(-18, 6), Size = UDim2.fromOffset(2, 0), BorderSizePixel = 0 }, kc), "BackgroundColor3")
local word = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(-34, -6), Size = UDim2.fromOffset(320, 70), Font = Enum.Font.GothamBlack, Text = "luxxs", TextSize = 64, TextColor3 = C(240, 242, 240), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1 }, kc)
local by = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 68), Size = UDim2.fromOffset(300, 16), Font = Enum.Font.Code, Text = "by drhub  /  knife duels", TextSize = 12, TextColor3 = C(120, 128, 124), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1 }, kc)
local c1 = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 1, -26), Size = UDim2.fromOffset(300, 14), Font = Enum.Font.Code, Text = "lx // session locked", TextSize = 11, TextColor3 = C(95, 102, 99), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1 }, ov)

local tab = A(mk("Frame", { Position = UDim2.fromOffset(0, 104), Size = UDim2.fromOffset(0, 54), BorderSizePixel = 0, ClipsDescendants = true }, kc), "BackgroundColor3")
local tabCr = mk("UICorner", { CornerRadius = UDim.new(0, 0) }, tab)
local tabLbl = mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "Lx", TextSize = 20, TextColor3 = C(8, 10, 9) }, tab)
local tabSt = A(mk("UIStroke", { Thickness = 0 }, tab), "Color")

local strip = mk("Frame", { Position = UDim2.fromOffset(54, 104), Size = UDim2.fromOffset(0, 54), BackgroundColor3 = C(12, 13, 12), BackgroundTransparency = .1, BorderSizePixel = 0, ClipsDescendants = true }, kc)
local stripSt = mk("UIStroke", { Thickness = 1, Color = C(52, 57, 55) }, strip)
local kbox = mk("TextBox", { Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(314, 54), BackgroundTransparency = 1, Text = "", PlaceholderText = "ключ_", PlaceholderColor3 = C(90, 97, 94), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 20, TextColor3 = C(236, 240, 237), TextXAlignment = Enum.TextXAlignment.Left }, strip)
local kgo = mk("TextButton", { Position = UDim2.fromOffset(340, 0), Size = UDim2.fromOffset(46, 54), BackgroundTransparency = 1, Text = "→", Font = Enum.Font.GothamBold, TextSize = 24, AutoButtonColor = false }, strip)
A(kgo, "TextColor3")
local line = A(mk("Frame", { Position = UDim2.fromOffset(54, 158), Size = UDim2.fromOffset(0, 2), BorderSizePixel = 0 }, kc), "BackgroundColor3")
local status = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 168), Size = UDim2.fromOffset(440, 16), Font = Enum.Font.Code, Text = "", TextSize = 12, TextColor3 = C(120, 128, 124), TextXAlignment = Enum.TextXAlignment.Left }, kc)

-- появление
tw(ov, .5, { BackgroundTransparency = .28 })
tw(keyBlur, .6, { Size = 18 })
tw(rule, .6, { Size = UDim2.fromOffset(2, 160) })
tw(word, .6, { TextTransparency = 0, Position = UDim2.fromOffset(-14, -6) })
task.delay(.2, function() tw(by, .5, { TextTransparency = 0 }) end)
task.delay(.3, function() tw(tab, .45, { Size = UDim2.fromOffset(54, 54) }, Enum.EasingStyle.Back) end)
task.delay(.45, function() tw(strip, .6, { Size = UDim2.fromOffset(386, 54) }) end)
task.delay(.7, function() tw(c1, .5, { TextTransparency = 0 }) end)

local busy = false
kbox.Focused:Connect(function() if not busy then tw(line, .35, { Size = UDim2.fromOffset(386, 2) }) end end)
kbox.FocusLost:Connect(function() if not busy and kbox.Text == "" then tw(line, .3, { Size = UDim2.fromOffset(0, 2) }) end end)

local function deny()
	status.Text = "x  неверный ключ"
	status.TextColor3 = C(255, 90, 90)
	stripSt.Color = C(255, 90, 90)
	local p = kc.Position
	for _, dx in ipairs({ 12, -12, 8, -8, 4, 0 }) do
		tw(kc, .045, { Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset) }, Enum.EasingStyle.Sine)
		task.wait(.045)
	end
	task.wait(.5)
	stripSt.Color = C(52, 57, 55)
	status.Text = ""
	kbox.Text = ""
end

local function submit()
	if busy then return end
	busy = true
	if (kbox.Text:gsub("%s", "")):lower() ~= KEY then
		deny()
		busy = false
		return
	end
	kbox:ReleaseFocus()
	local msg = "> доступ разрешён"
	status.TextColor3 = accent
	for i = 1, utf8.len(msg) do
		status.Text = msg:sub(1, (utf8.offset(msg, i + 1) or #msg + 1) - 1)
		task.wait(.03)
	end
	task.wait(.3)
	tw(strip, .4, { Size = UDim2.fromOffset(0, 54) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	tw(line, .3, { Size = UDim2.fromOffset(0, 2) })
	tw(word, .4, { TextTransparency = 1, Position = UDim2.fromOffset(-34, -6) })
	for _, o in ipairs({ by, status, c1 }) do tw(o, .3, { TextTransparency = 1 }) end
	tw(rule, .4, { Size = UDim2.fromOffset(2, 0) })
	task.wait(.45)
	-- плашка Lx превращается в иконку меню
	local ap, as = tab.AbsolutePosition, tab.AbsoluteSize
	tab.Parent = ov
	tab.AnchorPoint = Vector2.new(.5, .5)
	tab.Size = UDim2.fromOffset(as.X, as.Y)
	tab.Position = UDim2.fromOffset(ap.X + as.X / 2, ap.Y + as.Y / 2)
	tw(tab, .6, { Position = UDim2.new(0, 53, .5, 0), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = C(13, 15, 14) }, Enum.EasingStyle.Quart)
	tw(tabCr, .6, { CornerRadius = UDim.new(1, 0) })
	tw(tabLbl, .6, { TextColor3 = accent })
	tw(tabSt, .6, { Thickness = 2 })
	tw(ov, .6, { BackgroundTransparency = 1 })
	tw(keyBlur, .6, { Size = 0 })
	task.wait(.65)
	icon:FindFirstChildOfClass("UIScale").Scale = 1
	icon.Visible = true
	ov:Destroy()
	keyBlur:Destroy()
	setOpen(true)
end
kgo.MouseButton1Click:Connect(submit)
kbox.FocusLost:Connect(function(enter) if enter then submit() end end)
end

------------------------------------------------------------------ ГЛАВНОЕ ОКНО
local win = mk("CanvasGroup", { Name = "win", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(840, 460), BackgroundColor3 = C(11, 13, 12), GroupTransparency = 1, Visible = false }, gui)
rc(win, 10)
local winStroke = mk("UIStroke", { Thickness = 1.6, Color = C(255, 255, 255) }, win)
local wsg = mk("UIGradient", {}, winStroke)
local winBg = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0 }, win)
mk("UIGradient", { Rotation = 135, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(22, 25, 23)), ColorSequenceKeypoint.new(.55, C(12, 14, 13)), ColorSequenceKeypoint.new(1, C(9, 10, 9)) }) }, winBg)
panels[#panels + 1] = winBg
local deco = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true }, win)
for x = 0, 840, 40 do mk("Frame", { Position = UDim2.fromOffset(x, 38), Size = UDim2.fromOffset(1, 422), BackgroundColor3 = C(255, 255, 255), BackgroundTransparency = .965, BorderSizePixel = 0 }, deco) end
for y = 38, 460, 40 do mk("Frame", { Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(840, 1), BackgroundColor3 = C(255, 255, 255), BackgroundTransparency = .965, BorderSizePixel = 0 }, deco) end
glowBlob(deco, 540, 80, 220, 9)
glowBlob(deco, 160, 450, 200, 8)
local sweep = A(mk("Frame", { Position = UDim2.fromOffset(-140, 38), Size = UDim2.fromOffset(140, 422), BorderSizePixel = 0 }, deco), "BackgroundColor3")
mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, .93), NumberSequenceKeypoint.new(1, 1) }) }, sweep)
TweenService:Create(sweep, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Position = UDim2.fromOffset(840, 38) }):Play()
local wscale = mk("UIScale", {}, win)
local openF = mk("NumberValue", { Value = .85 })
local function applyScale() wscale.Scale = S.scale * openF.Value end
openF.Changed:Connect(applyScale) applyScale()

local function applyAlpha()
	win.BackgroundTransparency = S.alpha
	for _, o in ipairs(panels) do o.BackgroundTransparency = math.clamp(.05 + S.alpha, 0, .9) end
end
local function pan(o) panels[#panels + 1] = o return o end

local tb = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C(15, 18, 17), BorderSizePixel = 0 }, win)
do
	local ln = A(mk("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, tb), "BackgroundColor3")
	mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.6, .35), NumberSequenceKeypoint.new(1, 1) }) }, ln)
end
mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(300, 36), Font = Enum.Font.GothamBold, Text = "luxxs  ·  by drhub  ·  knife duels", TextSize = 14, TextColor3 = C(200, 207, 203), TextXAlignment = Enum.TextXAlignment.Left }, tb)
local closeB = mk("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, -1), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = C(170, 176, 173) }, tb)

-- перетаскивание
local function drag(frame, handle, onClick)
	local dn, moved, start, orig = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dn, moved, start, orig = true, false, i.Position, frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dn = false
					if not moved and onClick then onClick() end
				end
			end)
		end
	end)
	on(UIS.InputChanged, function(i)
		if dn and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			if d.Magnitude > 4 then moved = true end
			if moved then frame.Position = UDim2.new(orig.X.Scale, orig.X.Offset + d.X, orig.Y.Scale, orig.Y.Offset + d.Y) end
		end
	end)
end
drag(win, tb)

local side = pan(mk("Frame", { Position = UDim2.fromOffset(0, 38), Size = UDim2.fromOffset(140, 422), BackgroundColor3 = C(14, 16, 15), BorderSizePixel = 0 }, win))
local content = mk("Frame", { Position = UDim2.fromOffset(140, 38), Size = UDim2.fromOffset(430, 422), BackgroundTransparency = 1 }, win)
local pv = pan(mk("Frame", { Position = UDim2.fromOffset(570, 38), Size = UDim2.fromOffset(270, 422), BackgroundColor3 = C(13, 15, 14), BorderSizePixel = 0 }, win))
mk("Frame", { Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C(34, 40, 37), BorderSizePixel = 0 }, pv)

local logo = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 1, -44), Size = UDim2.fromOffset(110, 26), Font = Enum.Font.GothamBlack, Text = "luxxs", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left }, side)
A(logo, "TextColor3")
do
	local by = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 80, 1, -38), Size = UDim2.fromOffset(56, 14), Font = Enum.Font.GothamBold, Text = "by drhub", TextSize = 11, TextTransparency = .3, TextXAlignment = Enum.TextXAlignment.Left }, side)
	A(by, "TextColor3")
	mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(255, 255, 255), C(190, 190, 190)) }, side)
	local div = mk("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C(36, 42, 39), BorderSizePixel = 0 }, side)
end
TweenService:Create(logo, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = .45 }):Play()

-- компоненты
local ord = 0
local function newPage()
	local s = mk("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false }, content)
	A(s, "ScrollBarImageColor3")
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	mk("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10) }, s)
	return s
end
local function row(p, h)
	ord += 1
	local r = pan(mk("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C(20, 23, 22), BorderSizePixel = 0, LayoutOrder = ord }, p))
	rc(r, 6)
	mk("UIStroke", { Thickness = 1, Color = C(36, 42, 39) }, r)
	mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(255, 255, 255), C(205, 205, 205)) }, r)
	return r
end
local function hoverfx(r, hit)
	hit.MouseEnter:Connect(function() tw(r, .15, { BackgroundColor3 = C(30, 34, 32) }) end)
	hit.MouseLeave:Connect(function() tw(r, .25, { BackgroundColor3 = C(20, 23, 22) }) end)
end
local function lbl(parent, text, x, y, w, size, color, align)
	return mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 18), Font = Enum.Font.Gotham, Text = text, TextSize = size or 14, TextColor3 = color or C(218, 224, 221), TextXAlignment = align or Enum.TextXAlignment.Left }, parent)
end
local function header(p, text)
	ord += 1
	local l = mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBold, Text = "   " .. string.upper(text), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord }, p)
	A(l, "TextColor3")
	local b = A(mk("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(3, 11), BorderSizePixel = 0 }, l), "BackgroundColor3")
	rc(b)
	local tx = l.TextBounds.X + 10
	local ln = mk("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, tx, .5, 0), Size = UDim2.new(1, -tx, 0, 1), BorderSizePixel = 0 }, l)
	A(ln, "BackgroundColor3")
	mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, .45), NumberSequenceKeypoint.new(1, 1) }) }, ln)
end
local function note(p, text)
	ord += 1
	mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextWrapped = true, TextColor3 = C(115, 123, 119), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = ord }, p)
end

local function toggle(p, text, k, cb)
	local r = row(p, 34)
	lbl(r, text, 12, 8, 280)
	local tr = mk("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(38, 18), BorderSizePixel = 0 }, r)
	rc(tr)
	local kn = mk("Frame", { Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0 }, tr)
	rc(kn)
	local trs = mk("UIStroke", { Thickness = 3, Transparency = 1 }, tr)
	A(trs, "Color")
	local bar = A(mk("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(3, 0), BorderSizePixel = 0 }, r), "BackgroundColor3")
	rc(bar)
	local function ref(anim)
		local t = anim and .18 or 0
		tw(bar, t, { Size = UDim2.fromOffset(3, S[k] and 20 or 0) })
		tw(trs, t, { Transparency = S[k] and .7 or 1 })
		tw(tr, t, { BackgroundColor3 = S[k] and accent or C(50, 55, 53) })
		tw(kn, t, { Position = S[k] and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) })
	end
	ref(false)
	refs[#refs + 1] = function() ref(false) end
	local hit = mk("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, r)
	hoverfx(r, hit)
	hit.MouseButton1Click:Connect(function()
		S[k] = not S[k]
		ref(true)
		if cb then cb(S[k]) end
	end)
end

local function slider(p, text, k, mn, mx, dec, cb)
	local r = row(p, 46)
	lbl(r, text, 12, 6, 260)
	local vl = lbl(r, "", 0, 6, 394, 13, accent, Enum.TextXAlignment.Right)
	A(vl, "TextColor3")
	local bar = mk("Frame", { Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = C(40, 45, 43), BorderSizePixel = 0 }, r)
	rc(bar)
	local fill = A(mk("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bar), "BackgroundColor3")
	rc(fill)
	mk("UIGradient", { Color = ColorSequence.new(C(190, 190, 190), C(255, 255, 255)) }, fill)
	local knob = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(1, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0 }, fill)
	rc(knob)
	A(mk("UIStroke", { Thickness = 3, Transparency = .55 }, knob), "Color")
	local function set(v, fire)
		v = math.clamp(v, mn, mx)
		local m = 10 ^ dec
		v = math.floor(v * m + .5) / m
		S[k] = v
		fill.Size = UDim2.fromScale((v - mn) / (mx - mn), 1)
		vl.Text = tostring(v)
		if fire and cb then cb(v) end
	end
	set(S[k])
	local function fromX(x) set(mn + (mx - mn) * math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1), true) end
	local d = false
	local hit = mk("TextButton", { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "" }, r)
	hoverfx(r, hit)
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true fromX(i.Position.X) end
	end)
	on(UIS.InputChanged, function(i)
		if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
	end)
	on(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end
	end)
	return set
end

local function choice(p, text, k, opts, cb)
	local r = row(p, 58)
	lbl(r, text, 12, 6, 280)
	local hold = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 24) }, r)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, hold)
	local btns = {}
	local function ref()
		for o, b in pairs(btns) do
			local s = S[k] == o
			tw(b, .15, { BackgroundColor3 = s and accent or C(32, 36, 34), TextColor3 = s and C(8, 10, 9) or C(190, 196, 193) })
		end
	end
	for _, o in ipairs(opts) do
		local b = mk("TextButton", { Size = UDim2.new(1 / #opts, -4 * (#opts - 1) / #opts, 1, 0), Text = o, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0 }, hold)
		rc(b, 5)
		btns[o] = b
		b.MouseButton1Click:Connect(function() S[k] = o ref() if cb then cb(o) end end)
	end
	ref()
	refs[#refs + 1] = ref
end

local function colors(p, text, k, cb)
	local r = row(p, 58)
	lbl(r, text, 12, 6, 280)
	local hold = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 24) }, r)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, hold)
	local sw = {}
	for _, n in ipairs(COLORS) do
		local b = mk("TextButton", { Text = "", Size = UDim2.fromOffset(24, 24), BackgroundColor3 = CMAP[n] or C(255, 255, 255), AutoButtonColor = false }, hold)
		rc(b)
		local st = mk("UIStroke", { Thickness = 2, Color = C(255, 255, 255), Transparency = 1 }, b)
		if n == "Радуга" then
			local ks = {}
			for i = 0, 5 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, .8, 1)) end
			mk("UIGradient", { Color = ColorSequence.new(ks), Rotation = 45 }, b)
		end
		sw[n] = st
		b.MouseButton1Click:Connect(function()
			S[k] = n
			for m, s in pairs(sw) do tw(s, .15, { Transparency = m == n and 0 or 1 }) end
			if cb then cb(n) end
		end)
	end
	for m, s in pairs(sw) do s.Transparency = S[k] == m and 0 or 1 end
end

local function button(p, text, cb)
	local r = row(p, 34)
	local b = mk("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false }, r)
	A(b, "TextColor3")
	b.MouseButton1Click:Connect(cb)
end

------------------------------------------------------------------ PREVIEW
mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 8), Size = UDim2.fromOffset(200, 18), Font = Enum.Font.GothamBold, Text = "PREVIEW  /  LIVE", TextSize = 11, TextColor3 = C(120, 128, 124), TextXAlignment = Enum.TextXAlignment.Left }, pv)
local liveDot = A(mk("Frame", { Position = UDim2.fromOffset(248, 13), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0 }, pv), "BackgroundColor3")
rc(liveDot)
local st = mk("Frame", { Position = UDim2.fromOffset(10, 30), Size = UDim2.fromOffset(250, 340), BackgroundColor3 = C(10, 12, 11), BorderSizePixel = 0, ClipsDescendants = true }, pv)
rc(st, 8)
mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(26, 33, 30), C(8, 10, 9)) }, st)
local stStroke = mk("UIStroke", { Thickness = 1.6, Color = C(255, 255, 255) }, st)
local stGrad = mk("UIGradient", {}, stStroke)
glowBlob(st, 125, 165, 150, 11, .955)
-- пол с перспективной сеткой
for i = 1, 7 do
	local y = 236 + (i / 7) ^ 1.7 * 104
	local l = newLine(st) A(l, "BackgroundColor3") l.BackgroundTransparency = .86
	setLine(l, Vector2.new(0, y), Vector2.new(250, y), 1)
end
for j = -6, 6 do
	local l = newLine(st) A(l, "BackgroundColor3") l.BackgroundTransparency = .86
	setLine(l, Vector2.new(125 + j * 10, 236), Vector2.new(125 + j * 70, 340), 1)
end
local ringF = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 288), Size = UDim2.fromOffset(110, 20), BackgroundTransparency = 1 }, st)
rc(ringF)
local ringS = A(mk("UIStroke", { Thickness = 2, Transparency = .4 }, ringF), "Color")
local ring2 = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 288), Size = UDim2.fromOffset(150, 28), BackgroundTransparency = 1 }, st)
rc(ring2)
A(mk("UIStroke", { Thickness = 1.5, Transparency = .55 }, ring2), "Color")
local psweep = A(mk("Frame", { Size = UDim2.fromOffset(250, 40), BorderSizePixel = 0, ZIndex = 2 }, st), "BackgroundColor3")
mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, .9), NumberSequenceKeypoint.new(1, 1) }) }, psweep)
local pvP = {}
for i = 1, 14 do
	local f = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(2 + i % 3, 2 + i % 3), BorderSizePixel = 0, BackgroundTransparency = .5 }, st)
	rc(f) A(f, "BackgroundColor3")
	pvP[i] = { f = f, x = (i * 37) % 250, sp = 10 + (i * 7) % 22, ph = i }
end
for _, c in ipairs({ { 6, 6, 0, 0 }, { 244, 6, 1, 0 }, { 6, 334, 0, 1 }, { 244, 334, 1, 1 } }) do
	local ax, ay = c[3], c[4]
	A(mk("Frame", { Position = UDim2.fromOffset(c[1], c[2]), AnchorPoint = Vector2.new(ax, ay), Size = UDim2.fromOffset(14, 2), BorderSizePixel = 0, ZIndex = 11 }, st), "BackgroundColor3")
	A(mk("Frame", { Position = UDim2.fromOffset(c[1], c[2]), AnchorPoint = Vector2.new(ax, ay), Size = UDim2.fromOffset(2, 14), BorderSizePixel = 0, ZIndex = 11 }, st), "BackgroundColor3")
end
mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(120, 12), Font = Enum.Font.Code, Text = "RT // MANNEQUIN", TextSize = 9, TextColor3 = C(110, 118, 114), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 }, st)
local shadow = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 288), Size = UDim2.fromOffset(130, 14), BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = .45, BorderSizePixel = 0 }, st)
rc(shadow)

local GRAY = C(150, 152, 156)
local body = {}
local function bp(x, y, w, h, r)
	local f = mk("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = GRAY, BorderSizePixel = 0, ZIndex = 3 }, st)
	rc(f, r)
	mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(165, 165, 165)), ColorSequenceKeypoint.new(.5, C(255, 255, 255)), ColorSequenceKeypoint.new(1, C(160, 160, 160)) }) }, f)
	local s = mk("UIStroke", { Thickness = 2.5, Enabled = false }, f)
	body[#body + 1] = { f = f, s = s }
end
bp(106, 43, 38, 38, 19) bp(118, 79, 14, 11, 4) bp(93, 88, 64, 92, 9) bp(73, 90, 18, 84, 8) bp(159, 90, 18, 84, 8) bp(94, 184, 28, 100, 8) bp(128, 184, 28, 100, 8)
bp(93, 172, 64, 16, 8) bp(83, 88, 20, 20, 10) bp(147, 88, 20, 20, 10) bp(71, 126, 22, 14, 7) bp(157, 126, 22, 14, 7)
bp(72, 170, 20, 18, 8) bp(158, 170, 20, 18, 8) bp(93, 226, 30, 16, 8) bp(127, 226, 30, 16, 8) bp(90, 278, 36, 14, 7) bp(124, 278, 36, 14, 7)
-- детали корпуса
local visor = mk("Frame", { Position = UDim2.fromOffset(111, 56), Size = UDim2.fromOffset(28, 10), BackgroundColor3 = C(14, 16, 18), BorderSizePixel = 0, ZIndex = 4 }, st)
rc(visor, 5)
local vl = A(mk("Frame", { Position = UDim2.fromOffset(113, 60), Size = UDim2.fromOffset(24, 2), BorderSizePixel = 0, ZIndex = 5 }, st), "BackgroundColor3")
rc(vl)
mk("Frame", { Position = UDim2.fromOffset(124, 100), Size = UDim2.fromOffset(2, 70), BackgroundColor3 = C(80, 82, 88), BackgroundTransparency = .3, BorderSizePixel = 0, ZIndex = 4 }, st)
mk("Frame", { Position = UDim2.fromOffset(99, 98), Size = UDim2.fromOffset(52, 2), BackgroundColor3 = C(80, 82, 88), BackgroundTransparency = .3, BorderSizePixel = 0, ZIndex = 4 }, st)
mk("Frame", { Position = UDim2.fromOffset(99, 150), Size = UDim2.fromOffset(52, 2), BackgroundColor3 = C(80, 82, 88), BackgroundTransparency = .3, BorderSizePixel = 0, ZIndex = 4 }, st)
local reactor = A(mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 122), Size = UDim2.fromOffset(9, 9), BorderSizePixel = 0, ZIndex = 5 }, st), "BackgroundColor3")
rc(reactor)
A(mk("UIStroke", { Thickness = 4, Transparency = .65 }, reactor), "Color")

-- крылья в превью
local pvW = { ["Ангел"] = {}, ["Демон"] = {} }
local function feathers(kind, lens, angs, hgt)
	for sd = -1, 1, 2 do
		for i, L in ipairs(lens) do
			local ang = kind == "Ангел"
			local f = mk("Frame", {
				AnchorPoint = Vector2.new(sd == 1 and 0 or 1, .5), Position = UDim2.fromOffset(125 + sd * 25, 100), Size = UDim2.fromOffset(L, hgt),
				BackgroundColor3 = ang and C(255, 255, 255):Lerp(C(255, 226, 150), (i - 1) / 5) or C(40, 6, 10):Lerp(C(205, 24, 34), (i - 1) / 5),
				BorderSizePixel = 0, ZIndex = 2, Visible = false,
			}, st)
			rc(f)
			if ang then
				mk("UIGradient", { Rotation = sd == 1 and 0 or 180, Transparency = NumberSequence.new(0, .7) }, f)
			else
				mk("UIStroke", { Color = C(230, 40, 50), Thickness = 1, Transparency = .4 }, f)
			end
			pvW[kind][#pvW[kind] + 1] = { f = f, side = sd, a = angs[i], i = i }
		end
	end
end
feathers("Ангел", { 92, 86, 78, 68, 58, 48 }, { -72, -50, -28, -6, 16, 38 }, 14)
feathers("Демон", { 100, 90, 78, 64, 50, 38 }, { -80, -58, -36, -14, 8, 30 }, 8)

-- трейл
local pvT = {}
for k = 0, 9 do
	pvT[k] = mk("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.fromOffset(98 - k * 9, 272 + math.sin(k * .6) * 3), Size = UDim2.fromOffset(10, 9 - k * .7), BorderSizePixel = 0, BackgroundTransparency = .1 + k * .09, Visible = false, ZIndex = 2 }, st)
	rc(pvT[k])
end

-- FOV кольцо
local pvRing = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 170), BackgroundTransparency = 1, Visible = false, ZIndex = 1 }, st)
rc(pvRing)
A(mk("UIStroke", { Thickness = 1.2, Transparency = .45 }, pvRing), "Color")

-- боксы
local pvB2 = mk("Frame", { Position = UDim2.fromOffset(62, 36), Size = UDim2.fromOffset(126, 256), BackgroundTransparency = 1, Visible = false, ZIndex = 5 }, st)
local pvB2s = mk("UIStroke", { Thickness = 1.5 }, pvB2)
local pvB3 = {}
do
	local f0, f1 = Vector2.new(62, 52), Vector2.new(170, 292)
	local off = Vector2.new(18, -14)
	local pts = {}
	for xi = 0, 1 do for yi = 0, 1 do for zi = 0, 1 do
		pts[xi * 4 + yi * 2 + zi + 1] = Vector2.new(xi == 1 and f1.X or f0.X, yi == 1 and f1.Y or f0.Y) + (zi == 1 and off or Vector2.zero)
	end end end
	for k, e in ipairs(E12) do
		local l = newLine(st)
		l.ZIndex = 5
		setLine(l, pts[e[1]], pts[e[2]], 1.5)
		l.Visible = false
		pvB3[k] = l
	end
end
local pvName = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.fromOffset(125, 34), Size = UDim2.fromOffset(120, 14), Font = Enum.Font.GothamBold, Text = "Enemy_01", TextSize = 13, TextColor3 = C(255, 255, 255), Visible = false, ZIndex = 6 }, st)
local pvDist = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(65, 296), Size = UDim2.fromOffset(120, 14), Font = Enum.Font.Gotham, Text = "42m", TextSize = 12, TextColor3 = C(220, 220, 220), Visible = false, ZIndex = 6 }, st)
local pvHb = mk("Frame", { Position = UDim2.fromOffset(54, 36), Size = UDim2.fromOffset(3, 256), BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = .4, BorderSizePixel = 0, Visible = false, ZIndex = 5 }, st)
local pvHf = mk("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, .8), BorderSizePixel = 0 }, pvHb)
local pvTr = newLine(st) pvTr.ZIndex = 5
setLine(pvTr, Vector2.new(30, 340), Vector2.new(125, 292), 1.2) pvTr.Visible = false

-- скелет
local J = {
	head = Vector2.new(125, 62), neck = Vector2.new(125, 86), pelvis = Vector2.new(125, 176),
	sl = Vector2.new(94, 98), sr = Vector2.new(156, 98), el = Vector2.new(82, 132), er = Vector2.new(168, 132),
	hl = Vector2.new(82, 170), hr = Vector2.new(168, 170), hipL = Vector2.new(110, 178), hipR = Vector2.new(140, 178),
	kl = Vector2.new(108, 232), kr = Vector2.new(142, 232), fl = Vector2.new(108, 282), fr = Vector2.new(142, 282),
}
local SKP = { { "head", "neck" }, { "neck", "pelvis" }, { "neck", "sl" }, { "neck", "sr" }, { "sl", "el" }, { "el", "hl" }, { "sr", "er" }, { "er", "hr" },
	{ "pelvis", "hipL" }, { "pelvis", "hipR" }, { "hipL", "kl" }, { "kl", "fl" }, { "hipR", "kr" }, { "kr", "fr" } }
local pvSk = {}
for k, e in ipairs(SKP) do
	local l = newLine(st) l.ZIndex = 6
	setLine(l, J[e[1]], J[e[2]], 2) l.Visible = false
	pvSk[k] = l
end

-- выбор части тела для аима
local ZONES = {
	Head = { 106, 43, 38, 38, Vector2.new(125, 62), "Голова" },
	Chest = { 93, 88, 64, 46, Vector2.new(125, 111), "Грудь" },
	Torso = { 93, 134, 64, 46, Vector2.new(125, 157), "Торс / таз" },
	Legs = { 94, 184, 62, 100, Vector2.new(125, 234), "Ноги" },
}
local hov = mk("Frame", { BackgroundTransparency = 1, Visible = false, ZIndex = 7 }, st)
rc(hov, 8)
A(mk("UIStroke", { Thickness = 1.5, Transparency = .35 }, hov), "Color")
local dot = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(125, 62), BorderSizePixel = 0, ZIndex = 10 }, st)
A(dot, "BackgroundColor3") rc(dot)
local dotGlow = A(mk("UIStroke", { Thickness = 6, Transparency = .6 }, dot), "Color")
local halo = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = .8, BorderSizePixel = 0, ZIndex = 9 }, dot)
rc(halo) A(halo, "BackgroundColor3")
local rip = {}
for i = 1, 2 do
	local f = mk("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12), ZIndex = 9 }, st)
	rc(f)
	rip[i] = { f = f, s = A(mk("UIStroke", { Thickness = 1.5 }, f), "Color") }
end
-- подсветка выбранной части тела и луч прицела
local sel = mk("Frame", { Position = UDim2.fromOffset(103, 40), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = .8, BorderSizePixel = 0, ZIndex = 6 }, st)
rc(sel, 10) A(sel, "BackgroundColor3")
A(mk("UIStroke", { Thickness = 1.5, Transparency = .2 }, sel), "Color")
local beam = A(mk("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(125, 62), Size = UDim2.fromOffset(250, 1), BorderSizePixel = 0, ZIndex = 5 }, st), "BackgroundColor3")
mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, .1), NumberSequenceKeypoint.new(1, 1) }) }, beam)
local cap = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 378), Size = UDim2.fromOffset(240, 18), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, pv)
A(cap, "TextColor3")
mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 396), Size = UDim2.fromOffset(240, 16), Font = Enum.Font.Gotham, Text = "нажми на часть тела — аим целится туда", TextSize = 11, TextColor3 = C(110, 118, 114), TextXAlignment = Enum.TextXAlignment.Left }, pv)

local function setBone(n, anim)
	S.aimBone = n
	local z = ZONES[n]
	local t = anim and .45 or 0
	tw(dot, t, { Position = UDim2.fromOffset(z[5].X, z[5].Y) })
	tw(sel, t, { Position = UDim2.fromOffset(z[1] - 3, z[2] - 3), Size = UDim2.fromOffset(z[3] + 6, z[4] + 6) })
	tw(beam, t, { Position = UDim2.fromOffset(125, z[5].Y) })
	cap.Text = "Цель: " .. z[6]
end
for n, z in pairs(ZONES) do
	local b = mk("TextButton", { Position = UDim2.fromOffset(z[1], z[2]), Size = UDim2.fromOffset(z[3], z[4]), BackgroundTransparency = 1, Text = "", ZIndex = 9 }, st)
	b.MouseEnter:Connect(function() hov.Position = b.Position hov.Size = b.Size hov.Visible = true end)
	b.MouseLeave:Connect(function() hov.Visible = false end)
	b.MouseButton1Click:Connect(function() setBone(n, true) end)
end
setBone("Head", false)

local function pvUpdate(t)
	local bc, sc = col(S.boxColor), col(S.skelColor)
	for _, b in ipairs(body) do
		if S.chams then b.f.BackgroundColor3 = col(S.chamsColor) b.f.BackgroundTransparency = .2
		else b.f.BackgroundColor3 = GRAY b.f.BackgroundTransparency = 0 end
		b.s.Enabled = S.glow
		if S.glow then b.s.Color = col(S.glowColor) b.s.Thickness = 2.5 + math.sin(t * 3) * 1.2 end
	end
	pvB2.Visible = S.box and S.boxMode == "2D" pvB2s.Color = bc
	for _, l in ipairs(pvB3) do l.Visible = S.box and S.boxMode == "3D" l.BackgroundColor3 = bc end
	pvName.Visible = S.name
	pvDist.Visible = S.dist
	local hp = .65 + math.sin(t * 1.3) * .3
	pvHb.Visible = S.health pvHf.Size = UDim2.fromScale(1, hp) pvHf.BackgroundColor3 = Color3.fromHSV(hp * .33, .8, 1)
	pvTr.Visible = S.tracers pvTr.BackgroundColor3 = bc
	for _, l in ipairs(pvSk) do l.Visible = S.skeleton l.BackgroundColor3 = sc end
	for k, f in pairs(pvT) do f.Visible = S.trail f.BackgroundColor3 = col(S.trailColor, k * .03) end
	for kind, list in pairs(pvW) do
		local vis = S.wings == kind
		local sp = kind == "Ангел" and 3 or 4
		for _, w in ipairs(list) do
			w.f.Visible = vis
			if vis then w.f.Rotation = w.side * (w.a + math.sin(t * sp) * 10 * (1 + w.i * .08)) end
		end
	end
	local r = math.clamp(S.fov * 1.1, 50, 235)
	pvRing.Visible = S.aim and S.aimFov
	pvRing.Size = UDim2.fromOffset(r, r)
	dotGlow.Thickness = 5 + math.sin(t * 4) * 2
	for _, p in ipairs(pvP) do p.f.Position = UDim2.fromOffset(p.x + math.sin(t * .8 + p.ph) * 10, 340 - (t * p.sp + p.ph * 30) % 340) end
	psweep.Position = UDim2.fromOffset(0, (t * 70) % 420 - 60)
	local k = (t * .8) % 1
	ringF.Size = UDim2.fromOffset(110 + 90 * k, 20 + 22 * k) ringS.Transparency = .2 + .8 * k
	reactor.BackgroundTransparency = .1 + .35 * (math.sin(t * 3) * .5 + .5)
	vl.BackgroundTransparency = .15 + .4 * (math.sin(t * 2) * .5 + .5)
	liveDot.BackgroundTransparency = .5 * (math.sin(t * 4) * .5 + .5)
	local dp = dot.Position
	for i, rg in ipairs(rip) do
		local kk = (t * .9 + i * .5) % 1
		rg.f.Position = dp
		rg.f.Size = UDim2.fromOffset(12 + 46 * kk, 12 + 46 * kk)
		rg.s.Transparency = .2 + .8 * kk
	end
	local hs = 26 + 6 * math.sin(t * 4)
	halo.Size = UDim2.fromOffset(hs, hs)
	stGrad.Rotation = (t * 40) % 360
	stGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, C(35, 40, 38)), ColorSequenceKeypoint.new(1, accent) })
end

------------------------------------------------------------------ СТРАНИЦЫ
local pESP, pAim, pMove, pExtra, pCfg = newPage(), newPage(), newPage(), newPage(), newPage()

header(pESP, "Бокс")
toggle(pESP, "ESP Box", "box")
choice(pESP, "Тип бокса", "boxMode", { "2D", "3D" })
colors(pESP, "Цвет бокса", "boxColor")
header(pESP, "Тело")
toggle(pESP, "Ник игрока", "name")
toggle(pESP, "Skeleton", "skeleton")
colors(pESP, "Цвет skeleton", "skelColor")
toggle(pESP, "Chams", "chams")
colors(pESP, "Цвет chams", "chamsColor")
toggle(pESP, "Glow", "glow")
colors(pESP, "Цвет glow", "glowColor")
header(pESP, "Дополнительно")
toggle(pESP, "Полоса HP", "health")
toggle(pESP, "Дистанция", "dist")
toggle(pESP, "Трейсеры", "tracers")
toggle(pESP, "Не трогать тиммейтов (аим, ESP, chams)", "team")

header(pAim, "Аимбот")
toggle(pAim, "Aimbot", "aim")
toggle(pAim, "FOV круг", "aimFov")
slider(pAim, "Размер FOV", "fov", 30, 400, 0)
choice(pAim, "Режим", "aimMode", { "Плавный", "Резкий" })
slider(pAim, "Скорость наведения", "speed", 1, 30, 0)
choice(pAim, "Активация", "aimKey", { "ПКМ", "Всегда" })
note(pAim, "Часть тела выбирается в превью справа. Через стены аим не целится.")

header(pMove, "Движение")
toggle(pMove, "Fly", "fly", function(v) if not v then stopFly() end end)
slider(pMove, "Скорость полёта", "flySpeed", 10, 200, 0)
toggle(pMove, "Noclip", "noclip")
header(pMove, "Мир и камера")
toggle(pMove, "Fullbright", "fullbright", fullbright)
toggle(pMove, "Свой FOV камеры", "camFov")
slider(pMove, "FOV камеры", "camFovV", 60, 120, 0)
toggle(pMove, "Прицел", "cross")
header(pMove, "FPS")
toggle(pMove, "Счётчик FPS", "fpsShow")
toggle(pMove, "Показывать свой FPS в счётчике", "fpsFake")
slider(pMove, "Свой FPS", "fps", 30, 999, 0, function() applyFpsCap() end)
button(pMove, "Применить лимит", applyFpsCap)

header(pExtra, "Крылья")
choice(pExtra, "Тип", "wings", { "Нет", "Ангел", "Демон" }, buildWings)
header(pExtra, "Трейл")
toggle(pExtra, "Trail", "trail", function(v) if v then buildTrail() else clearTrail() end end)
colors(pExtra, "Цвет трейла", "trailColor")

local unload
header(pCfg, "Меню")
slider(pCfg, "Прозрачность", "alpha", 0, .75, 2, applyAlpha)
slider(pCfg, "Размер", "scale", .4, 1.2, 2, applyScale)
local setHueSlider
do
	local r = row(pCfg, 58)
	lbl(r, "Цвет меню", 12, 6, 280)
	local hold = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 24) }, r)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, hold)
	for _, n in ipairs(COLORS) do
		if CMAP[n] and n ~= "Белый" then
			local b = mk("TextButton", { Text = "", Size = UDim2.fromOffset(24, 24), BackgroundColor3 = CMAP[n], AutoButtonColor = false }, hold)
			rc(b)
			b.MouseButton1Click:Connect(function()
				local h = CMAP[n]:ToHSV()
				setHue(h)
				if setHueSlider then setHueSlider(h) end
			end)
		end
	end
end
setHueSlider = slider(pCfg, "Оттенок", "hue", 0, 1, 2, setHue)
note(pCfg, "RightShift — открыть / закрыть. Иконку Lx можно перетаскивать.")
button(pCfg, "Выгрузить скрипт", function() unload() end)

-- вкладки
-- ТЕЛЕПОРТ
local pTP
do
pTP = newPage()
local toastL = mk("TextLabel", { AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -30), Size = UDim2.fromOffset(260, 30), BackgroundColor3 = C(12, 13, 12), BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.Code, TextSize = 13, TextColor3 = C(235, 240, 237), TextTransparency = 1, ZIndex = 50 }, gui)
local toastSt = A(mk("UIStroke", { Thickness = 1, Transparency = 1 }, toastL), "Color")
local toastId = 0
local function toast(text)
	toastId += 1
	local id = toastId
	toastL.Text = text
	tw(toastL, .2, { TextTransparency = 0, BackgroundTransparency = .1 })
	tw(toastSt, .2, { Transparency = 0 })
	task.delay(1.8, function()
		if id == toastId then
			tw(toastL, .3, { TextTransparency = 1, BackgroundTransparency = 1 })
			tw(toastSt, .3, { Transparency = 1 })
		end
	end)
end

local function tpTo(plr)
	local ch = plr.Character
	local th = ch and ch:FindFirstChild("HumanoidRootPart")
	local hrp = hrpHum()
	if not th or not hrp then toast("цель недоступна") return end
	local goal
	if S.tpPos == "Над" then
		goal = CFrame.new(th.Position + Vector3.new(0, 5, 0))
	else
		local off = S.tpPos == "Рядом" and Vector3.new(4, 0, 0) or Vector3.new(0, 0, 3.5)
		goal = CFrame.lookAt((th.CFrame * CFrame.new(off)).Position, th.Position)
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	if S.tpSmooth then
		hrp.Anchored = true
		local tn = TweenService:Create(hrp, TweenInfo.new(S.tpTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = goal })
		tn.Completed:Connect(function() hrp.Anchored = false end)
		tn:Play()
	else
		hrp.CFrame = goal
	end
	toast("тп → " .. plr.Name)
end

local function others()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hm = p ~= lp and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hm and hm.Health > 0 and p.Character:FindFirstChild("HumanoidRootPart") then list[#list + 1] = p end
	end
	return list
end

header(pTP, "Телепорт")
choice(pTP, "Позиция относительно цели", "tpPos", { "Позади", "Рядом", "Над" })
toggle(pTP, "Плавный телепорт", "tpSmooth")
slider(pTP, "Время полёта (сек)", "tpTime", .1, 2, 1)
button(pTP, "К ближайшему игроку", function()
	local hrp = hrpHum()
	local best, bd
	for _, p in ipairs(others()) do
		local d = hrp and (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
		if not bd or d < bd then best, bd = p, d end
	end
	if best then tpTo(best) else toast("никого нет рядом") end
end)
button(pTP, "К случайному игроку", function()
	local l = others()
	if #l > 0 then tpTo(l[math.random(#l)]) else toast("никого нет") end
end)
do
	local r = row(pTP, 42)
	local tb2 = mk("TextBox", { Position = UDim2.fromOffset(10, 7), Size = UDim2.new(1, -90, 0, 28), BackgroundColor3 = C(14, 16, 15), Text = "", PlaceholderText = "ник игрока", PlaceholderColor3 = C(90, 97, 94), ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 14, TextColor3 = C(236, 240, 237), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, r)
	rc(tb2, 5)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 8) }, tb2)
	local go = mk("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(64, 28), Text = "TP", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C(8, 10, 9), AutoButtonColor = false, BorderSizePixel = 0 }, r)
	A(go, "BackgroundColor3") rc(go, 5)
	go.MouseButton1Click:Connect(function()
		local q = tb2.Text:lower()
		if q == "" then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and (p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then tpTo(p) return end
		end
		toast("игрок не найден")
	end)
end
header(pTP, "Игроки")
local holder = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 9999 }, pTP)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
local function rebuild()
	for _, c in ipairs(holder:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
	local hrp = hrpHum()
	local n = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			n += 1
			local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C(20, 23, 22), BorderSizePixel = 0, LayoutOrder = n }, holder)
			rc(r, 6)
			mk("UIStroke", { Thickness = 1, Color = C(36, 42, 39) }, r)
			local nm = plr.DisplayName ~= plr.Name and (plr.DisplayName .. "  @" .. plr.Name) or plr.Name
			lbl(r, nm, 12, 10, 200)
			local th = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local dtxt = (hrp and th) and (math.floor((th.Position - hrp.Position).Magnitude) .. "m") or "-"
			mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -76, 0, 10), Size = UDim2.fromOffset(60, 18), Font = Enum.Font.Code, Text = dtxt, TextSize = 12, TextColor3 = C(120, 128, 124), TextXAlignment = Enum.TextXAlignment.Right }, r)
			local b = mk("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(56, 26), Text = "TP", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C(8, 10, 9), AutoButtonColor = false, BorderSizePixel = 0 }, r)
			A(b, "BackgroundColor3") rc(b, 5)
			b.MouseButton1Click:Connect(function() tpTo(plr) end)
		end
	end
	if n == 0 then
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.Code, Text = "других игроков нет", TextSize = 13, TextColor3 = C(110, 118, 114) }, holder)
	end
end
on(Players.PlayerAdded, function() task.defer(rebuild) end)
on(Players.PlayerRemoving, function() task.defer(rebuild) end)
rebuild()
-- список обновить вручную: кнопка ниже заголовка не нужна, но пусть будет
button(pTP, "Обновить список", rebuild)
end

local tabs = { { "ESP", pESP }, { "Aim", pAim }, { "Move", pMove }, { "TP", pTP }, { "Extra", pExtra }, { "Config", pCfg } }
local tabB = {}
local function pick(n)
	for _, t in ipairs(tabs) do
		local on_ = t[1] == n
		t[2].Visible = on_
		local b = tabB[t[1]]
		tw(b.bar, .2, { Size = UDim2.fromOffset(3, on_ and 20 or 0) })
		tw(b.btn, .2, { TextColor3 = on_ and C(240, 245, 242) or C(125, 133, 129), BackgroundTransparency = on_ and .75 or 1 })
	end
end
for i, t in ipairs(tabs) do
	local btn = mk("TextButton", { Position = UDim2.fromOffset(0, 12 + (i - 1) * 36), Size = UDim2.fromOffset(140, 32), BackgroundTransparency = 1, Text = t[1], Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BorderSizePixel = 0 }, side)
	A(btn, "BackgroundColor3")
	mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, btn)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 20) }, btn)
	local bar = A(mk("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(3, 0), BorderSizePixel = 0 }, btn), "BackgroundColor3")
	tabB[t[1]] = { btn = btn, bar = bar }
	btn.MouseButton1Click:Connect(function() pick(t[1]) end)
end
pick("ESP")
applyAlpha()

------------------------------------------------------------------ ИКОНКА + ОТКРЫТИЕ
icon = mk("TextButton", { Name = "icon", Position = UDim2.new(0, 26, .5, -27), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = C(13, 15, 14), Text = "Lx", Font = Enum.Font.GothamBlack, TextSize = 20, AutoButtonColor = false, Visible = false }, gui)
A(icon, "TextColor3") rc(icon)
A(mk("UIStroke", { Thickness = 2 }, icon), "Color")
local isc = mk("UIScale", { Scale = 0 }, icon)

isOpen = false
setOpen = function(v)
	isOpen = v
	if v then win.Visible = true end
	tw(openF, .4, { Value = v and 1 or .85 }, v and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
	tw(win, .3, { GroupTransparency = v and 0 or 1 })
	if not v then task.delay(.35, function() if not isOpen then win.Visible = false end end) end
end
drag(icon, icon, function()
	tw(isc, .1, { Scale = .88 })
	task.delay(.1, function() tw(isc, .25, { Scale = 1 }, Enum.EasingStyle.Back) end)
	setOpen(not isOpen)
end)
closeB.MouseButton1Click:Connect(function() setOpen(false) end)
on(UIS.InputBegan, function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift and icon.Visible then setOpen(not isOpen) end
end)

------------------------------------------------------------------ ГЛАВНЫЙ ЦИКЛ
on(RunService.RenderStepped, function(dt)
	local t = tick()
	cam = Workspace.CurrentCamera
	for plr, o in pairs(ESP) do updEsp(plr, o, t) end

	local m = aimCenter()
	fovRing.Visible = S.aim and S.aimFov
	if fovRing.Visible then
		fovRing.Size = UDim2.fromOffset(S.fov * 2, S.fov * 2)
		fovRing.Position = UDim2.fromOffset(m.X, m.Y)
	end

	flyStep()
	crossStep()
	wingStep(t)
	trailStep()

	fpsLbl.Visible = S.fpsShow
	fa += dt fc += 1
	if fa >= .25 then
		fpsLbl.Text = ("FPS %d"):format(S.fpsFake and S.fps or math.floor(fc / fa + .5))
		fa, fc = 0, 0
	end

	if isOpen then
		wsg.Rotation = (t * 50) % 360
		wsg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, C(40, 44, 42)), ColorSequenceKeypoint.new(1, accent) })
		pvUpdate(t)
	end
end)

unload = function()
	for _, c in ipairs(conns) do c:Disconnect() end
	pcall(function() RunService:UnbindFromRenderStep("lx_aim") end)
	clearWings() clearTrail() stopFly() fullbright(false)
	pcall(function() keyBlur:Destroy() end)
	hlFolder:Destroy() espGui:Destroy() gui:Destroy()
end

end

local ok, err = xpcall(__lx_main, function(e) return tostring(e) end)
if not ok then
	warn("[luxxs] " .. tostring(err))
	pcall(function()
		local g = Instance.new("ScreenGui") g.Name = "lx_err" g.ResetOnSpawn = false g.Parent = GUIP
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -20, 0, 120) t.Position = UDim2.fromOffset(10, 10)
		t.BackgroundColor3 = Color3.fromRGB(30, 10, 10) t.TextColor3 = Color3.fromRGB(255, 200, 200)
		t.TextWrapped = true t.TextSize = 14 t.Font = Enum.Font.Code
		t.Text = "luxxs error:\n" .. tostring(err)
		t.Parent = g
		task.delay(25, function() g:Destroy() end)
	end)
end
