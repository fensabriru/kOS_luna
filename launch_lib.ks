function instantVelatAlt{
	parameter altitude.
	parameter sma.
	if sma=0 { set sma to ship:orbit:semimajoraxis.}
	local v is sqrt(Body:MU*((2/(altitude+body:radius))-(1/sma))).
	return v.
}
//creates Hohmann node
FUNCTION Hohmann {
	set newsma to (periapsis+(body:radius*2)+target:altitude)/2.
	set temperiod to 2*constant:pi*sqrt((newsma*newsma*newsma)/body:mu).
	set halfp to temperiod/2.
	set posv to positionat(target,time:seconds+halfp)-target:body:position.
	set temp to halfp/(360/target:orbit:period).
	set tempt to time:seconds.
	until tempt>time:seconds+ship:orbit:period{
		set shippos to positionat(ship,tempt)-ship:body:position.
		if ( vang(shippos,posv)>179)
			break.
		else
			set tempt to tempt+10.
	}
	set dv to instantVelatAlt((positionat(ship,tempt)-ship:body:position):mag-body:radius,newsma)-instantVelatAlt((positionat(ship,tempt)-ship:body:position):mag-body:radius,0).
	set myNode to node(tempt,0,0,dv).
	add mynode.
}
//Returns what our yaw angle should be to point our ship
//at an arbitrary steering vector
function GetYawError
{
	parameter steer_vector.
	local v1 is vcrs(ship:facing:upvector, steer_vector).
	local v2 is vcrs(ship:facing:upvector, ship:facing:vector).
	local yaw_angle is vang(v1, v2).
	if vang(vcrs(ship:facing:upvector, v1), v2) > 90
	{
		set yaw_angle to -yaw_angle.
	}
	return yaw_angle.
}

//Returns what our pitch angle should be to point our ship
//at an arbitrary steering vector
function GetPitchError
{
	parameter steer_vector.
	local v1 is vcrs(ship:facing:upvector, ship:facing:vector).
	local v2 is vcrs(ship:facing:upvector, steer_vector).
	
	local pitch_error is vang(ship:facing:upvector, steer_vector).
	if vang(v1, v2) > 90
	{
		if pitch_error < 90
		{
			set pitch_error to -90 - pitch_error.
		}
		else
		{
			set pitch_error to 270 - pitch_error.
		}
	}
	else
	{
		set pitch_error to pitch_error - 90.
	}
	return pitch_error.
}

//So for right now we're using a PID controller to drive
//The ratio of our apoapsis / desired orbital altitude to 1
function pitch_angle_error_boost
{
	return apoapsis / 200000.
}

//And after we reach our intended altitude we kill our vertical velocity
function pitch_angle_error_circularize
{
	return verticalspeed.
}

//Return a list of engines in the specified stage
function GetStageEngines
{
	parameter p_stage.
	list engines in englist.
	set stage_engines to list().
	for eng in englist
	{
		if eng:stage() = p_stage
		{
			stage_engines:add(eng).
		}
	}
	return stage_engines.
}

//Launch countdown. Activate 1st stage engines at T-3 seconds
//Automatic abort if TWR at T-0 is less than 1
function LaunchCountdown
{
	local x is 10.
	lock throttle to 1.
	set englist to GetStageEngines(stage:number() - 1).
	until x = 0
	{
		hudtext("Liftoff in T-" + x + " seconds", 1, 2, 25, green, true).
		if x = 3
		{
			for eng in englist
			{
				eng:activate().
			}
		}
		wait 1.
		set x to x - 1.
	}
	if (ship:mass() * 9.81) > ship:availablethrust()
	{
		hudtext("Insufficient liftoff thrust, aborting launch", 5, 2, 15, red, true).
		for eng in englist
		{ 
			eng:shutdown(). 
		}
	}
	else 
	{ 
		stage. 
		wait until verticalspeed > 0.
	}
}

//Compares our current angular momentum to the angular momentum of our target circular orbit
//and returns true if they're within am_error of each other
function OrbitAchieved
{
	parameter orbit_altitude.
	local am_error is 0.00025.
	local angular_momentum is vcrs(ship:body:position, ship:velocity:orbit):mag.
	local desd_velocity is sqrt(ship:body:mu / (orbit_altitude + ship:body:radius)).
	local desd_angular_momentum is (orbit_altitude + ship:body:radius) * desd_velocity.
	if (1 - (angular_momentum / desd_angular_momentum)) < am_error
	{
		return true.
	}
	else 
	{
		return false.
	}
}

function Decouple
{
	list parts in partslist.
	for part in partslist
	{
		if part:stage() = stage:number() - 1 and part:modules():contains("ModuleDecouple")
		{
			part:getmodule("ModuleDecouple"):doevent("decouple").
		}
	}
}

//Automatic stage with ullage
//If we lose thrust below 10000 meters, trigger an abort
function NextStage
{
	if altitude < 10000
	{
		toggle abort.
	}
	local eng_list is GetStageEngines(stage:number() - 1).
	local ullage is false.
	for eng in eng_list
	{
		//solid motors don't have a 'propellant' field so we light them first.
		if not (eng:getmodule("ModuleEnginesRF"):hasfield("propellant"))
		eng:activate().
		set ullage to true.
	}
	Decouple().
	if ullage
	{
		wait 0.5.
	}
	stage.
	wait 1.
}

//I wrote this because I keep forgetting to assign fairings an action group
function GetFairings
{
	local fairings_list is list().
	list parts in partslist.
	for part in partslist
	{
		if part:modules:contains("ProceduralFairingDecoupler")
		{
			fairings_list:add(part).
		}
	}
	return fairings_list.
}

function JettisonFairings
{
	parameter fairings_list.
	for fairing in fairings_list
	{
		if fairing:modules:contains("ProceduralFairingDecoupler")
		{
			fairing:getmodule("ProceduralFairingDecoupler"):doevent("jettison").
		}
	}
}

function ShutdownEngines
{
	local englist is GetStageEngines(stage:number).
	for eng in englist
	{
		if eng:ignition()
		{
			eng:shutdown().
		}
	}
}