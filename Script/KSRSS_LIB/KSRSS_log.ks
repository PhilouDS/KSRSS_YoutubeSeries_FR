//runOncePath("0:/KSRSS_LIB/KSRSS_Outils.ks").
if exists("lib:/KSRSS_Outils") {
  runOncePath("lib:/KSRSS_Outils").
} else {runOncePath("main:/KSRSS_Outils").}

lock logDir to 
  choose "0:/KSRSS_LOGS/" if (homeConnection:isconnected)
  else "main:/".


global logWidth is 91.
lock fileName to logDir + ship:name + ".txt".
print "LOG : " + fileName.
wait 0.
global logUpdated is " ✒ Journal de bord mis à jour.".
wait 0.
global atmHeight is 80_000.
global atmTransition is 56_000.

// STARTING A NEW MISSION

global function logMission {
  parameter title.
  underscoreLogLine(1, "·").
  addLogCenterEntry("~ " + title + " ~").
  upperscoreLogLine(1, "·").
  emptyLogLine().
  print logUpdated.
}

global function logGeneralInfo {
  parameter theApoCible is (atmHeight + 20000).
  parameter theWantedAzimut is ship:geoposition:lat.
  parameter theLaunchAzimut is 90.
  parameter editor is "VAB".
  local KSC_lat is ship:geoposition:lat.
  print "Enregistrement des infos générales".
  //set description to kuniverse:getCraft(ship:name, editor):description.
  set cout to kuniverse:getCraft(ship:name, editor):cost.
  local tmpFonds is addons:career:funds.
  local tmpScience is addons:career:science.
  local tmpReputation is addons:career:reputation.
  logSection("ÉTAT SPACE CENTER").
  set tmpFonds to round(tmpFonds, 2).
  set tmpScience to round(tmpScience, 2).
  set tmpReputation to round(tmpReputation, 2).
  addLogLeftEntry("FONDS      : √ " + grandNombre(tmpFonds, 2)).
  addLogLeftEntry("SCIENCE    : ☆ " + grandNombre(tmpScience, 2)).
  addLogLeftEntry("RÉPUTATION : ☺ " + grandNombre(tmpReputation, 2)).
  print "État du KSC enregistré".
  emptyLogLine().
  
  logSection("INFORMATIONS GÉNÉRALES").
  print "Date enregistrée". wait 0.2.
  addLogLeftEntry("DATE            : " + timestamp(time:seconds):full).
  emptyLogLine().
  
  print "Enregistrement vaisseau en cours". wait 0.2.
  addLogLeftEntry("VAISSEAU        : " + ship:name).
  local crewList is ship:crew().
  if crewList:length = 0 {
    addLogItem("Vaisseau entièrement automatisé").
  }
  else {
    for crew in crewList {
      addLogItem(crew:name + " - " + crew:trait + " (XP " + crew:experience + ")").
    }
  }
  emptyLogLine().
  //addLogLeftEntry("DESCRIPTION     : " + description).
  print "☑ Coût". wait 0.1.
  addLogLeftEntry("COÛT            : √ " + grandNombre(round(cout,2),2)).
  print "☑ Masse". wait 0.1.
  addLogLeftEntry("MASSE           : " + round(ship:mass, 3) + " t").
  print "☑ Rapport Poussée-Poids". wait 0.1.
  addLogLeftEntry("RPP             : " + round(calculTWR(), 2)).
  print "☑ Nombre d'étages". wait 0.1.
  addLogLeftEntry("Nombre d'étages : " + ship:stageNum).
  
  emptyLogLine().

  logSection("DONNÉES INITIALES DU LANCEMENT").
  wait 0.
  local testApo is grandNombre(theApoCible, 2).
  wait 0.
  addLogLeftEntry("APOASTRE SOUHAITÉE    : " + testApo + " m").
  if theWantedAzimut <> KSC_lat {addLogLeftEntry("INCLINAISON SOUHAITÉE : " + theWantedAzimut + "°").}
  if theLaunchAzimut <> 90 {addLogLeftEntry("AZIMUT DE LANCEMENT   : " + round(theLaunchAzimut,3) + "°").}
  emptyLogLine().
  
  logSection("ÉVÉNEMENTS DE VOL").
  print logUpdated.
}

// DURING A FLIGHT

global function logStaging {
  logFlightEvent("Séparation d'étage réalisée.").
  wait 0.
  local shipAlt is round(ship:altitude,2).
  local shipVitSrf is round(ship:velocity:surface:mag,2).
  local shipVitObt is round(ship:velocity:orbit:mag,2).
  wait 0.
  addLogLeftEntry("  · RPP                    : " + round(calculTWR(),2)).
  addLogLeftEntry("  · ALTITUDE               : " + grandNombre(shipAlt, 2) + " m").
  addLogLeftEntry("  · VITESSE SURFACE        : " + grandNombre(shipVitSrf) + " m/s").
  addLogLeftEntry("  · VITESSE ORBITALE       : " + grandNombre(shipVitObt) + " m/s").
  addLogLeftEntry("  · PRESSION ATMOSPHÉRIQUE : " +
    round(ship:q,3) + " ATM / " + round(ship:q * constant:ATMtokPa,3) + " kPA").
  print logUpdated.
}

global function logTransfertHohmann {
  parameter vitInit.
  parameter vitFin.
  parameter deltaHom.
  logFlightEvent("Calcul d'un transfert de Hohmann").
  addLogLeftEntry("  · Vitesse initiale : " + vitInit + " m/s.").
  addLogLeftEntry("  · Vitesse finale   : " + vitFin + " m/s.").
  addLogLeftEntry("  · Delta-V          : " + deltaHom + " m/s.").
  print logUpdated.
}

global function logNode {
  parameter burnTime.
  parameter burnETA.
  parameter newNode is 0.
  if newNode = 0 {
    logFlightEvent("Enregistrement de la manoeuvre").
  }
  else {
    logFlightEvent("Modification du noeud de manoeuvre").
  }
  addLogLeftEntry("  · Durée de la manoeuvre : " + burnTime + " s.").
  addLogLeftEntry("  · Temps avant manoeuvre : " + timestamp(burnETA):clock + " s.").
  print logUpdated.
}

global function logScience {
  parameter deployedScience.
  parameter donnees.
  parameter scienceConservee.
  parameter scienceTransmise.
  logFlightEvent("Expérience scientifique réalisée : ").
  addLogLeftEntry("  *** " + deployedScience + " ***").
  addLogLeftEntry("  · Données              : " + round(donnees,2) + " mits.").
  addLogLeftEntry("  · Science si conservée : " + round(scienceConservee,2) + " pts.").
  addLogLeftEntry("  · Science si transmise : " + round(scienceTransmise,2) + " pts.").
  print logUpdated.
}

global function logOrbitInfo {
  emptyLogLine().
  logSection("INFORMATIONS DE L'ORBITE").
  wait 0.
  set shipApo to round(ship:orbit:apoapsis, 2).
  set shipPer to round(ship:orbit:periapsis, 2).
  wait 0.
  addLogLeftEntry("Apogée                       : " + grandNombre(shipApo,2) + " m").
  addLogLeftEntry("Périgée                      : " + grandNombre(shipPer,2) + " m").
  addLogLeftEntry("Argument du périgée          : " + round(ship:orbit:argumentofperiapsis, 2) + "°").
  addLogLeftEntry("Excentricité                 : " + round(10^4 * ship:orbit:eccentricity, 2) + " x 10^(-4)").
  addLogLeftEntry("Période orbitale             : " + TIME(ship:orbit:period):clock).
  addLogLeftEntry("Inclinaison                  : " + round(ship:orbit:inclination, 3) + "°").
  addLogLeftEntry("Longitude du noeud ascendant : " + round(ship:orbit:longitudeofascendingnode, 2) + "°").
  upperscoreLogLine(2).
  print logUpdated.
}

// ENDING A MISSION

global function logSuicidBurn {
  parameter RPP, Vm, Tm, burningAltitude.
  emptyLogLine().
  logSection("DONNÉES POUR LA PROCÉDURE D'ATTERRISSAGE").
  addLogLeftEntry("RPP                 : " + round(RPP,2)).
  addLogLeftEntry("Delta-V nécessaire  : " + round(Vm, 2) + " m/s").
  addLogLeftEntry("Durée de l'allumage : " + round(Tm,2) + " s").
  addLogLeftEntry("Altitude d'allumage : " + grandNombre(burningAltitude,2) + " m").
  upperscoreLogLine(2).
  print logUpdated.
}

global function logAtterrissage {
  parameter recover is true.
  wait until ship:status = "landed" or ship:status = "splashed".
  if recover = true {
    wait until addons:career:isRecoverable(ship).
  }
  emptyLogLine().
  logSection("ATTERRISSAGE EFFECTUÉ").
  local shipGeoposition is ship:geoPosition.
  local shipBody is ship:body:name.
    set shipBody to shipBody:toString.
    set shipBody to shipBody:toUpper.
  local shipLNG is round(shipGeoposition:LNG, 4) + "°".
  local shipLAT is round(shipGeoposition:LAT, 4) + "°".
  local shipBiome is addons:scanSat:getBiome(ship:body, shipGeoposition).
    if shipBiome = "unknown" {set shipBiome to "biome inconnu".}
  local shipAlt is addons:scanSat:elevation(ship:body, shipGeoposition) + " m au-dessus du niveau 0".
    if shipAlt = -1 {set shipAlt to "inconnue".}
  logFlightEvent("Le vaisseau est stabilisé.", 0).
  addLogLeftEntry("EMPLACEMENT").
  addLogLeftEntry("  · " + shipBody + ", " + shipBiome).
  addLogLeftEntry("  · " + ship:status).
  addLogLeftEntry("COORDONNÉES").
  addLogLeftEntry("  · longitude : " + shipLNG).
  addLogLeftEntry("  · latitude  : " + shipLAT).
  addLogLeftEntry("  · altitude  : " + shipAlt + " (données altimétriques ScanSat)").
  emptyLogLine().
  print logUpdated.
}

global function logFinMission {
  parameter maxAltitude is -1.
  underscoreLogLine().
  addLogCenterEntry("~ FIN DE LA MISSION ~").
  upperscoreLogLine().
  emptyLogLine().
  logSection("RÉCAPITULATIF").
  addLogLeftEntry("DATE DE FIN                : " + timestamp(time:seconds):full).
  local laDuree is timestamp(missionTime):clock.
  if timestamp(missionTime):day > 1 {
    if timestamp(missionTime):year > 1 {
      set laDuree to (timestamp(missionTime):year - 1) + "a." + 
          (timestamp(missionTime):day - 1) + "j." + laDuree.
    }
    else {
      set laDuree to (timestamp(missionTime):day - 1) + "j." + laDuree.
    }
  }
  addLogLeftEntry("DURÉE DE LA MISSION        : " + laDuree).
  wait 0.
  if maxAltitude > 0 {
    addLogLeftEntry("ALTITUDE MAXIMALE          : " + grandNombre(round(maxAltitude, 2),2) + " m").
  }
  emptyLogLine().
  underscoreLogLine().
  print logUpdated.
}

// SECTIONNING FUNCTIONS

global function logSection {
  parameter secTitle.
  set secTitle to "# " + secTitle.
  addLogLeftEntry(secTitle).
  upperscoreLogLine(2).
}

global function logFlightEvent {
  parameter event.
  parameter emptyline is 1.
  if emptyline = 1 {emptyLogLine().}
  local laDuree is timestamp(missionTime):clock.
  if timestamp(missionTime):day > 1 {
    if timestamp(missionTime):year > 1 {
      set laDuree to (timestamp(missionTime):year - 1) + "a." + 
          (timestamp(missionTime):day - 1) + "j." +
          timestamp(missionTime):clock.
    }
    else {
      set laDuree to (timestamp(missionTime):day - 1) + "j." + timestamp(missionTime):clock.
    }
  }
  addLogLeftEntry("T+ " + laDuree + " : " + event).
  print logUpdated.
}

// SECUNDARY FUNCTIONS

global function grandNombre {
  parameter nombre.
  parameter rounded is 4.
  return round(nombre, rounded).
}

// global function grandNombre {
//   parameter nombre.
//   parameter rounded is 4.
//   set nombre to round(nombre, rounded).
//   if nombre < 1000 {return nombre.}
//   else {
//     set tempNombre to "".
//     set tranche to -1.
//     set pow to 0.
//     set decPart to nombre - floor(nombre).
//     until tranche = 0 {
//       set tranche to
//         (mod(nombre ,10^(3 + pow)) - mod(nombre ,10^(pow)))/10^(pow).
//       if tranche = 0 {break.}
//       set addTranche to "".
//       if tranche < 10 {set addTranche to "00".}
//       if tranche < 100 and tranche >= 10 {set addTranche to "0".}
//       set trancheDec to tranche + decPart.
//       set tempNombre to choose addTranche + trancheDec if tempNombre = "" else addTranche + tranche + " " + tempNombre.
//       set pow to pow + 3.
//     }
//     if tempNombre:length > 0 {
//       until tempNombre[0] <> 0 {
//         set tempNombre to tempNombre:remove(0,1).
//       }
//     }
//     set nombre to tempNombre.
//     return nombre.
//   }
// }

global function emptyLogLine {
  parameter border is "|".
  set emptyLine to border.
  set i to 0.
  until i >= logWidth - 2 {
    set emptyLine to emptyLine + " ".
    set i to i + 1.
  }
  set emptyLine to emptyLine + border.
  log emptyLine to fileName.
}

global function underscoreLogLine {
  parameter fraction is 1.
  parameter border is "|".
  if fraction < 1 {set fraction to 1.}
  set underscoreLine to border.
  set i to 0.
  until i >= (logWidth - 2)/fraction {
    set underscoreLine to underscoreLine + "_".
    set i to i + 1.
  }
  if fraction > 1 {
    set i to 0.
    until i >= (logWidth - 2) * (fraction - 1)/fraction - 1 {
      set underscoreLine to underscoreLine + " ".
      set i to i + 1.
    }
  }
  set underscoreLine to underscoreLine + border.
  log underscoreLine to fileName.
}

global function upperscoreLogLine {
  parameter fraction is 1.
  parameter border is "|".
  if fraction < 1 {set fraction to 1.}
  set upperscoreLine to border.
  set i to 0.
  until i >= (logWidth - 2)/fraction {
    set upperscoreLine to upperscoreLine + "‾".
    set i to i + 1.
  }
  if fraction > 1 {
    set i to 0.
    until i >= (logWidth - 2) * (fraction - 1)/fraction - 1{
      set upperscoreLine to upperscoreLine + " ".
      set i to i + 1.
    }
  }
  set upperscoreLine to upperscoreLine + border.
  log upperscoreLine to fileName.
}

global function addLogCenterEntry {
  parameter cEntry.
  set cEntry to cEntry:toString.
  if MOD(cEntry:length, 2) = 0 {
      set cEntry to cEntry + " ".
  }
  set cEntryLength to cEntry:length.
  set blankWidth to floor((logWidth - 2 - cEntryLength)/2).
  set printcEntry to "|".
  set i to 0.
  until i >= blankWidth {
    set printcEntry to printcEntry + " ".
    set i to i + 1.
  }
  set printcEntry to printcEntry + cEntry.
  set i to 0.
  until i >= blankWidth {
    set printcEntry to printcEntry + " ".
    set i to i + 1.
  }
  set printcEntry to printcEntry + "|".
  log printcEntry to fileName.
}

global function addLogLeftEntry {
  parameter lEntry.
  set lEntry to lEntry:toString.
  if MOD(lEntry:length, 2) = 0 {
      set lEntry to lEntry + " ".
  }
  set lEntryLength to lEntry:length.
  set blankWidth to logWidth - 2 - lEntryLength.
  set printlEntry to "|" + lEntry.
  set i to 0.
  until i >= blankWidth {
    set printlEntry to printlEntry + " ".
    set i to i + 1.
  }
  set printlEntry to printlEntry + "|".
  log printlEntry to fileName.
}

global function addLogItem {
  parameter theItem.
  parameter loc is "left".
  if loc = "left" {
    addLogLeftEntry("  · " + theItem).
  }
  if loc = "center" {
    addLogCenterEntry("  · " + theItem).
  }
}