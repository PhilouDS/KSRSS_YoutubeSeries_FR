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
  if exists("lib" + idx + ":/KSRSS_RDV") {
    runOncePath("lib" + idx + ":/KSRSS_RDV").
    break.
  } else {set idx to idx + 1.}
}
if idx >= proc:length {
  runOncePath("main:/KSRSS_RDV").
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

local apoCible is 450_000.
local wantedInclination is 90.
local launchAzimut is 360 + correctionLaunchInclination(wantedInclination, apoCible).

lock steering to heading(launchAzimut, 90).

set missionName to "MISE EN ORBITE DU TÉLÉSCOPE".
logMission(missionName).
logGeneralInfo(apoCible, ship:geoposition:lat, launchAzimut).

prelaunch().
decollage(launchAzimut).
wait 0.2.
triggerStaging(0).


when ship:altitude > atmAlt then {
  logFlightEvent("Espace atteint").
  AG2 on.
  logFlightEvent("Coiffe déployée").
}

wait 1.

wait until ship:verticalSpeed > 80.
gravityTurn(apoCible, launchAzimut, 85).

AG1 on.
wait 1.

circularization("Ap").
wait 1.
exeMnv().
wait 0.
logOrbitInfo().
wait 1.
unlock steering.
wait 1.

endProgram(-1, -1, false).