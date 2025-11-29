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
// GRAVITY TURN
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function gravityTurn{
  parameter altitudeCible, inclinaisonCible, pitchAngle.
  logFlightEvent("Début du Gravity Turn").
  addLogLeftEntry("  · Vitesse initiale : " + round(ship:verticalSpeed,1) + " m/s.").
  addLogLeftEntry("  · Angle initial    : " + pitchAngle + "°").
  local directionTilt is heading(inclinaisonCible, pitchAngle).
  print("Pitch program.").
  lock steering to directionTilt.
  wait until vAng(facing:vector,directionTilt:vector) < 1.
  wait until vAng(srfPrograde:vector, facing:vector) < 1.
  logFlightEvent("Suivi du prograde : " + round(ship:verticalSpeed,1) + " m/s.").
  lock steering to heading(inclinaisonCible,90 - vAng(up:vector, srfPrograde:vector)).
  wait until ship:altitude >= 56000 or apoapsis >= 0.98*altitudeCible.
  set navMode to "orbit".
  lock steering to heading(inclinaisonCible,90 - vAng(up:vector, Prograde:vector)).
  wait until apoapsis >= altitudeCible.
  lock throttle to 0.
  logFlightEvent("Fin du Gravity Turn").
  set warp to 2.
  wait until ship:altitude > 0.98*atmHeight.
  set warp to 0.
  set kUniverse:timeWarp:mode to "RAILS".
  wait until ship:altitude > atmHeight.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// STAGING
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global function triggerStaging {
  parameter stopPreserve.
  print "Séparation automatique activée.".
  set oldThrust to ship:availableThrust.
  when ship:availablethrust < oldThrust - 10 then {
    until false {
      activeStage().
      wait 0.2.
      if ship:availableThrust > 0 or stage:number = 0 { 
        break.
      }
    }
    logStaging().
    set oldThrust to ship:availablethrust.
    if stage:number > stopPreserve {
      print "Séparation automatique activée.".
      preserve.
    } else {
      print "Séparation automatique désactivée.".
    }
  }
}

function activeStage {
  wait until stage:ready.
  stage.
}