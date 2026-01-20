clearScreen.

switch to "main".

list processors in proc.

local lib is list(
  "KSRSS_log",
  "KSRSS_Outils",
  "KSRSS_Manoeuvre",
  "KSRSS_Stats",
  "KSRSS_Systemes",
  "KSRSS_Transfert",
  "KSRSS_Transfert_LuneTerre"
).
local idx is 1.

for L in lib {
  set idx to 1.
  until idx = proc:length {
    if exists("lib" + idx + ":/" + L) {
      runOncePath("lib" + idx + ":/" + L).
      break.
    } else {set idx to idx + 1.}
  }
  if idx = proc:length {
    runOncePath("main:/" + L).
  }
}

local titreMission is "ÉCHANTILLONS LUNAIRES".
logMission(titreMission).

local apoCible is 150_000.
local targetBody is Moon.
local wantedInclination is targetBody:orbit:inclination.
local moonPeri is 12_000.
local moonInc is 1.1*targetBody:orbit:inclination.

set wantedAzimuth to launchWindowAzimuth(targetBody, apoCible, wantedInclination).

prelaunch().
decollage(wantedAzimuth, 90).
wait 1.
triggerStaging(4).

when ship:altitude > atmHeight then {
  logFlightEvent("Espace atteint").
  deployerCoiffe().
}

wait until ship:verticalSpeed > 50.
gravityTurn(apoCible, wantedAzimuth, 85).
wait 1.
deployerAntennes().
AG1 on.
lights on.

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

transfert(targetBody, 1_000_000).
clearScreen.

wait 1.

correctionFutureInclinaison(moonInc, 3600, 0.1, 1).
wait 0.5.
exeMnv().
wait 0.5.

correctionFuturPeriapsis(moonPeri, 7200).
wait 0.5.
exeMnv().
wait 0.5.

when ship:body = moon then {
  logFlightEvent("La sonde a atteint la sphère d'influence de la Lune.").
}

doWarp(time:seconds + ETA:transition - 120).
print "Toujours dans la sphère d'influence de la Terre".
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 2.
doWarp(time:seconds + ETA:transition).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 0.
wait until ship:body = Moon.
print "Dans la sphère d'influence de la Lune".
wait 2.

thrustLimiter(100, false).
wait 0.

correctionFuturPeriapsis(moonPeri, 500, 0.025, 500, false).
wait 0.5.
exeMnv().
wait 0.5.

circularization("PE").
wait 0.5.
exeMnv().
wait 0.5.
logOrbitInfo().

wait until terminal:input:haschar.
set warp to 0.
clearScreen.
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.

lights on.
wait 1.

//landing(kp, ki, kd, doit découpler avant d'annuler la vitesse horizontale, étage pour l'atterrissage)
landing(3.12, 25.876777, 0.094046, false, 2).

wait 1.

logAtterrissage(false).
wait 1.
unlock steering.
wait 0.
thrustLimiter(100, false).
wait 0.
clearScreen.
sas on.
wait 0.
print "EXPÉRIENCE EN PRÉPARATION" at (0,0).
print "=========================" at (0,1).
wait 1.

ouvrirService().
  print "Ouverture de la baie utilitaire." at (0,3).
wait 2.
ag2 on.
  logFlightEvent("Glairine mystérieuse : expérience en cours.").
  print "Glairine mystérieuse : expérience en cours." at (0,4).
wait 5.

doWarp(time:seconds + 11*60).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.

ag3 on.
  logFlightEvent("Glairine mystérieuse : expérience terminée.").
  print "Glairine mystérieuse : expérience terminée." at (0,5).
wait 1.
fermerService().
  print "Fermeture de la baie utilitaire." at (0,6).
wait 2.

sas off.

LuneTerre(15, 50).

wait 1.

when ship:body = Kerbin then {
  logFlightEvent("La sonde est de retour dans la sphère d'influence de la Terre.").
}

doWarp(time:seconds + ETA:transition - 120).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 2.
doWarp(time:seconds + ETA:transition).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 0.
wait until ship:body = Kerbin.
wait 2.


doWarp(time:seconds + ETA:periapsis - 5*60).
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 0.

set warp to 2.
wait until ship:altitude < 160_000.
set warp to 0.
wait until kuniverse:timewarp:rate = 1.
wait until kuniverse:timewarp:issettled.
wait 0.

when ship:altitude < atmHeight then {
  logFlightEvent("Entrée dans l'atmosphère").
  print "Entrée dans l'atmosphère".
  wait 0.
  retracterAntennes().
  wait 1.
  print "Antenne rétractée".
  set navMode to "orbit".
}

lock steering to retrograde.
wait until ship:altitude < 130_000.
lock throttle to 1.
wait until ship:availablethrust < 0.1.
lock throttle to 0.

set aVector to theNormalVector().
lock steering to aVector.
alignFacing(aVector,1).
wait 1.
until stage:number = 0 {
  wait until stage:ready.
  stage.
}
wait 0.5.
lock steering to retrograde.
set navMode to "orbit".
wait 1.

when ship:altitude < 25_000 then {
  set navMode to "surface".
  lock steering to srfRetrograde.
}

when ship:verticalspeed > -100 and ship:dynamicpressure * constant:atmtokpa < 1 then {
  deployerAntennes().
  print "Antenne déployée".
}

when ship:verticalspeed > -25 then {
  unlock steering.
  logFlightEvent("Parachutes de freinage complètement déployés").
  print "Parachutes de freinage complètement déployés".
}

when ship:verticalspeed > -9 then {
  logFlightEvent("Parachute principal complètement déployé").
  print "Parachute principal complètement déployé".
}

until ship:status = "landed" or ship:status = "splashed" {
  print "  Vitesse surface  : " + round(ship:velocity:surface:mag, 2) + " m/s       " at (0,11).
  print "Vitesse verticale  : " + round(ship:verticalspeed, 2) + " m/s       " at (0,12).
  print "         Altitude  : " + round(ship:altitude, 2) + " m       " at (0,13).
  print "Pression dynamique : " + round(ship:dynamicpressure * constant:atmtokpa, 4) + " kPa         " at (0,14).
}

clearScreen.

wait 0.

endProgram(-1, 1, true).