-- Variables that are used on both client and server
SWEP.Gun = "m9k_barret_m82" -- must be the name of your swep but NO CAPITALS!

SWEP.Category                 = "M9K Sniper Rifles"
SWEP.Author                   = ""
SWEP.Contact                  = ""
SWEP.Purpose                  = ""
SWEP.Instructions             = ""
SWEP.MuzzleAttachment         = "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment     = "2" -- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName                = "Barret M82" -- Weapon name (Shown on HUD)
SWEP.Slot                     = 3
SWEP.SlotPos                  = 51
SWEP.DrawAmmo                 = true -- Should draw the default HL2 ammo counter
SWEP.DrawCrosshair            = false
SWEP.XHair                    = false -- Used for returning crosshair after scope. Must be the same as DrawCrosshair
SWEP.Weight                   = 50
SWEP.AutoSwitchTo             = true
SWEP.AutoSwitchFrom           = true
SWEP.BoltAction               = false
SWEP.HoldType                 = "rpg"



SWEP.ViewModelFOV             = 70
SWEP.ViewModelFlip            = true
SWEP.ViewModel                = "models/weapons/v_50calm82.mdl"
SWEP.WorldModel               = "models/weapons/w_barret_m82.mdl"
--oops
SWEP.Base                     = "bobs_scoped_base"
SWEP.Spawnable                = true
SWEP.AdminSpawnable           = true

SWEP.Primary.Sound            = "BarretM82.Single"
SWEP.Primary.RPM              = 80 -- This is in Rounds Per Minute
SWEP.Primary.ClipSize         = 10
SWEP.Primary.DefaultClip      = 60
SWEP.Primary.KickUp           = 2 -- Maximum up recoil (rise)
SWEP.Primary.KickDown         = 1.2 -- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal   = 1.5 -- Maximum up recoil (stock)
SWEP.Primary.Automatic        = false -- Automatic/Semi Auto
SWEP.Primary.Ammo             = "SniperPenetratedRound" -- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal piercing shotgun pellets

SWEP.Secondary.ScopeZoom      = 9
SWEP.Secondary.UseACOG        = false -- Choose one scope type
SWEP.Secondary.UseMilDot      = false
SWEP.Secondary.UseSVD         = false
SWEP.Secondary.UseParabolic   = true
SWEP.Secondary.UseElcan       = false
SWEP.Secondary.UseGreenDuplex = false
SWEP.Secondary.UseAimpoint    = false
SWEP.Secondary.UseMatador     = false

SWEP.data                     = {}
SWEP.data.ironsights          = 1
SWEP.ScopeScale               = 0.7
SWEP.ReticleScale             = 0.6

SWEP.Primary.NumShots         = 1 --how many bullets to shoot per trigger pull
SWEP.Primary.Damage           = 110 --base damage per bullet
SWEP.Primary.SpreadHip           = .07 --define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.SpreadIronSights     = .00001 -- ironsight accuracy, should be the same for shotguns


SWEP.SightsPos                = Vector( 2.894, 0, 1.7624 )
SWEP.SightsAng                = Vector( 0, 0, 0 )
SWEP.RunSightsPos             = Vector( -2.3095, -3.0514, 2.3965 )
SWEP.RunSightsAng             = Vector( -19.8471, -33.9181, 10 )

-- Custom simfphys projectile settings for this weapon.
-- Tweak these instead of the base ShootBullet's hitscan Damage/Force.
SWEP.SimfphysDamage      = 300   -- direct-hit damage
SWEP.SimfphysForce       = 500   -- physics impact force
SWEP.SimfphysSize        = 4     -- projectile size
SWEP.SimfphysDeflectAng  = 25     -- deflection angle on glancing hits (0 = none for an AP round)
SWEP.SimfphysBlastRadius  = 0     -- 0 = no splash damage (set >0 for explosive rounds)
SWEP.SimfphysBlastDamage = 0
SWEP.SimfphysBlastEffect = "simfphys_tankweapon_explosion_micro"

local function simfphysSpread( dir, aimcone )
	if aimcone <= 0 then return dir end

	local ang = dir:Angle()
	local right = ang:Right()
	local up = ang:Up()

	-- random point inside a unit circle, so spread is even in all directions
	local x, y
	repeat
		x = math.Rand( -1, 1 )
		y = math.Rand( -1, 1 )
	until x * x + y * y <= 1

	return ( dir + x * aimcone * right + y * aimcone * up ):GetNormalized()
end

function SWEP:ShootBullet( damage, bulletCount, aimcone )
	bulletCount = bulletCount or 1
	aimcone = aimcone or 0

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if IsFirstTimePredicted() then
		local bulletDir = ( owner:GetAimVector():Angle() + owner:GetViewPunchAngles() ):Forward()

		if SERVER then
			local shootDir = simfphysSpread( bulletDir, aimcone )

			local projectile = {}
				projectile.filter = { self, owner }
				projectile.shootOrigin = owner:M9K_GetShootPos()
				projectile.shootDirection = shootDir
				projectile.attacker = owner
				projectile.attackingent = self
				projectile.Damage = self.SimfphysDamage
				projectile.Force = self.SimfphysForce
				projectile.Size = self.SimfphysSize
				projectile.DeflectAng = self.SimfphysDeflectAng
				projectile.BlastRadius = self.SimfphysBlastRadius
				projectile.BlastDamage = self.SimfphysBlastDamage
				projectile.BlastEffect = self.SimfphysBlastEffect
			simfphys.FirePhysProjectile( projectile )
		end

		hook.Run( "M9K_BulletFired", self, owner )
	end

	local recoilPitch = util.SharedRandom( "m9k_recoil_pitch", -self.Primary.KickDown, -self.Primary.KickUp * self.KickUpMultiplier, 100 )
	local recoilYaw = util.SharedRandom( "m9k_recoil_yaw", -self.Primary.KickHorizontal, self.Primary.KickHorizontal, 200 )

	if self:GetIronsightsActive() and not self.Scoped then
		recoilPitch = recoilPitch * 0.5
		recoilYaw = recoilYaw * 0.5
	end

	recoilPitch = recoilPitch * 0.75
	recoilYaw = recoilYaw * 0.75

	self:SetRecoilPitch( recoilPitch )
	self:SetRecoilYaw( recoilYaw )
end
