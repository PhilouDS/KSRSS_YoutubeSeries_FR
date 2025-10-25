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

if exists("lib:/KSRSS_RDV") {
  runOncePath("lib:/KSRSS_RDV").
} else {
  runOncePath("main:/KSRSS_RDV").
}

logMission("RÉCUPÉRATION DES DONNÉES SCIENCE JR").

set transmit to 1.

set vesselTarget to VESSEL("JR-OBT").
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

when homeConnection:isconnected AND exists("main:/" + ship:name + ".txt") then {
  wait 0.
  copyPath("main:/" + ship:name + ".txt", "0:/KSRSS_LOGS/" + ship:name + "_transmission_" + transmit + ".txt").
  wait 0.
  deletePath("main:/" + ship:name + ".txt").
  wait 0.
  set transmit to transmit + 1.
  print "Transmission du log de mission".
  wait 0.
  preserve.
}

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