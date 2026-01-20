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

wait until ship:verticalSpeed > 65.

local directionTilt is heading(wantedAzimuth, 85).
print("Pitch program.").
lock steering to directionTilt.
wait until vAng(facing:vector,directionTilt:vector) < 1.
wait until vAng(srfPrograde:vector, facing:vector) < 1.
logFlightEvent("Suivi du prograde : " + round(ship:verticalSpeed,1) + " m/s.").
lock steering to prograde.
wait 1.

endProgram(-1, -1, false).