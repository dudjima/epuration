#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\Users\benjamin.duriez\Downloads\if_meliae-trashcan_full-new_25375.ico
#AutoIt3Wrapper_Res_Comment=programme permettant de faire une épuration pour PyxVital/VitalZen. Il prend en compte un argument : chemin du dossier FSE à épurer. Par défaut, il travailleras sur C:\Pyxvital\FSE
#AutoIt3Wrapper_Res_Fileversion=1.0.0.8
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Language=1036
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#RequireAdmin
#include <File.au3>
#include <Date.au3>
#include <Array.au3>
#include <WinAPIShPath.au3>
#include '..\constantes.au3'


#cs
explication du programme :
Dans un premier temps on vérifie le chemin du dosser Pyx à épurer, on peut le mettre en argument.(ex : D:\VitalZen)

=> On parcours les dossier (FSE ou LOTS)
=> On liste les dossiers non bak
=> On crée un dossier bak si nécessaire
=> On parcours chaque dossier et on déplace le fichier si nécessaire

#ce

#Region Definition des constantes
$chemin_logs 	= $dossier_logs & "\epuration_log.log"
Local $liste_dossiers[3] = [2, "FSE", "LOTS"]
#EndRegion

$dossier_existe = FileExists($dossier_logs)
if $dossier_existe = 0 Then
	DirCreate($dossier_logs)
	_FileWriteLog($chemin_logs, "Création du dossier de logs")
EndIf

_FileWriteLog($chemin_logs, "Début de la moulinette")

; ON RÉCUPERE LA CONFIGURATION DE PYXVITAL.INI

$ini_pyxvital = IniRead ($chemin_pyxvital_ini, "Répertoires", "FSE", "0")
if $ini_pyxvital == 0 Then
	_FileWriteLog($chemin_logs, "pyxvital.ini non trouve")
	MsgBox(0,"Erreur = 0", "Le programme ne trouve pas de pyxvital installé sur le poste")
Else
	$chemin_pyx =  StringTrimRight($ini_pyxvital,6)
	_FileWriteLog($chemin_logs, "Chemin FSE dans pyxvital.ini = " & $chemin_pyx)
EndIf

; ON VÉRIFIE SI ON EST SUR UNE INSTALLATION CLIENT-SERVEUR OU NON
If $chemin_pyx = @HomeDrive & "\pyxvital" Then ; on est sur une installation monoposte
	_FileWriteLog($chemin_logs, "Type d'installation : Monoposte")
ElseIf $chemin_pyx = @HomeDrive & "\vzlan" Then ; on est sur un poste serveur
	_FileWriteLog($chemin_logs, "Type d'installation : Serveur")
Else
	MsgBox(0, "Erreur = 1", "Vous êtes sur un poste client, merci d'utiliser le programme sur le serveur directement.")
	Exit
EndIf
#Region Parcours dossiers
; ON PARCOURS LES DOSSIERS
For $h = 1 To UBound($liste_dossiers)-1
	; ON RECUPERE LE DOSSIER LOT OU FSE A TRAITER
	$dossier = $liste_dossiers[$h]
	; ON LISTE LES DOSSIERS A EPURER. ON EXCLUE LES FICHIERS QUI CONTIENNENT LE TERME BAK
	$chemin_dossier = $chemin_pyx & "\" & $dossier

	$liste_situations = _FileListToArrayRec($chemin_dossier, "*|*bak;*old", 2, 0, 1)

	#Region Parcours situations
	$recap = "" ; ON INITIALISE LA VARIABLE RÉCAPITULANT LES TRANSFERTS
	_FileWriteLog($chemin_logs,"Parcours des situations du dossier " & $dossier)

	For $i = 1 To ubound($liste_situations) - 1  ; ON COMMENCE À 1 CAR LA ZONE 0 CONTIENT LA TAILLE DU TABLEAU ET DU COUP ON FAIT 1 POUR NE PAS SORTIR DU TABLEAU
		; ON CREE LE CHEMIN DES FICHIERS
		$chemin_situation = $chemin_dossier & "\" & $liste_situations[$i]
		_FileWriteLog($chemin_logs,"situation lue : " & $chemin_situation)

		; ON TESTE L'EXISTENCE DES DOSSIERS DE BACKUP SI NON ON LES CREES
		$existence_bak = FileExists($chemin_situation & "bak")
		If $existence_bak = 0 Then
			DirCreate ($chemin_situation & "bak")
			_FileWriteLog($chemin_logs, "dossier crée : " & $chemin_situation & "bak")
		EndIf
		; ON LISTE LES FICHIERS  DU DOSSIER PARCOURU
		$liste_FSE = _FileListToArray($chemin_situation)
		; ON PARCOURS LES FICHIERS

		$compteur = 0
		#Region parcours des fichiers
		For $j = 1 to UBound($liste_FSE) - 1  ; ON COMMENCE À 1 CAR LA ZONE 0 CONTIENT LA TAILLE DU TABLEAU ET DU COUP ON FAIT 1 POUR NE PAS SORTIR DU  TABLEAU
			; ON DEFINI LE CHEMIN DU FICHIER
			$chemin_fichier = $chemin_situation & "\" & $liste_FSE[$j]

			; ON RECUPERE LA DATE DE CREATION DU FICHIER ET ON LA CONVERTIS
			$date_fichier_array = FileGetTime($chemin_fichier)
			$date_fichier = $date_fichier_array[0] & "/" & $date_fichier_array[1] & "/" & $date_fichier_array[2]
			; ON CALCULE L'ANCIENNETE DU FICHIER PAR RAPPORT A AUJOURD'HUI
			$dif = _DateDiff("D", $date_fichier, _NowCalc())

			_FileWriteLog($chemin_logs,"Fichier lu : " & $chemin_fichier& " - Date : " & $date_fichier &" - Difference : "& $dif)

			; SI IL A PLUS DE 3 MOIS ON LE BOUGE DANS LE DOSSIER BAK QUI VA BIEN
			If $dif > 92 Then
				$test = FileMove($chemin_fichier,$chemin_situation&"bak",0)
				_FileWriteLog($chemin_logs, "Fichier déplacé : " & $chemin_fichier)
				$compteur += 1
			Else ; SI LE FICHIER A MOINS DE 3 MOIS LES FICHIERS SUIVANT AURONT AUSSI MOINS DE 3 MOIS (ORDRE CHRONOLOGIQUE) ON ARRETE DE BOUCLER
				_FileWriteLog($chemin_logs, "Début des fichiers de moins de 3 mois : STOP")
;~ 				ExitLoop ; QUITTE LA BOUCLE FOR
			EndIf
		Next
		#EndRegion

		;ON HISTORISE LES FSE DÉPLACÉ
		$recap = $dossier & " - compteur de " & $liste_situations[$i] & " = " & $compteur
		_FileWriteLog($chemin_logs,$recap)
	Next
	#EndRegion
Next
#EndRegion
_FileWriteLog($chemin_logs, "Fin de l'épuration")
Exit
