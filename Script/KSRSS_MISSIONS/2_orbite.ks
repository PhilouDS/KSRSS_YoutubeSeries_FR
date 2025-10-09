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

local apoCible is 120_000.
local launchAzimut is 90.
lock steering to heading(launchAzimut, 90).

logMission("MISE EN ORBITE AUTOMATISÉE").
logGeneralInfo(apoCible, ship:geoposition:lat, launchAzimut).

prelaunch().
decollage(launchAzimut).
wait 0.2.
triggerStaging(0).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
}

wait until ship:verticalSpeed > 85.
gravityTurn(apoCible, launchAzimut, 85).
wait 1.

circularization("Ap").
wait 0.1.
exeMnv(false).

wait 0.2.

logOrbitInfo().
wait 1.