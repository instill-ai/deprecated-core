.DEFAULT_GOAL:=help

#============================================================================

# load environment variables
include .env
export

COMPOSE_FILES := -f docker-compose.yml
ifeq (${OBSERVE_ENABLED}, true)
	COMPOSE_FILES := ${COMPOSE_FILES} -f docker-compose.observe.yml
endif

UNAME_S := $(shell uname -s)

CONTAINER_BUILD_NAME := base-build
CONTAINER_COMPOSE_NAME := base-dind
CONTAINER_COMPOSE_IMAGE_NAME := instill/base-compose
CONTAINER_PLAYWRIGHT_IMAGE_NAME := instill/console-playwright
CONTAINER_BACKEND_INTEGRATION_TEST_NAME := base-backend-integration-test
CONTAINER_CONSOLE_INTEGRATION_TEST_NAME := base-console-integration-test

HELM_NAMESPACE := instill-ai
HELM_RELEASE_NAME := base

#============================================================================

.PHONY: all
all:			## Launch all services with their up-to-date release version
	@EDITION=local-ce docker compose ${COMPOSE_FILES} up -d --quiet-pull
	@EDITION=local-ce docker compose ${COMPOSE_FILES} rm -f

.PHONY: latest
latest:			## Lunch all dependent services with their latest codebase
	@COMPOSE_PROFILES=$(PROFILE) EDITION=local-ce:latest docker compose ${COMPOSE_FILES} -f docker-compose.latest.yml up -d --quiet-pull
	@COMPOSE_PROFILES=$(PROFILE) EDITION=local-ce:latest docker compose ${COMPOSE_FILES} -f docker-compose.latest.yml rm -f

.PHONY: logs
logs:			## Tail all logs with -n 10
	@docker compose logs --follow --tail=10

.PHONY: pull
pull:			## Pull all service images
	@docker compose pull

.PHONY: stop
stop:			## Stop all components
	@docker compose stop

.PHONY: start
start:			## Start all stopped services
	@docker compose start

.PHONY: restart
restart:		## Restart all services
	@docker compose restart

.PHONY: rm
rm:				## Remove all stopped service containers
	@docker compose rm -f

.PHONY: down
down:			## Stop all services and remove all service containers and volumes
	@docker rm -f ${CONTAINER_BUILD_NAME}-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_BUILD_NAME}-release >/dev/null 2>&1
	@docker rm -f ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-release >/dev/null 2>&1
	@docker rm -f ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-release >/dev/null 2>&1
	@docker rm -f ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-helm-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-release >/dev/null 2>&1
	@docker rm -f ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-helm-release >/dev/null 2>&1
	@docker rm -f ${CONTAINER_COMPOSE_NAME}-latest >/dev/null 2>&1
	@docker rm -f ${CONTAINER_COMPOSE_NAME}-release >/dev/null 2>&1
	@docker compose -f docker-compose.yml -f docker-compose.observe.yml down -v
	@if docker compose ls -q | grep -q "instill-model"; then \
		docker run -it --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			--name ${CONTAINER_COMPOSE_NAME} \
			${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
				/bin/bash -c 'cd /instill-ai/model && make down' \
			"; \
	fi
	@if docker compose ls -q | grep -q "instill-vdp"; then \
		docker run -it --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			--name ${CONTAINER_COMPOSE_NAME} \
			${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
				/bin/bash -c 'cd /instill-ai/vdp && make down' \
			"; \
	fi

.PHONY: images
images:			## List all container images
	@docker compose images

.PHONY: ps
ps:				## List all service containers
	@docker compose ps

.PHONY: top
top:			## Display all running service processes
	@docker compose top

.PHONY: doc
doc:						## Run Redoc for OpenAPI spec at http://localhost:3001
	@docker compose up -d redoc_openapi

.PHONY: build-latest
build-latest:				## Build latest images for all Instill Base components
	@docker build --progress plain \
		--build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
		--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
		--build-arg K6_VERSION=${K6_VERSION} \
		--build-arg CACHE_DATE="$(shell date)" \
		--target latest \
		-t ${CONTAINER_COMPOSE_IMAGE_NAME}:latest .
	@docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${BUILD_CONFIG_DIR_PATH}/.env:/instill-ai/base/.env \
		-v ${BUILD_CONFIG_DIR_PATH}/docker-compose.build.yml:/instill-ai/base/docker-compose.build.yml \
		--name ${CONTAINER_BUILD_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			API_GATEWAY_VERSION=latest \
			MGMT_BACKEND_VERSION=latest \
			CONSOLE_VERSION=latest \
			docker compose -f docker-compose.build.yml build --progress plain \
		"

.PHONY: build-release
build-release:				## Build release images for all Instill Base components
	@docker build --progress plain \
		--build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
		--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
		--build-arg K6_VERSION=${K6_VERSION} \
		--build-arg CACHE_DATE="$(shell date)" \
		--build-arg API_GATEWAY_VERSION=${API_GATEWAY_VERSION} \
		--build-arg MGMT_BACKEND_VERSION=${MGMT_BACKEND_VERSION} \
		--build-arg CONSOLE_VERSION=${CONSOLE_VERSION} \
		--target release \
		-t ${CONTAINER_COMPOSE_IMAGE_NAME}:release .
	@docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${BUILD_CONFIG_DIR_PATH}/.env:/instill-ai/base/.env \
		-v ${BUILD_CONFIG_DIR_PATH}/docker-compose.build.yml:/instill-ai/base/docker-compose.build.yml \
		--name ${CONTAINER_BUILD_NAME}-release \
		${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/bash -c " \
			API_GATEWAY_VERSION=${API_GATEWAY_VERSION} \
			MGMT_BACKEND_VERSION=${MGMT_BACKEND_VERSION} \
			CONSOLE_VERSION=${CONSOLE_VERSION} \
			docker compose -f docker-compose.build.yml build --progress plain \
		"

.PHONY: integration-test-latest
integration-test-latest:			## Run integration test on the latest Instill Base
	@make build-latest
	@COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull
	@COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml rm -f
	@docker run -it --rm \
		--network instill-network \
		--name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=${API_GATEWAY_BASE_HOST} API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
	@make down

.PHONY: integration-test-release
integration-test-release:			## Run integration test on the release Instill Base
	@make build-release
	@EDITION=local-ce:test docker compose up -d --quiet-pull
	@EDITION=local-ce:test docker compose rm -f
	@docker run -it --rm \
		--network instill-network \
		--name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-release \
		${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=${API_GATEWAY_BASE_HOST} API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
	@make down

.PHONY: helm-integration-test-latest
helm-integration-test-latest:                       ## Run integration test on the Helm latest for Instill Base
	@make build-latest
	@helm install ${HELM_RELEASE_NAME} charts/base --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGatewayBase.image.tag=latest \
		--set mgmtBackend.image.tag=latest \
		--set console.image.tag=latest \
		--set tags.observability=false
	@kubectl rollout status deployment base-api-gateway-base --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_BASE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_BASE_POD_NAME} ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_BASE_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run -it --rm -p ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-latest ${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=host.docker.internal API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
else ifeq ($(UNAME_S),Linux)
	@docker run -it --rm --network host --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-latest ${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=localhost API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
endif
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

.PHONY: helm-integration-test-release
helm-integration-test-release:                       ## Run integration test on the Helm release for Instill Base
	@make build-release
	@helm install ${HELM_RELEASE_NAME} charts/base --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGatewayBase.image.tag=${API_GATEWAY_VERSION} \
		--set mgmtBackend.image.tag=${MGMT_BACKEND_VERSION} \
		--set console.image.tag=${CONSOLE_VERSION} \
		--set tags.observability=false
	@kubectl rollout status deployment base-api-gateway-base --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_BASE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_BASE_POD_NAME} ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_BASE_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run -it --rm -p ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-release ${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=host.docker.internal API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
else ifeq ($(UNAME_S),Linux)
	@docker run -it --rm --network host --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-release ${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/bash -c " \
			/bin/bash -c 'cd mgmt-backend && make integration-test API_GATEWAY_BASE_HOST=localhost API_GATEWAY_BASE_PORT=${API_GATEWAY_BASE_PORT}' \
		"
endif
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

# ==================================================================
# ==================== Console Integration Test ====================
# ==================================================================

.PHONY: console-integration-test-latest
console-integration-test-latest:			## Run console integration test on the latest Instill Base
	@make build-latest
	@COMPOSE_PROFILES=all EDITION=local-ce:test CONSOLE_PUBLIC_API_GATEWAY_BASE_HOST=api-gateway-base CONSOLE_PUBLIC_API_GATEWAY_VDP_HOST=api-gateway-vdp CONSOLE_PUBLIC_API_GATEWAY_MODEL_HOST=api-gateway-model docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull
	@COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml rm -f
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/bash -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/bash -c 'cd /instill-ai/vdp && COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/bash -c 'cd /instill-ai/vdp && COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml rm -f' && \
			/bin/bash -c 'rm -r $${TMP_CONFIG_DIR}/*' \
		" && rm -r $${TMP_CONFIG_DIR}
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/bash -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/bash -c 'cd /instill-ai/model && COMPOSE_PROFILES=all EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/bash -c 'cd /instill-ai/model && COMPOSE_PROFILES=all EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose -f docker-compose.yml -f docker-compose.latest.yml rm -f' && \
			/bin/bash -c 'rm -r $${TMP_CONFIG_DIR}/*' \
		" && rm -r $${TMP_CONFIG_DIR}
	@docker run -it --rm \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_CONSOLE_EDITION=local-ce:test \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://${CONSOLE_HOST}:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://${API_GATEWAY_BASE_HOST}:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://${API_GATEWAY_BASE_HOST}:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://${API_GATEWAY_VDP_HOST}:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://${API_GATEWAY_VDP_HOST}:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://${API_GATEWAY_MODEL_HOST}:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://${API_GATEWAY_MODEL_HOST}:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		--network instill-network \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:latest
	@make down

.PHONY: console-integration-test-release
console-integration-test-release:			## Run console integration test on the release Instill Base
	@make build-release
	@EDITION=local-ce:test CONSOLE_PUBLIC_API_GATEWAY_BASE_HOST=api-gateway-base CONSOLE_PUBLIC_API_GATEWAY_VDP_HOST=api-gateway-vdp CONSOLE_PUBLIC_API_GATEWAY_MODEL_HOST=api-gateway-model docker compose up -d --quiet-pull
	@EDITION=local-ce:test docker compose rm -f
	@docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			/bin/bash -c 'cd /instill-ai/vdp && EDITION=local-ce:test docker compose up -d --quiet-pull' \
			/bin/bash -c 'cd /instill-ai/vdp && EDITION=local-ce:test docker compose rm -f' \
		"
	@docker run -it --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			/bin/bash -c 'cd /instill-ai/model && EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose up -d --quiet-pull' \
			/bin/bash -c 'cd /instill-ai/model && EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose rm -f' \
		"
	@docker run -it --rm \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_CONSOLE_EDITION=local-ce:test \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://${CONSOLE_HOST}:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://${API_GATEWAY_BASE_HOST}:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://${API_GATEWAY_BASE_HOST}:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://${API_GATEWAY_VDP_HOST}:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://${API_GATEWAY_VDP_HOST}:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://${API_GATEWAY_MODEL_HOST}:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://${API_GATEWAY_MODEL_HOST}:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		--network instill-network \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-release \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:${CONSOLE_VERSION}
	@make down

.PHONY: console-helm-integration-test-latest
console-helm-integration-test-latest:                       ## Run console integration test on the Helm latest for Instill Base
	@make build-latest
	@helm install ${HELM_RELEASE_NAME} charts/base --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGatewayBase.image.tag=latest \
		--set mgmtBackend.image.tag=latest \
		--set console.image.tag=latest \
		--set apiGatewayBaseURL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		--set console.serverApiGatewayBaseURL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		--set apiGatewayVDPURL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		--set console.serverApiGatewayVDPURL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		--set apiGatewayModelURL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		--set console.serverApiGatewayModelURL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		--set consoleURL=http://host.docker.internal:${CONSOLE_PORT}
	@kubectl rollout status deployment base-api-gateway-base --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_BASE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_BASE_POD_NAME} ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} > /dev/null 2>&1 &
	@export CONSOLE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=console,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${CONSOLE_POD_NAME} ${CONSOLE_PORT}:${CONSOLE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_BASE_PORT} > /dev/null 2>&1; do sleep 1; done
	@while ! nc -vz localhost ${CONSOLE_PORT} > /dev/null 2>&1; do sleep 1; done
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run -it --rm \
		-v ${HOME}/.kube/config:/instill-ai/kubeconfig \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/bash -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/bash -c 'cd /instill-ai/vdp && \
				helm --kubeconfig /instill-ai/kubeconfig install vdp charts/vdp --namespace ${HELM_NAMESPACE} --create-namespace \
					--set edition=k8s-ce:test \
					--set apiGatewayVDP.image.tag=latest \
					--set pipelineBackend.image.tag=latest \
					--set connectorBackend.image.tag=latest \
					--set controllerVDP.image.tag=latest' \
			/bin/bash -c 'rm -r $${TMP_CONFIG_DIR}/*' \
		" && rm -r $${TMP_CONFIG_DIR}
	@kubectl rollout status deployment vdp-api-gateway-vdp --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_VDP_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-vdp,app.kubernetes.io/instance=vdp" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_VDP_POD_NAME} ${API_GATEWAY_VDP_PORT}:${API_GATEWAY_VDP_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_VDP_PORT} > /dev/null 2>&1; do sleep 1; done
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run -it --rm \
		-v ${HOME}/.kube/config:/instill-ai/kubeconfig \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/bash -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/bash -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/bash -c 'cd /instill-ai/model && \
				helm --kubeconfig /instill-ai/kubeconfig install model charts/model --namespace ${HELM_NAMESPACE} --create-namespace \
						--set edition=k8s-ce:test \
						--set apiGatewayModel.image.tag=latest \
						--set modelBackend.image.tag=latest \
						--set controllerModel.image.tag=latest \
						--set itMode.enabled=true' \
			/bin/bash -c 'rm -r $${TMP_CONFIG_DIR}/*' \
		" && rm -r $${TMP_CONFIG_DIR}
	@kubectl rollout status deployment model-api-gateway-model --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_MODEL_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-model,app.kubernetes.io/instance=model" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_MODEL_POD_NAME} ${API_GATEWAY_MODEL_PORT}:${API_GATEWAY_MODEL_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_MODEL_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run -it --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://host.docker.internal:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:latest
else ifeq ($(UNAME_S),Linux)
	@docker run -it --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://localhost:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://localhost:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://localhost:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://localhost:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://localhost:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://localhost:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://localhost:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--network host \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:latest
endif
	@helm uninstall model --namespace ${HELM_NAMESPACE}
	@helm uninstall vdp --namespace ${HELM_NAMESPACE}
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

.PHONY: console-helm-integration-test-release
console-helm-integration-test-release:                       ## Run console integration test on the Helm release for Instill Base
	@make build-release
	@helm install ${HELM_RELEASE_NAME} charts/base --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGatewayBase.image.tag=${API_GATEWAY_VERSION} \
		--set mgmtBackend.image.tag=${MGMT_BACKEND_VERSION} \
		--set console.image.tag=${CONSOLE_VERSION} \
		--set apiGatewayBaseURL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		--set console.serverApiGatewayBaseURL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		--set apiGatewayVDPURL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		--set console.serverApiGatewayVDPURL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		--set apiGatewayModelURL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		--set console.serverApiGatewayModelURL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		--set consoleURL=http://host.docker.internal:${CONSOLE_PORT}
	@kubectl rollout status deployment base-api-gateway-base --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_BASE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_BASE_POD_NAME} ${API_GATEWAY_BASE_PORT}:${API_GATEWAY_BASE_PORT} > /dev/null 2>&1 &
	@export CONSOLE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=console,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${CONSOLE_POD_NAME} ${CONSOLE_PORT}:${CONSOLE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_BASE_PORT} > /dev/null 2>&1; do sleep 1; done
	@while ! nc -vz localhost ${CONSOLE_PORT} > /dev/null 2>&1; do sleep 1; done
	@helm install vdp charts/vdp --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGatewayVDP.image.tag=${API_GATEWAY_VERSION} \
		--set pipelineBackend.image.tag={PIPELINE_BACKEND_VERSION} \
		--set connector.image.tag=latest \
		--set controllerVDP.image.tag=latest \
	@kubectl rollout status deployment vdp-api-gateway-vdp --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_VDP_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=vdp" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_VDP_POD_NAME} ${API_GATEWAY_VDP_PORT}:${API_GATEWAY_VDP_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_VDP_PORT} > /dev/null 2>&1; do sleep 1; done
	@helm install model charts/vdp --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGatewayModel.image.tag=latest \
		--set modelBackend.image.tag=latest \
		--set controllerModel.image.tag=latest \
		--set itMode.enabled=true \
	@kubectl rollout status deployment model-api-gateway-model --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_MODEL_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway-base,app.kubernetes.io/instance=model" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_MODEL_POD_NAME} ${API_GATEWAY_MODEL_PORT}:${API_GATEWAY_MODEL_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_MODEL_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run -it --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://host.docker.internal:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:${CONSOLE_VERSION}
else ifeq ($(UNAME_S),Linux)
	@docker run -it --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://localhost:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_BASE_API_GATEWAY_URL=http://localhost:${API_GATEWAY_BASE_PORT} \
		-e NEXT_SERVER_BASE_API_GATEWAY_URL=http://localhost:${API_GATEWAY_BASE_PORT} \
		-e NEXT_PUBLIC_VDP_API_GATEWAY_URL=http://localhost:${API_GATEWAY_VDP_PORT} \
		-e NEXT_SERVER_VDP_API_GATEWAY_URL=http://localhost:${API_GATEWAY_VDP_PORT} \
		-e NEXT_PUBLIC_MODEL_API_GATEWAY_URL=http://localhost:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_SERVER_MODEL_API_GATEWAY_URL=http://localhost:${API_GATEWAY_MODEL_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--network host \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:${CONSOLE_VERSION}
endif
	@helm uninstall model --namespace ${HELM_NAMESPACE}
	@helm uninstall vdp --namespace ${HELM_NAMESPACE}
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

.PHONY: help
help:       	## Show this help
	@echo "\nMake Application with Docker Compose"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m (default: help)\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
