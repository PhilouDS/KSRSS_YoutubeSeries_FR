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

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// TERMINAL
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function openTerminal {
  parameter theHeight is 30.
  parameter theWidth is 55.
  set terminal:width to theWidth.
  set terminal:height to theHeight.
  clearScreen.
  core:part:getModule("kosProcessor"):doEvent("open terminal").
}

global function closeTerminal {
  core:part:getModule("kosProcessor"):doEvent("close terminal").
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// SAVES
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function startSave {
  local save_chrono is time:seconds.
  until kuniverse:canquicksave {
    if (time:seconds - save_chrono > 2) {break.}
  }
  if (kUniverse:canquicksave) {
    kUniverse:quicksaveto(ship:name + " - début").
  }
}

global function saveSituation {
  parameter situation.
  local save_chrono is time:seconds.
  until kuniverse:canquicksave {
    if (time:seconds - save_chrono > 2) {break.}
  }
  if (kUniverse:canquicksave) {
    kUniverse:quicksaveto(ship:name + " - situation - " + situation).
  }
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// MISSION
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function endProgram {
  parameter maxAltitude is -1.
  parameter recover is 1.
  parameter transmit_log is false.
  parameter transmit_name is ship:name.
  clearScreen.
  print "FERMETURE DU PROGRAMME.".
  wait 1.
  if recover = 1 {
    logFlightEvent("Vaisseau en cours de récupération").
  }
  wait 0.
  logFinMission(maxAltitude).
  closeTerminal().
  unlock steering.
  wait 0.  
  set ship:control:neutralize to true.
  set ship:control:pilotmainthrottle to 0.
  if transmit_log {
    if exists("main:/" + transmit_name + ".txt") {
      wait until homeConnection:isconnected.
      wait 0.
      copyPath("main:/" + transmit_name + ".txt", "0:/KSRSS_LOGS/" + transmit_name + "_transmited.txt").
      wait 0.
    }
    if exists("main:/" + ship:name + ".txt") {
      wait until homeConnection:isconnected.
      wait 0.
      copyPath("main:/" + ship:name + ".txt", "0:/KSRSS_LOGS/" + ship:name + "_transmited.txt").
      wait 0.
    }
    print "Transmission du log de mission".
  }
  if recover = 1 {
    wait until addons:career:isRecoverable(ship).
    wait until addons:career:Recovervessel(ship).
  }
  wait 0.
  sas on.
  list processors in proc.
  for p in proc {
    if p:volume:name <> "main" {
      p:deactivate().
      wait 0.
    }
  }
  shutdown.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// ENGINES
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function listOfEngines {
  list ENGINES in myEnginesList.
  return myEnginesList.
}

global function calculTWR {
  parameter twrAltitude is ship:altitude.
  //--- masse totale :
  set totalMass to ship:mass.
  local stageClamp is 1.
  //--- on retire la masse des rampes de lancement :
  for prt in ship:partsDubbed("launchClamp1") {
    set totalMass to totalMass - prt:mass.
  }

  if ship:partsDubbed("launchClamp1"):length > 0 {
    set stageClamp to ship:stagenum - ship:partsDubbed("launchClamp1")[0]:stage.
  }

  local engList is listOfEngines().
  local firstStageEngine is list().
  for eng in engList {
    if eng:stage >= ship:stagenum - stageClamp {firstStageEngine:add(eng).}
  }

  set wantedThrust to 0.
  for en in firstStageEngine {
    set wantedThrust to wantedThrust + en:possibleThrust.
  }

  set grav_here to g_here(twrAltitude).
  return wantedThrust / (totalMass*grav_here).
}

global function thrustLimiter {
  parameter pourcentage.
  parameter printPerc is true.
  local engList is listOfEngines().
  for eng in engList {
    set eng:thrustLimit to pourcentage.
    if printPerc {print eng:name + " : " + eng:thrustLimit.}
  }
}

global function g_here {
  parameter choosenAlt is ship:altitude.
  return body:mu / ((body:radius + choosenAlt)^2).
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// NAVIGATION
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function doWarp {
  parameter aTime.
  warpTo(aTime).
  wait until kuniverse:timewarp:rate = 1.
  wait until kuniverse:timewarp:issettled.
  wait 1.
}

global function alignFacing{
  parameter aVector.
  parameter aDeltaAng is 5.
  wait until vAng(ship:facing:vector, aVector) < aDeltaAng.
}

global function theNormalVector {
  parameter theDirection is "normal".
  parameter object is ship.  
  local normalVector is vectorCrossProduct(object:velocity:orbit:normalized, (object:position - object:body:position):normalized):normalized.
  if theDirection = "anti" {set normalVector to (-1) * normalVector.}
  return normalVector.
}

global function vernalAngle {
  parameter Obj is ship.
  local angle is Obj:orbit:lan + Obj:orbit:argumentofperiapsis + Obj:orbit:trueanomaly.
  return angle - 360*floor(angle / 360).
}

global function relativeNodeAngle {
  parameter ANorDN.
  parameter Obj1 is target.
  parameter Obj2 is ship.
  local vecNormalShip is theNormalVector("anti", Obj2).
  local vecNormalTarget is theNormalVector("anti", Obj1).
  local vecNode is 
    choose vectorCrossProduct(vecNormalShip, vecNormalTarget):normalized if ANorDN = "AN"
    else -vectorCrossProduct(vecNormalShip, vecNormalTarget):normalized.
  local angle is vang(-body:position, vecNode).
  local signVector is vcrs(-body:position, vecNode).
  local sign is vdot(vecNormalShip, signVector).
  if sign < 0 {
    set angle to angle * -1.
  }
  return angle.
}


global function timeToRelativeNode {
  parameter ANorDN.
  parameter deltaAngleNode.
  parameter Obj1 is target.
  parameter Obj2 is ship.
  
  local targetNode is relativeNodeAngle(ANorDN, Obj1, Obj2).
  local shipAngularVelocity is Obj2:orbit:period / 360.
  return (targetNode - deltaAngleNode) * shipAngularVelocity.
}

function goToRelativeNode {
  parameter ANorDN. // "AN" or "DN"
  parameter deltaAngleNode.
  parameter Obj1 is target.
  parameter Obj2 is ship.
  local targetVector is choose theNormalVector("anti") if ANorDN = "AN" else theNormalVector().
  local timeToTargetNode is time:seconds + timeToRelativeNode(ANorDN, deltaAngleNode, Obj1, Obj2)-20.
  lock steering to targetVector.
  alignFacing(targetVector).
  doWarp(timeToTargetNode).
  wait 0.5.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// LISTS RELATED
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
function minOf {
  parameter aList.
  local theMinimum is aList[0].
  for I in range(aList:length - 1) {
    if aList[I] < theMinimum {set theMinimum to aList[I].}
  }
  return theMinimum.
}

function maxOf {
  parameter aList.
  local theMaximum is aList[0].
  for I in range(aList:length - 1) {
    if aList[I] > theMaximum {set theMaximum to aList[I].}
  }
  return theMaximum.
}
