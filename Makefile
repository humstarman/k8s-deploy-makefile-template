include Makefile.inc

define replace
	@find ${MANIFEST} -type f -name "*.yaml" | xargs sed -i s?"$(1)"?"$(2)"?g
endef

all: cp sed 
#all: build push deploy logs-init

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
	$(call replace, {{.name}}, ${NAME})
	$(call replace, {{.name0}}, ${NAME0})
	$(call replace, {{.name1}}, ${NAME1})
	$(call replace, {{.name2}}, ${NAME2})
	$(call replace, {{.name3}}, ${NAME3})
	$(call replace, {{.name4}}, ${NAME4})
	$(call replace, {{.name5}}, ${NAME5})
	$(call replace, {{.name6}}, ${NAME6})
	$(call replace, {{.name7}}, ${NAME7})
	$(call replace, {{.name8}}, ${NAME8})
	$(call replace, {{.name9}}, ${NAME9})
	$(call replace, {{.name10}}, ${NAME10})
	$(call replace, {{.namespace}}, ${NAMESPACE})
	$(call replace, {{.port}}, ${PORT})
	$(call replace, {{.url}}, ${URL})
	$(call replace, {{.image}}, ${IMAGE})
	$(call replace, {{.image0}}, ${IMAGE0})
	$(call replace, {{.image1}}, ${IMAGE1})
	$(call replace, {{.image2}}, ${IMAGE2})
	$(call replace, {{.image3}}, ${IMAGE3})
	$(call replace, {{.image4}}, ${IMAGE4})
	$(call replace, {{.image5}}, ${IMAGE5})
	$(call replace, {{.image6}}, ${IMAGE6})
	$(call replace, {{.image7}}, ${IMAGE7})
	$(call replace, {{.image8}}, ${IMAGE8})
	$(call replace, {{.image10}}, ${IMAGE10})
	$(call replace, {{.image.pull.policy}}, ${IMAGE_PULL_POLICY})
	$(call replace, {{.image.pull.policy2}}, ${IMAGE_PULL_POLICY2})
	$(call replace, {{.labels.key}}, ${LABELS_KEY})
	$(call replace, {{.labels.value}}, ${LABELS_VALUE})
	$(call replace, {{.scripts.cm}}, ${SCRIPTS_CM})
	$(call replace, {{.conf.cm}}, ${CONF_CM})
	$(call replace, {{.env.cm}}, ${ENV_CM})
	$(call replace, {{.proxy}}, ${PROXY})
	$(call replace, {{.discovery.name}}, ${DISCOVERY_NAME})
	$(call replace, {{.discovery.namespace}}, ${DISCOVERY_NAMESPACE})
	$(call replace, {{.object}}, ${OBJECT})
	$(call replace, {{.service.account}}, ${SERVICE_ACCOUNT})
	$(call replace, {{.svc1}}, ${SVC1})
	$(call replace, {{.svc2}}, ${SVC2})
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
	@$(call replace, {{.name0}} ${NAME0}
	@$(call replace, {{.name10}} ${NAME10}

pod:
	@kubectl -n ${NAMESPACE} get pods

pods: pod
po: pod

logs-init:
	@while true; do kubectl -n ${NAMESPACE} logs `kubectl -n ${NAMESPACE} get pod -l component=${NAME0} -o jsonpath='{.items[0].metadata.name}'` -f 2>/dev/null && break; sleep 1; done

svc:
	@

restart: clean all
