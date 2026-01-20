list processors in proc.
local idx is 1.

until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Transfert") {
    runOncePath("lib" + idx + ":/KSRSS_Transfert").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Transfert").
}


global function LuneTerre {
  parameter apo_orbite is 15.
  parameter apo_terre is 50.
  parameter degreesFromNorth is 90.
  parameter pitchAboveHorizon is 90.
  wait 0.
  sas off.
  set navMode to "orbit".
  clearScreen.
  print "Préparation au retour sur Terre.".
  wait 0.
  decollage_Lune(apo_orbite*1000, degreesFromNorth, pitchAboveHorizon).
  wait 1.
  circularization("AP").
  wait 0.5.
  exeMnv().
  wait 0.5.
  logOrbitInfo().
  wait 1.
  clearScreen.
  TransfertLuneTerre(apo_terre*1000).
  clearScreen.
}

function decollage_Lune {
  parameter wanted_apo is 15_000.
  parameter degreesFromNorth is 90.
  parameter pitchAboveHorizon is 90.
  local altitudeAtLaunch is ship:altitude.
  lock throttle to 0.
  lock steering to heading(degreesFromNorth, pitchAboveHorizon).
  compteReboursLune().
  wait until stage:ready.
  wait 0.
  stage.
  wait 0.
  lock throttle to 1.
  wait 0.
  logFlightEvent("Décollage de la Lune").
  clearScreen.
  print "Décollage".
  wait until ship:altitude > altitudeAtLaunch + 50.
  set pitch to 45.
  wait 0.
  lock steering to heading(degreesFromNorth, pitch).
  wait 0.
  wait until ship:orbit:apoapsis > 0.4*wanted_apo.
  until ship:orbit:apoapsis > wanted_apo {
    set pitch to 10*(1-ship:orbit:apoapsis/wanted_apo).
    lock steering to heading(degreesFromNorth, pitch).
    print "Angle : " + round(pitch, 2) + "°   " at (0,2).
    wait 0.
  }
  lock throttle to 0.
  logFlightEvent("Coupure des moteurs").
}

function compteReboursLune {
  parameter decompteSecondes is 3.
  set V1 to getvoice(0).
  set V1:volume to 0.1.
  print("Compte à rebours enclenché.").
  wait 1.
  from {local monCompteur is decompteSecondes.}
  until monCompteur = 0
  step {set monCompteur to monCompteur - 1.}
  do {
    print ("... ") + monCompteur + (" ...").
    V1:play(note(440, 0.2)).
    wait 1.
  }
  V1:play(note(880, 0.5)).
}

function TransfertLuneTerre {
  parameter apo_terre.
  set old_distance to 0.//3* Kerbin:altitudeOf(body:position).
  clearScreen.
  wait 0.
  print "En attente d'alignement...".
  set warp to 4.
  until inegaliteTriangulaire() < old_distance {
    print "Écart : " + round(inegaliteTriangulaire(), 2) at (0,2).
    set old_distance to inegaliteTriangulaire().
    wait 0.1.
  }
  set warp to 3.
  until inegaliteTriangulaire() > old_distance {
    print "Écart : " + round(inegaliteTriangulaire(), 2) at (0,2).
    set old_distance to inegaliteTriangulaire().
    wait 0.1.
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  wait 0.5.
  clearScreen.
  print "Préparation de la manoeuvre.".
  logFlightEvent("Préparation de la manoeuvre vers la Terre").
  local deltaV is HohmannTransfert(ship:orbit:periapsis, ship:body:soiRadius).
  wait 0.5.
  set transNode to node(time:seconds + 0.75*ship:orbit:period, 0, 0, deltaV+20).
  wait 0.
  add transNode.
  until transNode:orbit:hasnextpatch = true {
    set transNode:prograde to transNode:prograde + 1.
    print "Amélioration du noeud de manoeuvre" at (0,3).
    print "Prograde : " + round(transNode:prograde, 1) + " m/s     " at (0,3).
    wait 0.
  }
  wait 1.
  correctionFuturPeriapsisBis(5*apo_terre, -1, 2, 10000, true).
  wait 0.5.
  correctionFuturPeriapsisBis(apo_terre, -1, 0.1, 2500, true).
  wait 0.5.  
  logFlightEvent("Manoeuvre ajustée : +" + round(transNode:deltav:mag - deltaV,1) + " m/s").
  wait 0.5.
  exeMnv().
  wait 0.5.
}


function correctionFuturPeriapsisBis{
  parameter wantedPeriapsis, newTime.
  parameter deltaChange is 0.1.
  parameter marginValue is 1000.
  parameter doNextPatch is true.
  clearScreen.
  local correctNode is choose
    nextNode if newTime < 0 else
    node(time:seconds + newTime, 0, 0, 0).
  
  wait 0.1.
  if newTime > 0 {add correctNode.}
  wait 0.1.

  local newValue is list().
  local oldPeriapsis is choose correctNode:orbit:nextpatch:periapsis if doNextPatch = true else correctNode:orbit:periapsis.

  lock periapsisChanging to choose abs(wantedPeriapsis - correctNode:orbit:nextpatch:periapsis) if doNextPatch = true else abs(wantedPeriapsis - correctNode:orbit:periapsis).

  until abs(oldPeriapsis - wantedPeriapsis) <= marginValue {
    print ("Pe : ") + round(oldPeriapsis,2) at (0,1).

    print "Prograde : " + round(correctNode:prograde, 2) at (0,3).
    print "Normal   : " + round(correctNode:normal, 2) at (0,4).
    print "Radial   : " + round(correctNode:radialOut, 2) at (0,5).
    print "Δv       : " + round(correctNode:deltaV:mag, 2) at (0,7).
    print "Time     : " + round(correctNode:time, 2) at (0,9).

    addNodeTime(correctNode, deltaChange).
    newValue:add(periapsisChanging). subNodeTime(correctNode, deltaChange).
    subNodeTime(correctNode, deltaChange).
    newValue:add(periapsisChanging). addNodeTime(correctNode, deltaChange).

    changeNormal(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeAntiNormal(correctNode, deltaChange).
    changeAntiNormal(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeNormal(correctNode, deltaChange).

    changePrograde(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRetrograde(correctNode, deltaChange).
    changeRetrograde(correctNode, deltaChange).
    newValue:add(periapsisChanging). changePrograde(correctNode, deltaChange).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {addNodeTime(correctNode, deltaChange).}
    if indexNewCorrection = 1 {subNodeTime(correctNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(correctNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(correctNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(correctNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(correctNode, deltaChange).}
    
    set oldPeriapsis to choose correctNode:orbit:nextpatch:periapsis if doNextPatch = true else correctNode:orbit:periapsis.
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}