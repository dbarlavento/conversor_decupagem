#!/bin/bash

#Adicionar função para gerar arquivo de texto com instruções sobre a vizualização
#dos arquivos.


### Definiçõe das variaveis globais

# Caminho para o cocoadialog
CD_DIALOG="/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog"

# Caminho para o conversor
CD_CONVERSOR="/Applications/./ffmpeg"
#CD_CONVERSOR="/Applications/./HandBrakeCLI"
#CD_CONVERSOR="outro"

# Caminho para a pasta criada pelo Xdcamtransfer durante a captura dos videos
CD_VID_ORIGEM=""

# Caminho para a pasta onde são criadas as pastas com os arquivos convertidos
CD_VID_DESTINO=""

# Arquivos temporarios contendo a listagens dos arquivos a serem convertidos separados por \n
TEMP_1="/tmp/ARQUIVOS_1.list"
#Arquivos temporarios contendo a listagens dos arquivos a serem convertidos separados por espaços
TEMP_2="/tmp/ARQUIVOS_2.list"

# Variavel contendo a fila para a barra de progresso (progressbar)
PROGRESSFIFO="/tmp/progressfifo_decupagem"

# Comando para encerrar o terminal
KILL="kill -9 `ps -A | grep -w Terminal.app | grep -v grep | awk '{print $1}'`"





### Início do programa
# Configura o endereço do conversor como seu caminho absoluto
#PATH_APP=$( pwd )
#CD_CONVERSOR=$(echo "$PATH_APP""$CD_CONVERSOR")

###Pede ao usuário que selecione a pasta contendo os arquivos a serem convertidos
CD_VID_ORIGEM=$("$CD_DIALOG" fileselect \
    --title "LIS Softwares - Decupagem"\
    --text "Selecione a pasta com os arquivos brutos" \
    --with-directory $HOME \
    --select-only-directories)

#Verifica se o item selecionado é um diretório
if test -d "$CD_VID_ORIGEM" 
then
    #Remove os espaços do nome do diretório e os troca por underline
#	nomeDir=$( echo "$CD_VID_ORIGEM" | sed 's/ /_/g' )
	
	#Renomeia a pasta selecionada
	#echo "$nomeDir"
#	mv "$CD_VID_ORIGEM" "$nomeDir"
	
#	CD_VID_ORIGEM=$( echo "$nomeDir" )
	
#	unset nomeDir

    ls "$CD_VID_ORIGEM"/*.mov > "$TEMP_1"

    # Contagem do numero de arquivos e tratamento da saida do comando wc
    num=$( wc -l "$TEMP_1" | sed 's/^[ \t]*//')
    num=${num%"$TEMP_1"}
    
    #Verifica se a pasta tem arquivos mov
    if test "$num" -ne 0 
    then
        echo "entrou no if"
        # Cria lista de arquivos a serem convertidos
        cat "$TEMP_1" | tr '\n' ' ' > "$TEMP_2"
        respFinal=0
    else
        respFinal=$("$CD_DIALOG" ok-msgbox \
			--title "LIS Softwares - Decupagem" \
			--text "ERRO!" \
			--informative-text "Selecione uma pasta que contenha arquivos de video" \
			--no-cancel)
    fi #Fim do if
else
    echo "deu erro!!!"
fi #Fim do if

# Encerra o programa quando precionar ok, pasta não tem arquivo mov
if test "$respFinal" -eq 1
then
echo "fim!!!"
fi #Fim do if

# Desabilita a varialvel
unset respFinal

# Cria uma pasta para receber os arquivos convertidos, tem que testar se a pasta existe!
CD_VID_DESTINO="$CD_VID_ORIGEM/decupagem/"
mkdir "$CD_VID_DESTINO"

# Converte os arquivos para 720x480 usando o handbrakeCLI
# ./HandBrakeCLI -i entrada -o saida --width 720 --height 480

# Inicialização das variaveis 
numArq=1
arqIn="1"
arqOut="1"
contadorArq=1

# Inicio do progressbar de converção
rm -f "$PROGRESSFIFO" 			#remove fila criadas anteriormente
mkfifo "$PROGRESSFIFO"			#cria nova fila

# Direciona o conteudo da fila para o comando da progressbar
"$CD_DIALOG" progressbar --title "LIS Softwares - Decupagem" < "$PROGRESSFIFO" & 	

exec 3<> "$PROGRESSFIFO"		#cria descritivo associado ao arquivo PROGRESSFIFO

# Loop de converção
while test -n "$arqIn"
do
        
        # Extrai do arquivo "$TEMP2" a coluna indicada por "$contadorArq" contendo o nome do arquivo
        # a ser convertido e salva em "$arqIn"
        arqIn=$( cut -d' ' -f"$numArq" "$TEMP_2" )

        # Verifica se a lista de arquivos chegou ao fim
        if test -n "$arqIn"
        then
        
            # Parametros para o progressbar
            porcentagemTotal=$(( ($numArq * 100) / $num ))
        
            echo -n "$porcentagemTotal Convertendo $numArq de $num" >&3
        	
            # Cria o nome do arquivo apos a converção
            arqOut=${arqIn%/*}
            arqOut=${arqIn#$arqOut/}
            arqOut="${arqOut%.mov}".mp4
            arqOut="$CD_VID_DESTINO$arqOut"

            # Converte os arquivos usando o conversor definido em CD_CONVERSOR 
            "$CD_CONVERSOR" \
                -i "$arqIn" \
		-vf scale=720:480 \
		-map 0:0 -map 0:1 -map 0:2 \
                "$arqOut" \
		-y
            
            numArq=$(( 1 + $numArq ))
		
            contadorArq=$(( 1 + $contadorArq ))          	
                        		
	fi #Fim do if
		
done #Fim do while

# Finaliza a progressbar de converção dos arquivos
exec 3>&-
rm -f /tmp/progressbar

# Termina o programa
echo "fim!!!
################################################################################
