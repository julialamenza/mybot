#!/bin/bash
T1="ok"
	if [ "$T1" = ok ]; then 
		echo is true
	else
		echo is false
	fi
# echo 'Stage atualmente esta no ambiente! Para iniciar o processo de atualizacao resposta a questao abaixo!'

# while true; do
#     read -p 'Voce tem certeza que deseja atualizar o ambiente ?' yn
#     case $yn in
#         [Yy]* ) 
# 		echo 'Realizando deploy!'
# 	;;
#         [Nn]* ) 
# 		exit;
# 	;;
#         * ) 
#                 echo "Por favor, responda yes ou no."
# 	;;
#     esac
# done