ENT.Type = "anim"
ENT.PrintName = "Prox mine"
ENT.Author = "Bob"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = ""
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.DisableDuplicator = true
ENT.CanTool = false

if CLIENT then return end

AddCSLuaFile()

function ENT:Initialize()
    self:SetModel( "models/weapons/w_px_planted.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end

    self.TimeLeft = CurTime() + 3
    self.BombHealth = 100
end

ENT.DetectRadius = 100 -- units; how close a target must be to trip the mine

-- Set the console var m9k_proxy_debug to 1 to log detection to the server console.
local proxy_debug = CreateConVar( "m9k_proxy_debug", "0", FCVAR_ARCHIVE, "Log M9K proximity mine detection" )
local function proxyLog( ... )
    if proxy_debug:GetBool() then print( "[m9k_proxy]", ... ) end
end

-- Returns the vehicle an entity is riding in / driving, across Source vehicles,
-- simfphys and LVS. NULL if none.
local function proxyGetVehicle( ent )
    if ent:IsPlayer() then
        if ent.GetVehicle and IsValid( ent:GetVehicle() ) then return ent:GetVehicle() end
        if ent.GetSimfphysCar and IsValid( ent:GetSimfphysCar() ) then return ent:GetSimfphysCar() end
        if ent.lvsGetVehicle and IsValid( ent:lvsGetVehicle() ) then return ent:lvsGetVehicle() end
    end
    return NULL
end

-- Walks parent + framework links so we can ignore the whole vehicle during LOS.
local function proxyVehicleParts( veh, out )
    if not IsValid( veh ) then return out end
    out[#out + 1] = veh
    if IsValid( veh:GetParent() ) then out[#out + 1] = veh:GetParent() end
    if veh.GetParent and IsValid( veh:GetParent() ) then
        local p = veh:GetParent()
        if IsValid( p:GetParent() ) then out[#out + 1] = p:GetParent() end
    end
    -- simfphys: pod -> car via GetPhysicsObjectCount owner, or .base
    if veh.base and IsValid( veh.base ) then out[#out + 1] = veh.base end
    return out
end

function ENT:CheckTarget( ent )
    if not IsValid( ent ) then return false end

    local isPlayer = ent:IsPlayer()
    local isNPC    = ent:IsNPC()
    if not ( isPlayer or isNPC ) then return false end
    if isPlayer and not ent:Alive() then return false end

    if ent:WorldSpaceCenter():Distance( self:WorldSpaceCenter() ) > self.DetectRadius then
        return false
    end

    if hook.Run( "M9k_ProxyMineCanTrigger", self, ent, self.ProxyBombOwner ) == false then
        return false
    end

    local veh = proxyGetVehicle( ent )
    local inVehicle = IsValid( veh )

    -- Line-of-sight check, ignoring the mine and (if any) the target's vehicle.
    local filter = proxyVehicleParts( veh, { self } )
    local tr = util.TraceLine( {
        start  = self:WorldSpaceCenter(),
        endpos = ent:WorldSpaceCenter(),
        filter = filter,
    } )

    if tr.Entity == ent or tr.Entity == veh or tr.Entity:IsPlayer() or tr.Entity:IsNPC() then
        proxyLog( "triggered by", ent, inVehicle and "(in vehicle)" or "(on foot)" )
        return true
    end

    -- In a vehicle but LOS is still blocked (big chassis, multi-part car):
    -- proximity alone is enough for a vehicle occupant.
    if inVehicle then
        proxyLog( "triggered by", ent, "(in vehicle, no LOS)" )
        return true
    end

    return false
end

function ENT:Think()
    if self.TimeLeft and self.TimeLeft < CurTime() then
        local targets = ents.FindInSphere( self:WorldSpaceCenter(), self.DetectRadius + 64 )

        -- Players seated in scripted vehicles are not always returned by
        -- FindInSphere, so check every player explicitly too.
        for _, ply in ipairs( player.GetAll() ) do
            targets[#targets + 1] = ply
        end

        for _, ent in ipairs( targets ) do
            if self:CheckTarget( ent ) then
                self:Explosion()
                return
            end
        end
    end

    self:NextThink( CurTime() + 0.1 )
    return true
end

function ENT:Explosion()
    if not IsValid( self.ProxyBombOwner ) then
        self:Remove()
        return
    end

    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    util.Effect( "HelicopterMegaBomb", effectdata )
    util.Effect( "ThumperDust", effectdata )
    util.Effect( "Explosion", effectdata )

    local effectBoom = EffectData()
    effectBoom:SetOrigin( self:GetPos() )
    effectBoom:SetNormal( self:VectorGet() )
    effectBoom:SetEntity( self )
    effectBoom:SetScale( 1 )
    effectBoom:SetRadius( 67 )
    effectBoom:SetMagnitude( 18 )
    util.Effect( "m9k_gdcw_cinematicboom", effectBoom )

    util.BlastDamage( self, self.ProxyBombOwner, self:GetPos(), 200, 250 )
    util.ScreenShake( self:GetPos(), 2000, 255, 2.5, 1250 )

    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 4 ) .. ".wav", self.Pos, 100, 100 )
    self:Remove()
end

function ENT:VectorGet()
    local startpos = self:GetPos()

    local downtrace = {}
    downtrace.start = startpos
    downtrace.endpos = startpos + self:GetUp() * -5
    downtrace.filter = self
    local tracedown = util.TraceLine( downtrace )

    if tracedown.Hit then
        return tracedown.HitNormal
    else
        return Vector( 0, 0, 1 )
    end
end

function ENT:OnTakeDamage( dmginfo )
    if self.Exploded then return end

    local dmg = dmginfo:GetDamage()
    self.BombHealth = self.BombHealth - dmg
    if self.BombHealth <= 0 then
        self.Exploded = true
        self:Explosion()
    end
end
