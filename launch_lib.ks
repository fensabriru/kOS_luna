function time_to_node {
    SET w TO ship:orbit:period/360.
    SET shiptolan TO 360 - (orbit:argumentofperiapsis + orbit:trueanomaly).
    if shiptolan < 0 {
        set shiptolan to shiptolan + 360.
    }
    return shiptolan * w.
}
function dV_normal {
    SET v TO velocityat(ship,time:seconds + time_to_node()):orbit:mag.
    return 2 * v * sin(delta_i/2).
}
function dV_prograde {
    SET v TO velocityat(ship,time:seconds + time_to_node()):orbit:mag.
    local v_prograde is v/cos(delta_i).
    return v - v_prograde.
}
function changeInc{
	declare parameter desired_i.
	set delta_i to desired_i - orbit:inclination.
	set myNode to node(time:seconds + time_to_node(),0,dV_normal(),dV_prograde).
	add myNode.
}
function speedforcirorb{
	parameter altitude.
	return sqrt((constant:g*body:mass)/(altitude+body:radius)).
}
function changeapo{
	parameter tgtapo.
	set newsma to (periapsis+(body:radius*2)+tgtapo)/2.
	set dv to instantvelatalt(periapsis,newsma)-instantvelatalt(periapsis,0).
	print dv.
	set myNode to node(time:seconds+eta:periapsis,0,0,dv).
	add myNode.
}
function changeper{
	parameter tgtper.
	set newsma to (tgtper+(body:radius*2)+apoapsis)/2.
	set dv to instantvelatalt(apoapsis,newsma)-instantvelatalt(apoapsis,0).
	set myNode to node(time:seconds+eta:apoapsis,0,0,dv).
	add myNode.
}
function circularize{
	parameter where.
	if where:contains("periapsis") {
		set myNode to node(time:seconds+eta:periapsis,0,0,speedforcirorb(ship:orbit:periapsis)-instantvelatalt(ship:orbit:periapsis,orbit:semimajoraxis)).
		add myNode.
	}
	else if where:contains("apoapsis") {
		set myNode to node(time:seconds+eta:apoapsis,0,0,speedforcirorb(ship:orbit:apoapsis)-instantvelatalt(ship:orbit:apoapsis,orbit:semimajoraxis)).
		add myNode.
	}
}
function instantVelatAlt{
	parameter altitude.
	parameter sma.
	if sma=0 { set sma to ship:orbit:semimajoraxis.}
	local v is sqrt(Body:MU*((2/(altitude+body:radius))-(1/sma))).
	return v.
}
function Hohmann {
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
	add myNode.
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
	//return apoapsis / 200000.
	return apoapsis / destorb.
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
		if x = 2
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
function report_sat{
	IF DEFINED old_peri {
		SET cls TO 0.
	} ELSE {
		SET old_peri TO 22.
		SET cls TO 1.
	}
	IF DEFINED old_apo {
		SET cls TO 0.
	} ELSE {
		SET cls TO 1.
		SET old_apo TO 11.
	}
	IF APOAPSIS < 200000 {
		SET line_apoapsis to 11.
	} ELSE IF APOAPSIS < 500000 {
		SET line_apoapsis to 10.
	} ELSE IF APOAPSIS < 750000 {
		SET line_apoapsis to 9.
	} ELSE IF APOAPSIS < 1000000 {
		SET line_apoapsis to 8.
	} ELSE IF APOAPSIS < 2000000 {
		SET line_apoapsis to 7.
	} ELSE IF APOAPSIS < 5000000 {
		SET line_apoapsis to 6.
	} ELSE IF APOAPSIS < 10000000 {
		SET line_apoapsis to 5.
	} ELSE IF APOAPSIS < 15000000 {
		SET line_apoapsis to 4.
	} ELSE IF APOAPSIS < 20000000 {
		SET line_apoapsis to 3.
	} ELSE IF APOAPSIS < 30000000 {
		SET line_apoapsis to 2.
	} ELSE {
		SET line_apoapsis to 1.
	}
	IF PERIAPSIS < 200000 {
		SET line_periapsis to 22.
	} ELSE IF PERIAPSIS < 500000 {
		SET line_periapsis to 23.
	} ELSE IF PERIAPSIS < 750000 {
		SET line_periapsis to 24.
	} ELSE IF PERIAPSIS < 1000000 {
		SET line_periapsis to 25.
	} ELSE IF PERIAPSIS < 2000000 {
		SET line_periapsis to 26.
	} ELSE IF PERIAPSIS < 5000000 {
		SET line_periapsis to 27.
	} ELSE IF PERIAPSIS < 10000000 {
		SET line_periapsis to 28.
	} ELSE IF PERIAPSIS < 15000000 {
		SET line_periapsis to 29.
	} ELSE IF PERIAPSIS < 20000000 {
		SET line_periapsis to 30.
	} ELSE IF PERIAPSIS < 30000000 {
		SET line_periapsis to 31.
	} ELSE {
		SET line_periapsis to 32.
	} 
	IF old_peri <> line_periapsis {
		SET old_peri TO line_periapsis.
		SET cls TO 1.
	} ELSE IF old_apo <> line_apoapsis {
		SET old_apo TO line_apoapsis.
		SET cls TO 1.
	}
	IF cls = 1 {clearscreen.}		
	PRINT "              APOAPSIS _____ " + ROUND(SHIP:APOAPSIS,0) at (0,line_apoapsis).
	PRINT "                       _____			" at (0,12).
	PRINT "                   ,-:` \;',`'-,		" at (0,13). 
	PRINT "                 .'-;_,;  ':-;_,'.		" at (0,14).
	PRINT "                /;   '/    ,  _`.-\	" at (0,15).
	PRINT "               | '`. (`     /` ` \`|	" at (0,16).
	PRINT "               |:.  `\`-.   \_   / |	" at (0,17).
	PRINT "               |     (   `,  .`\ ;'|	" at (0,18).
	PRINT "                \     | .'     `-'/	" at (0,19).
	PRINT "                 `.   ;/        .'		" at (0,20).
	PRINT "                   `'-._____.			" at (0,21).
	PRINT "              PERIAPSIS ____ " + ROUND(SHIP:PERIAPSIS,0) at (0,line_periapsis).
	PRINT "            ACTUAL  INCLINATION - " + ROUND(ORBIT:INCLINATION,0) at (0,34).
	PRINT "            DESIRED INCLINATION - " + desiredInc at (0,35).
}
function sateliteDeployed{
	clearscreen.
	PRINT "              *********************".
	PRINT "              * SATELITE DEPLOYED *".
	PRINT "              *********************".
	PRINT "              APOAPSIS  :" + ROUND(SHIP:APOAPSIS,0).
	PRINT "              PERIAPSIS :" + ROUND(SHIP:PERIAPSIS,0).
	PRINT "              INCLINATION -" + ROUND(ORBIT:INCLINATION,0).
	PRINT " .       .                   .       .      .     .      .".
	PRINT ".    .         .    .            .     ______".
	PRINT "        .             .               ////////".
	PRINT "      .    .   ________   .  .      /////////     .    .".
	PRINT " .            |.____.  /\        ./////////    .".
	PRINT "            .//      \/  |\     /////////".
	PRINT "     .    .//          \ |  \ /////////       .     .   .".
	PRINT "          ||.    .    .| |  ///////// .     .".
	PRINT ".         ||           | |//`,/////                .".
	PRINT "   .       \\        ./ //  /  \/   .".
	PRINT "             \\.___./ //\` '   ,_\     .     .".
	PRINT ".           .     \ //////\ , /   \                 .    .".
	PRINT "             .    ///////// \|  '  |    .".
	PRINT "     .          ///////// .   \ _ /          .".
	PRINT "              /////////                              .".
	PRINT "       .   ./////////     .     .".
	PRINT "           --------   .                  ..             .".
	PRINT "        .        .         .                       .".
	PRINT "              ________________________".
	PRINT "__------------                        -------------_________".
}
