# KSRSS_YoutubeSeries_FR

_Codes kOS utilisés dans ma série youtube sur KSRSS._

dernière maj : 29 novembre 2025

## Important

**Attention :** J'utilise pour le moment systématiquement QUATRE processeurs kOS (celui à plus faible capacité) et les bibliothèques sont chargés dans ces processeurs ! Un **seul** processeur est configuré pour utiliser un fichier de _boot_. Le script principal de la mission est également chargé dans un processeur.

Lors du lancement du fichier de _boot_, toutes les bibliothèques au format `.ks` sont compilées et transformées au format `.ksm`. Ces fichiers sont stockés dans le répertoire `KSM_LIB`. L'avantage, c'est qu'il suffit de modifier les fichiers `.ks` et les fichiers `.ksm` seront automatiquement mis à jour à chaque nouveau vol.

Vous pouvez utiliser librement tous ces scripts, les modifier et les partager mais ce serait évidemment appréciable que vous me citiez dans vos sources.

Au fur et à mesure de ma partie, tous les scripts sont indéniablement amenés à être modifiés.

## Structure du dossier `Script`

```text
|   Avion_AP.ks
|   dv-map-ksrss2.5x.png
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
|       KSRSS_Transfert.ksm
|
+---KSRSS_LIB
|       KSRSS_En-vol.ks
|       KSRSS_Lancement.ks
|       KSRSS_log.ks
|       KSRSS_Manoeuvre.ks
|       KSRSS_Outils.ks
|       KSRSS_RDV.ks
|       KSRSS_Stats.ks
|       KSRSS_Transfert.ks
|
+---KSRSS_LOGS
|
|  non détaillé ici
|
+---KSRSS_MISSIONS
|       00_mnv.ks
|       01_tout_droit.ks
|       02_orbite.ks
|       03_orbite_AR.ks
|       04_orbite_polaire.ks
|       05_survol_lune.ks
|       06_orbite_lune.ks
|       07_vers_Lune.ks
|       08_rdv.ks
|       09_geoOrbit.ks
|       10_JR_espace_lointain.ks
|       11_relais_lunaire.ks
|       12a_docking_1.ks
|       12b_docking_2.ks
|       13_Touristes.ks
|       14_geoOrbit_x4.ks
|       15_alunissage.ks
|       16_relais_lunaire_5M.ks
|       17_alunissage_polaire.ks
|       18_biomes_lunaires.ks
|       18b_biomes_lunaires.ks
|       19_Kerbal_orbite_lunaire.ks
|       99_sauvetage.ks
```
