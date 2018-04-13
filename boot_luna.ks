ship:rootpart():getmodule("kOSProcessor"):doevent("open terminal").
wait 5.
print "Version 3.0.5".
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
	run launch(200000, 82, GetOrbitNormal(moon)).
}
if apoapsis < 500000 and ship:body = earth
{
	SET WARP TO 0.
	Hohmann().
	SET nd TO NEXTNODE.
	//Next line is important, this is the only way how control RCS only ship. If you know better way please advice :) 
	set ship:control:neutralize to true.
	RCS ON.
	SET np TO nd:DELTAV:DIRECTION.
	LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
	WAIT UNTIL ABS(np:PITCH - FACING:PITCH) < 1 AND ABS(np:YAW - FACING:YAW) < 1.
	set ship:control:fore to 1.
	wait 5.
	lock throttle to 1.
	rcs off.
	SAS ON.
	SET WARPMODE TO "RAILS".
	SET WARP TO 2.	
	WAIT UNTIL nd:eta <= 60.
	SET WARP TO 1.	
	WAIT UNTIL nd:eta <= 15.
	SET WARP TO 0.
	WAIT UNTIL nd:ETA <= 0.
	STAGE.
	wait until apoapsis > 384400000.
	list engines in englist.
	for eng in englist
	{
		eng:shutdown().
	}
	stage.
}
REMOVE nd.
TOGGLE ag3.
