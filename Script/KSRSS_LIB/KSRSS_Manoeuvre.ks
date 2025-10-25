// runOncePath("0:/KSRSS_LIB/KSRSS_log.ks").
// runOncePath("0:/KSRSS_LIB/KSRSS_Outils.ks").
// runOncePath("0:/KSRSS_LIB/KSRSS_Stats.ks").
if exists("lib:/KSRSS_log") {
  runOncePath("lib:/KSRSS_log").
} else {runOncePath("main:/KSRSS_log").}

if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {runOncePath("main:/KSRSS_Outils").}

if exists("lib:/KSRSS_Stats") {
  runOncePath("lib:/KSRSS_Stats").
} else {runOncePath("main:/KSRSS_Stats").}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// VITESSE ORBITALE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function computeVelocity {
  parameter peri, apo, altitudeVaisseau.
  
  local rayon is body:radius.
  local RV is rayon + altitudeVaisseau. // altitude du vaisseau depuis centre de masse
  local RP is rayon + peri. // periapsis du vaisseau depuis centre de masse
  local RA is rayon + apo. // apoapsis du vaisseau depuis centre de masse
  local DGA is (RA + RP) / 2. // demi grand axe

  return sqrt(body:mu * (2/RV - 1/DGA)). // SQuare RooT
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// TRANSFERT DE HOHMANN
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function HohmannTransfert {
  parameter altitudeVaisseau, altitudeCible.
  local vitesseInitiale is 0.
  local vitesseFinale is 0.
  local deltaVhohmann is 0.

  set vitesseInitiale to computeVelocity(orbit:periapsis, orbit:apoapsis, altitudeVaisseau).
  if altitudeVaisseau < altitudeCible {
    set vitesseFinale to computeVelocity(altitudeVaisseau, altitudeCible, altitudeVaisseau).
  } 
  else {
    set vitesseFinale to computeVelocity(altitudeCible, altitudeVaisseau, altitudeVaisseau).
  }

  set deltaVhohmann to vitesseFinale - vitesseInitiale.

  print("---").
  print ("Vi = ") + round(vitesseInitiale,2) + (" m/s.").
  print ("Vf = ") + round(vitesseFinale,2) + (" m/s.").
  print ("Delta V = ") + round(deltaVhohmann,2) + (" m/s.").
  print("---").
  print("Calcul de la manoeuvre effectué.").
  print(" ").
  logTransfertHohmann(round(vitesseInitiale,2), round(vitesseFinale,2), round(deltaVhohmann,2)).
  return deltaVhohmann.
}

global function goToFrom {
  parameter goTo, goFrom. // goFrom must be apoapsis or periapsis
  local shipFrom is choose ship:orbit:apoapsis if goFrom = "AP" else ship:orbit:periapsis.
  local deltaV is HohmannTransfert(shipFrom, goTo).
  local nodeTime is choose ETA:apoapsis if goFrom = "AP" else ETA:periapsis.
  local aNode is node(time:seconds + nodeTime, 0, 0, deltaV).
  add aNode.
}


//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// EXÉCUTER MANOEUVRE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function exeMnv{
  parameter active_rcs is true.
  parameter minBurnTime is 10.
  sas off.
  clearScreen.
  if hasNode {
    local theNextNode is nextNode.
    lock steering to theNextNode:burnVector.
    if active_rcs = true {alignFacing(theNextNode:burnVector).}
    set max_acc to ship:availableThrust/ship:mass.
    local tempStageNumber is stage:number.
    local burnTime is computeBurningTime(theNextNode:deltav:mag, stage:number).
    if burnTime < minBurnTime {
      thrustLimiter(burnTime * 100 / minBurnTime).
      set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
    }
    
    logNode(round(burnTime, 2), round(theNextNode:ETA - burnTime/2, 2)).

    wait 0.1.
    if stage:number <> tempStageNumber {
      thrustLimiter(100).
      set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
      if burnTime < minBurnTime {
        local perc is max(burnTime * 100 / minBurnTime, 0.5).
        thrustLimiter(perc).
        set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
      }
      logNode(round(burnTime, 2), round(theNextNode:ETA - burnTime/2, 2), 1).
    }
    wait 0.1.

    local before_mnv is 10.

    if active_rcs = false {set before_mnv to 20.}
    wait 1.

    doWarp(time:seconds + theNextNode:eta - (burnTime/2 + before_mnv)).
    wait 0.

    local throt is 0.
    local isDone to false.

    if active_rcs = true {
      until theNextNode:eta <= (burnTime/2) + 0.1
        {print "Manoeuvre dans : " + round(theNextNode:ETA - burnTime/2, 2) + " s      " at (0,(terminal:height - 2)).}
        lock throttle to throt.
    }
    else {
      print "En attente de la manoeuvre sans RCS.".
      alignFacing(theNextNode:burnVector, 45).
      lock throttle to 0.1.
      wait 0.
      alignFacing(theNextNode:burnVector).
      wait 0.
      until theNextNode:eta <= (burnTime/2) + 0.1
        {print "Manoeuvre dans : " + round(theNextNode:ETA - burnTime/2, 2) + " s      " at (0,(terminal:height - 2)).}
      lock throttle to 1.
    }

    logFlightEvent("Allumage des moteurs : début de la manoeuvre.").
    

    set dv0 to theNextNode:deltav.

    until isDone
    {
      set max_acc to ship:availableThrust/ship:mass.
      set throt to min(theNextNode:deltav:mag/max_acc, 1).

      if vdot(dv0, theNextNode:deltav) < 0 {lock throttle to 0. break.}

      if theNextNode:deltav:mag < 0.1 {
        wait until vdot(dv0, theNextNode:deltav) < 0.5.
        lock throttle to 0.
        set isDone to True.
      }
    }
    wait 1.
    remove theNextNode.
  }
  else {
    print("Pas de noeud de manoeuvre existant.").
  }
  lock steering to prograde.
  thrustLimiter(100).
  logFlightEvent("Coupure des moteurs : fin de la manoeuvre").
  logFlightEvent("Vitesse actuelle : " + grandNombre(round(ship:velocity:orbit:mag,2),2) + " m/s").
}

function computeBurningTime {
  // a node is mandatory
  parameter dvNode, stageNum.
  local bTime is 0.
  local newDV is 0.
  local newStageNum is 0.
  local dataStage is caracteristicsStage(stageNum).
  local stgInitMass is dataStage[0].
  local stgEffectiveVelocity is dataStage[4].
  local stgFuelFlow is dataStage[5].
  local stgDV is dataStage[6].
  local stgCombTime is dataStage[7].
  if stgDV > dvNode {
    return (stgInitMass / stgFuelFlow) * (1 - constant:e^(-dvNode / stgEffectiveVelocity)).
  }
  else {
    set bTime to stgCombTime.
    set newDV to dvNode - stgDV.
    set newStageNum to stageNum - 1.
    return bTime + computeBurningTime(newDV, newStageNum).
  }
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCULER MANOEUVRE DE CIRCULARISATION
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function circularization {
  parameter ApOuPe.

  local deltaVcirc is 0.
  local theNextNode is node(0,0,0,0).

  if (ApOuPe = "AP") {
    set deltaVcirc to HohmannTransfert (orbit:apoapsis, orbit:apoapsis).
    set theNextNode to node(time:seconds + ETA:apoapsis, 0, 0, deltaVcirc).
  }
  else {
    set deltaVcirc to HohmannTransfert (orbit:periapsis, orbit:periapsis).
    set theNextNode to node(time:seconds + ETA:periapsis, 0, 0, deltaVcirc).
  }

  add theNextNode.
}



//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// TRANSFERT VERS UN SATELLITE NATUREL
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function transfert {
  parameter theTarget, thePeriapsis.
  set target to theTarget.
  clearScreen.
  logFlightEvent("Début du ciblage pour le transfert vers " + theTarget:name).

  local targetAngle is 180 - computeTargetAngle(target).
  lock phaseAngle to computePhaseAngle(target).
  
  until abs(targetAngle - phaseAngle) < 25 {
    set warp to 4.
    print ("Angle cible : ") + round(targetAngle, 2) + ("°    ") at (0,8).
    print ("Angle phase : ") + round(phaseAngle, 2) + ("°    ") at (0,9).
    wait 0.1.
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.

  local deltaAngle is abs(targetAngle - phaseAngle).
  local deltaTime is deltaAngle * ship:orbit:period / 360.

  local deltaV is HohmannTransfert(ship:altitude, theTarget:orbit:apoapsis - theTarget:radius - 2*thePeriapsis).
  local transferNode is node(time:seconds + deltaTime, 0, 0, deltaV).
  add transferNode.

  local reachNextPath is false.
  when transferNode:orbit:hasnextpatch then {
    set reachNextPath to true.
  }

  if reachNextPath = true and transferNode:orbit:hasnextpatch = false {
    local changePrograde is -0.2.
    until transferNode:orbit:hasnextpatch {
      set transferNode:prograde to transferNode:prograde - changePrograde.
    }
  }
  wait 0.1.
  
  exeMnv().
  wait 0.1.

  if ship:orbit:hasnextpatch = false {
    lock steering to retrograde.
    alignFacing(retrograde:vector).
    thrustLimiter(5).
    lock throttle to 0.1.
    wait until ship:orbit:hasnextpatch.
    lock throttle to 0.
  }

  lock steering to prograde.
  alignFacing(prograde:vector).

  thrustLimiter(100).
  wait 1.
  logFlightEvent("Fin de la manoeuvre de transfert vers " + theTarget).
}

function computeTargetAngle { // /!\ assuming circular orbit
  parameter theTarget.
  local futurPe is choose
    ship:apoapsis if ship:apoapsis < theTarget:orbit:apoapsis
    else theTarget:orbit:apoapsis.
  set futurPe to futurPe + body:radius.

  local futurAp is choose
    theTarget:orbit:apoapsis if ship:apoapsis < theTarget:apoapsis
    else ship:apoapsis.
  set futurAp to futurAp + body:radius.

  local semiMajorAxis is (futurPe + futurAp) / 2.
  local semiPeriod is constant:pi * sqrt(semiMajorAxis^3 / body:mu).
  local targetPeriod is theTarget:orbit:period.
  return semiPeriod * 360 / targetPeriod.
}

function computePhaseAngle {
  parameter theTarget.

  local angleShip is vernalAngle().
  local targetAngle is vernalAngle(theTarget).

  local diffAngle is targetAngle - angleShip.
  return diffAngle - 360 * floor(diffAngle/360).
}




//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCULER INCLINAISON RELATIVE PAR RAPPORT À UNE CIBLE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function correctionRelativeInclination{
  parameter theTarget, deltaAngleNode.
  parameter targetInclination is 0.1.
  clearScreen.

  local theWantedNode is "DN".
  local theWantedVector is theNormalVector().

  if relativeNodeAngle("AN", theTarget, ship) > relativeNodeAngle("DN", theTarget, ship) {
    set theWantedNode to "AN".
    set theWantedVector to theNormalVector("anti").
  }

  goToRelativeNode(theWantedNode, deltaAngleNode, theTarget).
  wait 0.5.
  lock steering to theWantedVector.
  alignFacing(theWantedVector).
  clearScreen.
  
  local incThrot is vAng(theNormalVector(), theNormalVector("normal", theTarget))/2.
  lock throttle to incThrot.

  wait until abs(vAng(theNormalVector(), theNormalVector("normal", theTarget)) - targetInclination) < 2*deltaAngleNode.
  wait until abs(vAng(theNormalVector(), theNormalVector("normal", theTarget)) - targetInclination) < deltaAngleNode OR   abs(vAng(theNormalVector(), theNormalVector("normal", theTarget)) - targetInclination) > 2*deltaAngleNode.
  lock throttle to 0.
  wait 0.5.
  print "New relative inclination: " + round(vAng(theNormalVector(), theNormalVector("normal", theTarget)),4) + "°".
  logFlightEvent("Nouvelle inclinaison relative avec " + target + " : " + round(vAng(theNormalVector(), theNormalVector("normal", theTarget)),4) + "°").
  wait 0.5.
}



//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// MODIFIER L'INCLINAISON DE L'ORBITE ACTUELLE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function correctionAbsoluteInclination{
  parameter targetInc.
  parameter loc is "AN".

  local theAngleNode is ship:orbit:LAN.
  local aVector is theNormalVector("anti").
  local deltaInc is 1_000.

  if loc = "DN" {
    local LDN is 180 + ship:orbit:LAN.
    set LDN to LDN - 360*floor(LDN / 360).
    set theAngleNode to LDN.
    set aVector to theNormalVector().
  }

  lock steering to aVector.
  alignFacing(aVector,1).
  wait 1.
  set warp to 4.

  wait until vernalAngle() < theAngleNode - 2 and vernalAngle() > theAngleNode - 5.
  set warp to 2.
  wait until abs(vernalAngle() - theAngleNode) <= 0.5.
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  alignFacing(aVector,1).
  lock throttle to 0.5.
  until abs(ship:orbit:inclination - targetInc) > deltaInc {
    set deltaInc to abs(ship:orbit:inclination - targetInc).
    print deltaInc at (0,terminal:height - 3).
    print abs(ship:orbit:inclination - targetInc) at (0,terminal:height - 2).
    wait 0.1.
  }
  lock throttle to 0.
  wait 0.5.
  print "New inclination: " + round(ship:orbit:inclination, 3) + "°".
  logFlightEvent("Inclinaison de l'orbite corrigée : " + round(ship:orbit:inclination, 3) + "°").
  wait 0.5.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// GEOSTATIONARY ALTITUDE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function geoAlt {
  // geostationary altitude from body's center of mass
  set geo to ((ship:body:mu * ship:body:rotationPeriod^2) / (4 * constant:PI^2))^(1/3).
  return geo.  
}
