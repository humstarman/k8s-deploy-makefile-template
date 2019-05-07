include Makefile.inc

define sed
	@find ${MANIFEST} -type f -name "*.yaml" | xargs sed -i s?"$(1)"?"$(2)"?g
endef

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
	$(call sed, {{.name}}, ${NAME})
	$(call sed, {{.name0}}, ${NAME0})
	$(call sed, {{.name1}}, ${NAME1})
	$(call sed, {{.name2}}, ${NAME2})
	$(call sed, {{.name3}}, ${NAME3})
	$(call sed, {{.name4}}, ${NAME4})
	$(call sed, {{.name5}}, ${NAME5})
	$(call sed, {{.name6}}, ${NAME6})
	$(call sed, {{.name7}}, ${NAME7})
	$(call sed, {{.name8}}, ${NAME8})
	$(call sed, {{.name9}}, ${NAME9})
	$(call sed, {{.name10}}, ${NAME10})
	$(call sed, {{.namespace}}, ${NAMESPACE})
	$(call sed, {{.port}}, ${PORT})
	$(call sed, {{.url}}, ${URL})
	$(call sed, {{.image}}, ${IMAGE})
	$(call sed, {{.image0}}, ${IMAGE0})
	$(call sed, {{.image1}}, ${IMAGE1})
	$(call sed, {{.image2}}, ${IMAGE2})
	$(call sed, {{.image3}}, ${IMAGE3})
	$(call sed, {{.image4}}, ${IMAGE4})
	$(call sed, {{.image5}}, ${IMAGE5})
	$(call sed, {{.image6}}, ${IMAGE6})
	$(call sed, {{.image7}}, ${IMAGE7})
	$(call sed, {{.image8}}, ${IMAGE8})
	$(call sed, {{.image10}}, ${IMAGE10})
	$(call sed, {{.image.pull.policy}}, ${IMAGE_PULL_POLICY})
	$(call sed, {{.image.pull.policy2}}, ${IMAGE_PULL_POLICY2})
	$(call sed, {{.labels.key}}, ${LABELS_KEY})
	$(call sed, {{.labels.value}}, ${LABELS_VALUE})
	$(call sed, {{.scripts.cm}}, ${SCRIPTS_CM})
	$(call sed, {{.conf.cm}}, ${CONF_CM})
	$(call sed, {{.env.cm}}, ${ENV_CM})
	$(call sed, {{.proxy}}, ${PROXY})
	$(call sed, {{.discovery.name}}, ${DISCOVERY_NAME})
	$(call sed, {{.discovery.namespace}}, ${DISCOVERY_NAMESPACE})
	$(call sed, {{.object}}, ${OBJECT})
	$(call sed, {{.service.account}}, ${SERVICE_ACCOUNT})
	$(call sed, {{.svc1}}, ${SVC1})
	$(call sed, {{.svc2}}, ${SVC2})
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
	@$(call sed, {{.name0}} ${NAME0}
	@$(call sed, {{.name10}} ${NAME10}

pod:
	@kubectl -n ${NAMESPACE} get pods

pods: pod
po: pod

logs-init:
	@while true; do kubectl -n ${NAMESPACE} logs `kubectl -n ${NAMESPACE} get pod -l component=${NAME0} -o jsonpath='{.items[0].metadata.name}'` -f 2>/dev/null && break; sleep 1; done

svc:
	@

restart: clean all
