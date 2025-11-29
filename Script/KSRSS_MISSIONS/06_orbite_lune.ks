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


logMission("ORBITE LUNAIRE").

local apoCible is 120_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(1).

wait until ship:verticalSpeed > 55.
gravityTurn(apoCible, wantedAzimuth, 85).
wait 1.
rcs on.

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

transfert(targetBody, -50_000).
clearScreen.
wait 1.

set coef_prog to 1.

if (ship:orbit:nextpatch:periapsis < 0) {
  if (ship:orbit:nextpatch:inclination < 90) {
    set coef_prog to -1.
  }
  alignFacing(coef_prog * prograde:vector).
  lock throttle to 0.05.
  wait until (ship:orbit:nextpatch:periapsis > 40_000).
  wait 0.
  lock throttle to 0.
}

rcs off.

when ship:body = moon then {
  logFlightEvent("La sonde a atteint la sphère d'influence de la Lune.").
}

doWarp(time:seconds + ETA:transition - 120).
print "Toujours dans la sphère d'influence de la Terre".
wait 10.
doWarp(time:seconds + ETA:transition + 10).
wait 0.
print "Dans la sphère d'influence de la Lune".
wait 2.

unlock throttle.
unlock steering.

wait until ship:orbit:eccentricity < 0.01.
wait 20.
logOrbitInfo().
wait 1.

endProgram(-1, -1, true).
