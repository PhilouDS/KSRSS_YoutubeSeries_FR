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


logMission("LANCEMENT VERS LA LUNE").

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

endProgram(-1, -1, false).