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


local titreMission is "SCANNER - SITE" + ship:name.
logMission(titreMission).

local apoCible is 140_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.
local moonPeri is 120_000.
local moonInc is 90.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(1).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
  AG2 on. // COIFFE
  logFlightEvent("Coiffe déployée").
}

wait until ship:verticalSpeed > 55.
gravityTurn(apoCible, wantedAzimuth, 85).
wait 1.
AG1 on. // ANTENNES

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

when ship:body = moon then {
  logFlightEvent("La sonde a atteint la sphère d'influence de la Lune.").
}

doWarp(time:seconds + ETA:transition - 120).
print "Toujours dans la sphère d'influence de la Terre".
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
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
exeMnv().
wait 0.5.

correctionFuturPeriapsis(moonPeri, 500, 0.025, 500, false).
wait 0.5.
exeMnv().
wait 0.5.

circularization("PE").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().

wait 1.
AG3 on. // SCANNERS
logFlightEvent("Scanners activés").

wait 5.

endProgram(-1, -1, true).