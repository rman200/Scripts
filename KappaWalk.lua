--[[

    KappaWalk.lua

    Authors: RMAN
    Credits: All the mighty guys before us who copy/pasted stuff + edited
]]


require 'utils'

function table.contains(t, what, member)
    for i, v in pairs(t) do
        if member and v[member] == what or v == what then 
            return i, v 
        end
    end
end
delayedActions = {}
function DelayAction(func, delay, args)
    if not delayedActionsExecuter then
            function delayedActionsExecuter()
                    for i, funcs in pairs(delayedActions) do
                            if i <= RiotClock.time then
                                    for _, f in ipairs(funcs) do 
                                            f.func(unpack(f.args or {})) 
                                    end
                                    delayedActions[i] = nil
                            end
                    end
            end
            AddEvent(Events.OnTick , delayedActionsExecuter)                
    end
    local time = RiotClock.time + (delay or 0)
    if delayedActions[time] then 
            table.insert(delayedActions[time], { func = func, args = args })
    else 
            delayedActions[time] = { { func = func, args = args } }
    end
end

function GetMousePos()
	return pwHud.hudManager.activeVirtualCursorPos
end

local function class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

local lengthOf, huge, pi,  floor, ceil, sqrt, max, min = math.lengthOf, math.huge , math.pi , math.floor , math.ceil , math.sqrt , math.max , math.min 
local abs, deg, acos, atan = math.abs , math.deg , math.acos , math.atan 
local insert, contains, remove, sort = table.insert , table.contains , table.remove , table.sort
local _HERO, _MINION, _TURRET = GameObjectType.AIHeroClient , GameObjectType.obj_AI_Minion , GameObjectType.obj_AI_Turret
local TEAM_JUNGLE = 300
local TEAM_ALLY = myHero.team
local TEAM_ENEMY = TEAM_JUNGLE - TEAM_ALLY

GlobalKeys = {
	ComboKey = 0x20,
	MixedKey = 0x43,
	LaneClearKey = 0x56,
	LastHitKey = 0x58
}
OrbwalkingMode = class()

function OrbwalkingMode:__init(args)
	self.Name = args.Name
    self.ModeBehaviour = args.OrbwalkBehaviour
    self.GetTargetImplementation = args.TargetDelegate
    self.MenuItem = args.Key    
    --key.Activate() --activate menu
    self.Active = function() return IsKeyDown(args.Key) end
end

function OrbwalkingMode:GetTarget()
	if self.GetTargetImplementation then
		return self.GetTargetImplementation()
	end
end

function OrbwalkingMode:Execute()
	if self.ModeBehaviour then
		self.ModeBehaviour()
	end
end

Orbwalker = class()


function Orbwalker:__init()
	PrintChat("KappaWalk Initialized. Have Fun!")
    self.AttackingEnabled = true
	self.LastTarget = nil
	self.MovingEnabled = true
	self.WindUpTime = 0

	self.OrbwalkingMode = {
		["None"]      = "None",
		["Combo"]     = "Combo",
		["Mixed"]     = "Mixed",
		["Laneclear"] = "Laneclear",
		["Lasthit"]   = "Lasthit",		
		["Custom"]    = "Custom"
	}

	self.specialAttacks =
	{
		"caitlynheadshotmissile",
		"goldcardpreattack",
		"redcardpreattack",
		"bluecardpreattack",
		"viktorqbuff",
		"quinnwenhanced",
		"renektonexecute",
		"renektonsuperexecute",
		"trundleq",
		"xenzhaothrust",
		"xenzhaothrust2",
		"xenzhaothrust3",
		"frostarrow",
		"garenqattack",
		"kennenmegaproc",
		"masteryidoublestrike",
		"mordekaiserqattack",
		"reksaiq",
		"warwickq",
		"vaynecondemnmissile",
		"masochismattack"
	}

	self.attackResets =
	{
		"asheq",
		"dariusnoxiantacticsonh",
		"garenq",
		"gravesmove",
		"jaxempowertwo",
		"jaycehypercharge",
		"leonashieldofdaybreak",
		"luciane",
		"monkeykingdoubleattack",
		"mordekaisermaceofspades",
		"nasusq",
		"nautiluspiercinggaze",
		"netherblade",
		"gangplankqwrapper",
		"powerfist",
		"renektonpreexecute",
		"rengarq",
		"shyvanadoubleattack",
		"sivirw",
		"takedown",
		"talonnoxiandiplomacy",
		"trundletrollsmash",
		"vaynetumble",
		"vie",
		"volibearq",
		"xenzhaocombotarget",
		"yorickspectral",
		"reksaiq",
		"itemtitanichydracleave",
		"masochism",
		"illaoiw",
		"elisespiderw",
		"fiorae",
		"meditate",
		"sejuaninorthernwinds",
		"camilleq",
		"camilleq2",
		"vorpalspikes"
	}

	self.projectilespeeds = {["Velkoz"]= 2000,["TeemoMushroom"] = math.huge,["TestCubeRender"] = math.huge ,["Xerath"] = 2000.0000 ,["Kassadin"] = math.huge ,["Rengar"] = math.huge ,["Thresh"] = 1000.0000 ,["Ziggs"] = 1500.0000 ,["ZyraPassive"] = 1500.0000 ,["ZyraThornPlant"] = 1500.0000 ,["KogMaw"] = 1800.0000 ,["HeimerTBlue"] = 1599.3999 ,["EliseSpider"] = 500.0000 ,["Skarner"] = 500.0000 ,["ChaosNexus"] = 500.0000 ,["Katarina"] = 467.0000 ,["Riven"] = 347.79999 ,["SightWard"] = 347.79999 ,["HeimerTYellow"] = 1599.3999 ,["Ashe"] = 2500.0000 ,["VisionWard"] = 2000.0000 ,["TT_NGolem2"] = math.huge ,["ThreshLantern"] = math.huge ,["TT_Spiderboss"] = math.huge ,["OrderNexus"] = math.huge ,["Soraka"] = 1000.0000 ,["Jinx"] = 2750.0000 ,["TestCubeRenderwCollision"] = 2750.0000 ,["Red_Minion_Wizard"] = 650.0000 ,["JarvanIV"] = 20.0000 ,["Blue_Minion_Wizard"] = 650.0000 ,["TT_ChaosTurret2"] = 1200.0000 ,["TT_ChaosTurret3"] = 1200.0000 ,["TT_ChaosTurret1"] = 1200.0000 ,["ChaosTurretGiant"] = 1200.0000 ,["Dragon"] = 1200.0000 ,["LuluSnowman"] = 1200.0000 ,["Worm"] = 1200.0000 ,["ChaosTurretWorm"] = 1200.0000 ,["TT_ChaosInhibitor"] = 1200.0000 ,["ChaosTurretNormal"] = 1200.0000 ,["AncientGolem"] = 500.0000 ,["ZyraGraspingPlant"] = 500.0000 ,["HA_AP_OrderTurret3"] = 1200.0000 ,["HA_AP_OrderTurret2"] = 1200.0000 ,["Tryndamere"] = 347.79999 ,["OrderTurretNormal2"] = 1200.0000 ,["Singed"] = 700.0000 ,["OrderInhibitor"] = 700.0000 ,["Diana"] = 347.79999 ,["HA_FB_HealthRelic"] = 347.79999 ,["TT_OrderInhibitor"] = 347.79999 ,["GreatWraith"] = 750.0000 ,["Yasuo"] = 347.79999 ,["OrderTurretDragon"] = 1200.0000 ,["OrderTurretNormal"] = 1200.0000 ,["LizardElder"] = 500.0000 ,["HA_AP_ChaosTurret"] = 1200.0000 ,["Ahri"] = 1750.0000 ,["Lulu"] = 1450.0000 ,["ChaosInhibitor"] = 1450.0000 ,["HA_AP_ChaosTurret3"] = 1200.0000 ,["HA_AP_ChaosTurret2"] = 1200.0000 ,["ChaosTurretWorm2"] = 1200.0000 ,["TT_OrderTurret1"] = 1200.0000 ,["TT_OrderTurret2"] = 1200.0000 ,["TT_OrderTurret3"] = 1200.0000 ,["LuluFaerie"] = 1200.0000 ,["HA_AP_OrderTurret"] = 1200.0000 ,["OrderTurretAngel"] = 1200.0000 ,["YellowTrinketUpgrade"] = 1200.0000 ,["MasterYi"] = math.huge ,["Lissandra"] = 2000.0000 ,["ARAMOrderTurretNexus"] = 1200.0000 ,["Draven"] = 1700.0000 ,["FiddleSticks"] = 1750.0000 ,["SmallGolem"] = math.huge ,["ARAMOrderTurretFront"] = 1200.0000 ,["ChaosTurretTutorial"] = 1200.0000 ,["NasusUlt"] = 1200.0000 ,["Maokai"] = math.huge ,["Wraith"] = 750.0000 ,["Wolf"] = math.huge ,["Sivir"] = 1750.0000 ,["Corki"] = 2000.0000 ,["Janna"] = 1200.0000 ,["Nasus"] = math.huge ,["Golem"] = math.huge ,["ARAMChaosTurretFront"] = 1200.0000 ,["ARAMOrderTurretInhib"] = 1200.0000 ,["LeeSin"] = math.huge ,["HA_AP_ChaosTurretTutorial"] = 1200.0000 ,["GiantWolf"] = math.huge ,["HA_AP_OrderTurretTutorial"] = 1200.0000 ,["YoungLizard"] = 750.0000 ,["Jax"] = 400.0000 ,["LesserWraith"] = math.huge ,["Blitzcrank"] = math.huge ,["ARAMChaosTurretInhib"] = 1200.0000 ,["Shen"] = 400.0000 ,["Nocturne"] = math.huge ,["Sona"] = 1500.0000 ,["ARAMChaosTurretNexus"] = 1200.0000 ,["YellowTrinket"] = 1200.0000 ,["OrderTurretTutorial"] = 1200.0000 ,["Caitlyn"] = 2500.0000 ,["Trundle"] = 347.79999 ,["Malphite"] = 1000.0000 ,["Mordekaiser"] = math.huge ,["ZyraSeed"] = math.huge ,["Vi"] = 1000.0000 ,["Tutorial_Red_Minion_Wizard"] = 650.0000 ,["Renekton"] = math.huge ,["Anivia"] = 1400.0000 ,["Fizz"] = math.huge ,["Heimerdinger"] = 1500.0000 ,["Evelynn"] = 467.0000 ,["Rumble"] = 347.79999 ,["Leblanc"] = 1700.0000 ,["Darius"] = math.huge ,["OlafAxe"] = math.huge ,["Viktor"] = 2300.0000 ,["XinZhao"] = 20.0000 ,["Orianna"] = 1450.0000 ,["Vladimir"] = 1400.0000 ,["Nidalee"] = 1750.0000 ,["Tutorial_Red_Minion_Basic"] = math.huge ,["ZedShadow"] = 467.0000 ,["Syndra"] = 1800.0000 ,["Zac"] = 1000.0000 ,["Olaf"] = 347.79999 ,["Veigar"] = 1100.0000 ,["Twitch"] = 2500.0000 ,["Alistar"] = math.huge ,["Akali"] = 467.0000 ,["Urgot"] = 1300.0000 ,["Leona"] = 347.79999 ,["Talon"] = math.huge ,["Karma"] = 1500.0000 ,["Jayce"] = 347.79999 ,["Galio"] = 1000.0000 ,["Shaco"] = math.huge ,["Taric"] = math.huge ,["TwistedFate"] = 1500.0000 ,["Varus"] = 2000.0000 ,["Garen"] = 347.79999 ,["Swain"] = 1600.0000 ,["Vayne"] = 2000.0000 ,["Fiora"] = 467.0000 ,["Quinn"] = 2000.0000 ,["Kayle"] = math.huge ,["Blue_Minion_Basic"] = math.huge ,["Brand"] = 2000.0000 ,["Teemo"] = 1300.0000 ,["Amumu"] = 500.0000 ,["Annie"] = 1200.0000 ,["Odin_Blue_Minion_caster"] = 1200.0000 ,["Elise"] = 1600.0000 ,["Nami"] = 1500.0000 ,["Poppy"] = 500.0000 ,["AniviaEgg"] = 500.0000 ,["Tristana"] = 2250.0000 ,["Graves"] = 3000.0000 ,["Morgana"] = 1600.0000 ,["Gragas"] = math.huge ,["MissFortune"] = 2000.0000 ,["Warwick"] = math.huge ,["Cassiopeia"] = 1200.0000 ,["Tutorial_Blue_Minion_Wizard"] = 650.0000 ,["DrMundo"] = math.huge ,["Volibear"] = 467.0000 ,["Irelia"] = 467.0000 ,["Odin_Red_Minion_Caster"] = 650.0000 ,["Lucian"] = 2800.0000 ,["Yorick"] = math.huge ,["RammusPB"] = math.huge ,["Red_Minion_Basic"] = math.huge ,["Udyr"] = 467.0000 ,["MonkeyKing"] = 20.0000 ,["Tutorial_Blue_Minion_Basic"] = math.huge ,["Kennen"] = 1600.0000 ,["Nunu"] = 500.0000 ,["Ryze"] = 2400.0000 ,["Zed"] = 467.0000 ,["Nautilus"] = 1000.0000 ,["Gangplank"] = 1000.0000 ,["Lux"] = 1600.0000 ,["Sejuani"] = 500.0000 ,["Ezreal"] = 2000.0000 ,["OdinNeutralGuardian"] = 1800.0000 ,["Khazix"] = 500.0000 ,["Sion"] = math.huge ,["Aatrox"] = 347.79999 ,["Hecarim"] = 500.0000 ,["Pantheon"] = 20.0000 ,["Shyvana"] = 467.0000 ,["Zyra"] = 1700.0000 ,["Karthus"] = 1200.0000 ,["Rammus"] = math.huge ,["Zilean"] = 1200.0000 ,["Chogath"] = 500.0000 ,["Malzahar"] = 2000.0000 ,["YorickRavenousGhoul"] = 347.79999 ,["YorickSpectralGhoul"] = 347.79999 ,["JinxMine"] = 347.79999 ,["YorickDecayedGhoul"] = 347.79999 ,["XerathArcaneBarrageLauncher"] = 347.79999 ,["Odin_SOG_Order_Crystal"] = 347.79999 ,["TestCube"] = 347.79999 ,["ShyvanaDragon"] = math.huge ,["FizzBait"] = math.huge ,["Blue_Minion_MechMelee"] = math.huge ,["OdinQuestBuff"] = math.huge ,["TT_Buffplat_L"] = math.huge ,["TT_Buffplat_R"] = math.huge ,["KogMawDead"] = math.huge ,["TempMovableChar"] = math.huge ,["Lizard"] = 500.0000 ,["GolemOdin"] = math.huge ,["OdinOpeningBarrier"] = math.huge ,["TT_ChaosTurret4"] = 500.0000 ,["TT_Flytrap_A"] = 500.0000 ,["TT_NWolf"] = math.huge ,["OdinShieldRelic"] = math.huge ,["LuluSquill"] = math.huge ,["redDragon"] = math.huge ,["MonkeyKingClone"] = math.huge ,["Odin_skeleton"] = math.huge ,["OdinChaosTurretShrine"] = 500.0000 ,["Cassiopeia_Death"] = 500.0000 ,["OdinCenterRelic"] = 500.0000 ,["OdinRedSuperminion"] = math.huge ,["JarvanIVWall"] = math.huge ,["ARAMOrderNexus"] = math.huge ,["Red_Minion_MechCannon"] = 1200.0000 ,["OdinBlueSuperminion"] = math.huge ,["SyndraOrbs"] = math.huge ,["LuluKitty"] = math.huge ,["SwainNoBird"] = math.huge ,["LuluLadybug"] = math.huge ,["CaitlynTrap"] = math.huge ,["TT_Shroom_A"] = math.huge ,["ARAMChaosTurretShrine"] = 500.0000 ,["Odin_Windmill_Propellers"] = 500.0000 ,["TT_NWolf2"] = math.huge ,["OdinMinionGraveyardPortal"] = math.huge ,["SwainBeam"] = math.huge ,["Summoner_Rider_Order"] = math.huge ,["TT_Relic"] = math.huge ,["odin_lifts_crystal"] = math.huge ,["OdinOrderTurretShrine"] = 500.0000 ,["SpellBook1"] = 500.0000 ,["Blue_Minion_MechCannon"] = 1200.0000 ,["TT_ChaosInhibitor_D"] = 1200.0000 ,["Odin_SoG_Chaos"] = 1200.0000 ,["TrundleWall"] = 1200.0000 ,["HA_AP_HealthRelic"] = 1200.0000 ,["OrderTurretShrine"] = 500.0000 ,["OriannaBall"] = 500.0000 ,["ChaosTurretShrine"] = 500.0000 ,["LuluCupcake"] = 500.0000 ,["HA_AP_ChaosTurretShrine"] = 500.0000 ,["TT_NWraith2"] = 750.0000 ,["TT_Tree_A"] = 750.0000 ,["SummonerBeacon"] = 750.0000 ,["Odin_Drill"] = 750.0000 ,["TT_NGolem"] = math.huge ,["AramSpeedShrine"] = math.huge ,["OriannaNoBall"] = math.huge ,["Odin_Minecart"] = math.huge ,["Summoner_Rider_Chaos"] = math.huge ,["OdinSpeedShrine"] = math.huge ,["TT_SpeedShrine"] = math.huge ,["odin_lifts_buckets"] = math.huge ,["OdinRockSaw"] = math.huge ,["OdinMinionSpawnPortal"] = math.huge ,["SyndraSphere"] = math.huge ,["Red_Minion_MechMelee"] = math.huge ,["SwainRaven"] = math.huge ,["crystal_platform"] = math.huge ,["MaokaiSproutling"] = math.huge ,["Urf"] = math.huge ,["TestCubeRender10Vision"] = math.huge ,["MalzaharVoidling"] = 500.0000 ,["GhostWard"] = 500.0000 ,["MonkeyKingFlying"] = 500.0000 ,["LuluPig"] = 500.0000 ,["AniviaIceBlock"] = 500.0000 ,["TT_OrderInhibitor_D"] = 500.0000 ,["Odin_SoG_Order"] = 500.0000 ,["RammusDBC"] = 500.0000 ,["FizzShark"] = 500.0000 ,["LuluDragon"] = 500.0000 ,["OdinTestCubeRender"] = 500.0000 ,["TT_Tree1"] = 500.0000 ,["ARAMOrderTurretShrine"] = 500.0000 ,["Odin_Windmill_Gears"] = 500.0000 ,["ARAMChaosNexus"] = 500.0000 ,["TT_NWraith"] = 750.0000 ,["TT_OrderTurret4"] = 500.0000 ,["Odin_SOG_Chaos_Crystal"] = 500.0000 ,["OdinQuestIndicator"] = 500.0000 ,["JarvanIVStandard"] = 500.0000 ,["TT_DummyPusher"] = 500.0000 ,["OdinClaw"] = 500.0000 ,["EliseSpiderling"] = 2000.0000 ,["QuinnValor"] = math.huge ,["UdyrTigerUlt"] = math.huge ,["UdyrTurtleUlt"] = math.huge ,["UdyrUlt"] = math.huge ,["UdyrPhoenixUlt"] = math.huge ,["ShacoBox"] = 1500.0000 ,["HA_AP_Poro"] = 1500.0000 ,["AnnieTibbers"] = math.huge ,["UdyrPhoenix"] = math.huge ,["UdyrTurtle"] = math.huge ,["UdyrTiger"] = math.huge ,["HA_AP_OrderShrineTurret"] = 500.0000 ,["HA_AP_Chains_Long"] = 500.0000 ,["HA_AP_BridgeLaneStatue"] = 500.0000 ,["HA_AP_ChaosTurretRubble"] = 500.0000 ,["HA_AP_PoroSpawner"] = 500.0000 ,["HA_AP_Cutaway"] = 500.0000 ,["HA_AP_Chains"] = 500.0000 ,["ChaosInhibitor_D"] = 500.0000 ,["ZacRebirthBloblet"] = 500.0000 ,["OrderInhibitor_D"] = 500.0000 ,["Nidalee_Spear"] = 500.0000 ,["Nidalee_Cougar"] = 500.0000 ,["TT_Buffplat_Chain"] = 500.0000 ,["WriggleLantern"] = 500.0000 ,["TwistedLizardElder"] = 500.0000 ,["RabidWolf"] = math.huge ,["HeimerTGreen"] = 1599.3999 ,["HeimerTRed"] = 1599.3999 ,["ViktorFF"] = 1599.3999 ,["TwistedGolem"] = math.huge ,["TwistedSmallWolf"] = math.huge ,["TwistedGiantWolf"] = math.huge ,["TwistedTinyWraith"] = 750.0000 ,["TwistedBlueWraith"] = 750.0000 ,["TwistedYoungLizard"] = 750.0000 ,["Red_Minion_Melee"] = math.huge ,["Blue_Minion_Melee"] = math.huge ,["Blue_Minion_Healer"] = 1000.0000 ,["Ghast"] = 750.0000 ,["blueDragon"] = 800.0000 ,["Red_Minion_MechRange"] = 3000, ["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_OrderMinionMelee"] = math.huge, ["SRU_ChaosMinionMelee"] = math.huge, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"]  = 1200, ["SRUAP_Turret_Chaos2"]  = 1200, ["SRUAP_Turret_Chaos3"] = 1200, ["SRUAP_Turret_Order1"]  = 1200, ["SRUAP_Turret_Order2"]  = 1200, ["SRUAP_Turret_Order3"] = 1200, ["SRUAP_Turret_Chaos4"] = 1200, ["SRUAP_Turret_Chaos5"] = 500, ["SRUAP_Turret_Order4"] = 1200, ["SRUAP_Turret_Order5"] = 500 }
	self.PreAttackCallbacks = {}
	self.PreMoveCallbacks = {}
	self.PostAttackCallbacks = {}
	self.NonKillableMinionCallbacks = {}
	self.TargetSelector = nil
	self.unkillable = {}
	-----------------------------------------------------------------------Prediction--------------------------------------------------------------------------------
	self.Attacks = {}
	self.LastCleanUp = 0

	-----------------------------------------------------------------------Configuration--------------------------------------------------------------------------------
	self.AttackDelayReduction = function() return 0 end --90/1000
	self.ExtraWindUp = function() return 0 end --NetClient.ping/2000
	self.HoldPositionRadius = function() return 100 end
	self.DrawHoldPosition = function() return true end
	self.DrawAttackRange = function() return true end
	self.DrawKillable = function() return true end

	self.ExtraDelay = 0
	self.AttackPlants = false
	self.AttackWards = true
	self.AttackBarrels = true

	-----------------------------------------------------------------------Implement--------------------------------------------------------------------------------

	self.LastAttackCommandSentTime = 0
	self.AnimationTime = function() return myHero.attackCastDelay end	
	self.ServerAttackDetectionTick = 0
	self.ForcedTarget = nil
	self.noWasteAttackChamps = { ["Kalista"] = true, ["Twitch"] = true }
	self.NoCancelChamps = { "Kalista" }
	self.WindUpTime = function() return self.AnimationTime() + self.ExtraWindUp() end
	self.ActiveModes = { }
	--AddEvent(Events.OnTick, function(...) self:OnTick(...) end)
	AddEvent(Events.OnBasicAttack, function(...) self:OnProcessAutoAttack(...) end)
	AddEvent(Events.OnProcessSpell, function(...) self:OnProcessSpell(...) end)
	AddEvent(Events.OnStopCastSpell, function(...) self:OnStopCast(...) end)
	AddEvent(Events.OnCreateObject, function(...) self:OnCreateObject(...) end)
	AddEvent(Events.OnDeleteObject, function(...) self:OnDeleteObject(...) end)
	AddEvent(Events.OnTick, function() self:OnUpdate() end)
	AddEvent(Events.OnDraw, function() self:OnDraw() end)

	self.OrbwalkerModes = {}
	self:AddMode({Name = "Combo",Key = GlobalKeys.ComboKey, TargetDelegate = function() return self:GetHeroTarget() end, OrbwalkDelegate = nil})
	self:AddMode({Name = "LaneClear",Key = GlobalKeys.LaneClearKey, TargetDelegate = function() return self:GetLaneClearTarget() end, OrbwalkDelegate = nil})
	self:AddMode({Name = "LastHit",Key = GlobalKeys.LastHitKey, TargetDelegate = function() return self:GetLastHitTarget() end, OrbwalkDelegate = nil})
	self:AddMode({Name = "Mixed",Key = GlobalKeys.MixedKey, TargetDelegate = function() return self:GetMixedModeTarget() end, OrbwalkDelegate = nil})
end

function Orbwalker:OnPreAttack(fn)
	insert(self.PreAttackCallbacks, fn)	
end

function Orbwalker:OnPreMove(fn)
	insert(self.PreMoveCallbacks, fn)	
end

function Orbwalker:OnPostAttack(fn)
	insert(self.PostAttackCallbacks, fn)	
end

function Orbwalker:OnNonKillableMinion(fn)
	insert(self.NonKillableMinionCallbacks, fn)	
end

function Orbwalker:AddMode(mode)
	mode.ParentInstance = self
	local newMode = OrbwalkingMode(mode)
	insert(self.OrbwalkerModes, newMode)	
end


function Orbwalker:AllowAttack(bool)
	self.AttackingEnabled = bool
end

function Orbwalker:AllowMovement(bool)
	self.MovingEnabled = bool
end

function Orbwalker:AttackReset(list)
	self.AttackResets = list
end

function Orbwalker:GetActiveMode()
	if #self.OrbwalkerModes then
		for k,v in pairs(self.OrbwalkerModes) do
			if v.Active() then return v end
		end
	end
end

function Orbwalker:AttackCooldownTime()
	local champion = myHero.charName
	local attackDelay = myHero.attackDelay	
	if champion == "Graves" then
		attackDelay = (1.0740296828 * attackDelay - 0.7162381256175)
	end

	if champion == "Kalista" then 
		return attackDelay
	end
	return (attackDelay - self.AttackDelayReduction()) * 800
end

--
function Orbwalker:IsWindingUp()
	local detectionTime = max(self.ServerAttackDetectionTick, self.LastAttackCommandSentTime)	
	return GetTickCount()  - detectionTime <= self.WindUpTime() * 1000-- + NetClient.ping / 2
end

function Orbwalker:AttackReady()	
	return GetTickCount() + NetClient.ping / 2 - self.ServerAttackDetectionTick >= self:AttackCooldownTime()
end

function Orbwalker:ForceTarget(unit)
	if unit then
		self.ForcedTarget = unit
	else
		return self.ForcedTarget
	end
end

function Orbwalker:SetLastTarget(unit)
	if unit then
		self.LastTarget = unit
	else
		return self.LastTarget
	end
end

function Orbwalker:ServerAttackDetectionTick(value)
	if value then
		self.ServerAttackDetectionTick = value
	else
		return self.ServerAttackDetectionTick
	end
end

function Orbwalker:GetTrueAttackRange(unit)
	local unit = unit or myHero
	return unit.characterIntermediate.attackRange + unit.boundingRadius
end

function Orbwalker:Attack(target)
	local args = {Target = target, Process = true}
	for k,v in pairs(self.PreAttackCallbacks) do
		self.PreAttackCallbacks[k](args)
	end
	if args.Process then
		local targetToAttack = args.Target 
		if self.ForcedTarget ~= nil and IsValidTarget(self.ForcedTarget, self:GetTrueAttackRange()) then
			targetToAttack = self.ForcedTarget
		end
		local detectionTime = max(self.ServerAttackDetectionTick, self.LastAttackCommandSentTime)				
		myHero:IssueOrder(GameObjectOrder.AttackUnit, targetToAttack)
		self.LastAttackCommandSentTime = GetTickCount()
		return true
	end
	return false
end

function Orbwalker:Move(target)
	local args = {Target = target, Process = true}
	for k,v in pairs(self.PreMoveCallbacks) do
		self.PreMoveCallbacks[k](args)
	end
	if args.Process then		
		myHero:IssueOrder(GameObjectOrder.MoveTo, args.Target)		
		return true
	end
	return false
end

function Orbwalker:IsValidAttackableObject(unit)
	if not IsValidTarget(self.ForcedTarget, self:GetTrueAttackRange()) then
		return false
	end
	local unitType = unit.type
	if unitType == GameObjectType.AIHeroClient or unitType == GameObjectType.obj_AI_Minion or unitType == GameObjectType.obj_AI_Turret or unitType == GameObjectType.obj_BarracksDampener or unitType == GameObjectType.obj_HQ then
		return true
	end

	local name = unit.charName:lower()
	--J4 flag
	if (name:find("beacon")) then	
		return false;
	end
	if (not self.AttackPlants and name:find("sru_plant_") ~= nil) or (not self.AttackWards and name:find("ward") ~= nil) then
		return false
	end

	if name:find("zyraseed") then
		return false
	end

	if unitType == 3 then
		return true
	end

	if name:find("gangplankbarrel") ~= nil then
		if IsAlly(unit) or not self.AttackBarrels then
			return false
		end
	end
	return true
end

function Orbwalker:CanAttack()
	if not self.AttackingEnabled then
		return false
	elseif 	myHero.buffManager:HasBuffOfType(BuffType.Polymorph) or 
			(myHero.buffManager:HasBuffOfType(BuffType.Blind) and not contains(self.noWasteAttackChamps, myHero.charName)) or
			(myHero.charName == "Jhin" and myHero.buffManager:HasBuff("JhinPassiveReload")) or (myHero.charName == "Graves" and myHero.buffManager:HasBuff("GravesBasicAttackAmmo1")) then
		return false
	elseif myHero.charName == "Kalista" then--contains(self.NoCancelChamps,myHero.charName) 
		return true
	elseif self:IsWindingUp() then
		return false
	end	
	return self:AttackReady()
end

function Orbwalker:CanMove()
	if not self.MovingEnabled then
		return false
	elseif 	GetDistance(GetMousePos()) < self.HoldPositionRadius() then
		return false
	elseif contains(self.NoCancelChamps, myHero.charName) then
		return true
	elseif self:IsWindingUp() then
		return false
	end
	return true
end

function Orbwalker:GetOrbwalkingTarget()
	return self.LastTarget
end

function Orbwalker:GetTarget(mode)
	if self.ForcedTarget ~= nil and IsValidTarget(self.ForcedTarget, self:GetTrueAttackRange()) then
		return self.ForcedTarget
	end
	return mode and mode:GetTarget()
end

function Orbwalker:Orbwalk()
	if GetTickCount() - self.LastAttackCommandSentTime < 70 + min(60, NetClient.ping) then return end
	local mode = self:GetActiveMode()
	if mode == nil then return end
	--
	if self.ForcedTarget ~= nil and not IsValidTarget(self.ForcedTarget, self:GetTrueAttackRange()) then
		self.ForcedTarget = nil
	end
	if self.LastTarget ~= nil and not IsValidTarget(self.LastTarget, self:GetTrueAttackRange()) then
		self.LastTarget = nil
	end
	--
	mode:Execute()
	--
	if self:CanAttack() then
		local target = self.LastTarget or self:GetTarget(mode) 
		if target then			
			self:Attack(target)
		end
	end	
	if self:CanMove() then
		self:Move(GetMousePos())
	end
end

function Orbwalker:ResetAutoAttackTimer()
	self.ServerAttackDetectionTick = 0
	self.LastAttackCommandSentTime = 0
end

function Orbwalker:OnProcessAutoAttack(sender,spell)
	if sender and sender.isMelee and IsValidTarget(sender, 4000) and spell and spell.target then
		local target = spell.target
		if target.type ~= _MINION then return end
		local attack = {
			AttackStatus = "Detected",
			DetectTime = RiotClock.time - NetClient.ping / 2000,
			Sender = sender,
			Target = target,
			SNetworkId = sender.networkId,
			NetworkId = target.networkId,
			Damage = self:CalcDamageOfAttack(sender, target, sender.basicAttack, 0),
			StartPosition = StartPosition,
			AnimationDelay = sender.attackCastDelay ,
			Type = "Melee",
			TimeToLand = TimeToLand,
		}				
		self:AddAttack(attack)
	end
	if sender == myHero and spell and spell.target then
		self.ServerAttackDetectionTick = GetTickCount() - NetClient.ping /2
		self.LastTarget = spell.target 
		self.ForcedTarget = nil 
		DelayAction(function() 
			local args = {Target = self.LastTarget}
			for k,v in pairs(self.PostAttackCallbacks) do
				self.PostAttackCallbacks[k](args)
			end
		end, self.WindUpTime())
		if contains(self.attackResets, name) then
			self:ResetAutoAttackTimer()
		end		
	end
end

function Orbwalker:CanKillMinion(minion, time)
	local rtime = (time and time) or self:TimeForAutoToReachTarget(minion)
	local pred = self:GetPredictedHealth(minion,rtime)
	if pred <= 0 then
		--insert(self.unkillable, minion)
		if self.NonKillableMinionsCallbacks then
			for k,v in pairs(self.NonKillableMinionsCallbacks) do
				self.NonKillableMinionsCallbacks[k](minion)				
			end
		end
		return false
	end
	return pred <= self:GetRealAutoAttackDamage(minion)
end

function Orbwalker:GetHeroTarget()
	local targets = ObjectManager:GetEnemyHeroes()
	for k,v in pairs(targets) do
		if IsValidTarget(v, self:GetTrueAttackRange()) and (v.charName ~= "Jax" or (v.charName == "Jax" and not v.buffManager:HasBuff("JaxCounterStrike"))) then
			return v
		end
	end	
end

function Orbwalker:GetLaneClearTarget()
	if self:UnderTurretMode() then
		return self:GetLastHitTarget()	--Need to add Under Turret Logic
	end
	local range = self:GetTrueAttackRange()
	local attackable = {}
	for k,v in pairs(ObjectManager:GetEnemyMinions()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end
	for k,v in pairs(ObjectManager:GetEnemyHeroes()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end
	for k,v in pairs(ObjectManager:GetEnemyTurrets()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end
	sort(attackable, function(a, b) return a.maxHealth > b.maxHealth end)
	--	
	for k, v in pairs(attackable) do
		if self:CanKillMinion(v) then
			return v
		end
	end
	--
	for k, v in pairs(attackable) do
		if self:ShouldWaitMinion(v) then
			myHero:IssueOrder(GameObjectOrder.MoveTo, GetMousePos())		
			return 
		end
	end
	--
	local structure = self:GetStructureTarget(attackable)
	if structure then 
		return structure 
	end
	--
	local last = self.LastTarget
	if last ~= nil and IsValidTarget(last, self:GetTrueAttackRange()) then
		local predHealth = self:GetPredictedHealth(last)
		if abs(last-predHealth < 0) then
			return self.LastTarget
		end
	end
	for k,minion in pairs(attackable) do
		local predHealth = self:GetPredictedHealth(minion)
		if minion.health - predHealth < 0 then
			return minion
		end
	end
	for i= #attackable, 1, -1 do
		if attackable[i] ~= nil then
			return attackable[i]
		end
	end
	local hero = self:GetHeroTarget()
	if hero ~= nil then
		return hero 
	end	
end

function Orbwalker:UnderTurretMode()
	for k, v in pairs(ObjectManager:GetAllyTurrets()) do
		if v.isValid and GetDistance(v) <= 950 then--+ self:GetTrueAttackRange()
			return true
		end		
	end
	return false
end

function Orbwalker:GetUnderTurret()
	--Under Tower Logic
end

function Orbwalker:GetLastHitTarget(attackable)
	local attackable = attackable
	if attackable == nil then
		attackable = {}
		local range = self:GetTrueAttackRange()
		for k,v in pairs(ObjectManager:GetEnemyMinions()) do
			if IsValidTarget(v, range) then
				insert(attackable, v)
			end
		end
		for k,v in pairs(ObjectManager:GetEnemyHeroes()) do
			if IsValidTarget(v, range) then
				insert(attackable, v)
			end
		end
		for k,v in pairs(ObjectManager:GetEnemyTurrets()) do
			if IsValidTarget(v, range) then
				insert(attackable, v)
			end
		end		
	end
	if attackable == nil then return end 
	for k, v in pairs(attackable) do
		if self:CanKillMinion(v) then
			return v
		end
	end
	--[[
	sort(attackable, function(a, b) return a.maxHealth > b.maxHealth end)
	sort(attackable, function(a, b) return a.health < b.health end)
	for k, v in pairs(attackable) do
		if v.isValid then
			return v 
		end
	end]]
end

function Orbwalker:GetMixedModeTarget()
	local range = self:GetTrueAttackRange()
	attackable = {}
	for k,v in pairs(ObjectManager:GetEnemyMinions()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end
	for k,v in pairs(ObjectManager:GetEnemyHeroes()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end
	for k,v in pairs(ObjectManager:GetEnemyTurrets()) do
		if IsValidTarget(v, range) then
			insert(attackable, v)
		end
	end		
	for k, v in pairs(attackable) do
		if self:CanKillMinion(v) then
			return v
		end
	end
	local structure = self:GetStructureTarget(attackable)
	if structure then 
		return structure 
	end
	local hero = self:GetHeroTarget()
	if hero ~= nil then
		return hero 
	end
end

function Orbwalker:GetPredictedHealth(minion, time)
	time = time or self:TimeForAutoToReachTarget(minion)
	return math.ceil(self:GetPrediction(minion, time))
end

function Orbwalker:GetStructureTarget(attackable)
	local range = self:GetTrueAttackRange()
	for k, v in pairs(attackable) do
		if v.type == GameObjectType.obj_HQ or v.type == GameObjectType.obj_AI_Turret or v.type == GameObjectType.obj_BarracksDampener then
			return v
		end
	end	
end

function Orbwalker:OnProcessSpell(sender, spell)
	if sender == myHero then
		local name = spell.spellData.name:lower()
		if contains(self.specialAttacks, name) then
			self:OnProcessAutoAttack(sender, spell)
		end
		if contains(self.attackResets, name) then
			self:ResetAutoAttackTimer()
		end
	end
end

function Orbwalker:OnDraw()
	--[[
	for k, v in pairs(self.Attacks) do
		for i, attack in pairs(self.Attacks[k]) do
			if attack.AttackStatus == "Detected" and attack.Type == "Ranged" then 
				local startPos = Vector(attack.StartPosition)
				local targPos = Vector(attack.Target)
				local pos =  startPos + (targPos - startPos):normalized() * ((RiotClock.time - attack.DetectTime) /attack.TimeToLand) * GetDistance(startPos, targPos)
				DrawHandler:Circle3D(D3DXVECTOR3(pos.x, pos.y, pos.z), 30, 0xffffffff)
			end
		end
	end]]
	--if self.unkillable then
	--	for k,v in pairs(self.unkillable) do
	--		if v.isValid and not v.isDead then
	--			DrawHandler:Circle3D(v.position, 50, 0xffffffff)
	--		end
	--	end
	--end

	if self.DrawAttackRange then
		DrawHandler:Circle3D(myHero.position, self:GetTrueAttackRange(), 0xffffffff)
	end
	if self.DrawHoldPosition then
		DrawHandler:Circle3D(myHero.position, self.DrawHoldPositionRadius, 0xffffffff)
	end
	if self.DrawKillable then
		for k, v in pairs(ObjectManager:GetEnemyMinions()) do
			if IsValidTarget(v, 1000) then
				if v.health <= self:GetRealAutoAttackDamage(v)  then				
					DrawHandler:Circle3D(v.position, 50, 0xffff0000)
				elseif v.health <= self:GetRealAutoAttackDamage(v) * 3 then
					DrawHandler:Circle3D(v.position, 50, 0xffffffff)
				end
			end
		end
	end
end

function Orbwalker:GetRealAutoAttackDamage(minion)
	if minion.charName:lower():find("ward") then
		return 1
	end
	return self:CalcDamageOfAttack(myHero, minion, myHero.basicAttack, -5) --should add Menu.HealthPredOffset 
end

function Orbwalker:ShouldWaitMinion(minion)
	local time = self:TimeForAutoToReachTarget(minion) + myHero.attackDelay + 0.1
	local pred = self:GetLaneClearHealthPrediction(minion, time)
	local delta = (minion.health - pred) 
	if minion.health - delta * 2 < self:GetRealAutoAttackDamage(minion) then
		return true
	end
	return false
end

function Orbwalker:OnStopCast(sender,animation, bool)
	if sender == myHero and animation then
		self:ResetAutoAttackTimer()
	end	
end

function Orbwalker:GetBasicAttackMissileSpeed(hero)
	if hero.isMelee or hero.charName == "Azir" or hero.charName == "Velkoz" or hero.charName == "Thresh" or hero.charName == "Rakan" or 
		(hero.charName == "Kayle" and hero.buffManager:HasBuff("JudicatorRighteousFury")) or (hero.charName == "Viktor" and hero.buffManager:HasBuff("ViktorPowerTransferReturn")) then
		return huge
	end
	return hero.basicAttack.spellDataInfo.missileSpeed
end

function Orbwalker:TimeForAutoToReachTarget(minion)
	local dist = GetDistance(minion)
	local attackTravelTime = dist / self:GetBasicAttackMissileSpeed(myHero) 	
	return self.AnimationTime() + attackTravelTime + NetClient.ping /2000
end

-----------------------------------------------------------------------Prediction--------------------------------------------------------------------------------
function Orbwalker:GetProjectileSpeed(unit)
    return self.projectilespeeds[unit.charName] and self.projectilespeeds[unit.charName] or hero.basicAttack.spellDataInfo.missileSpeed
end

function Orbwalker:GetPrediction(target, time)
	local predictedDamage = 0

	for k, v in pairs(self.Attacks) do
		for i, attack in pairs(self.Attacks[k]) do			
			if not self:AutoAttack_HasReached(attack) and self:AutoAttack_IsValid(attack) and 
					attack.Target.networkId == target.networkId and RiotClock.time - attack.DetectTime <= 3 then
				mlt = RiotClock.time + time
				alt = RiotClock.time + self:AutoAttack_ETA(attack)

				if mlt - alt > 0.1 + self.ExtraDelay then
					predictedDamage = predictedDamage + attack.Damage
				end
			end
		end
	end	
	return target.health - predictedDamage	
end

function Orbwalker:GetLaneClearHealthPrediction(target, time)
	local predictedDamage = 0
	local rTime = time

	for k, v in pairs(self.Attacks) do
		for i, attack in pairs(self.Attacks[k]) do
			local check2 = attack.Target.networkId ~= target.networkId or RiotClock.time - attack.DetectTime > rTime
			if not check2 then
				predictedDamage = predictedDamage + attack.Damage
			end
		end
	end

	return target.health - predictedDamage
end

function Orbwalker:CalcDamageOfAttack(source, target, spell, additionalDamage)    --Working -RMAN (in-game)
    -- read initial armor and damage values
    local sourceStats = source.characterIntermediate
    local totalDamage = source.characterIntermediate.baseAttackDamage + source.characterIntermediate.flatPhysicalDamageMod    
    local armorPenPercent = source.characterIntermediate.percentArmorPenetration
    local armorPen = source.characterIntermediate.flatArmorPenetration
    totalDamage = totalDamage + (additionalDamage or 0)    
    local damageMultiplier = (spell and (spell.name:find("CritAttack") or spell.name:find("CaitlynHeadshot")) and 2) or 1
    
    -- minions give wrong values for armorPen and armorPenPercent
    if source.type == _MINION then
        armorPenPercent = 1
    elseif source.type == _TURRET then
        armorPenPercent = 0.7
    end

    -- turrets ignore armor penetration and critical attacks
    if target.type == _TURRET then
        armorPenPercent = 1
        armorPen = 0
        damageMultiplier = 1
    end

    -- calculate initial damage multiplier for negative and positive armor

    local targetArmor = ((target.characterIntermediate.armor + target.characterIntermediate.bonusArmor) * 1 - (armorPenPercent)/100) - armorPen 
    
    if targetArmor < 0 then -- minions can't go below 0 armor.
        damageMultiplier = (2 - 100 / (100 - targetArmor)) * damageMultiplier
        --damageMultiplier = 1 * damageMultiplier
    else
        damageMultiplier = 100 / (100 + targetArmor) * damageMultiplier
    end    	

    -- use ability power or ad based damage on turrets
    if source.type == _HERO and target.type == _TURRET then
        totalDamage = math.max(totalDamage, source.characterIntermediate.baseAttackDamage + 0.4 * (source.characterIntermediate.flatMagicDamageMod + source.characterIntermediate.baseAbilityDamage))
    end

    -- minions deal less damage to enemy heroes
    if source.type == _MINION and target.type == _HERO and source.team ~= TEAM_NEUTRAL then
        damageMultiplier = 0.60 * damageMultiplier
    end

    -- heros deal less damage to turrets
    if source.type == _HERO and target.type == _TURRET then    	
        damageMultiplier = 0.35 * damageMultiplier
    end

    -- minions deal less damage to turrets
    if source.type == _MINION and target.type == _TURRET then
        damageMultiplier = 0.475 * damageMultiplier
    end

    -- siege minions and superminions take less damage from turrets
    if source.type == _TURRET and target.charName:find("MinionSiege")  then 
        damageMultiplier = 0.8 * damageMultiplier
    end

    -- caster minions and basic minions take more damage from turrets
    if source.type == _TURRET and target.charName:find("MinionRanged") or target.charName:find("MinionMelee") then 
        damageMultiplier = (1 / 0.875) * damageMultiplier
    end       

    -- turrets deal more damage to all units by default
    if source.type == _TURRET then
        damageMultiplier = 1.11 * damageMultiplier
    end
    -- calculate damage dealt  
    --PrintChat(" Damage of ".. source.charName.."\'s hit is " ..damageMultiplier * totalDamage)
    return damageMultiplier * totalDamage
end

function Orbwalker:OnCreateObject(unit)
	if unit and unit.type == GameObjectType.MissileClient then 
		unit = unit.asMissile
		local sender = unit.spellCaster
		local target = unit.target

		if not sender or not target or 
		   not sender.isValid or not target.isValid or
		       sender == 0 or target == 0 or 
		       sender.isDead or target.isDead or 
		       GetDistance(sender) > 4000		    
		   then return 
		end

		local StartPosition = unit.launchPos
		local EndPosition = unit.destPos
		local TimeToLand = GetDistance(StartPosition,EndPosition) / unit.missileData.spellData.spellDataInfo.missileSpeed

		local attack = {			
			AttackStatus = "Detected",
			DetectTime = RiotClock.time - NetClient.ping / 2000,
			Sender = sender,
			Target = target,
			SNetworkId = sender.networkId,
			NetworkId = target.networkId,
			Damage = self:CalcDamageOfAttack(sender, target, unit.missileData.spellData, -3),
			StartPosition = StartPosition,
			AnimationDelay = sender.attackCastDelay ,
			Type = "Ranged",
			TimeToLand = TimeToLand,
			Missile = unit
		}				
		self:AddAttack(attack)
	end
end
--
function Orbwalker:OnUpdate()
	if not myHero.isDead and not MenuGUI.isChatOpen then
		self:Orbwalk()
	end
	---
	if RiotClock.time - self.LastCleanUp <= 0.1 then
		return
	end

	for k, v in pairs(self.Attacks) do
		for i, attack in pairs(self.Attacks[k]) do
			if not attack.Sender.isValid or attack.Sender.IsDead or not attack.Target.isValid or attack.Target.IsDead then
			    self.Attacks[k][i].AttackStatus = "Completed"
            end

			--Remove All
			if RiotClock.time - attack.DetectTime > 5 then
				self:RemoveAttack(attack)
			end
		end
	end
	self.LastCleanUp = RiotClock.time
end

function Orbwalker:OnDeleteObject(unit)
	if unit and unit.type == GameObjectType.MissileClient then
		local unit = unit.asMissile 
		local target = unit.target
		local sender = unit.spellCaster
		if not target or not sender then return end
		local attacks = self.Attacks[sender.networkId]
		local minDetectTime = 0
		local attack = nil
		if attacks then
			for i, a in pairs(attacks) do
				if a.Target.networkId == target.networkId and a.AttackStatus ~= "Completed" and a.Type == "Ranged" then
					if minDetectTime == 0 then
						minDetectTime = a.DetectTime
						attack = a
					end

					if minDetectTime > a.DetectTime then
						minDetectTime = a.DetectTime
						attack = a
					end
				end
			end
		end

		if attack ~= nil then
			for i, a in pairs(self.Attacks[attack.Sender.networkId]) do
				if a.Target.networkId == attack.Target.networkId then
					self.Attacks[attack.Sender.networkId][i].AttackStatus = "Completed"
				end
			end
		end
	end
end

function Orbwalker:AddAttack(attack)
	local k = attack.Sender.networkId
	if not self.Attacks[k] then
		self.Attacks[k] = {}
	end

	for i, a in pairs(self.Attacks[k]) do
		if a.Type == "Melee" then
			self.Attacks[k][i].AttackStatus = "Completed"
		end
	end

	insert(self.Attacks[k], attack)
end
--
function Orbwalker:RemoveAttack(attack)
	local k = attack.Sender.networkId
	if not self.Attacks[k] then return end
	local id = 0
	for i, a in pairs(self.Attacks[k]) do
		if a.Target.networkId == attack.Target.networkId then
			id = i
		end
	end
	if id > 0 then
		remove(self.Attacks[k], id)
	end
end

function Orbwalker:GetAttack(unitId)
	return self.Attacks[unitId]
end

function Orbwalker:AutoAttack_LandTime(attack)
	if attack.Type == "Ranged" then
		return RiotClock.time + attack.TimeToLand
	end
	if attack.Type == "Melee" then
		return attack.DetectTime + attack.AnimationDelay + self.ExtraDelay
	end
end

function Orbwalker:AutoAttack_ETA(attack)
	return self:AutoAttack_LandTime(attack) - RiotClock.time
end

function Orbwalker:AutoAttack_IsValid(attack)
	return attack and attack.Sender.isValid and attack.Target.isValid
end

function Orbwalker:AutoAttack_HasReached(attack)
	if attack.Type == "Ranged" then
		if not self:AutoAttack_IsValid(attack) or attack.AttackStatus == "Completed" or self:AutoAttack_ETA(attack) < -0.2 then
			return true
		end
	end

	if attack.Type == "Melee" then
		if attack.AttackStatus == "Completed" or not self:AutoAttack_IsValid(attack) or self:AutoAttack_ETA(attack) < -0.1 then
			return true
		end
	end
	return false
end

function OnLoad()
	Orbwalker()
end


