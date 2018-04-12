ship:rootpart():getmodule("kOSProcessor"):doevent("open terminal").
wait 5.
print "Version 3.0.4".
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
	SET nd TO NEXTNODE.
	SET WARPMODE TO "RAILS".
	SET WARP TO 2.	
	WAIT UNTIL nd:eta <= 180.
	SET WARP TO 0.
	set ship:control:neutralize to true.
	rcs on.
	SET np TO nd:DELTAV:DIRECTION.
	LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
	WAIT UNTIL ABS(np:PITCH - FACING:PITCH) < 1 AND ABS(np:YAW - FACING:YAW) < 1.
	//lock steering to prograde.
	//wait until vang(ship:facing:vector, ship:prograde:vector) < 1.
	set ship:control:fore to 1.
	wait 5.
	lock throttle to 1.
	wait 0.1.
	rcs off.
	wait until nd:eta <= 10.
	stage.
	wait until apoapsis > 384400000.
	list engines in englist.
	for eng in englist
	{
		eng:shutdown().
	}
	stage.
}


wait until altitude > 200000000 or ship:body = moon.
toggle ag3.
wait 5.
toggle ag1.
