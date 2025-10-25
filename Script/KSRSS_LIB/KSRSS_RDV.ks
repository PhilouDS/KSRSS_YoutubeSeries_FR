if exists("lib:/KSRSS_log") {
  runOncePath("lib:/KSRSS_log").
} else {runOncePath("main:/KSRSS_log").}

if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {runOncePath("main:/KSRSS_Outils").}

if exists("lib:/KSRSS_Stats") {
  runOncePath("lib:/KSRSS_Stats").
} else {runOncePath("main:/KSRSS_Stats").}

// rendezVous: we suppose that the target is always
// in a lower orbit than the ship.
// (because first rescue contracts often use very low orbit so it's better to be
// in a higher orbit)
// Warning: orbits are circular and have the same inclination!!

global function rendezVous {
  parameter vesselTarget is target.
  parameter allActions is "auto".
  set navMode to "orbit".
  
  logFlightEvent("Début de la procédure de rendez-vous").
  // local higher is ship:orbit:periapsis > target:orbit:apoapsis.
  // if higher {lock steering to retrograde.}

  local targetAngle is computeTargetAngle(vesselTarget).
  if targetAngle < 180 {
    set targetAngle to 180 - targetAngle.
  }
  else {
    set targetAngle to 360 + (180 - targetAngle).
  }
  lock phaseAngle to computePhaseAngle(vesselTarget).

  lock theDiff to phaseAngle - targetAngle.
  if targetAngle - 20 < 0 {lock theDiff to phaseAngle - 360 + targetAngle.}

  until abs(theDiff) > 20 {set warp to 3.}
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  wait 1.
  
  lock steering to theNormalVector().
  wait 1.

  clearScreen.
  print " ═════ RENDEZ-VOUS ═════".
  print "Angle ciblé : " + round(targetAngle,2) + ("°     ") at (0,1).

  set warp to 4.
  until abs(theDiff) < 20 {
    print "Angle actuel : " + round(phaseAngle,2) + ("°     ") at (0,3).
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  clearScreen.
  wait 5.

  local deltaAngle is abs(theDiff).
  local deltaTime is deltaAngle * ship:orbit:period / 360.

  local deltaV is HohmannTransfert(ship:altitude, vesselTarget:orbit:apoapsis).
  local transferNode is node(time:seconds + deltaTime, 0, 0, deltaV).
  add transferNode.

  local newDistance is relativePositionAt(transferNode).
  wait 0.2.
  clearScreen.
  wait 0.2.
  print " ═════ DISTANCE RELATIVE ═════".
  print ("Avant correction : ") + round(newDistance,2) + (" m     ") at (0,1).

  until newDistance < 50_000 {
    set transferNode:time to transferNode:time + 0.3.
    set newDistance to relativePositionAt(transferNode).
    print ("En cours de correction : ") + round(newDistance,2) + (" m     ") at (0,2).
  }

  wait 0.1.

  until newDistance < 15_000 {
    set transferNode:time to transferNode:time + 0.1.
    set newDistance to relativePositionAt(transferNode).
    print ("En cours de correction : ") + round(newDistance,2) + (" m     ") at (0,2).
  }

  local oldDistance is 16_000.
  set newDistance to relativePositionAt(transferNode).

  until newDistance > oldDistance {
    set oldDistance to relativePositionAt(transferNode).
    set transferNode:time to transferNode:time + 0.1.
    set newDistance to relativePositionAt(transferNode).
    print ("En cours de correction : ") + round(newDistance,2) + (" m     ") at (0,2).
  }
  wait 0.1.
  
  // until relativePositionAt(transferNode) < 150 {
  //   set transferNode:time to transferNode:time + 0.001.
  //   set newDistance to relativePositionAt(transferNode).
  //   print newDistance at (0,2).
  // }
 
  wait 0.5.
  clearScreen.

  logFlightEvent("Acquisition du ciblage de la cible").

  exeMnv().

  wait 1.

  local newNode is node(time:seconds + 360, 0, 0, 0).
  add newNode.
  wait 0.1.
  correctionApproach(newNode, target, 0.1, 0.01).
  wait 0.5.
  correctionApproach(newNode, target, 0.05, 0.001).
  wait 0.5.
  lock relativeDistance to (ship:orbit:position - vesselTarget:orbit:position):mag.

  when relativeDistance <= 2000 then {
    logFlightEvent("Cible en approche (" + round(relativeDistance, 2) + " m)").
  }

  when relativeDistance <= 100 then {
    logFlightEvent("Cible à proximité. En attente du transfert.").
  }

  if allActions = "auto" {
    exeMnv().
    wait 1.
    HUDTEXT("MODIFICATION MANUELLE REQUISE !", 10, 2, 20, red, true).
    print "Créer un noeud de manoeuvre pour améliorer l'approche".
    print "Dès que le noeud de manoeuvre est correct, taper 'a'.".
    terminal:input:clear().
    wait 0.1.
    wait until hasNode.
    wait until terminal:input:haschar.
    wait 0.1.
    exeMnv().
    wait 0.5.

    set navMode to "target".
    wait 1.
    lock steering to retrograde.
    alignFacing(retrograde:vector).
    wait 1.
    clearScreen.
    wait 1.
    local burningDistance is burningApproach(vesselTarget)[0].
    local burningTime is burningApproach(vesselTarget)[1].
    
    if burningTime < 10 {
      local perc is max(0.5, 10 * burningTime).
      thrustLimiter(perc).
      set burningTime to burningTime*100/perc.
      set burningDistance to burningApproach(vesselTarget)[0].
    }
    wait 1.

    clearScreen.  
    print " ═════ PARAMÈTRES ═════" at (0,10).
    print (" Allumage des moteurs pendant : ") + round(burningTime,2) + (" s     ") at (0,11).
    print ("À une distance de la cible de : ") + round(burningDistance,2) + (" m     ") at (0,12).
    wait 0.5.

    lock relativeDistance to (ship:orbit:position - vesselTarget:orbit:position):mag.
    lock myVel to relativeVelocity(vesselTarget).
    set mapView to true.
    wait 1.
    set warp to 3.
    wait until relativeDistance <= burningDistance + 7_000.
    set warp to 0.
    wait until kuniverse:timewarp:rate = 1.
    logFlightEvent("Cible en approche (" + round(relativeDistance, 2) + " m)").
    set mapView to false.

    
    lock steering to (target:velocity:orbit - ship:velocity:orbit).
    wait 1.
    until relativeDistance <= burningDistance + 50 {
      print ("Distance actuelle de la cible : ") + round(relativeDistance,2) + (" m     ") at (0,5).
    }.

    print ("                                                             ") at (0,5).

    set tset to 0.
    lock throttle to tset.

    set done to False.
  //  set dv0 to myVel.
    lock myVel to relativeVelocity(vesselTarget, time:seconds).

    until done
    {
      set max_acc to ship:availableThrust/ship:mass.
      set tset to min(myVel/max_acc, 1).
      print ("Vitesse relative par rapport à la cible : ") + round(myVel, 2) + (" m/s     ") at (0,5).

      if myVel < 1 {
        lock throttle to 0.05.
      }
      if myVel < 0.15 {
        lock throttle to 0.
        set done to True.
      }
    }

    lock throttle to 0.
    wait 1.
    set navMode to "orbit".
    wait 0.5.
    unset target.
    wait 0.5.
    thrustLimiter(100).
    wait 0.5.
  }
  else {
    logFlightEvent("Passage en mode manuel.").
    unlock steering.
    sas on.
    lights on.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
  }
}

function burningApproach {
  parameter vesselTarget is target.
  local thisStage is stage:number.
  local listStage is caracteristicsStage(thisStage).

  local relativeVel is relativeVelocity(vesselTarget).
  local FkN is listStage[2].
  local FN is FkN * 1000.
  local effectiveVel is listStage[4].
  local theMassKg is ship:mass * 1000.

  local numberA is (theMassKg * (effectiveVel)^2) / FN.
  local numberB is relativeVel / effectiveVel.

  local Distance is numberA * (1 - constant:e^(-1 * numberB) * (numberB + 1)).
  local approachTime is Distance / relativeVel.
  return list(Distance, approachTime).
}

function relativePositionAt {
  parameter aNode.
  parameter VesselTarget is target.
  local timeToTarget is aNode:eta + (orbitAt(ship, time:seconds + aNode:eta )):period/2.

  return (positionAt(ship, time:seconds + timeToTarget) - positionAt(VesselTarget, time:seconds + timeToTarget)):mag.
}

function relativeVelocity {
  parameter VesselTarget is target.
  parameter etaTime is 0.
  if etaTime = 0 {
    set etaTime to choose ETA:periapsis if ship:verticalSpeed < 0 else ETA:apoapsis.
    set etaTime to time:seconds + etaTime.
  }
  return (velocityAt(ship, etaTime):orbit - velocityAt(VesselTarget, etaTime):orbit):mag.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCULER CORRECTION APPROCHE RENDEZ-VOUS
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function correctionApproach{
  parameter oneNode is nextNode.
  parameter oneTarget is target.
  parameter deltaChange is 0.05.
  parameter deltaTime is 0.001.

  local newDistance is 0.
  local newValue is list().
  clearScreen.
  local oldDistance is relativePositionAt(oneNode, oneTarget).
  print " ═════ DISTANCE RELATIVE ═════".
  print "(ΔC = " + deltaChange + "  ||  Δt = " + deltaTime + ")".
  lock distanceChange to relativePositionAt(oneNode, oneTarget).

  until newDistance > oldDistance {
    print ("En cours de correction : ") + round(newDistance,2) + (" m     ") at (0,3).
    set oldDistance to relativePositionAt(oneNode, oneTarget).
    changeRadialOut(oneNode, deltaChange).
    newValue:add(distanceChange). changeRadialIn(oneNode, deltaChange).
    changeRadialIn(oneNode, deltaChange).
    newValue:add(distanceChange). changeRadialOut(oneNode, deltaChange).

    changeNormal(oneNode, deltaChange).
    newValue:add(distanceChange). changeAntiNormal(oneNode, deltaChange).
    changeAntiNormal(oneNode, deltaChange).
    newValue:add(distanceChange). changeNormal(oneNode, deltaChange).

    changePrograde(oneNode, deltaChange).
    newValue:add(distanceChange). changeRetrograde(oneNode, deltaChange).
    changeRetrograde(oneNode, deltaChange).
    newValue:add(distanceChange). changePrograde(oneNode, deltaChange).

    addNodeTime(oneNode, deltaTime).
    newValue:add(distanceChange). subNodeTime(oneNode, deltaTime).
    subNodeTime(oneNode, deltaTime).
    newValue:add(distanceChange). addNodeTime(oneNode, deltaTime).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {changeRadialOut(oneNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(oneNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(oneNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(oneNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(oneNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(oneNode, deltaChange).}
    if indexNewCorrection = 6 {addNodeTime(oneNode, deltaChange).}
    if indexNewCorrection = 7 {subNodeTime(oneNode, deltaChange).}
    
    set newDistance to relativePositionAt(oneNode, oneTarget).
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}

function changeRadialOut
  {parameter aNode, deltaChange. set aNode:radialout to aNode:radialOut + deltaChange.}
function changeRadialIn
  {parameter aNode, deltaChange. set aNode:radialOut to aNode:radialOut - deltaChange.}
function changeNormal
  {parameter aNode, deltaChange. set aNode:normal to aNode:normal + deltaChange.}
function changeAntiNormal
  {parameter aNode, deltaChange. set aNode:normal to aNode:normal - deltaChange.}
function changePrograde
  {parameter aNode, deltaChange. set aNode:prograde to aNode:prograde + deltaChange.}
function changeRetrograde
  {parameter aNode, deltaChange. set aNode:prograde to aNode:prograde - deltaChange.}
function addNodeTime
  {parameter aNode, deltaChange. set aNode:time to aNode:time + deltaChange.}
function subNodeTime
  {parameter aNode, deltaChange. set aNode:time to aNode:time - deltaChange.}