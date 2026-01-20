list processors in proc.
local idx is 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_log") {
    runOncePath("lib" + idx + ":/KSRSS_log").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_log").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Outils") {
    runOncePath("lib" + idx + ":/KSRSS_Outils").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Outils").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Stats") {
    runOncePath("lib" + idx + ":/KSRSS_Stats").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Stats").
}
set idx to 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Manoeuvre") {
    runOncePath("lib" + idx + ":/KSRSS_Manoeuvre").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Manoeuvre").
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// TRANSFERT VERS UN SATELLITE NATUREL
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function transfert {
  parameter theTarget, thePeriapsis.
  parameter reverseOrbit is false.
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

  local meanAltitude to (theTarget:altitude + (theTarget:orbit:apoapsis + theTarget:orbit:periapsis)/2)/2.
  wait 0.

  local deltaV is HohmannTransfert(ship:altitude, meanAltitude - theTarget:radius - thePeriapsis).
  wait 0.
  local transferNode is node(time:seconds + deltaTime, 0, 0, deltaV).
  wait 0.
  add transferNode.
  wait 0.
  // local sign is 1.
  // if not(transferNode:orbit:hasnextpatch) {
  //   print "POINT 1".
  //   if transferNode:orbit:apoapsis > theTarget:orbit:apoapsis {
  //     set sign to -1.
  //   }
  //   print sign.
  //   local changePrograde is sign * 0.2.
  //   print "POINT 2". // BUG kOS -> paramètres incorrects/manquants ??
  //   until transferNode:orbit:hasnextpatch {
  //     set transferNode:prograde to transferNode:prograde + changePrograde.
  //     wait 0.
  //     print "PROGRADE : " + round(transferNode:prograde, 2) + " m/s    " at (0,terminal:height - 2).
  //   }
  // }
  // wait 0.
  // print "POINT 3".
  // wait 0.1.
  // if transferNode:orbit:hasnextpatch {
  //   print "POINT 4".
  //   if (transferNode:orbit:inclination > 90 and not(reverseOrbit)) {
  //     print "POINT 5".
  //     until transferNode:orbit:inclination < 90 {
  //       set transferNode:prograde to transferNode:prograde - 0.2.
  //       wait 0.
  //       print "INC. : " + round(transferNode:orbit:inclination, 1) + "°    " at (0,terminal:height - 2).
  //     }
  //   }
  // }
  
  exeMnv().
  wait 0.1.

  local wantedVel is computeVelocity(ship:orbit:periapsis, theTarget:altitude, ship:altitude).
  local actualVel is computeVelocity(ship:orbit:periapsis, ship:orbit:periapsis, ship:altitude).
  local sign is (wantedVel - actualVel).

  if not(ship:orbit:hasnextpatch) {
    lock steering to (sign * prograde:vector).
    alignFacing(sign * prograde:vector).
    thrustLimiter(5, false).
    lock throttle to 0.1.
    wait until ship:orbit:hasnextpatch.
    wait until ship:orbit:nextPatch:body = theTarget.
    wait until ship:orbit:nextPatch:periapsis <= 3 * thePeriapsis.
    lock throttle to 0.
  }

  lock steering to prograde.
  alignFacing(prograde:vector).

  thrustLimiter(100, false).
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
// CALCULER CORRECTION FUTURE INCLINAISON
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function correctionFutureInclinaison{
  parameter wantedInc, newTime.
  parameter deltaChange is 0.1.
  parameter marginValue is 0.2.
  parameter doNextPatch is true.
  clearScreen.
  local correctNode is node(time:seconds + newTime, 0, 0, 0).
  wait 0.1.
  add correctNode.
  wait 0.1.
  
  local newValue is list().
  local oldInclination is
    choose correctNode:orbit:nextpatch:inclination if doNextPatch = true
    else correctNode:orbit:inclination.

  lock incChanging to
    choose abs(wantedInc - correctNode:orbit:nextpatch:inclination) if doNextPatch = true
    else abs(wantedInc - correctNode:orbit:inclination).

  until abs(oldInclination - wantedInc) <= marginValue {
    
    print ("Cible   : ") + round(wantedInc,2) + "°     " at (0,1).
    print ("Inc     : ") + round(oldInclination,2) + "°     " at (0,2).

    print "Prograde : " + round(correctNode:prograde, 2) at (0,4).
    print "Normal   : " + round(correctNode:normal, 2) at (0,5).
    print "Radial   : " + round(correctNode:radialOut, 2) at (0,6).
    print "Δv       : " + round(correctNode:deltaV:mag, 2) at (0,8).
    
    changeRadialOut(correctNode, deltaChange).
    newValue:add(incChanging). changeRadialIn(correctNode, deltaChange).
    changeRadialIn(correctNode, deltaChange).
    newValue:add(incChanging). changeRadialOut(correctNode, deltaChange).

    changeNormal(correctNode, deltaChange).
    newValue:add(incChanging). changeAntiNormal(correctNode, deltaChange).
    changeAntiNormal(correctNode, deltaChange).
    newValue:add(incChanging). changeNormal(correctNode, deltaChange).

    changePrograde(correctNode, deltaChange).
    newValue:add(incChanging). changeRetrograde(correctNode, deltaChange).
    changeRetrograde(correctNode, deltaChange).
    newValue:add(incChanging). changePrograde(correctNode, deltaChange).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {changeRadialOut(correctNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(correctNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(correctNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(correctNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(correctNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(correctNode, deltaChange).}
    
    set oldInclination to
      choose correctNode:orbit:nextpatch:inclination if doNextPatch = true
      else correctNode:orbit:inclination.
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}


//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCULER CORRECTION FUTUR PERIAPSIS
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function correctionFuturPeriapsis{
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

    changeRadialOut(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRadialIn(correctNode, deltaChange).
    changeRadialIn(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRadialOut(correctNode, deltaChange).

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
    if indexNewCorrection = 0 {changeRadialOut(correctNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(correctNode, deltaChange).}
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

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// SUICID BURN
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function landing {
  parameter Kp.
  parameter Ki.
  parameter Kd.
  parameter mustStage is false.
  parameter stageToLand is 0.

  clearScreen.
  sas off.

  logFlightEvent("Début de la procédure d'atterrissage").

  when ship:availableThrust = 0 then {stage.}

  set bb to ship:bounds.
  lock altitudeAGL to max(0, bb:bottomaltradar).

  cancelSurfaceVelocity(mustStage, stageToLand).

  wait 1.

  suicidBurn(Kp, Ki, Kd, stageToLand).

  wait 1.
}

function cancelSurfaceVelocity {
  parameter doStage is false.
  parameter wantedStageNumber is 0.

  set navMode to "SURFACE".
  lock steering to srfRetrograde.
  wait until vAng(ship:facing:vector, srfRetrograde:vector) < 5.

  local oldVel is ship:velocity:surface:mag.
  lock throttle to 1.
  wait 0.
  wait until ship:velocity:surface:mag <= 5.
  wait 0.
  lock throttle to 0.
  wait 0.
  if doStage = true {
    until stage:number=wantedStageNumber {
        wait until stage:ready.
        stage.
    }
    wait 1.
  }
}

function suicidBurn {
  parameter Kp.
  parameter Ki.
  parameter Kd.
  parameter stageToLand is 0.

  if stage:number<>stageToLand {
    until stage:number=stageToLand {
        wait until stage:ready.
        stage.
    }
  }

  wait 0.1.

  local start_line is 0.

  set power to 0.
  lock throttle to power.

  local initialAltitude is altitudeAGL.
  wait 0.
  local tempAltitude is initialAltitude / 3.

  set old_twr to calculTWRbis(0).
  wait 0.
  set lim_thrust to 3 * 100 / old_twr.
  wait 0.
  thrustLimiter(lim_thrust, false).
  wait 0.1.

  local burningAltitude is initialAltitude / calculTWRbis(0).
  set new_twr to calculTWRbis(burningAltitude).
  local Vm is SQRT(2 * (initialAltitude - burningAltitude) * g_here()).
  local Tm is Vm / ((new_twr - 1) * g_here()).

  logFlightEvent("Calculs des données pour l'allumage du moteur.").
  logSuicidBurn(new_twr, Vm, Tm, burningAltitude).

  clearScreen.

  print "Manoeuvre d'atterrissage" at (0,start_line).
  print "========================" at (0,start_line + 1).

  print ("                  RPP ≈ ") + round(new_twr,2) at (0,start_line + 3).
  print ("                   Δv ≈ ") + round(Vm, 2) + (" m/s") at (0,start_line + 4).
  print ("Durée de la manoeuvre ≈ ") + round(Tm,2) + (" s") at (0,start_line + 5).
  print ("Altitude de manoeuvre ≈ ") + round(burningAltitude, 2) + (" m.") at (0,start_line + 6).
  wait 0.

  local dV_avant is stage:deltav:current.
  wait 0.

  until altitudeAGL <= ceiling(burningAltitude/100)*100 {
      print ("  Altitude du sol : ") + round(altitudeAGL, 2) + (" m         ") at (0,start_line + 10).
      print ("Vitesse verticale : ") + round(ship:verticalspeed, 2) + (" m/s      ") at (0,start_line + 11).
      print ("     Contact dans : ") + round(altitudeAGL / abs(ship:verticalspeed), 2) + (" s      ") at (0,start_line + 12).
      wait 0.1.
  }

  set power to 1.

  when ship:verticalspeed >= -40 then {GEAR ON.}

  when altitudeAGL < 100 then {lock steering to up.}

  clearScreen.

  set start_line to 0.

  set VPID to pidLoop(Kp, Ki, Kd, 0, 1).

  print "PID configurée" at (0,start_line).
  print "==============" at (0,start_line + 1).

  wait 0.

  until (ship:status = "landed") or (ship:status = "splashed") {
    set VPID:setpoint to
    CHOOSE min(-1, -0.1*altitudeAGL) if (altitudeAGL < 100 and ship:verticalspeed > -10)
    else -10.
    set power to VPID:update(time:seconds, ship:verticalspeed).
    
    print "Objectif  : " + round(VPID:setpoint, 2) + " m/s      " at (0, start_line + 3).

    print "Puissance         : " + round(power, 2) + "                " at (0, start_line + 5).
    print "Vitesse verticale : " + round(ship:verticalspeed, 2) + " m/s      " at (0, start_line + 6).
    print "Altitude r/r sol  : " + round(altitudeAGL, 1) + " m       " at (0,start_line + 7).
    print "Contact dans      : " + round(altitudeAGL / abs(ship:verticalspeed), 2) + (" s      ") at (0,start_line + 8).
    wait 0.
  }
  lock throttle to 0.
  wait 1.
  local dV_used is (dV_avant - stage:deltaV:current).
  wait 0.
  print "Δv calculé        : " + round(Vm, 2) + (" m/s      ") at (0,start_line + 11).
  print "Δv utilisé        : " + round(dV_used, 2) + (" m/s      ") at (0,start_line + 12).
  wait 1.
}

function calculTWRbis {
  parameter twrAltitude is ship:altitude.
  //--- masse totale :
  set totalMass to ship:mass.

  set g_here to body:mu / ((body:radius + twrAltitude)^2).
  return ship:availablethrust / (totalMass*g_here).
}


function groundSlope { // cheers Kevin
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  local a is body:geopositionOf(center + 5 * north:vector).
  local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

  local a_vec is a:altitudePosition(a:terrainHeight).
  local b_vec is b:altitudePosition(b:terrainHeight).
  local c_vec is c:altitudePosition(c:terrainHeight).

  return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}

global function inegaliteTriangulaire {
  lock KerbinBody to Kerbin:altitudeOf(ship:body:position).
  lock ShipBody to ship:body:altitudeOf(ship:position).
  lock ShipKerbin to Kerbin:altitudeOf(ship:position).

  return abs((ShipKerbin + ShipBody) - (KerbinBody - ship:body:radius)).
}