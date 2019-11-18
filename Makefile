image-name-split = $(word $2,$(subst :, ,$1))

SHELL=/bin/bash
DOCKERIMAGE_FILE="docker-image.txt"
NAME := $(call image-name-split,$(shell cat $(DOCKERIMAGE_FILE)), 1)
IMAGE=$(shell cat $(DOCKERIMAGE_FILE))

.DEFAULT_GOAL := help

.PHONY: activate
activate:		## Activate an addon package for development
	@if [[ -z ${pkg} ]]; then\
		echo "You need to specify package name in make command";\
		echo "Ex: make activate pkg=volto-datablocks";\
	else \
		exec ./pkg_helper.py activate ${pkg};\
		echo "Running npm install in src/addons/${pkg}";\
		cd "src/addons/${pkg}";\
		npm install;\
		echo "Done.";\
	fi

.PHONY: deactivate
deactivate:		## Deactivate an addon package for development
	@if [[ -z ${pkg} ]]; then\
		echo "You need to specify package name in make command";\
		echo "Ex: make deactivate pkg=volto-datablocks";\
	else \
		exec ./pkg_helper.py deactivate ${pkg};\
		echo "Deactivated ${pkg}";\
	fi

.PHONY: all
all: clean build		## (Inside container) build a production version of resources
	@echo "Built production files"

.PHONY: clean
clean:
	rm -rf build/

.PHONY: build
build:
	DEBUG= \
				 NODE_OPTIONS=--max_old_space_size=4096 \
				 RAZZLE_API_PATH=VOLTO_API_PATH \
				 RAZZLE_INTERNAL_API_PATH=VOLTO_INTERNAL_API_PATH \
				 yarn build;	\
	./entrypoint-prod.sh

.PHONY: start
start:		## (Inside container) starts production mode frontend server
	npm run start:prod

.PHONY: analyze
analyze:		## (Inside container) build production resources and start bundle analyzer HTTP server
	DEBUG= \
				 BUNDLE_ANALYZE=true \
				 NODE_OPTIONS=--max_old_space_size=4096 \
				 RAZZLE_API_PATH=VOLTO_API_PATH \
				 RAZZLE_INTERNAL_API_PATH=VOLTO_INTERNAL_API_PATH \
				 yarn build

.PHONY: release
release: bump build-image push		## (Host side) release a new version of frontend docker image

.PHONY: bump
bump:
	echo "Bumping version...";
	python ./../scripts/version_bump.py $(DOCKERIMAGE_FILE);

.PHONY: build-image
build-image:
	@echo "Building new docker image: $(IMAGE)";
	docker build . --network=host -t "$(IMAGE)";
	@echo "Image built."

.PHONY: push
push:
	docker push $(IMAGE)
	docker tag $(IMAGE) $(NAME):latest
	docker push $(NAME):latest

.PHONY: init-submodules
init-submodules:		## Initialize the git submodules
	git submodule update --init --recursive

.PHONY: help
help:		## Show this help.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"