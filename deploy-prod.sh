#!/bin/bash

#################################
##### VARIAVEIS DE AMBIENTE #####
#################################

# Pasta de Aplicacao
APP_PATH='sample'

# URL de checagem do ambiente stage
URL_STAGE='env-stage.us-east-1.elasticbeanstalk.com'

# Nome do Ambiente A
ENVIROMENT_A='sample-env-a'

# Nome do Ambiente A
ENVIROMENT_B='sample-env-b'

# Configuracao do ambiente Stage
STAGE_CONFIG='stage-template'

# Configuracao do ambiente Prod para troca de tamanho de servidor
PROD_CONFIG1='prod-template-1'

# Configuracao do ambiente Prod para troca de tamanho de servidor
PROD_CONFIG2='prod-template-2'

# Tempoe em minutos para realizar o Diminuicao do ambiente de prod para stage
TEMPO_DOWN_ENV='30'

###########################################################################
#### SCRIPT A SER EXECUTADO, EDITAR APENAS COM CERTEZA DO QUE DESEJA ######
###########################################################################

# Definindo status Ready
STATUS_READY="Ready"

# Definindo status Green
STATUS_GREEN="Green"

# Contruindo caminho da aplicacao
APP_PATH="$HOME/$APP_PATH"

# Checando existencia da pasta da Aplicacao
echo "Script esta checando a existencia da pasta da Aplicacao"
if [ -d $APP_PATH ] ;
then  

# Acessando Pasta de Aplicacao
cd $APP_PATH

# Checando existencia de configuracao de GIT.
echo "Script esta checando a existencia de configuracao de GIT"

# Contador de configuracao do GIT
COUNTER_GIT=`(ls -la .git | wc -l 2> /dev/null)`

# Reportando existencia de agendamentos
if [ $COUNTER_GIT -lt 2 ];
then
echo "Nao existe configuracao de GIT, necessario configurar e executar novamente."
exit
else
echo "Existe configuracao do GIT."
fi

# Checando existencia de configuracao de ElasticBeanstalk.
echo "Script esta checando a existencia de configuracao de ElastickBeanstalk"

# Contador da configuracao do beanstalk
COUNTER_EBT=`(ls -la .elasticbeanstalk | wc -l 2> /dev/null)`

# Reportando existencia de conf de elasticbeanstalk
if [ $COUNTER_EBT -lt 2 ];
then
echo "Nao existe configuracao de EBT, necessario configurar e executar novamente."
exit
else
echo "Existe configuracao do EBT."
fi

# Buscando o ambiente de stage
URL_PORTAL_A=`(eb status $ENVIROMENT_A | grep CNAME | cut -d " " -f4)`
URL_PORTAL_B=`(eb status $ENVIROMENT_B | grep CNAME | cut -d " " -f4)`

# Checando se o ambiente stage esta no ambiente a
if [ $URL_PORTAL_A == $URL_STAGE ] ;
then 
ENV_STAGE=$ENVIROMENT_A
ENV_PROD=$ENVIROMENT_B
fi

# Checando se o ambiente stage esta no ambiente b
if [ $URL_PORTAL_B == $URL_STAGE ] ;
then 
ENV_STAGE=$ENVIROMENT_B
ENV_PROD=$ENVIROMENT_A
fi

# Checando status dos Ambientes.
echo "Script esta checando STATUS dos ambientes Stage = $ENV_STAGE e Prod = $ENV_PROD"

# Obtendo status dos Ambientes.
STATUS_ENV_STAGE=`(eb status $ENV_STAGE | grep Status | cut -d " " -f4)`
STATUS_ENV_PROD=`(eb status $ENV_PROD | grep Status | cut -d " " -f4)`

# Checando se STATUS dos ambientes estao como READY, Caso nao estajam script sera paralizado.
if [[ $STATUS_ENV_STAGE != $STATUS_READY || $STATUS_ENV_PROD != $STATUS_READY ]] ;
then
echo "Ambientes nao estao em estado $STATUS_READY. Execute novamente quando ambos estiverem com Status: $STATUS_READY."
exit
else 
echo "Ambientes estao em estado $STATUS_READY"
fi

# Checando health dos Ambientes.
echo "Script esta checando HEALTH do ambiente Stage = $ENV_STAGE"

# Obtendo healt dos Ambientes.
HEALTH_ENV_STAGE=`(eb status $ENV_STAGE | grep Health | cut -d " " -f4)`
HEALTH_ENV_PROD=`(eb status $ENV_PROD | grep Health | cut -d " " -f4)`

# Checando se HEALTH dos ambientes STAGE estao como GREEN, Caso nao estajam script sera paralizado.
if [[ $HEALTH_ENV_STAGE != "$STATUS_GREEN" ]] ;
then
echo "Ambiente $ENV_STAGE nao esta em estado $STATUS_GREEN. Execute novamente quando o Health estiver: $STATUS_GREEN."
exit
else 
echo "Ambiente $ENV_STAGE esta em health $STATUS_GREEN"
fi

# Checando Agendamentos no Ambiente Stage.
echo "Script esta checando agendamentos do ambiente Stage = $ENV_STAGE"

# Contador de agendamentos
COUNTER_AT=`(atq | wc -l)` 

# Reportando existencia de agendamentos
if [ $COUNTER_AT -eq 0 ]; 
then
echo "Nao existem agendamentos."
else
echo "Existem agendamentos, necessario remove-los."
fi

# Variavel de controle de SWAP
while [[ $COUNTER_AT -gt 0 ]]; do
	
	# Obtendo ID do ATQ para remocao do agendamento
	ID_ATQ=`(atq | cut -s -f1 | awk NR==1)`
	
	# Removendo agendamentos do servidor de STAGE
	echo "Removendo agendamento de ID $ID_ATQ"
	atrm $ID_ATQ	
	
	# Atualizando o contador do ATQ
	COUNTER_AT=`(atq | wc -l)`
done

# Apresentando ambiente em Stage para usuarios e confirmando atualizacao
echo 'Stage atualmente esta no ambiente '$ENV_STAGE'! Para iniciar o processo de atualizacao resposta a questao abaixo!' | tee /var/log/deploy.log

# Confirmando Aumento de ambiente.
while true; do
    read -p 'Voce tem certeza que deseja efetuar a atualizacao do ambiente STAGE para PROD?' yn
    case $yn in
        [Yy]* ) echo 'Realizando deploy em '$ENV_STAGE'!' | tee /var/log/deploy.log; break;;
        [Nn]* ) exit;;
        * ) echo "Por favor, responda yes ou no.";;
    esac
done

# Checando necessidade de aumento de ambiente

# Obtendo informacoes de variaveis de STAGE ou PROD, desta forma identificamos a configuracao de STAGE se esta tamanho de prod.
echo "Obtendo informacoes de variaveis de STAGE ou PROD, desta forma identificamos a configuracao de STAGE se esta tamanho de prod."
CONFIG_STAGE=`(eb printenv $ENV_STAGE | grep stage | wc -l)`

# IF para execucao de aumento de ambiente em caso de necessidade.
if [ $CONFIG_STAGE -eq 0 ];
then
echo "Configracao de ambiente STAGE, ja esta no tamanho de PROD."
else
echo "Existe a necessidade de UPDATE de tamanho de Ambiente de STAGE."
# Realizando a troca de tamanho do servidor. 
echo 'Realizando a troca do tamanho do servidor do Ambiente '$ENV_STAGE' para a configuracao '$PROD_CONFIG1'!' | tee /var/log/deploy.log 
eb config $ENV_STAGE --cfg $PROD_CONFIG1 --timeout 15
# Realizando o Restart dos servidor web para atualizacao das variaveis de ambiente. 
echo 'Realizando restart do servidor primario para atualizacao das variaveis de ambiente no Ambiente '$ENV_STAGE'.' | tee /var/log/deploy.log 
aws elasticbeanstalk restart-app-server --environment-name $ENV_STAGE

# Tempo para atualizacao de Health do ambiente
sleep 10

# Checando health do Ambiente Stage.
echo "Script esta checando STATUS do ambiente Stage = $ENV_STAGE"

# Contador do health
COUNTER=0

# Variavel de controle de SWAP
READY_TO_SWAP=false

# Aguardando ambiente mover para Green
while [[ $READY_TO_SWAP == false && $COUNTER -lt 5 ]]; do
	echo "Obtendo Status de Stage"
	STATUS_ENV_STAGE=`(eb status $ENV_STAGE | grep Status | cut -d " " -f4)`
	if [ $STATUS_ENV_STAGE == $STATUS_READY ];
		then
		READY_TO_SWAP=true
		else
		sleep 30
		COUNTER=$[$COUNTER+1]
	fi
done

if [ $READY_TO_SWAP != "true" ] ;
then 
echo "Ambiente nao esta em Status $STATUS_READY"
exit
else
echo "Ambiente esta em Status $STATUS_READY" 
fi

# Realizando o aumento de servidores no template de PROD
echo 'Realizando o resize do Ambiente para varios servidores em '$ENV_STAGE' para a configuracao '$PROD_CONFIG2'!' | tee /var/log/deploy.log 
eb config $ENV_STAGE --cfg $PROD_CONFIG2 --timeout 15
echo 'Resize do Ambiente '$ENV_STAGE' para a configuracao '$PROD_CONFIG2' efetuado com Sucesso!' | tee /var/log/deploy.log
fi

# Checando status dos Ambientes.
echo "PREPARANDO SWAP DE URLS: Script esta checando STATUS dos ambientes Stage = $ENV_STAGE e Prod = $ENV_PROD"

# Obtendo status dos Ambientes.
STATUS_ENV_STAGE=`(eb status $ENV_STAGE | grep Status | cut -d " " -f4)`
STATUS_ENV_PROD=`(eb status $ENV_PROD | grep Status | cut -d " " -f4)`

# Checando se STATUS dos ambientes estao como READY, Caso nao estajam script sera paralizado.
if [[ $STATUS_ENV_STAGE != $STATUS_READY || $STATUS_ENV_PROD != $STATUS_READY ]] ;
then
echo "Ambientes nao estao em estado $STATUS_READY"
exit
else 
echo "Ambientes estao em estado $STATUS_READY"
fi

# Checando health do Ambiente Stage.
echo "PREPARANDO SWAP DE URLS: Script esta checando HEALTH do ambiente Stage = $ENV_STAGE"

# Contador do health
COUNTER=0

# Variavel de controle de SWAP
READY_TO_SWAP=false

# Aguardando ambiente mover para Green
while [[ $READY_TO_SWAP == false && $COUNTER -lt 5 ]]; do
	echo "PREPARANDO SWAP DE URLS: Obtendo Health de Stage"
	HEALTH_ENV_STAGE=`(eb status $ENV_STAGE | grep Health | cut -d " " -f4)`
	if [ $HEALTH_ENV_STAGE == $STATUS_GREEN ];
		then
		READY_TO_SWAP=true
		else
		sleep 30
		COUNTER=$[$COUNTER+1]
	fi
done

if [ $READY_TO_SWAP != "true" ] ;
then 
echo "Ambiente nao esta em Health $STATUS_GREEN"
exit
else
echo "PRONTO PARA SWAP DE URLS. Ambiente esta em Health $STATUS_GREEN" 
fi

# Confirmando execucao de SWAP de URLs
while true; do
    read -p 'Voce tem certeza que deseja efetuar o SWAP de URLs de STAGE para PROD (Confirme se o seu ambiente de Stage esta correto igual a prod)?' yn
    case $yn in
        [Yy]* ) echo 'Realizando SWAP de URLS em '$ENV_STAGE'!' | tee /var/log/deploy.log; aws cloudwatch put-metric-data --metric-name Deploy --namespace DeployServer --statistic-values Sum=2,Minimum=0,Maximum=2,SampleCount=1 --unit Count; break;;
        [Nn]* ) exit;;
        * ) echo "Por favor, responda yes ou no.";;
    esac
done

# Realizando o SWAP de URLS do Ambiente de Stage para Prod
echo 'Realizando o SWAP de URLS do Ambiente STAGE para PROD '$ENV_STAGE' -> Ambiente de Producao.' | tee /var/log/deploy.log
aws elasticbeanstalk swap-environment-cnames --source-environment-name $ENVIROMENT_A --destination-environment-name $ENVIROMENT_B
echo 'SWAP de URLS do Ambiente STAGE para PROD realizado com sucesso! '$ENV_STAGE' agora esta como Producao!' | tee /var/log/deploy.log

# Agendando a diminiocao do ambiente de prod anterie para ser diminuido
echo 'Agendando para que o antigo ambiente de PROD '$ENV_PROD' seja diminuido para a configuracao '$STAGE_CONFIG'. Esta configuracao levara '$TEMPO_DOWN_ENV' minutos para ser reduzido.' | tee /var/log/deploy.log 
at now + $TEMPO_DOWN_ENV minutes <<< "eb config $ENV_PROD --cfg $STAGE_CONFIG"

# Calculando tempo para agendamento de restart de varivais de ambiente no servidor novo de STAGE.
TEMPO_DOWN_ENV2=$[$TEMPO_DOWN_ENV+15]
echo 'Agendando para que o antigo ambiente de PROD '$ENV_PROD' seja reiniciado os servidores web para atualizacao da variavel de ambiente. Esta configuracao levara '$TEMPO_DOWN_ENV2' para ser reiniciado.' | tee /var/log/deploy.log 
at now + $TEMPO_DOWN_ENV2 minutes <<< "aws elasticbeanstalk restart-app-server --environment-name $ENV_PROD"

else

echo "$APP_PATH pasta nao existe. Favor configurar Aplicacao antes de executar o Script."
exit

fi