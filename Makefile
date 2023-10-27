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

CONTAINER_BUILD_NAME := core-build
CONTAINER_COMPOSE_NAME := core-dind
CONTAINER_COMPOSE_IMAGE_NAME := instill/core-compose
CONTAINER_PLAYWRIGHT_IMAGE_NAME := instill/console-playwright
CONTAINER_BACKEND_INTEGRATION_TEST_NAME := core-backend-integration-test
CONTAINER_CONSOLE_INTEGRATION_TEST_NAME := core-console-integration-test

HELM_NAMESPACE := instill-ai
HELM_RELEASE_NAME := core

#============================================================================

.PHONY: all
all:			## Launch all services with their up-to-date release version
	@if [ "${BUILD}" = "true" ]; then make build-release; fi
	@if [ ! -f "$$(echo ${SYSTEM_CONFIG_PATH}/user_uid)" ]; then \
		mkdir -p ${SYSTEM_CONFIG_PATH} && \
		docker run --rm --name uuidgen ${CONTAINER_COMPOSE_IMAGE_NAME}:release uuidgen > ${SYSTEM_CONFIG_PATH}/user_uid; \
	fi
	@EDITION=$${EDITION:=local-ce} DEFAULT_USER_UID=$$(cat ${SYSTEM_CONFIG_PATH}/user_uid) docker compose ${COMPOSE_FILES} up -d --quiet-pull
	@if [ ! "$$(docker image inspect ${CONTAINER_COMPOSE_IMAGE_NAME}:release --format='yes' 2> /dev/null)" = "yes" ]; then \
		docker build --progress plain \
			--build-arg ALPINE_VERSION=${ALPINE_VERSION} \
			--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
			--build-arg K6_VERSION=${K6_VERSION} \
			--build-arg CACHE_DATE="$(shell date)" \
			--build-arg INSTILL_VDP_VERSION=${INSTILL_VDP_VERSION} \
			--build-arg INSTILL_MODEL_VERSION=${INSTILL_MODEL_VERSION} \
			--build-arg API_GATEWAY_VERSION=${API_GATEWAY_VERSION} \
			--build-arg MGMT_BACKEND_VERSION=${MGMT_BACKEND_VERSION} \
			--build-arg CONSOLE_VERSION=${CONSOLE_VERSION} \
			--target release \
			-t ${CONTAINER_COMPOSE_IMAGE_NAME}:release .; \
	fi
	@if [ "${PROJECT}" = "all" ] || [ "${PROJECT}" = "vdp" ]; then \
		export TMP_CONFIG_DIR=$(shell mktemp -d) && \
		export SYSTEM_CONFIG_PATH=$(shell eval echo ${SYSTEM_CONFIG_PATH}) && \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
			-v $${SYSTEM_CONFIG_PATH}:$${SYSTEM_CONFIG_PATH} \
			-e BUILD=${BUILD} \
			-e BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} \
			--name ${CONTAINER_COMPOSE_NAME}-release \
			${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
				cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
				cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
				/bin/sh -c 'cd /instill-ai/vdp && make all BUILD=${BUILD} EDITION=$${EDITION:=local-ce} BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} SYSTEM_CONFIG_PATH=$${SYSTEM_CONFIG_PATH}' && \
				/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}; \
	fi
	@if [ "${PROJECT}" = "all" ] || [ "${PROJECT}" = "model" ]; then \
		export TMP_CONFIG_DIR=$(shell mktemp -d) && \
		export SYSTEM_CONFIG_PATH=$(shell eval echo ${SYSTEM_CONFIG_PATH}) && \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
			-v $${SYSTEM_CONFIG_PATH}:$${SYSTEM_CONFIG_PATH} \
			-e BUILD=${BUILD} \
			-e BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} \
			--name ${CONTAINER_COMPOSE_NAME}-release \
			${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
				cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
				cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
				/bin/sh -c 'cd /instill-ai/model && make all BUILD=${BUILD} EDITION=$${EDITION:=local-ce} BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} SYSTEM_CONFIG_PATH=$${SYSTEM_CONFIG_PATH}' && \
				/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}; \
	fi

.PHONY: latest
latest:			## Lunch all dependent services with their latest codebase
	@make build-latest
	@if [ ! -f "$$(echo ${SYSTEM_CONFIG_PATH}/user_uid)" ]; then \
		mkdir -p ${SYSTEM_CONFIG_PATH} && \
		docker run --rm --name uuidgen ${CONTAINER_COMPOSE_IMAGE_NAME}:latest uuidgen > ${SYSTEM_CONFIG_PATH}/user_uid; \
	fi
	@COMPOSE_PROFILES=${PROFILE} EDITION=$${EDITION:=local-ce:latest} DEFAULT_USER_UID=$$(cat ${SYSTEM_CONFIG_PATH}/user_uid) docker compose ${COMPOSE_FILES} -f docker-compose.latest.yml up -d --quiet-pull
	@if [ "${PROJECT}" = "all" ] || [ "${PROJECT}" = "vdp" ]; then \
		export TMP_CONFIG_DIR=$(shell mktemp -d) && \
		export SYSTEM_CONFIG_PATH=$(shell eval echo ${SYSTEM_CONFIG_PATH}) && \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
			-v $${SYSTEM_CONFIG_PATH}:$${SYSTEM_CONFIG_PATH} \
			-e BUILD=${BUILD} \
			-e PROFILE=${PROFILE} \
			-e BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} \
			--name ${CONTAINER_COMPOSE_NAME}-latest \
			${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
				cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
				cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
				/bin/sh -c 'cd /instill-ai/vdp && make latest BUILD=${BUILD} PROFILE=$${PROFILE} EDITION=$${EDITION:=local-ce:latest} BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} SYSTEM_CONFIG_PATH=$${SYSTEM_CONFIG_PATH}' && \
				/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}; \
	fi
	@if [ "${PROJECT}" = "all" ] || [ "${PROJECT}" = "model" ]; then \
		export TMP_CONFIG_DIR=$(shell mktemp -d) && \
		export SYSTEM_CONFIG_PATH=$(shell eval echo ${SYSTEM_CONFIG_PATH}) && \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
			-v $${SYSTEM_CONFIG_PATH}:$${SYSTEM_CONFIG_PATH} \
			-e BUILD=${BUILD} \
			-e PROFILE=${PROFILE} \
			-e BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} \
			--name ${CONTAINER_COMPOSE_NAME}-latest \
			${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
				cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
				cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
				/bin/sh -c 'cd /instill-ai/model && make latest BUILD=${BUILD} PROFILE=$${PROFILE} EDITION=$${EDITION:=local-ce:latest} BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR} SYSTEM_CONFIG_PATH=$${SYSTEM_CONFIG_PATH}' && \
				/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}; \
	fi

.PHONY: logs
logs:			## Tail all logs with -n 10
	@EDITION= DEFAULT_USER_UID= docker compose logs --follow --tail=10

.PHONY: pull
pull:			## Pull all service images
	@EDITION= DEFAULT_USER_UID= docker compose pull

.PHONY: stop
stop:			## Stop all components
	@EDITION= DEFAULT_USER_UID= docker compose stop

.PHONY: start
start:			## Start all stopped components
	@EDITION= DEFAULT_USER_UID= docker compose start

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
	@if [ "$$(docker image inspect ${CONTAINER_COMPOSE_IMAGE_NAME}:latest --format='yes' 2> /dev/null)" = "yes" ]; then \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			--name ${CONTAINER_COMPOSE_NAME} \
			${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
				/bin/sh -c 'if [ \"$$( docker container inspect -f '{{.State.Status}}' vdp-dind 2>/dev/null)\" != \"running\" ]; then cd /instill-ai/vdp && make down; fi' && \
				/bin/sh -c 'if [ \"$$( docker container inspect -f '{{.State.Status}}' model-dind 2>/dev/null)\" != \"running\" ]; then cd /instill-ai/model && make down; fi' \
			"; \
	elif [ "$$(docker image inspect ${CONTAINER_COMPOSE_IMAGE_NAME}:release --format='yes' 2> /dev/null)" = "yes" ]; then \
		docker run --rm \
			-v /var/run/docker.sock:/var/run/docker.sock \
			--name ${CONTAINER_COMPOSE_NAME} \
			${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
				/bin/sh -c 'if [ \"$$( docker container inspect -f '{{.State.Status}}' vdp-dind 2>/dev/null)\" != \"running\" ]; then cd /instill-ai/vdp && make down; fi' && \
				/bin/sh -c 'if [ \"$$( docker container inspect -f '{{.State.Status}}' model-dind 2>/dev/null)\" != \"running\" ]; then cd /instill-ai/model && make down; fi' \
			"; \
	fi
	@EDITION= DEFAULT_USER_UID= docker compose -f docker-compose.yml -f docker-compose.observe.yml down -v

.PHONY: images
images:			## List all container images
	@docker compose images

.PHONY: ps
ps:				## List all service containers
	@EDITION= DEFAULT_USER_UID= docker compose ps

.PHONY: top
top:			## Display all running service processes
	@EDITION= DEFAULT_USER_UID= docker compose top

.PHONY: doc
doc:						## Run Redoc for OpenAPI spec at http://localhost:3001
	@EDITION= DEFAULT_USER_UID= docker compose up -d redoc_openapi

.PHONY: build-latest
build-latest:				## Build latest images for all Instill Core components
	@docker build --progress plain \
		--build-arg ALPINE_VERSION=${ALPINE_VERSION} \
		--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
		--build-arg K6_VERSION=${K6_VERSION} \
		--build-arg CACHE_DATE="$(shell date)" \
		--target latest \
		-t ${CONTAINER_COMPOSE_IMAGE_NAME}:latest .
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${BUILD_CONFIG_DIR_PATH}/.env:/instill-ai/core/.env \
		-v ${BUILD_CONFIG_DIR_PATH}/docker-compose.build.yml:/instill-ai/core/docker-compose.build.yml \
		--name ${CONTAINER_BUILD_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			API_GATEWAY_VERSION=latest \
			MGMT_BACKEND_VERSION=latest \
			CONSOLE_VERSION=latest \
			docker compose -f docker-compose.build.yml build --progress plain \
		"

.PHONY: build-release
build-release:				## Build release images for all Instill Core components
	@docker build --progress plain \
		--build-arg ALPINE_VERSION=${ALPINE_VERSION} \
		--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
		--build-arg K6_VERSION=${K6_VERSION} \
		--build-arg CACHE_DATE="$(shell date)" \
		--build-arg INSTILL_VDP_VERSION=${INSTILL_VDP_VERSION} \
		--build-arg INSTILL_MODEL_VERSION=${INSTILL_MODEL_VERSION} \
		--build-arg API_GATEWAY_VERSION=${API_GATEWAY_VERSION} \
		--build-arg MGMT_BACKEND_VERSION=${MGMT_BACKEND_VERSION} \
		--build-arg CONSOLE_VERSION=${CONSOLE_VERSION} \
		--target release \
		-t ${CONTAINER_COMPOSE_IMAGE_NAME}:release .
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${BUILD_CONFIG_DIR_PATH}/.env:/instill-ai/core/.env \
		-v ${BUILD_CONFIG_DIR_PATH}/docker-compose.build.yml:/instill-ai/core/docker-compose.build.yml \
		--name ${CONTAINER_BUILD_NAME}-release \
		${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
			API_GATEWAY_VERSION=${API_GATEWAY_VERSION} \
			MGMT_BACKEND_VERSION=${MGMT_BACKEND_VERSION} \
			CONSOLE_VERSION=${CONSOLE_VERSION} \
			docker compose -f docker-compose.build.yml build --progress plain \
		"

.PHONY: integration-test-latest
integration-test-latest:			## Run integration test on the latest Instill Core
	@make latest BUILD=true PROJECT=core EDITION=local-ce:test
	@docker run --rm \
		--network instill-network \
		--name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=${API_GATEWAY_HOST}:${API_GATEWAY_PORT}' \
		"
	@make down

.PHONY: integration-test-release
integration-test-release:			## Run integration test on the release Instill Core
	@make all BUILD=true PROJECT=core EDITION=local-ce:test
	@docker run --rm \
		--network instill-network \
		--name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-release \
		${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=${API_GATEWAY_HOST}:${API_GATEWAY_PORT}' \
		"
	@make down

.PHONY: helm-integration-test-latest
helm-integration-test-latest:                       ## Run integration test on the Helm latest for Instill Core
	@make build-latest
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGateway.image.tag=latest \
		--set mgmtBackend.image.tag=latest \
		--set console.image.tag=latest \
		--set tags.observability=false
	@kubectl rollout status deployment core-api-gateway --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_POD_NAME} ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run --rm -p ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-latest ${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=host.docker.internal:${API_GATEWAY_PORT}' \
		"
else ifeq ($(UNAME_S),Linux)
	@docker run --rm --network host --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-latest ${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=localhost:${API_GATEWAY_PORT}' \
		"
endif
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

.PHONY: helm-integration-test-release
helm-integration-test-release:                       ## Run integration test on the Helm release for Instill Core
	@make build-release
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set apiGateway.image.tag=${API_GATEWAY_VERSION} \
		--set mgmtBackend.image.tag=${MGMT_BACKEND_VERSION} \
		--set console.image.tag=${CONSOLE_VERSION} \
		--set tags.observability=false
	@kubectl rollout status deployment core-api-gateway --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_POD_NAME} ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_PORT} > /dev/null 2>&1; do sleep 1; done
ifeq ($(UNAME_S),Darwin)
	@docker run --rm -p ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-release ${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=host.docker.internal:${API_GATEWAY_PORT}' \
		"
else ifeq ($(UNAME_S),Linux)
	@docker run --rm --network host --name ${CONTAINER_BACKEND_INTEGRATION_TEST_NAME}-helm-release ${CONTAINER_COMPOSE_IMAGE_NAME}:release /bin/sh -c " \
			/bin/sh -c 'cd mgmt-backend && make integration-test API_GATEWAY_URL=localhost:${API_GATEWAY_PORT}' \
		"
endif
	@helm uninstall ${HELM_RELEASE_NAME} --namespace ${HELM_NAMESPACE}
	@kubectl delete namespace instill-ai
	@pkill -f "port-forward"
	@make down

# ========================================================================================
# ==================== Console Integration Test (placeholder for now) ====================
# ========================================================================================

.PHONY: console-integration-test-latest
console-integration-test-latest:			## Run console integration test on the latest Instill Core
	@make latest PROJECT=core EDITION=local-ce:test CONSOLE_PUBLIC_API_GATEWAY_HOST=api-gateway
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/vdp && COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/model && COMPOSE_PROFILES=all EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@docker run --rm \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_CONSOLE_EDITION=local-ce:test \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://${CONSOLE_HOST}:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://${API_GATEWAY_HOST}:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://${API_GATEWAY_HOST}:${API_GATEWAY_PORT} \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		--network instill-network \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:latest
	@make down

.PHONY: console-integration-test-release
console-integration-test-release:			## Run console integration test on the release Instill Core
	@make all PROJECT=core EDITION=local-ce:test CONSOLE_PUBLIC_API_GATEWAY_HOST=api-gateway
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/vdp && COMPOSE_PROFILES=all EDITION=local-ce:test docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		--name ${CONTAINER_COMPOSE_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/model && COMPOSE_PROFILES=all EDITION=local-ce:test ITMODE_ENABLED=true TRITON_CONDA_ENV_PLATFORM=cpu docker compose -f docker-compose.yml -f docker-compose.latest.yml up -d --quiet-pull' && \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@docker run --rm \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_CONSOLE_EDITION=local-ce:test \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://${CONSOLE_HOST}:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://${API_GATEWAY_HOST}:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://${API_GATEWAY_HOST}:${API_GATEWAY_PORT} \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		--network instill-network \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-release \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:${CONSOLE_VERSION}
	@make down

.PHONY: console-helm-integration-test-latest
console-helm-integration-test-latest:                       ## Run console integration test on the Helm latest for Instill Core
	@make build-latest
ifeq ($(UNAME_S),Darwin)
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGateway.image.tag=latest \
		--set mgmtBackend.image.tag=latest \
		--set console.image.tag=latest \
		--set apiGatewayURL=http://host.docker.internal:${API_GATEWAY_PORT} \
		--set console.serverApiGatewayURL=http://host.docker.internal:${API_GATEWAY_PORT} \
		--set consoleURL=http://host.docker.internal:${CONSOLE_PORT}
else ifeq ($(UNAME_S),Linux)
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGateway.image.tag=latest \
		--set mgmtBackend.image.tag=latest \
		--set console.image.tag=latest \
		--set apiGatewayURL=http://localhost:${API_GATEWAY_PORT} \
		--set console.serverApiGatewayURL=http://localhost:${API_GATEWAY_PORT} \
		--set consoleURL=http://localhost:${CONSOLE_PORT}
endif
	@kubectl rollout status deployment core-api-gateway --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_POD_NAME} ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} > /dev/null 2>&1 &
	@export CONSOLE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=console,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${CONSOLE_POD_NAME} ${CONSOLE_PORT}:${CONSOLE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_PORT} > /dev/null 2>&1; do sleep 1; done
	@while ! nc -vz localhost ${CONSOLE_PORT} > /dev/null 2>&1; do sleep 1; done
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v ${HOME}/.kube/config:/root/.kube/config \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		${DOCKER_HELM_IT_EXTRA_PARAMS} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/vdp && \
				helm install vdp charts/vdp --namespace ${HELM_NAMESPACE} --create-namespace \
					--set edition=k8s-ce:test \
					--set pipelineBackend.image.tag=latest \
					--set connectorBackend.image.tag=latest \
					--set connectorBackend.excludelocalconnector=false \
					--set controllerVDP.image.tag=latest' \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v ${HOME}/.kube/config:/root/.kube/config \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		${DOCKER_HELM_IT_EXTRA_PARAMS} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/model && \
				helm install model charts/model --namespace ${HELM_NAMESPACE} --create-namespace \
						--set edition=k8s-ce:test \
						--set modelBackend.image.tag=latest \
						--set controllerModel.image.tag=latest \
						--set itMode.enabled=true' \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
ifeq ($(UNAME_S),Darwin)
	@docker run --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://host.docker.internal:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:latest
else ifeq ($(UNAME_S),Linux)
	@docker run --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://localhost:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://localhost:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://localhost:${API_GATEWAY_PORT} \
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
console-helm-integration-test-release:                       ## Run console integration test on the Helm release for Instill Core
	@make build-release
ifeq ($(UNAME_S),Darwin)
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGateway.image.tag=${API_GATEWAY_VERSION} \
		--set mgmtBackend.image.tag=${MGMT_BACKEND_VERSION} \
		--set console.image.tag=${CONSOLE_VERSION} \
		--set apiGatewayURL=http://host.docker.internal:${API_GATEWAY_PORT} \
		--set console.serverApiGatewayURL=http://host.docker.internal:${API_GATEWAY_PORT} \
		--set consoleURL=http://host.docker.internal:${CONSOLE_PORT}
else ifeq ($(UNAME_S),Linux)
	@helm install ${HELM_RELEASE_NAME} charts/core --namespace ${HELM_NAMESPACE} --create-namespace \
		--set edition=k8s-ce:test \
		--set tags.observability=false \
		--set tags.prometheusStack=false \
		--set apiGateway.image.tag=${API_GATEWAY_VERSION} \
		--set mgmtBackend.image.tag=${MGMT_BACKEND_VERSION} \
		--set console.image.tag=${CONSOLE_VERSION} \
		--set apiGatewayURL=http://localhost:${API_GATEWAY_PORT} \
		--set console.serverApiGatewayURL=http://localhost:${API_GATEWAY_PORT} \
		--set consoleURL=http://localhost:${CONSOLE_PORT}
endif
	@kubectl rollout status deployment core-api-gateway --namespace ${HELM_NAMESPACE} --timeout=120s
	@export API_GATEWAY_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=api-gateway,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${API_GATEWAY_POD_NAME} ${API_GATEWAY_PORT}:${API_GATEWAY_PORT} > /dev/null 2>&1 &
	@export CONSOLE_POD_NAME=$$(kubectl get pods --namespace ${HELM_NAMESPACE} -l "app.kubernetes.io/component=console,app.kubernetes.io/instance=${HELM_RELEASE_NAME}" -o jsonpath="{.items[0].metadata.name}") && \
		kubectl --namespace ${HELM_NAMESPACE} port-forward $${CONSOLE_POD_NAME} ${CONSOLE_PORT}:${CONSOLE_PORT} > /dev/null 2>&1 &
	@while ! nc -vz localhost ${API_GATEWAY_PORT} > /dev/null 2>&1; do sleep 1; done
	@while ! nc -vz localhost ${CONSOLE_PORT} > /dev/null 2>&1; do sleep 1; done
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v ${HOME}/.kube/config:/root/.kube/config \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		${DOCKER_HELM_IT_EXTRA_PARAMS} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/vdp/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/vdp/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/vdp && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/vdp && \
				helm install vdp charts/vdp --namespace ${HELM_NAMESPACE} --create-namespace \
					--set edition=k8s-ce:test \
					--set pipelineBackend.image.tag=latest \
					--set connectorBackend.image.tag=latest \
					--set connectorBackend.excludelocalconnector=false \
					--set controllerVDP.image.tag=latest' \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
	@export TMP_CONFIG_DIR=$(shell mktemp -d) && docker run --rm \
		-v ${HOME}/.kube/config:/root/.kube/config \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $${TMP_CONFIG_DIR}:$${TMP_CONFIG_DIR} \
		${DOCKER_HELM_IT_EXTRA_PARAMS} \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_COMPOSE_IMAGE_NAME}:latest /bin/sh -c " \
			cp /instill-ai/model/.env $${TMP_CONFIG_DIR}/.env && \
			cp /instill-ai/model/docker-compose.build.yml $${TMP_CONFIG_DIR}/docker-compose.build.yml && \
			/bin/sh -c 'cd /instill-ai/model && make build-latest BUILD_CONFIG_DIR_PATH=$${TMP_CONFIG_DIR}' && \
			/bin/sh -c 'cd /instill-ai/model && \
				helm install model charts/model --namespace ${HELM_NAMESPACE} --create-namespace \
						--set edition=k8s-ce:test \
						--set modelBackend.image.tag=latest \
						--set controllerModel.image.tag=latest \
						--set itMode.enabled=true' \
			/bin/sh -c 'rm -rf $${TMP_CONFIG_DIR}/*' \
		" && rm -rf $${TMP_CONFIG_DIR}
ifeq ($(UNAME_S),Darwin)
	@docker run --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://host.docker.internal:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://host.docker.internal:${API_GATEWAY_PORT} \
		-e NEXT_PUBLIC_API_VERSION=v1alpha \
		-e NEXT_PUBLIC_SELF_SIGNED_CERTIFICATION=false \
		-e NEXT_PUBLIC_INSTILL_AI_USER_COOKIE_NAME=instill-ai-user \
		-e NEXT_PUBLIC_CONSOLE_EDITION=k8s-ce:test \
		--entrypoint ./entrypoint-playwright.sh \
		--name ${CONTAINER_CONSOLE_INTEGRATION_TEST_NAME}-latest \
		${CONTAINER_PLAYWRIGHT_IMAGE_NAME}:${CONSOLE_VERSION}
else ifeq ($(UNAME_S),Linux)
	@docker run --rm \
		-e NEXT_PUBLIC_CONSOLE_BASE_URL=http://localhost:${CONSOLE_PORT} \
		-e NEXT_PUBLIC_API_GATEWAY_URL=http://localhost:${API_GATEWAY_PORT} \
		-e NEXT_SERVER_API_GATEWAY_URL=http://localhost:${API_GATEWAY_PORT} \
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
