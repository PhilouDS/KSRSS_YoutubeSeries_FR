if exists("lib:/KSRSS_log") {
  runOncePath("lib:/KSRSS_log").
} else {runOncePath("main:/KSRSS_log").}

if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {runOncePath("main:/KSRSS_Outils").}

// Earth caracteristics
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global earthRotationPeriod is Kerbin:rotationPeriod.
global omega is 2 * constant:pi / earthRotationPeriod.
global initialRotationEarth is 100.1833.
global atmAlt is 80_000.                // KSRSS/Configs/03_Earth/03_Earth.cfg
global upperAtm is 18_000.              // KSRSS/Configs/03_Earth/03_Earth.cfg
global transitionNavBall is 56_000.     // à vérifier
global transitionHighSpace is 350_000.  // KSRSS/Configs/03_Earth/03_Earth.cfg

// LaunchPad
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global KSClat is 5.09999838874518.
global KSCLng is -52.7523317667925.
global kscRotationVelocity is Kerbin:radius * omega * cos(KSClat).

// Moon
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
global moonInclination is Moon:orbit:inclination.
global moonPeriod is Moon:orbit:period.


//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// LIFTOFF
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function prelaunch {
  parameter degreesFromNorth is 90.
  parameter pitchAboveHorizon is 90.
  wait 0.2.
  sas off. rcs off.
  lock steering to heading(degreesFromNorth, pitchAboveHorizon).
  wait 0.2.
  lock throttle to 1.
}

global function decollage {
  parameter degreesFromNorth is 90.
  parameter pitchAboveHorizon is 90.
  parameter clamp is 1.
  if ship:partsDubbed("launchClamp1"):length = 0 {set clamp to 0.}
  compteRebours(5, clamp).

  if clamp = 1 {
    until ship:partsDubbed("launchClamp1"):length = 0 {
      stage.
      wait until stage:ready.
      wait 0.1.
    }
  }
  else {stage.}
  logFlightEvent("Décollage").
  clearScreen.
  print "Décollage".
  local altitudeAtLaunchPad is ship:altitude.
  wait 0.
  wait until ship:altitude > altitudeAtLaunchPad + 50.
  lock steering to heading(degreesFromNorth, pitchAboveHorizon).
  print "Roll program.".
}

function compteRebours{
  parameter decompteSecondes.
  parameter clamp is 1.
  set V1 to getvoice(0).
  set V1:volume to 0.1.
  print("Compte à rebours enclenché.").
  wait 1.
  from {local monCompteur is decompteSecondes.}
  until monCompteur = 0
  step {set monCompteur to monCompteur - 1.}
  do {
    print ("...") + monCompteur + ("...").
    V1:play(note(440, 0.2)).
    if monCompteur = 1 {
      if clamp = 1 {
        stage.
      }
    }
    wait 1.
  }
  V1:play(note(880, 0.5)).
}




//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCUL D'INCLINAISON AU DÉCOLLAGE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
function computeInclination {
    parameter ell, inc.
    local sinPhi is tan(ell) / tan(inc).
    local sinTheta is sin(ell) / sin(inc).
    local cosInc is cos(inc).
    local cosTheta is sqrt(1 - sinTheta^2).
    local cosPhi is sqrt(1 - sinPhi^2).

    local cosZeta is sinPhi * sinTheta + cosInc * cosTheta * cosPhi.
    return cosZeta.
}

function computeVel {                // identique à computeVelocity dans KSRSS_Maoeuvre
  parameter peri, apo, altitudeVaisseau.
  
  local rayon is body:radius.
  local RV is rayon + altitudeVaisseau. // altitude du vaisseau depuis centre de masse
  local RP is rayon + peri. // periapsis du vaisseau depuis centre de masse
  local RA is rayon + apo. // apoapsis du vaisseau depuis centre de masse
  local DGA is (RA + RP) / 2. // demi grand axe

  return sqrt(body:mu * (2/RV - 1/DGA)). // SQuare RooT
}

global function correctionLaunchInclination {
    parameter inc, targetAp.
    parameter ell is ship:geoPosition:lat.
    local cosZeta is computeInclination(ell, inc).
    local orbitVelocity is computeVel(targetAp, targetAp, targetAp).
    local neededVelocity is sqrt(orbitVelocity^2 + kscRotationVelocity^2 - 2 * orbitVelocity * kscRotationVelocity * cosZeta).
    return arcSin(-(neededVelocity^2 + kscRotationVelocity^2 - orbitVelocity^2)/(2 * neededVelocity * kscRotationVelocity)).
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CALCUL DE FENÊTRE DE LANCEMENT VERS LA LUNE
// MERCI ROMAIN POIRIER !!
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾


global function launchWindowAzimuth {
  parameter targetBody.
  parameter targetAp.
  parameter targetInc.
  set target to targetBody.
  local fenetreLancement is computeLaunchWindow(targetBody, targetAp, targetInc).
  local launchOne is fenetreLancement[0].
  local launchTwo is fenetreLancement[1].
  local azimuthAN is fenetreLancement[2].
  local azimuthDN is fenetreLancement[3].

  set timeToLaunch to choose launchOne if launchOne < launchTwo else launchTwo.
  print ("Launch at: day ") + time(timeToLaunch):day + (", ") + time(timeToLaunch):clock.
  local deltaTime is 60.
  set timeToLaunch to timeToLaunch - deltaTime.

  addLogLeftEntry("FENÊTRE DE LANCEMENT    : " + time(timeToLaunch):day + (", ") + time(timeToLaunch):clock).
  emptyLogLine().

  wait 1.
  doWarp(timeToLaunch).

  print "Fin du warp".

  set launchazimuth to choose azimuthAN if timeToRelativeNode("AN",0.1) < timeToRelativeNode("DN",0.1) else azimuthDN.
  set launchazimuthText to choose "Noeud ascendant" if timeToRelativeNode("AN",0.1) < timeToRelativeNode("DN",0.1) else "Noeud descendant".
  print ("           ") + launchazimuthText.

  wait until time:seconds > timeToLaunch.

  print "Fin de l'attente".


  logGeneralInfo(targetAp, targetInc, launchazimuth).
  print "Wanted inclination: " + round(targetInc,2) + "°".
  print "    Launch azimuth: " + round(launchazimuth,2) + "°".

  logSection("DONNÉES SUPPLÉMENTAIRES").
    addLogLeftEntry("NOEUD DE LANCEMENT    : " + launchazimuthText).
    emptyLogLine().

  return launchazimuth.
}



function computeLaunchWindow {
  parameter targetBody, targetAp, targetInc.
  
  local coef is floor(time:seconds/earthRotationPeriod).

  local ell is ship:geoposition:lat.
  local grandOmega is targetBody:orbit:lan.
  local inc is targetBody:orbit:inclination.
  local petitOmega is 360 / earthRotationPeriod.

  local grandA is cos(ell) * sin(grandOmega) * sin(inc).
  local grandB is -cos(ell) * cos(grandOmega) * sin(inc).
  local grandC is sin(ell) * cos(inc).

  local petitA is grandC - grandA.
  local petitB is 2 * grandB.
  local petitC is grandC + grandA.

  local delta is petitB^2 - 4 * petitA * petitC.

  local lSidUn is 2 * arcTan((-petitB + sqrt(delta))/ (2*petitA)).
  local lSidDeux is 2 * arcTan((-petitB - sqrt(delta))/ (2*petitA)).

  local tempsLancementUn is -1.
  local coefUn is coef.
  until tempsLancementUn > time:seconds {
      set tempsLancementUn to (lSidUn - initialRotationEarth - ship:geoposition:lng) / (petitOmega) + coefUn * earthRotationPeriod.
      set coefUn to coefUn + 1.
  }
  
  local tempsLancementDeux is -1.
  local coefDeux is coef.
  until tempsLancementDeux > time:seconds {
      set tempsLancementDeux to (lSidDeux - initialRotationEarth - ship:geoposition:lng) / (petitOmega) + coefDeux * earthRotationPeriod.
      set coefDeux to coefDeux + 1.
  }

  local vitesseCible is computeVel(targetAp, targetAp, targetAp).

  local cosZeta is computeInclination(KSClat, targetInc).

  local vitesseNecessaire is sqrt(vitesseCible^2 + kscRotationVelocity^2 - 2 * vitesseCible * kscRotationVelocity * cosZeta).

  local azimuthAN is arcSin(-(vitesseNecessaire^2 + kscRotationVelocity^2 - vitesseCible^2)/(2 * vitesseNecessaire * kscRotationVelocity)).
  local azimuthDN is 180 - azimuthAN.

  return list(tempsLancementUn, tempsLancementDeux, azimuthAN, azimuthDN).
}
