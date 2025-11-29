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


logMission("SATELLITE RELAIS LUNAIRE - SRL03").

local apoCible is 120_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.
local moonPeri is 5_000_000.
local moonInc is 135.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(2).

wait until ship:verticalSpeed > 65.
gravityTurn(apoCible, wantedAzimuth, 85).

wait 0.
AG1 on.

circularization("AP").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.
clearScreen.

wait 0.5.

correctionRelativeInclination(targetBody, 0.05).

wait 0.5.

transfert(targetBody, 0, true).
clearScreen.
wait 0.5.

correctionFutureInclinaison(moonInc - targetBody:orbit:inclination, 3600, 0.1, 1).
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
print "Toujours dans la sphère d'influence de la Terre".
wait 10.
doWarp(time:seconds + ETA:transition + 10).
wait 0.
wait until ship:body = Moon.
print "Dans la sphère d'influence de la Lune".
wait 2.

triggerStaging(0).
thrustLimiter(100, false).
wait 0.

correctionFutureInclinaison(moonInc, 500, 0.1, 0.5, false).
wait 0.5.
exeMnv().
wait 0.5.

correctionFuturPeriapsis(moonPeri, 500, 0.05, 500, false).
wait 0.5.
exeMnv().
wait 0.5.

circularization("PE").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.

unlock throttle.
wait 0.
unlock steering.

wait 1.

endProgram(-1, -1, true).
