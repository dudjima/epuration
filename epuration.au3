;#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\Users\benjamin.duriez\Downloads\if_meliae-trashcan_full-new_25375.ico
#AutoIt3Wrapper_Res_Comment=programme permettant de faire une épuration pour PyxVital/VitalZen. Il prend en compte un argument : chemin du dossier FSE à épurer. Par défaut, il travailleras sur C:\Pyxvital\FSE
#AutoIt3Wrapper_Res_Fileversion=0.0.0.4
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Language=1036
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <Date.au3>
#include <Array.au3>
#include <WinAPIShPath.au3>


#cs
explication du programme :
Dans un premier temps on vérifie le chemin du dosser Pyx à épurer, on peut le mettre en argument.(ex : D:\VitalZen)

=> On parcours les dossier (FSE ou LOTS)
=> On liste les dossiers non bak
=> On crée un dossier bak si nécessaire
=> On parcours chaque dossier et on déplace le fichier si nécessaire

#ce
#Region Definition des constantes
; ON INIALISE LES LOGS
$chemin_logs 	= "c:\trilog\logs\epuration_log.log"
Local $liste_dossiers[3] = [2, "FSE", "LOTS"]
#EndRegion


$dossier_existe = FileExists('c:\trilog\logs')
if $dossier_existe = 0 Then
	DirCreate('c:\trilog\logs')
	_FileWriteLog($chemin_logs, "Création du dossier de logs")
EndIf

_FileWriteLog($chemin_logs, "Début de la moulinette")

; On récupere la configuration de pyxvital.ini
$ini_pyxvital = IniReadSection("c:\pyxvital\pyxvital.ini","Répertoires")
if @error Then
	_FileWriteLog($chemin_logs, "pyxvital.ini non trouve")
	MsgBox(0,"Erreur = 0", "Le programme ne trouve pas de pyxvital installé sur le poste")
Else
	_FileWriteLog($chemin_logs, "Valeur témoin de pyxvital.ini = " & $ini_pyxvital[4][1] )
EndIf

; On vérifie si on est sur une installation client-serveur ou non
if $ini_pyxvital[4][1] = "c:\pyxvital\FSE\#" Then ; on est sur une installation monoposte
	$chemin_pyx 	= "c:\pyxvital"
	_FileWriteLog($chemin_logs, "Type d'installation : Monoposte")
ElseIf $ini_pyxvital[4][1] = "C:\Vzlan" Then ; on est sur un poste serveur
	_FileWriteLog($chemin_logs, "Type d'installation : Serveur")
	$chemin_pyx 	= "c:\VZLan"
else
	MsgBox(0,"Erreur = 1", "Vous êtes sur un poste client, merci d'utiliser le programme sur le serveur directement. ")
EndIf


; ON TEST SI IL Y A UN ARGUMENT DÉCLARÉ
$aCmdLine = _WinAPI_CommandLineToArgv($CmdLineRaw)
if $aCmdLine[1] = "/ErrorStdOut" Then
	_FileWriteLog($chemin_logs, "aucun argument trouvé" )
Else
	$chemin_pyx = $aCmdLine[1]
	_FileWriteLog($chemin_logs, "un argument trouvé : " & $aCmdLine[1]& " -----")

EndIf

#Region Parcours dossiers
; ON PARCOURS LES DOSSIERS
$h = 1
For $h = 1 To UBound($liste_dossiers)- 1
	; ON RECUPERE LE DOSSIER LOT OU FSE A TRAITER
	$dossier = $liste_dossiers[$h]

	; ON LISTE LES DOSSIERS A EPURER. ON EXCLUE LES FICHIERS QUI CONTIENNENT LE TERME BAK
	$chemin_dossier = $chemin_pyx &"\"&$dossier
	$liste_situations = _FileListToArrayRec($chemin_dossier,"*||*bak",0,1,1)

	#Region Parcours situations
	$recap = "" ; on initialise la variable récapitulant les transferts
	_FileWriteLog($chemin_logs,"Parcours des situations du dossier " & $dossier)
	$i = 1
	FOR $i = 1 to UBound($liste_situations)- 1  ; on commence à 1 car la zone 0 contient la taille du tableau et du coup on fait 1 pour ne pas sortir du  tableau
		; ON CREE LE CHEMIN DES FICHIERS
		$chemin_situation = $chemin_dossier & "\" & $liste_situations[$i]
		_FileWriteLog($chemin_logs,"situation lue : " & $chemin_situation)

		; ON TESTE L'EXISTENCE DES DOSSIERS DE BACKUP SI NON ON LES CREES
		$existence_bak = FileExists($chemin_situation&"bak")
		if $existence_bak = 0 then
			DirCreate ($chemin_situation & "bak")
			_FileWriteLog($chemin_logs,"dossier crée : " & $chemin_situation & "bak")
		Endif

		; ON LISTE LES FICHIERS  DU DOSSIER PARCOURU
		$liste_FSE = _FileListToArray($chemin_situation)
		; ON PARCOURS LES FICHIERS
		$j=1
		$compteur = 0
		#Region parcours des fichiers
		FOR $j = 1 to UBound($liste_FSE) - 1  ; on commence à 1 car la zone 0 contient la taille du tableau et du coup on fait 1 pour ne pas sortir du  tableau
			; ON DEFINI LE CHEMIN DU FICHIER
			$chemin_fichier = $chemin_situation&"\" & $liste_FSE[$j]

			; ON RECUPERE LA DATE DE CREATION DU FICHIER ET ON LA CONVERTIS
			$date_fichier_arrray = FileGetTime($chemin_fichier,1)
			$date_fichier = $date_fichier_arrray[0] &"/"& $date_fichier_arrray[1] &"/"& $date_fichier_arrray[2]

			; ON CALCULE L'ANCIENNETE DU FICHIER PAR RAPPORT A AUJOURD'HUI
			$dif = _DateDiff("D",$date_fichier,_NowCalc())

			; SI IL A PLUS DE 3 MOIS ON LE BOUGE DANS LE DOSSIER BAK QUI VA BIEN
			if $dif > 92 Then
				$test = FileMove($chemin_fichier,$chemin_situation&"bak",0)
				$compteur += 1
			EndIf
		NEXT
		#EndRegion

		;ON HISTORISE LES FSE DÉPLACÉ
		$recap = $dossier & " - compteur de " & $liste_situations[$i] & " = " & $compteur
		_FileWriteLog($chemin_logs,$recap)
	NEXT
	#EndRegion
Next
#EndRegion
_FileWriteLog($chemin_logs,"Fin de l'épuration")
EXIT
