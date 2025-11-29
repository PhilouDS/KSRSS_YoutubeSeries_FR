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

logMission("MISE EN ORBITE ET RETOUR").
logGeneralInfo(apoCible, ship:geoposition:lat, launchAzimut).

prelaunch().
decollage(launchAzimut, 90, 0).
wait 0.2.
triggerStaging(2).

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
wait 0.5.

HUDTEXT("RUN GOO EXPERIMENT!", 10, 2, 20, red, true).

wait 10.

local waitChrono is time:seconds.
set warp to 3.
wait until time:seconds > waitChrono + 641. // goo => 10'41"
set warp to 0.
wait until kuniverse:timewarp:rate = 1.
wait 5.

lock steering to retrograde.
lock throttle to 0.05.
print "Alignement en cours".
alignFacing(retrograde:vector, 20).
print "Alignement fini".
lock throttle to 1.

wait until ship:orbit:periapsis < 0 OR ship:availablethrust = 0.
lock throttle to 0.
wait 1.

until stage:number = 0 {
  wait until stage:ready.
  stage.
}
wait 0.

logFlightEvent("Expulsion du module de service et armement des parachutes").

wait until ship:altitude < atmHeight.
logFlightEvent("Réentrée dans l'atmosphère.").

wait until ship:altitude < atmTransition.
lock steering to srfRetrograde.

wait until ship:verticalSpeed > -10.
logFlightEvent("Parachutes complètement déployés.").


wait until ship:status = "landed" or ship:status = "splashed".
wait until addons:career:isRecoverable(ship).
logAtterrissage(false).
wait 1.

endProgram(-1, 0).