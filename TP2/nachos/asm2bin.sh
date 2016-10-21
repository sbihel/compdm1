#!/bin/sh                                         
############################################################                                                                                                       
#                                                 
#  asm2bin.sh permet de compiler un fichier assembleur MIPS                                                                                                          
#  (extension.s) en un exécutable pour Nachos     
#                                                 
#  Le fichier .s doit être dans le sous-répertoire test.                                                                                                           
#                                                 
#  Le fichier objet (extension .o) ainsi que le fichier                                                                                                            
#  exécutable seront dans le répertoire test à l'issue de                                                                                                           
#  la compilation si le fichier assembleur est valide                                                                                                              
#                                                 
#  Exemple d'utilisation : ./build.sh fichier     
#                                                 
#  Pensez à modifier les droits du scripts :      
#  chmod +x asm2bnin.sh                              
#                                                 
############################################################                                                                                                       

if test "$1" = ""
    then
    echo "usage: asm2bin.sh prog_name (without extension .s)"
    exit 1;
    fi

DIR=/share/m1info/cross-mips/bin

cd test

$DIR/mips-gcc -x assembler-with-cpp -c  -G0  -c $1.s
$DIR/mips-ld  -T ../lib/ldscript.lds ../lib/sys.o ../lib/libnachos.o $1.o -o $1
