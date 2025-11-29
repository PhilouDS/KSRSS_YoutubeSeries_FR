clearScreen.
switch to "main".

list processors in proc.
local idx is 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_log") {
    runOncePath("lib" + idx + ":/KSRSS_log").
    break.
  } else {set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_log").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Outils") {
    runOncePath("lib" + idx + ":/KSRSS_Outils").
    break.
  } else {set idx to idx + 1.}
}
if idx >= proc:length {
  runOncePath("main:/KSRSS_Outils").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Manoeuvre") {
    runOncePath("lib" + idx + ":/KSRSS_Manoeuvre").
    break.
  } else {set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Manoeuvre").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Stats") {
    runOncePath("lib" + idx + ":/KSRSS_Stats").
    break.
  } else {set idx to idx + 1.}
}
if idx >= proc:length {
  runOncePath("main:/KSRSS_Stats").
}

local apoCible is 120_000.
local finalApo is geoAlt() - ship:body:radius. // 8_948_293.03531072

local launchAzimut is 90.
lock steering to heading(launchAzimut, 90).

logMission("SATELLITE GEOSTATIONNAIRE").
logGeneralInfo(apoCible, ship:geoposition:lat, launchAzimut).

prelaunch().
decollage(launchAzimut).
wait 0.2.
triggerStaging(1).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
}

wait until ship:verticalSpeed > 55.
gravityTurn(apoCible, launchAzimut, 85).
wait 1.
RCS on.
wait 0.
AG1 on.

circularization("Ap").
wait 0.1.
exeMnv().

wait 0.2.

logOrbitInfo().
wait 0.5.

doWarp(time:seconds + 1*ship:orbit:period/3).
wait 0.

alignFacing(prograde:vector).
wait 0.1.
lock steering to prograde.
wait 2.

lock throttle to 1.

when (ship:orbit:apoapsis >= 0.9 * finalApo) then {
  lock throttle to 0.5.
}

when (ship:orbit:apoapsis >= 0.95 * finalApo) then {
  lock throttle to 0.2.
}

when (ship:orbit:apoapsis >= 0.975 * finalApo) then {
  lock throttle to 0.05.
}

wait until ship:orbit:apoapsis >= finalApo.

lock throttle to 0.

wait 1.

print "Circularisation".

circularization("Ap").
wait 0.1.
exeMnv().
wait 0.1.

print "Synchronisation de la période orbitale en cours".

set deltaPeriod to (Kerbin:rotationPeriod - ship:orbit:period).
if deltaPeriod > 0 {
  lock steering to prograde.
} else {
  lock steering to retrograde.
}
wait 2.
thrustLimiter(10).

lock throttle to 0.01.
wait until abs(Kerbin:rotationPeriod - ship:orbit:period) < 1.
lock throttle to 0.

wait 0.1.
print "Fin de la synchronisation".
thrustLimiter(100).
wait 0.1.

set aVector to theNormalVector().
wait 0.
lock steering to aVector.
alignFacing(aVector,1).
wait 1.
unlock steering.
wait 0.
logOrbitInfo().

wait 0.5.

endProgram(-1, -1, homeConnection:isconnected).