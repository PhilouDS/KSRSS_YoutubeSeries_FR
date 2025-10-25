clearScreen.

switch to 1.

if exists("lib:/KSRSS_log") {
  runOncePath("lib:/KSRSS_log").
} else {
  runOncePath("main:/KSRSS_log").
}

if exists("lib:/KSRSS_Manoeuvre") {
  runOncePath("lib:/KSRSS_Manoeuvre").
} else {
  runOncePath("main:/KSRSS_Manoeuvre"). 
}

if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {
  runOncePath("main:/KSRSS_Outils").
}

if exists("lib:/KSRSS_Stats") {
  runOncePath("lib:/KSRSS_Stats").
} else {
  runOncePath("main:/KSRSS_Stats").
}


logMission("SURVOL DE LA LUNE").

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
wait 2.
doWarp(time:seconds + ETA:transition + 10).
wait 2.
print "Dans la sphère d'influence de la Lune".
wait 1.

endProgram(-1, -1, true).