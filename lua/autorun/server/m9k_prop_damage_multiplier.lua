-- ---------------------------------------------------------------------------
-- M9K :: Per-projectile prop damage multiplier
-- ---------------------------------------------------------------------------
-- Lets each M9K explosive / projectile entity scale how much damage it deals
-- to PROPS, independently of the damage it deals to players, NPCs and
-- vehicles.
--
-- Motivation: a rocket that does 1000 damage is balanced against tanks,
-- aircraft and players, but flattens builds. Set a multiplier and the same
-- rocket keeps its 1000 damage against everything except props, which instead
-- take (1000 * multiplier).
--
-- ---------------------------------------------------------------------------
-- USAGE  (inside any entity file, e.g. lua/entities/m9k_gdcwa_matador_90mm.lua)
-- ---------------------------------------------------------------------------
--
--     ENT.M9KPropDamageMultiplier = 0.5   -- props take 50% of this shell's damage
--
-- May also be set per-instance at runtime on the server, e.g. in Initialize():
--
--     self.M9KPropDamageMultiplier = 0.35
--
--       1  = unchanged (default)      0   = props take no damage from this projectile
--     < 1  = props take less damage   > 1 = props take more damage
--
-- ---------------------------------------------------------------------------
-- This hooks Simple Prop Damage's public SPD_PreEntityTakeDamage extension
-- point. No Simple Prop Damage files are modified. If SPD is not installed
-- this file simply does nothing.
-- ---------------------------------------------------------------------------

if not SERVER then return end

-- Server-wide fallback multiplier, applied only to M9K projectiles that do NOT
-- define their own ENT.M9KPropDamageMultiplier. Leave at 1 to keep every
-- projectile that opts out untouched.
local m9kPropDmgDefault = CreateConVar(
	"m9k_prop_damage_mult_default", "1", bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY ),
	"Fallback prop-damage multiplier for M9K projectiles that don't set their own ENT.M9KPropDamageMultiplier."
)

-- Returns a usable multiplier for the given inflictor, or nil when there is
-- nothing to do (not an M9K entity, or multiplier resolves to exactly 1).
local function resolveMultiplier( inflictor )
	if not IsValid( inflictor ) then return end

	-- Restrict to M9K entities so we never disturb other addons' damage.
	local class = inflictor:GetClass()
	if not class or string.sub( class, 1, 4 ) ~= "m9k_" then return end

	local mult = inflictor.M9KPropDamageMultiplier
	if mult == nil then
		mult = m9kPropDmgDefault:GetFloat()
	end

	mult = tonumber( mult )
	if not mult or mult == 1 then return end
	if mult < 0 then mult = 0 end

	return mult
end

-- SPD runs this immediately before it applies blast / bullet / physics damage
-- to a prop. Because SPD calls each victim entity through its own DamageInfo,
-- scaling here affects ONLY the prop-health calculation -- the same explosion's
-- damage to players, NPCs and vehicles is left completely alone.
hook.Add( "SPD_PreEntityTakeDamage", "M9K_PropDamageMultiplier", function( ent, entTable, dmginfo )
	local mult = resolveMultiplier( dmginfo:GetInflictor() )
	if not mult then return end

	if mult == 0 then
		return false -- fully prop-safe: tell SPD to ignore this hit entirely
	end

	dmginfo:ScaleDamage( mult )
end )
