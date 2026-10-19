-- Variables that are used on both client and server
SWEP.Gun = "m9k_g11" -- must be the name of your swep but NO CAPITALS! (also the file name)

SWEP.Category                 = "M9K Assault Rifles"
SWEP.Author                   = ""
SWEP.Contact                  = ""
SWEP.Purpose                  = ""
SWEP.Instructions             = ""
SWEP.MuzzleAttachment         = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment     = "2" -- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName                = "HK G11" -- Weapon name (Shown on HUD)
SWEP.Slot                     = 2
SWEP.SlotPos                  = 27
SWEP.DrawAmmo                 = true -- Should draw the default HL2 ammo counter
SWEP.DrawCrosshair            = true
SWEP.Weight                   = 30
SWEP.AutoSwitchTo             = true
SWEP.AutoSwitchFrom           = true
SWEP.XHair                    = true -- Used for returning crosshair after scope. Must be the same as DrawCrosshair
SWEP.BoltAction               = false
SWEP.HoldType                 = "ar2"

SWEP.ViewModelFOV             = 70
SWEP.ViewModelFlip            = true
SWEP.ViewModel                = "models/weapons/v_rif_hkg11.mdl"
SWEP.WorldModel               = "models/weapons/w_auga3.mdl"
SWEP.Base                     = "bobs_scoped_base"
SWEP.Spawnable                = true
SWEP.AdminSpawnable           = true

SWEP.Primary.Sound            = "m9k_g11.wav"
SWEP.Primary.RPM              = 600 -- Full-auto RPM (burst mode uses BurstRPM below)
SWEP.Primary.ClipSize         = 30
SWEP.Primary.DefaultClip      = 60
SWEP.Primary.KickUp           = .66 -- Maximum up recoil (rise)
SWEP.Primary.KickDown         = .62 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal   = .1 -- Maximum horizontal recoil
SWEP.Primary.Automatic        = true -- Automatic/Semi Auto
SWEP.Primary.Ammo             = "ar2" -- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal piercing shotgun pellets
SWEP.SelectiveFire            = true

SWEP.Secondary.ScopeZoom      = 4
SWEP.Secondary.UseACOG        = false -- Choose one scope type
SWEP.Secondary.UseMilDot      = false
SWEP.Secondary.UseSVD         = false
SWEP.Secondary.UseParabolic   = false
SWEP.Secondary.UseElcan       = true
SWEP.Secondary.UseGreenDuplex = false
SWEP.Secondary.UseAimpoint    = false
SWEP.Secondary.UseMatador     = false

SWEP.data                     = {}
SWEP.data.ironsights          = 1
SWEP.ScopeScale               = 0.5
SWEP.ReticleScale             = 0.6

SWEP.Primary.NumShots         = 1 --how many bullets to shoot per trigger pull
SWEP.Primary.Damage           = 22 --base damage per bullet [AUG placeholder]
SWEP.Primary.SpreadHip        = .072 --define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.SpreadIronSights = .005 -- ironsight accuracy, should be the same for shotguns

SWEP.SightsPos                = Vector( 2.275, -2.9708, 0.5303 )
SWEP.SightsAng                = Vector( 0, 0, 0 )
SWEP.RunSightsPos             = Vector( -3.0328, 0, 1.888 )
SWEP.RunSightsAng             = Vector( -24.2146, -36.522, 10 )

SWEP.Primary.Burst            = false
SWEP.AutoRPM                  = SWEP.Primary.RPM
SWEP.BurstCount               = 3
SWEP.BurstRPM                 = 2100
SWEP.BurstDelay               = 0.45

SWEP.BurstRecoilMult          = 0.7

SWEP.AutoKickUp               = SWEP.Primary.KickUp
SWEP.AutoKickDown             = SWEP.Primary.KickDown
SWEP.AutoKickHorizontal       = SWEP.Primary.KickHorizontal

SWEP.DrawSound                = "g11_draw.wav"
SWEP.ClipOutSound             = "g11_clipout.wav"
SWEP.ClipInSound              = "g11_clipin.wav"
SWEP.TapSound                 = "g11_tap.wav"

SWEP.ClipOutTime              = 0.001
SWEP.ClipInTime               = 0.3
SWEP.TapTime                  = 0.7

SWEP.ReloadSoundID            = 0
SWEP.BurstLeft                = 0
SWEP.NextBurstShot            = 0

function SWEP:SelectFireMode()
    self.BurstLeft = 0

    local burst = not self.Primary.Burst
    local mult  = burst and self.BurstRecoilMult or 1

    self.Primary.Burst     = burst
    self.Primary.Automatic = not burst
    self.Primary.RPM       = burst and self.BurstRPM or self.AutoRPM
    self.Primary.KickUp         = self.AutoKickUp * mult
    self.Primary.KickDown       = self.AutoKickDown * mult
    self.Primary.KickHorizontal = self.AutoKickHorizontal * mult

    self.NextFireSelect = CurTime() + .5
    if CLIENT then
        self:GetOwner():PrintMessage( HUD_PRINTTALK, burst and "Hyperburst selected." or "Automatic selected." )
    end
    self:EmitSound( "Weapon_AR2.Empty" )
end

function SWEP:FireBurstRound()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    self.ShootThese = 1
    self:ShootBulletInformation()
    self:TakePrimaryAmmo( 1 )
    self:FireAnimation()

    owner:SetAnimation( PLAYER_ATTACK1 )
    owner:MuzzleFlash()
    self:CheckWeaponsAndAmmo()
    self.RicochetCoin = (math.random( 1, 4 ))
end

function SWEP:PrimaryAttack()
    if not self.Primary.Burst then
        return self.BaseClass.PrimaryAttack( self )
    end

    local owner = self:GetOwner()
    if not IsValid( owner ) or not owner:IsPlayer() then
        return self.BaseClass.PrimaryAttack( self )
    end

    if self.BurstLeft > 0 then return end
    if not self:CanPrimaryAttack() then return end
    if self:IsRunning() and not self.CanShootWhileRunning then return end
    if owner:KeyDown( IN_RELOAD ) then return end

    local interval = 60 / self.BurstRPM
    local total    = math.min( self.BurstCount, self:Clip1() )

    self:FireBurstRound()
    self.BurstLeft     = total - 1
    self.NextBurstShot = CurTime() + interval

    self:SetNextPrimaryFire( CurTime() + (total - 1) * interval + self.BurstDelay )
end

function SWEP:Think()
    self.BaseClass.Think( self )

    if self.BurstLeft > 0 then
        local owner = self:GetOwner()

        if not IsValid( owner ) or self:Clip1() <= 0 then
            self.BurstLeft = 0
            return
        end

        local interval = 60 / self.BurstRPM
        while self.BurstLeft > 0 and self.NextBurstShot <= CurTime() and self:Clip1() > 0 do
            self:FireBurstRound()
            self.BurstLeft     = self.BurstLeft - 1
            self.NextBurstShot = self.NextBurstShot + interval
        end
    end
end

function SWEP:Holster( wep )
    self.BurstLeft = 0
    self.ReloadSoundID = self.ReloadSoundID + 1
    return self.BaseClass.Holster( self, wep )
end

function SWEP:PlayG11Sound( name )
    self:EmitSound(name, 60, 100, 1, CHAN_ITEM )
end

function SWEP:Deploy()
    self.BurstLeft = 0
    self.ReloadSoundID = self.ReloadSoundID + 1

    local result = self.BaseClass.Deploy( self )

    if SERVER then
        self:PlayG11Sound( self.DrawSound )
    end

    return result
end

function SWEP:Reload()
    local wasReloading = self:GetReloading()

    self.BaseClass.Reload( self )

    if wasReloading or not self:GetReloading() then return end

    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid( owner ) or not owner:IsPlayer() then return end

    local vm = owner:GetViewModel()
    if not IsValid( vm ) then return end

    local duration = vm:SequenceDuration()
    self.ReloadSoundID = self.ReloadSoundID + 1
    local id = self.ReloadSoundID

    local function schedule( fraction, name )
        timer.Simple( duration * fraction, function()
            if not IsValid( self ) or not IsValid( owner ) then return end
            if self.ReloadSoundID ~= id then return end
            if not self:GetReloading() then return end
            self:PlayG11Sound( name )
        end )
    end

    schedule( self.ClipOutTime, self.ClipOutSound )
    schedule( self.ClipInTime,  self.ClipInSound )
    schedule( self.TapTime,     self.TapSound )
end
