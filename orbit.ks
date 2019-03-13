SET perigee TO 200000.		//Desired orbit (periapsis)
SET desiredInc TO 0.     	//Desired inclination - leave default if you dont care (be carefull for launch site latitude... basicaly you can incline to min lat+5)
SET burnout TO 0.         	//Set to 0 for circular orbit or exact apogee. Set to 1 to full burnout. 
SET apogee TO 0.	  	//Set desired apogee after circularization (if fuel left) 0 for circular orbit.
SET pitchover_angle TO 87.	//Starting pitchover angle (Higher TWR can have lower values)

ship:rootpart():getmodule("kOSProcessor"):doevent("open terminal").
print "Version 3.1".
if ship:status() = "prelaunch"
{
	switch to 0.
	run once rendezvous.
	RCS ON.
	SET vec TO V(desiredInc,0,0).
	run launch(perigee , pitchover_angle, vec, burnout, apogee).
}
UNLOCK STEERING.
UNLOCK THROTTLE.
SAS ON.
