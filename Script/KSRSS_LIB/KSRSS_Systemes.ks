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

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// ANTENNES
//_________________________________________________

local antenna_module is "ModuleDeployableAntenna".
local antenna_Event_Deploy is "déployer antenne".
local antenna_Event_Retract is "rétracter antenne".

global function deployerAntennes {
  parameter antenna_tag is "".
  for part in ship:partsTagged(antenna_Tag) {
    if part:hasmodule(antenna_module) {
      if part:getModule(antenna_module):hasEvent(antenna_Event_Deploy) {
        part:getModule(antenna_module):doEvent(antenna_Event_Deploy).
      }
    }
  }
  wait 0.
  logFlightEvent("Antenne(s) déployée(s).").
}
global function retracterAntennes {
  parameter antenna_tag is "".
  for part in ship:partsTagged(antenna_Tag) {
    if part:hasmodule(antenna_module) {
      if part:getModule(antenna_module):hasEvent(antenna_Event_Retract) {
        part:getModule(antenna_module):doEvent(antenna_Event_Retract).
      }
    }
  }
  wait 0.
  logFlightEvent("Antenne(s) rétractée(s).").
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// COIFFES
//_________________________________________________

local fairing_module is "ModuleProceduralFairing".
local fairing_Event_Deploy is "déployer".

global function deployerCoiffe {
  parameter fairing_Tag is "".
  for part in ship:partsTagged(fairing_Tag) {
    if part:hasmodule(fairing_module) {
      if part:getModule(fairing_module):hasEvent(fairing_Event_Deploy) {
        part:getModule(fairing_module):doEvent(fairing_Event_Deploy).
      }
    }
  }
  wait 0.
  logFlightEvent("Coiffe déployée.").
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// BAIE UTILITAIRE
//_________________________________________________

local service_module is "ModuleAnimateGeneric".
local service_Event_Open is "ouvrir".
local service_Event_Close is "fermer".

global function ouvrirService {
  parameter service_Tag is "".
  for part in ship:partsTagged(service_Tag) {
    if part:hasmodule(service_module) {
      if part:getModule(service_module):hasEvent(service_Event_Open) {
        part:getModule(service_module):doEvent(service_Event_Open).
      }
    }
  }
  wait 0.
  logFlightEvent("Ouverture de la baie utilitaire.").
}

global function fermerService {
  parameter service_Tag is "".
  for part in ship:partsTagged(service_Tag) {
    if part:hasmodule(service_module) {
      if part:getModule(service_module):hasEvent(service_Event_Close) {
        part:getModule(service_module):doEvent(service_Event_Close).
      }
    }
  }
  wait 0.
  logFlightEvent("Fermeture de la baie utilitaire.").
}