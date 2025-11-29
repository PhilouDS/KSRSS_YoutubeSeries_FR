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

set vesselTarget to VESSEL("RDV").
if not vesselTarget:crew():empty {set kerbalToRescue to vesselTarget:crew()[0].}
set target to vesselTarget.
local coef_rdv is
  choose 1.75 if vesselTarget:orbit:apoapsis < 200_000
  else 0.6.
local apoCible is coef_rdv * vesselTarget:orbit:apoapsis.
set missionName to "MISSION DE SAUVETAGE - " + kerbalToRescue:name.

logMission(missionName).

logSection("VAISSEAU EN DÉTRESSE").
addLogLeftEntry("Nous partons au secours de : " + kerbalToRescue:name).
addLogLeftEntry("Son vaisseau est actuellement à " + round(target:altitude,2) + " m d'altitude.").
emptyLogLine().

local wantedInclination is vesselTarget:orbit:inclination.

if abs(wantedInclination) > ship:geoposition:lat {
  set wantedAzimuth to launchWindowAzimuth(vesselTarget, apoCible, wantedInclination).
} else {
  set wantedInclination to ship:geoposition:lat.
  set wantedAzimuth to 90.
  print("pas de fenêtre calculée").
  wait 2.
  logGeneralInfo(apoCible, wantedInclination, wantedAzimuth).
}

emptyLogLine().


prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(1).


when ship:altitude > atmAlt then {
  logFlightEvent("Espace atteint").
}

wait 1.

wait until ship:verticalSpeed > 60.
gravityTurn(apoCible, wantedAzimuth, 85).

AG1 on.
wait 1.

circularization("Ap").
wait 1.
exeMnv().
wait 0.
logOrbitInfo().
wait 1.

correctionRelativeInclination(vesselTarget, 0.03).
wait 1.
circularization("Ap").
wait 1.
exeMnv().

clearScreen.

wait 1.
rendezVous(vesselTarget).

wait 1.

endProgram(-1, -1, false).