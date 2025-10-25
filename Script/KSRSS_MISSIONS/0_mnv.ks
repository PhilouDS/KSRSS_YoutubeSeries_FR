clearScreen.
rcs on.
sas off.
wait 0.

if exists("lib:/KSRSS_log") {
  runOncePath("lib:/KSRSS_log").
} else {
  runOncePath("main:/KSRSS_log").
}
wait 0.

if exists("lib:/KSRSS_Manoeuvre") {
  runOncePath("lib:/KSRSS_Manoeuvre").
} else {
  runOncePath("main:/KSRSS_Manoeuvre"). 
}
wait 0.

if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {
  runOncePath("main:/KSRSS_Outils").
}
wait 0.

if exists("lib:/KSRSS_Stats") {
  runOncePath("lib:/KSRSS_Stats").
} else {
  runOncePath("main:/KSRSS_Stats").
}
wait 0.

sas off.
wait 0.

if hasNode {
  local theNextNode is nextNode.
  wait 0.
  lock steering to theNextNode:burnVector.
  wait 0.
  alignFacing(theNextNode:burnVector).
  set max_acc to ship:availableThrust/ship:mass.
  wait 0.
  local tempStageNumber is stage:number.
  wait 0.
  local burnTime is computeBurningTime(theNextNode:deltav:mag, stage:number).
  wait 0.
  if burnTime < 10 {
    thrustLimiter(burnTime * 100 / 10).
    wait 0.
    set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
    wait 0.
  }
  
  logNode(round(burnTime, 2), round(theNextNode:ETA - burnTime/2, 2)).
  
  wait 0.1.
  if stage:number <> tempStageNumber {
    thrustLimiter(100).
    wait 0.
    set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
    wait 0.
    if burnTime < minBurnTime {
      local perc is max(burnTime * 100 / minBurnTime, 0.5).
      wait 0.
      thrustLimiter(perc).
      wait 0.
      set burnTime to computeBurningTime(theNextNode:deltav:mag, stage:number).
      wait 0.
    }
    logNode(round(burnTime, 2), round(theNextNode:ETA - burnTime/2, 2), 1).
  }
  wait 0.1.

  local before_mnv is 10.
  wait 0.1.

  doWarp(time:seconds + theNextNode:eta - (burnTime/2 + before_mnv)).
  wait 0.

  local throt is 0.
  local isDone to false.
  rcs off.

  until theNextNode:eta <= (burnTime/2) + 0.1
    {print "Manoeuvre dans : " + round(theNextNode:ETA - burnTime/2, 2) + " s      " at (0,(terminal:height - 2)).}
  lock throttle to throt.

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
  wait 0.
  logFlightEvent("Coupure des moteurs : fin de la manoeuvre").
  wait 1.
  remove theNextNode.
}
else {
  print("Pas de noeud de manoeuvre existant.").
}

thrustLimiter(100).
clearScreen.


rcs off.
sas on.
unlock steering.
set ship:control:pilotmainthrottle to 0.