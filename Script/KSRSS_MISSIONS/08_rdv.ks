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

logMission("RÉCUPÉRATION DES DONNÉES SCIENCE JR").

set vesselTarget to VESSEL("JR-OBT-H").
set target to vesselTarget.
local apoCible is 1.75 * vesselTarget:orbit:apoapsis.

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
rcs on.
wait 1.

circularization("Ap").
wait 1.
print "Avant mnv".
exeMnv().

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

endProgram(-1, -1, true).