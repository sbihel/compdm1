#!/bin/sh                                                   
############################################################
#                                                           
#  exec.sh permet de lancer l'exécution d'un fichier binaire
#  compilé pour Nachos sur le simulateur.                   
#                                                           
#  Le fichier binaire doit être dans le sous-répertoire test.                                                                                                                
#                                                           
#  Exemple d'utilisation : ./exec.sh fichier                
#                                                           
#  Pensez à modifier les droits du scripts :                
#  chmod +x exec.sh                                        
#                                                           
############################################################

if test "$1" = ""
    then
    echo "usage: exec.sh prog_name"
    exit 1;
    fi

#génération du fichier de config                            
sed -e "s/X_PROG/$1/g" ./template.cfg > nachos.cfg

#lancement du simulateur                                    
./nachos

#clean                                                      
rm -f DISK
rm -f nachos.cfg
