include Makefile.inc

all: build push deploy logs-init

.PHONY : compile
compile:
	@cd ${COMPILE} && BIN_CM=${NAME}-bin NAMESPACE=${NAMESPACE} make 

clean-compile:
	@cd ${COMPILE} && BIN_CM=${NAME}-bin NAMESPACE=${NAMESPACE} make clean 

build:
	@docker build -t ${IMAGE0} -f ${DOCKERFILES}/Dockerfile.${NAME0} .
	@docker build -t ${IMAGE3} -f ${DOCKERFILES}/Dockerfile.${NAME3} .
	@docker build -t ${IMAGE4} -f ${DOCKERFILES}/Dockerfile.${NAME4} .
	@docker build -t ${IMAGE6} -f ${DOCKERFILES}/Dockerfile.${NAME6} .
	@docker build -t ${IMAGE7} -f ${DOCKERFILES}/Dockerfile.${NAME7} .
	#@docker build -t ${IMAGE10} -f ${DOCKERFILES}/Dockerfile.${NAME10} .

push:
	@docker push ${IMAGE0}
	@docker push ${IMAGE3}
	@docker push ${IMAGE4}
	@docker push ${IMAGE6}
	@docker push ${IMAGE7}
	#@docker push ${IMAGE10}

cp:
	@find ${MANIFEST} -type f -name "*.sed" | sed s?".sed"?""?g | xargs -I {} cp {}.sed {}

sed:
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name}} -v ${NAME}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name0}} -v ${NAME0}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name1}} -v ${NAME1}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name2}} -v ${NAME2}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name3}} -v ${NAME3}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name4}} -v ${NAME4}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name5}} -v ${NAME5}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name6}} -v ${NAME6}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name7}} -v ${NAME7}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name8}} -v ${NAME8}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name9}} -v ${NAME9}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name10}} -v ${NAME10}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.namespace}} -v ${NAMESPACE}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.port}} -v ${PORT}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.url}} -v ${URL}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image}} -v ${IMAGE}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image0}} -v ${IMAGE0}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image1}} -v ${IMAGE1}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image2}} -v ${IMAGE2}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image3}} -v ${IMAGE3}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image4}} -v ${IMAGE4}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image5}} -v ${IMAGE5}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image6}} -v ${IMAGE6}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image7}} -v ${IMAGE7}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image8}} -v ${IMAGE8}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image10}} -v ${IMAGE10}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image.pull.policy}} -v ${IMAGE_PULL_POLICY}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.image.pull.policy2}} -v ${IMAGE_PULL_POLICY2}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.labels.key}} -v ${LABELS_KEY}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.labels.value}} -v ${LABELS_VALUE}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.scripts.cm}} -v ${SCRIPTS_CM}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.conf.cm}} -v ${CONF_CM}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.env.cm}} -v ${ENV_CM}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.proxy}} -v ${PROXY}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.discovery.name}} -v ${DISCOVERY_NAME}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.discovery.namespace}} -v ${DISCOVERY_NAMESPACE}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.object}} -v ${OBJECT}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.service.account}} -v ${SERVICE_ACCOUNT}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.svc1}} -v ${SVC1}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.svc2}} -v ${SVC2}
	@find ${MANIFEST} -type f -name "*.yaml" | xargs sed -i s?"{{.schedule}}"?"${SCHEDULE}"?g

deploy-main: OP=create
deploy-main:
	@kubectl -n ${NAMESPACE} ${OP} configmap ${SCRIPTS_CM} --from-file ${SCRIPTS}/.
	@kubectl -n ${NAMESPACE} ${OP} configmap ${CONF_CM} --from-file ${CONF}/.
	@kubectl ${OP} -f ${MANIFEST}/configmap.yaml
	@kubectl ${OP} -f ${MANIFEST}/daemonset.yaml
	@kubectl ${OP} -f ${MANIFEST}/service.yaml
	@kubectl ${OP} -f ${MANIFEST}/ingress.yaml
	@kubectl ${OP} -f ${MANIFEST}/job.yaml

deploy-cp: OP=create
deploy-cp:
	@kubectl ${OP} -f ${MANIFEST}/cronjob.yaml

deploy: cp sed deploy-main deploy-cp

deploy-one-off: OP=create
deploy-one-off: cp sed
	@kubectl ${OP} -f ${MANIFEST}/namespace.yaml
	@kubectl ${OP} -f ${MANIFEST}/rbac.yaml
	#@kubectl ${OP} configmap ${ADMIN}--from-file=conf=${ADMIN_CONF_PATH}

clean-main: OP=delete
clean-main:
	@kubectl -n ${NAMESPACE} ${OP} configmap ${SCRIPTS_CM}
	@kubectl -n ${NAMESPACE} ${OP} configmap ${CONF_CM}
	@kubectl ${OP} -f ${MANIFEST}/configmap.yaml
	@kubectl ${OP} -f ${MANIFEST}/daemonset.yaml
	@kubectl ${OP} -f ${MANIFEST}/service.yaml
	@kubectl ${OP} -f ${MANIFEST}/ingress.yaml
	@kubectl ${OP} -f ${MANIFEST}/job.yaml

clean-cp: OP=delete
clean-cp:
	@kubectl ${OP} -f ${MANIFEST}/cronjob.yaml

clean: clean-main clean-cp

clean-one-off: OP=create
clean-one-off:
	@kubectl ${OP} -f ${MANIFEST}/namespace.yaml
	@kubectl ${OP} -f ${MANIFEST}/rbac.yaml
	#@kubectl ${OP} configmap ${ADMIN}

mkcm: OP=create
mkcm:
	-@kubectl -n ${NAMESPACE} delete configmap $(CM_NAME)
	@kubectl -n ${NAMESPACE} ${OP} configmap $(CM_NAME) --from-file ${CONF}/. --from-file ${SCRIPTS}/.

dump:
	@ansible k8s -m shell -a "rm -rf /data/redis0/*; rm -rf /data/redis1/*"

clear: clean dump

restart: clear all

.PHONY : test
test: build push deploy-db

clean-test: clean-db

cj: export CJ=./test/cron-write
cj:
	@cd ${CJ} && make

clean-cj: export CJ=./test/cron-write
clean-cj:
	@cd ${CJ} && make clean

test-sed:
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name0}} -v ${NAME0}
	@${TOOLS}/sed.sh -m ${MANIFEST} -t {{.name10}} -v ${NAME10}

pod:
	@kubectl -n ${NAMESPACE} get pods

pods: pod
po: pod

logs-init:
	@while true; do kubectl -n ${NAMESPACE} logs `kubectl -n ${NAMESPACE} get pod -l component=${NAME0} -o jsonpath='{.items[0].metadata.name}'` -f 2>/dev/null && break; sleep 1; done

svc:
	@

restart: clean all
