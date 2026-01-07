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
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Transfert") {
    runOncePath("lib" + idx + ":/KSRSS_Transfert").
    break.
  } else {set idx to idx + 1.}
}
if idx >= proc:length {
  runOncePath("main:/KSRSS_Transfert").
}

compile("0:/Rover_v2.ks").
wait 0.
copypath("0:/Rover_v2.ksm", "main:/" + "rover.ksm").
wait 0.
print "Programme du rover chargé".
wait 0.

local rover is ship:partstagged("rover")[0].

local titreMission is "ROVER LUNAIRE".
logMission(titreMission).

local apoCible is 150_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.
local moonPeri is 10_000.
local moonInc is 90.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(4).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
  AG2 on. // COIFFE
}

wait until ship:verticalSpeed > 60.
gravityTurn(apoCible, wantedAzimuth, 85).
wait 1.
rcs on.
AG1 on. // PANNEAUX SOLAIRES

circularization("AP").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.
clearScreen.

wait 0.5.

correctionRelativeInclination(targetBody, 0.05).

wait 0.1.

transfert(targetBody, 1_000_000).
clearScreen.

wait 1.

correctionFutureInclinaison(moonInc - ship:orbit:inclination, 3600, 0.1, 1).
wait 0.5.
exeMnv().
wait 0.5.

correctionFuturPeriapsis(moonPeri, 7200).
wait 0.5.
exeMnv().
wait 0.5.

set steerVector to theNormalVector().
lock steering to steerVector.
alignFacing(steerVector).
wait 1.

when ship:body = moon then {
  logFlightEvent("La sonde a atteint la sphère d'influence de la Lune.").
}

doWarp(time:seconds + ETA:transition - 120).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
print "Toujours dans la sphère d'influence de la Terre".
wait 2.
doWarp(time:seconds + ETA:transition).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 0.
wait until ship:body = Moon.
print "Dans la sphère d'influence de la Lune".
wait 2.

thrustLimiter(100, false).
wait 0.

correctionFutureInclinaison(moonInc, 500, 0.05, 0.5, false).
wait 0.5.
if nextNode:deltav:mag >= 0.1 {exeMnv().}
wait 0.5.

correctionFuturPeriapsis(moonPeri, 500, 0.025, 500, false).
wait 0.5.
if nextNode:deltav:mag >= 0.1 {
  exeMnv().
}
else {
  remove nextNode.
}
wait 0.5.

triggerStaging(1).
lights on.

circularization("PE").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.
clearScreen.

set warp to 2.

wait until terminal:input:haschar.
set warp to 0.
clearScreen.
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.

lights on.
wait 1.

//landing(kp, ki, kd, doit découpler avant d'annuler la vitesse horizontale, étage pour l'atterrissage)
landing(3.15, 26.25, 0.0945, false, 1).

wait 1.

set oldShipName to ship:name.
wait 0.

logAtterrissage(false).
wait 1.

underscoreLogLine().
addLogCenterEntry("~ DÉCOUPLAGE DU ROVER ~").
upperscoreLogLine().
emptyLogLine().
wait 0.
brakes on.
wait 0.
rover:controlfrom().
set designation to "RL-BAL-GC-AS2C".
set shipname to designation + "_beta".

wait 0.
wait until ship:velocity:surface:mag < 0.1.
set startChrono to time:seconds.
clearScreen.
print "En attente de stabilisation..." at (0,0).
until (time:seconds - startChrono) > 10 {
  print round(time:seconds - startChrono, 1) + "s    " at (32, 0).
  wait 0.
}
wait until ship:velocity:surface:mag < 0.05.
wait until stage:ready.
brakes off.
wait 0.
stage.
lock wheelThrottle to 0.25.
wait 3.
lock wheelThrottle to 0.
brakes on.
wait until ship:velocity:surface:mag < 0.1.
wait 5.

clearScreen.

print "En attente de nouvelles instructions." at (0,0).
print "Utiliser le programme suivant :" at (0,1).
print "=========================================" at (0,3).
print "run rover(vitesse max, coef braquage max)" at (0,4).
print "=========================================" at (0,5).
print "      Vitesse max : 10 m/s" at (0,6).
print "Coef braquage max : 0.5" at (0,7).