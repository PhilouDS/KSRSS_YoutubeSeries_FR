# KSRSS_YoutubeSeries_FR

_Codes kOS utilisés dans ma série youtube sur KSRSS._

dernière maj : 20 janvier 2026

## Important

**Attention :** J'utilise au moins deux processeurs kOS ! Un **seul** processeur est configuré pour utiliser un fichier de _boot_. Le script principal de la mission est également chargé dans un processeur. Les bibliothèques sont chargées dans les autres processeurs et, lorsqu'il n'y a plus de place, les bibliothèques restantes sont chargées dans le processeur principal.

Lors du lancement du fichier de _boot_, toutes les bibliothèques au format `.ks` sont compilées et transformées au format `.ksm`. Ces fichiers sont stockés dans le répertoire `KSM_LIB`. L'avantage, c'est qu'il suffit de modifier les fichiers `.ks` et les fichiers `.ksm` seront automatiquement mis à jour à chaque nouveau vol.

Vous pouvez utiliser librement tous ces scripts, les modifier et les partager mais ce serait évidemment appréciable que vous me citiez dans vos sources.

Au fur et à mesure de ma partie, tous les scripts sont indéniablement amenés à être modifiés.

## Structure du dossier `Script`

```text
|   Avion_AP.ks
|   dv-map-ksrss2.5x.png
|   Rover_v2.ks
|
+---boot
|       1-Load_on_ship.ks
|       AP_boot.ks
|
+---KSM_LIB
|       KSRSS_En-vol.ksm
|       KSRSS_Lancement.ksm
|       KSRSS_log.ksm
|       KSRSS_Manoeuvre.ksm
|       KSRSS_Outils.ksm
|       KSRSS_RDV.ksm
|       KSRSS_Stats.ksm
|       KSRSS_Systemes.ksm
|       KSRSS_Transfert.ksm
|       KSRSS_Transfertt_LuneTerre.ksm
|
+---KSRSS_LIB
|       KSRSS_En-vol.ks
|       KSRSS_Lancement.ks
|       KSRSS_log.ks
|       KSRSS_Manoeuvre.ks
|       KSRSS_Outils.ks
|       KSRSS_RDV.ks
|       KSRSS_Stats.ks
|       KSRSS_Systemes.ks
|       KSRSS_Transfert.ks
|       KSRSS_Transfertt_LuneTerre.ks
|
+---KSRSS_LOGS
|
|  non détaillé ici
|
+---KSRSS_MISSIONS
|
|  non détaillé ici
|
```
