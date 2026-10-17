-- Variables that are used on both client and server
SWEP.Gun = "m9k_hk23e" -- must be the name of your swep but NO CAPITALS!

SWEP.Category                = "M9K Machine Guns"
SWEP.Author                = ""
SWEP.Contact                = ""
SWEP.Purpose                = ""
SWEP.Instructions                = ""
SWEP.MuzzleAttachment            = "1"     -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment            = "2"     -- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName                = "HK23E"        -- Weapon name (Shown on HUD)
SWEP.Slot                = 3
SWEP.SlotPos                = 35
SWEP.DrawAmmo                = true        -- Should draw the default HL2 ammo counter
SWEP.DrawCrosshair            = true        -- set false if you want no crosshair
SWEP.Weight                = 30
SWEP.AutoSwitchTo            = true
SWEP.AutoSwitchFrom            = true
SWEP.HoldType                 = "ar2"
SWEP.WeaponWeight           = 50 -- How many units the player's walk/run speed is reduced by while holding this weapon. Should never be higher than 199!


SWEP.ViewModelFOV            = 70
SWEP.ViewModelFlip            = false
SWEP.ViewModel                = "models/weapons/v_machinegunhk2.mdl"
SWEP.WorldModel                = "models/weapons/w_machinegunhk2.mdl"
SWEP.Base                = "bobs_gun_base"
SWEP.Spawnable                = true
SWEP.AdminSpawnable            = true
SWEP.FiresUnderwater = false

SWEP.DeployDelay = 1
SWEP.Primary.Sound            = "249s1.wav"
SWEP.Primary.RPM            = 800            -- This is in Rounds Per Minute
SWEP.Primary.ClipSize            = 100
SWEP.Primary.DefaultClip        = 300
SWEP.Primary.KickUp                = 0.8        -- Maximum up recoil (rise)
SWEP.Primary.KickDown            = 0.8        -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal        = 0.2        -- Maximum up recoil (stock)
SWEP.Primary.Automatic            = true        -- Automatic = true; Semi Auto = false
SWEP.Primary.Ammo            = "ar2"            -- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal piercing shotgun pellets

SWEP.Secondary.IronFOV            = 65        -- How much you 'zoom' in. Less is more!

SWEP.data                 = {}                --The starting firemode
SWEP.data.ironsights            = 1

SWEP.Primary.NumShots    = 1        -- How many bullets to shoot per trigger pull
SWEP.Primary.Damage        = 27    -- Base damage per bullet
SWEP.Primary.SpreadHip        = .06    -- Define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.SpreadIronSights = .017 -- Ironsight accuracy, should be the same for shotguns

SWEP.SightsPos = Vector(-3.38, 0, 1.9)
SWEP.SightsAng = Vector(0, -0.014, 0)
SWEP.RunSightsPos = Vector(5.081, -4.755, -1.476)
SWEP.RunSightsAng = Vector(0, 41.884, 0)

SWEP.ShowWorldModel = false -- stop the broken bonemerged draw

SWEP.WElements = {
    ["hk23e"] = {
        type = "Model",
        model = "models/weapons/w_machinegunhk2.mdl",
        bone = "ValveBiped.Bip01_R_Hand",
        rel = "",
        pos = Vector( -0.5, 1, 0.5 ),
        angle = Angle( -10, 0, 180 ),
        size = Vector( 1, 1, 1 ),
        color = Color( 255, 255, 255, 255 ),
        surpresslightning = false,
        material = "",
        skin = 0,
        bodygroup = {}
    }
}

if CLIENT then
    function SWEP:DrawWorldModel()
        self.ShowWorldModel = not IsValid( self:GetOwner() )
        self.BaseClass.DrawWorldModel( self )
    end
end
