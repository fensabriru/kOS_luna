SET desiredInc TO 28.     //Desired inclination - leave default if you dont care
SET moonperi TO 500000.
runpath("0:/launch_lib.ks").
SET waitloop TO 0.
wait 5.

ship:rootpart():getmodule("kOSProcessor"):doevent("open terminal").
if ship:status() = "prelaunch"
{
	switch to 0.
	run once rendezvous.
	if TimeToLaunchWindow(GetOrbitNormal(moon), 28) > 300
	{
		warpto(time:seconds + TimeToLaunchWindow(GetOrbitNormal(moon), 28) - 300).
	}
	wait until TimeToLaunchWindow(GetOrbitNormal(moon), 28) < 290.
	set target to "moon".
	run launch(200000, 87, GetOrbitNormal(moon)).	
}
if apoapsis < 500000 and ship:body = earth
{
	TOGGLE AG3.
	SET WARP TO 0.
	Hohmann().
	SET nd TO NEXTNODE.
	set ship:control:neutralize to true.
	RCS ON.
	SET np TO nd:DELTAV:DIRECTION.
	LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
	UNTIL waitloop = 1 {
		IF vang(ship:facing:vector, nd:DELTAV ) < 1 { BREAK. }
	} 
	RCS OFF.
	SAS ON.
	SET WARPMODE TO "RAILS".
	SET WARP TO 3.	
	WAIT UNTIL nd:eta <= 500.
	SET WARP TO 1.	
	WAIT UNTIL nd:eta <= 100.
	SET WARP TO 0.
	WAIT UNTIL nd:ETA <= 80.
	SAS OFF.
	RCS ON.
	NextStage().
	lock throttle to 1.
	set ship:control:fore to 1.
	UNTIL waitloop = 1 {
		//report_sat().
		IF nd:deltav:mag < 0.5 { BREAK. }
	}
	lock throttle to 0.
	RCS OFF.
	UNLOCK STEERING.
	UNLOCK THROTTLE.
	REMOVE myNode.
	NextStage().
}
wait until ship:body = moon. 
circularize("periapsis").
SET nd TO NEXTNODE.
SAS OFF.
set ship:control:neutralize to true.
RCS ON.
SET np TO nd:DELTAV:DIRECTION.
LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
UNTIL waitloop = 1 {
	IF vang(ship:facing:vector, nd:DELTAV ) < 1 { BREAK. }
} 
RCS OFF.
SET WARPMODE TO "RAILS".
SET WARP TO 2.	
WAIT UNTIL nd:eta <= 60.
SET WARP TO 1.	
WAIT UNTIL nd:eta <= 15.
SET WARP TO 0.
WAIT UNTIL nd:ETA <= 0.
set ship:control:neutralize to true.
set ship:control:fore to 1.
RCS ON.
UNTIL waitloop = 1 {
	IF nd:deltav:mag < 0.5 { BREAK. }
}
RCS OFF.
REMOVE myNode.
changeper(moonperi).
SET nd TO NEXTNODE.
set ship:control:neutralize to true.
RCS ON.
SET np TO nd:DELTAV:DIRECTION.
LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
UNTIL waitloop = 1 {
	IF vang(ship:facing:vector, nd:DELTAV ) < 1 { BREAK. }
} 
RCS OFF.
SET WARPMODE TO "RAILS".
SET WARP TO 2.	
WAIT UNTIL nd:eta <= 60.
SET WARP TO 1.	
WAIT UNTIL nd:eta <= 15.
SET WARP TO 0.
WAIT UNTIL nd:ETA <= 0.
set ship:control:neutralize to true.
set ship:control:fore to 1.
RCS ON.
UNTIL waitloop = 1 {
	IF nd:deltav:mag < 0.5 { BREAK. }
}
RCS OFF.
REMOVE myNode.
UNLOCK STEERING.
UNLOCK THROTTLE.
SAS ON.
