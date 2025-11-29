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
  if exists("lib" + idx + ":/KSRSS_Transfert") {
    runOncePath("lib" + idx + ":/KSRSS_Transfert").
    break.
  } else {set idx to idx + 1.}
}
if idx >= proc:length {
  runOncePath("main:/KSRSS_Transfert").
}

local biome_list is  // -> Dépend des biomes visités
  list(
    "Lowlands",
    "Oceanus Procellarum"
  ).

logMission("ALUNISSAGE - PÔLE NORD").

local apoCible is 120_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.
local moonPeri is 10_000.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(4).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
}

wait until ship:verticalSpeed > 50. // Valeur initiale = 50
gravityTurn(apoCible, wantedAzimuth, 85).
wait 1.
rcs on.
AG1 on. // ANTENNES

circularization("AP").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.
clearScreen.

wait 0.5.

correctionRelativeInclination(targetBody, 0.05).

wait 0.1.
triggerStaging(2).
wait 0.1.

transfert(targetBody, moonPeri).
clearScreen.

wait 1.


correctionFutureInclinaison(90 - ship:orbit:inclination, 3600, 0.1, 1).
wait 0.5.
exeMnv().
wait 0.5.

correctionFuturPeriapsis(0.5*moonPeri, 7200).
wait 0.5.
exeMnv().
wait 0.5.

set steerVector to theNormalVector().
lock steering to steerVector.
alignFacing(steerVector).
wait 1.

when ship:body = moon then {
  logFlightEvent("La sonde a atteint la sphère d'influence de la Lune.").
}

doWarp(time:seconds + ETA:transition - 120).
print "Toujours dans la sphère d'influence de la Terre".
wait 10.
doWarp(time:seconds + ETA:transition + 10).
wait 0.
print "Dans la sphère d'influence de la Lune".
wait until ship:body = Moon.
wait 2.

thrustLimiter(100, false).
wait 0.

correctionFutureInclinaison(90, 500, 0.1, 0.5, false).
wait 0.5.
exeMnv().
wait 0.5.

correctionFuturPeriapsis(moonPeri, 500, 0.05, 500, false).
wait 0.5.
exeMnv().
wait 0.5.

circularization("PE").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().
wait 1.
clearScreen.

triggerStaging(0).


set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
until abs(90 - ship:geoposition:lat) < 3 {
  set warp to 3.
  set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
  print "BIOME : " + actual_biome + "                    " at (0,0).
  if biome_list:find(actual_biome) >= 0 {
    print "Déjà visité..." at (0,1).
  } else {
    print "Biome inconnu" at (0,1).
  }
  wait 1.
}
set warp to 0.
clearScreen.
wait until kuniverse:timewarp:rate = 1.


landing(2.85, 23.197674, 0.087536, false).

wait 1.

set oldShipName to ship:name.
wait 0.

set shipname to ship:name + "_" + addons:scanSat:getBiome(ship:body, ship:geoPosition).

logAtterrissage(false).
wait 1.


endProgram(-1, -1, true, oldShipName).