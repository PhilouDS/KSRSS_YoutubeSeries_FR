clearscreen.
core:part:getModule("kosProcessor"):doEvent("close terminal").

// ==============================
// CONSTANTES & PARAMÈTRES
// ==============================

// Seuils Kourou 09/27 (degrés)
set end09_lat to 5.11779251382654.
set end09_lon to -52.8097926766841.
set end27_lat to 5.11785059545751.
set end27_lon to -52.7370655822809.

// Caps de finale
set rwy09_hdg to 90.
set rwy27_hdg to 270.

// Pente (deg) et vitesse cible
set glideslope_deg to 5.
set cutoff_dist    to 350.   // m : fin auto-throttle
set far_dist       to 4000.  // m : passage de 110 m/s à 70 m/s
set v_hold_far     to 110.   // m/s au-delà de far_dist
set v_hold_near    to 70.    // m/s à dist <= far_dist

// AGL robuste (point le plus bas du craft)
set bb to ship:bounds.
lock altitudeAGL to max(0, bb:bottomaltradar).

// ==============================
// FONCTIONS
// ==============================
function clamp { parameter x, lo, hi. if x < lo { return lo. } if x > hi { return hi. } return x. }.
function angnorm { parameter a. return mod((a + 360), 360). }.
function angdiff_signed { parameter a, b. return mod((a - b + 540), 360) - 180. }.
// Distance surface (m), trig en degrés (kOS)
function surface_dist {
  parameter lat1_deg, lon1_deg, lat2_deg, lon2_deg.
  set a to sin((lat2_deg - lat1_deg)/2)^2 + cos(lat1_deg)*cos(lat2_deg)*sin((lon2_deg - lon1_deg)/2)^2.
  set cdeg to 2 * arctan2(sqrt(a), sqrt(1 - a)).
  return ship:body:radius * cdeg * constant:degtorad.
}.

// ==============================
// CHOIX DU SEUIL (09/27) & BASES
// ==============================
set lat_now to ship:geoposition:lat.
set lon_now to ship:geoposition:lng.
set d09 to surface_dist(lat_now, lon_now, end09_lat, end09_lon).
set d27 to surface_dist(lat_now, lon_now, end27_lat, end27_lon).
if d09 <= d27 {
  set rwy_lat  to end09_lat.
  set rwy_lon  to end09_lon.
  set rwy_hdg  to rwy09_hdg.
  set rwy_name to "09".
} else {
  set rwy_lat  to end27_lat.
  set rwy_lon  to end27_lon.
  set rwy_hdg  to rwy27_hdg.
  set rwy_name to "27".
}.

// Vecteurs horizontaux
set eastv  to vcrs(up:vector, north:vector).
set northv to north:vector.

// Cap avion (0..360)
lock plane_hdg to angnorm( arctan2( vdot(ship:facing:forevector, eastv),
                                    vdot(ship:facing:forevector, northv) ) ).

// Métriques locales (plan tangent) au seuil choisi
set r_body        to ship:body:radius.
set m_per_deg_lat to r_body * constant:degtorad.
set m_per_deg_lon to r_body * constant:degtorad * cos(rwy_lat).

// Axe inbound (centre-ligne, direction QFU)
set ue_in to sin(rwy_hdg).   // Est
set un_in to cos(rwy_hdg).   // Nord

// Pente en tangente (trig kOS en degrés)
set slope to tan(glideslope_deg).

// ==============================
// GUI (HUD + contrôles)
// ==============================
set hud to gui(520, 420).

// Lignes texte
set rowTitle  to hud:addlabel("").
set rowInfo   to hud:addlabel("").   // Dist + Alt Cible
set rowSide   to hud:addlabel("").
set rowHdg    to hud:addlabel("").
set rowCmd    to hud:addlabel("").

// PAPI sur une SEULE ligne (clair)
set rowPAPI   to hud:addlabel("").

// “Colonne verticale” : 9 labels indépendants (pas de \n)
set vert0 to hud:addlabel("").
set vert1 to hud:addlabel("").
set vert2 to hud:addlabel("").
set vert3 to hud:addlabel("").
set vert4 to hud:addlabel("").
set vert5 to hud:addlabel("").
set vert6 to hud:addlabel("").
set vert7 to hud:addlabel("").
set vert8 to hud:addlabel("").

// Ligne boutons + témoin
set lineCtl   to hud:addhlayout().
set btn       to lineCtl:addbutton("V HOLD: OFF").
set ledLbl    to lineCtl:addlabel("<color=#777777ff>●</color>").
set btnx      to lineCtl:addbutton("FERMER").

set hud:visible to true.

// ==============================
// AUTO-THROTTLE (état)
// ==============================
set hold_on  to false.
set spd_int  to 0.
set spd_prev to 0.
set thr_prev to 0.

// Callbacks boutons (kOS: pas de parameter dans onclick)
set btn:onclick to {
  if hold_on {
    set hold_on to false.
    set btn:text to "V HOLD: OFF".
    set ledLbl:text to "<color=#777777ff>●</color>".
    unlock throttle.
  } else {
    set hold_on to true.
    set btn:text to "V HOLD: ON".
    set ledLbl:text to "<color=#00ff00ff>●</color>".
  }.
}.

set btnx:onclick to {
  if hold_on {
    set hold_on to false.
    unlock throttle.
  }.
  set hud:visible to false.
  set running to false.
}.

// Boucle de vie
set running to true.

// ==============================
// BOUCLE HUD + HOLD VITESSE
// ==============================
until not running {

  // --- position & distances ---
  set lat_now to ship:geoposition:lat.
  set lon_now to ship:geoposition:lng.
  set d_thr   to surface_dist(lat_now, lon_now, rwy_lat, rwy_lon).

  // Offsets locaux E/N (m) depuis le seuil
  set dx to (lon_now - rwy_lon) * m_per_deg_lon.   // Est +
  set dy to (lat_now - rwy_lat) * m_per_deg_lat.   // Nord +

  // Décomposition par rapport à l’axe inbound
  set along  to ue_in*dx + un_in*dy.
  set xtrack to (-un_in)*dx + ue_in*dy.
  // Affichage : xtrack > 0 => piste à TA DROITE (tu es à gauche de l’axe)
  //             xtrack < 0 => piste à TA GAUCHE (tu es à droite de l’axe)

  // Vitesse sol horizontale (pour le “lead” adaptatif)
  set v_surf to ship:velocity:surface.
  set v_up   to vdot(v_surf, up:vector).
  set v_h    to v_surf - (v_up * up:vector).
  set gs     to v_h:mag.

  // --------- CAP CONSEIL (carotte sur l’axe) ---------
  set lead_s to clamp( max(0.35 * d_thr, gs * 4), 600, 4000 ).
  set s_tgt  to along + lead_s.
  set dx_tgt to ue_in * s_tgt.
  set dy_tgt to un_in * s_tgt.
  set de     to dx_tgt - dx.
  set dn     to dy_tgt - dy.
  set cap_cmd to angnorm( arctan2(de, dn) ).

  // Virage demandé depuis le cap avion
  set turn_err to angdiff_signed(cap_cmd, plane_hdg).
  set turn_dir to "OK".
  if turn_err >  1 { set turn_dir to "droite". }.
  if turn_err < -1 { set turn_dir to "gauche". }.

  // --------- VERTICAL : Alt Cible / PAPI / Diamant ---------
  set h_des  to d_thr * slope.            // Alt Cible (m)
  set h_err  to h_des - altitudeAGL.      // + = trop bas ; - = trop haut

  // PAPI clair (4 pastilles, une ligne)
  // Seuils : très haut (< -40), haut (-40..-20), sur plan (-20..20), bas (20..40), très bas (>40)
  set papi_txt to "".
  if h_err < -40 {
    set papi_txt to "<color=#ffffffff>  ■■  ■■  ■■  ■■  </color>".          // 4 blanches
  } else if h_err < -20 {
    set papi_txt to "<color=#ffffffff>  ■■  ■■  ■■  </color><color=#ff0000ff>  ■■  </color>".   // 3 blanches + 1 rouge
  } else if h_err <= 20 {
    set papi_txt to "<color=#ffffffff>  ■■  ■■  </color><color=#ff0000ff>  ■■  ■■  </color>".   // 2 & 2
  } else if h_err <= 40 {
    set papi_txt to "<color=#ffffffff>  ■■  </color><color=#ff0000ff>  ■■  ■■  ■■  </color>".   // 1 blanche + 3 rouges
  } else {
    set papi_txt to "<color=#ff0000ff>  ■■  ■■  ■■  ■■  </color>".           // 4 rouges
  }.
  set rowPAPI:text to "PAPI : " + papi_txt.

  // “Diamant” vertical — 9 lignes indépendantes (pas = 20 m), 0 m en VERT
  set tick_step to 20.
  // Échelle inversée pour l’affichage (haut = bas, bas = haut) tout en gardant les valeurs justes :
  set ticks to list(80, 60, 40, 20, 0, -20, -40, -60, -80).
  // Si tu es BAS (h_err>0), le diamant monte (pos négatif, index au-dessus du 0) :
  set pos   to clamp( round((-h_err) / tick_step), -4, 4 ).
  set idx   to 4 + pos.


  // Construire le texte de chaque ligne (marqueur + échelle)
  // i=0..8, où i=4 est le 0 m
  function build_line {
    parameter i, idx, ticks.
    // marqueur
    set mark to "".
    if i = idx {
      set mark to "<color=#00ff00ff>◆</color>". // diamant VERT
    } else {
      set mark to "<color=#aaaaaaff>●</color>". // point gris
    }.
    // étiquette
    set val to ticks[i].
    set lab to "".
    if val = 0 {
      set lab to "<b><color=#00ff00ff>0 m</color></b>".
    } else {
      if val > 0 { set lab to "+" + val + " m". } else { set lab to "" + val + " m". }.
      set lab to "<color=#aaaaaaff>" + lab + "</color>".
    }.
    return mark + "   " + lab.
  }.

  set vert0:text to build_line(0, idx, ticks).
  set vert1:text to build_line(1, idx, ticks).
  set vert2:text to build_line(2, idx, ticks).
  set vert3:text to build_line(3, idx, ticks).
  set vert4:text to build_line(4, idx, ticks).
  set vert5:text to build_line(5, idx, ticks).
  set vert6:text to build_line(6, idx, ticks).
  set vert7:text to build_line(7, idx, ticks).
  set vert8:text to build_line(8, idx, ticks).

  // --------- AUTO-THROTTLE ---------
  if hold_on {
    // Cible vitesse selon distance
    set v_tgt to v_hold_far.
    if d_thr <= far_dist { set v_tgt to v_hold_near. }.

    // Rendre la main à l’approche
    if d_thr <= cutoff_dist {
      set applied_thr to clamp(ship:control:mainthrottle, 0, 1).
      set ship:control:pilotmainthrottle to applied_thr.
      unlock throttle.
      set V1 to getvoice(0).
      V1:play(note(440, 1)).
      set hold_on to false.
      set btn:text to "V HOLD: OFF".
      set ledLbl:text to "<color=#777777ff>●</color>".
    } else {
      // PID vitesse simple (+ anti-windup)
      set v_meas to ship:airspeed.
      set err    to v_tgt - v_meas.

      if not ((thr_prev <= 0 and err < 0) or (thr_prev >= 1 and err > 0)) {
        set spd_int to clamp(spd_int + err*0.1, -50, 50).
      }.
      set der     to (err - spd_prev) / 0.1.
      set spd_prev to err.

      set thr to clamp( 0.02*err + 0.01*spd_int + 0.05*der, 0, 1 ).
      lock throttle to thr.
      set thr_prev to thr.
    }.
  }.

  // --------- HUD TEXTE ---------
  set side to "centre".
  if xtrack >   5 { set side to "droite". }.
  if xtrack <  -5 { set side to "gauche". }.

  set rowTitle:text to "<b>HUD Alignement piste " + rwy_name + "</b>".
  set rowInfo:text to "Dist seuil : " + round(d_thr/1000, 2) + " km   |   Alt Cible : " + round(h_des, 0) + " m   |   Alt Actuelle : " + round(altitudeAGL, 0) + " m".
  set rowSide:text  to "Piste      : " + side + " (" + round(abs(xtrack),0) + " m)".
  set rowHdg:text   to "Cap avion  : " + round(plane_hdg,1) + " deg".
  set rowCmd:text   to "Cap conseil: " + round(cap_cmd,1) + " deg  — tourner " + turn_dir + " " + round(abs(turn_err),1) + " deg".

  wait 0.
}.

// Sortie sûre
if hold_on { unlock throttle. }.
