all: build

#Before Build, need to set CREDENTIAL_FILE_PATH

HOME=$(shell pwd)
BUILD_TOOLS_DIR=$(HOME)/build-tools

#Credential Path
DOCKERHUB_USER=`cat $(CREDENTIAL_FILE_PATH)/dockerhub/user`
DOCKERHUB_PWD=`cat $(CREDENTIAL_FILE_PATH)/dockerhub/pwd`
#GITHUB_USER=$(CREDENTIAL_FILE_PATH)/github/user
#GITHUB_PWD=$(CREDENTIAL_FILE_PATH)/github/pwd

#GO Envs
GO_PACKAGE=go$(GOLANG_VERSION).linux-amd64.tar.gz
GODOWNLOAD_URL=https://dl.google.com/go/$(GO_PACKAGE)
GOROOT=$(BUILD_TOOLS_DIR)/go
GOPATH=$(HOME)
OUTPUT_DIR=$(GOPATH)/bin
PATH:=$(PATH):$(GOROOT)/bin:$(GOPATH)

#Docker Envs
#DOCKER_ARCH=x86_64
#DOCKER_VERSION=19.03.1
#DOCKER_PACKAGE=docker-$(DOCKER_VERSION).tgz
#DOCKER_DOWNLOAD_URL=https://download.docker.com/linux/static/stable/$(DOCKER_ARCH)/$(DOCKER_PACKAGE)
#PATH:=$(PATH):$(BUILD_TOOLS_DIR)/docker
DOCKER_VERSION=3:19.03.1-3.*

#Project Envs
GOLANG_VERSION?=1.12.7
SUPPORTED_KUBE_VERSIONS=1.9.3
GITHUB_PROJECT_URL=https://github.com/JaneWangQuest/heapster.git
PREFIX=janewzh13

#Submodules
SUB_MODULES_GO=go
SUB_MODULES_GO_SRC=$(SUB_MODULES_GO)/src
SUB_MODULES_PREFIX=$(SUB_MODULES_GO_SRC)/k8s.io/
SUB_MODULES_HEAPSTER=heapster
SUB_MODULES=$(SUB_MODULES_HEAPSTER)

build: clean init-workspace init-go init-docker-centos subsystem push

init-workspace:
	mkdir -p $(BUILD_TOOLS_DIR)
	mkdir -p $(OUTPUT_DIR)
	
init-go:
	@echo "Download go from $(GODOWNLOAD_URL)."
	@wget --directory-prefix=$(BUILD_TOOLS_DIR) $(GODOWNLOAD_URL) >/dev/null 2>&1
	@echo "Extract $(BUILD_TOOLS_DIR)/$(GO_PACKAGE) to $(BUILD_TOOLS_DIR)/go after download..."
	@tar -zxf $(BUILD_TOOLS_DIR)/$(GO_PACKAGE) -C $(BUILD_TOOLS_DIR)
	@rm -f $(BUILD_TOOLS_DIR)/$(GO_PACKAGE)

init-docker-centos:
	@echo "Remove existing docker packages..."
	@yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
	@echo "Install docker required packages Community..."
	@yum install -y yum-utils device-mapper-persistent-data lvm2
	@echo "Add docker repository for installation."
	@yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	@echo "Install docker version docker-ce-$(DOCKER_VERSION)..."
	@yum install -y docker-ce-$(DOCKER_VERSION)
	@echo "Start docker daemon."
	@systemctl start docker
#	@echo "Download docker from $(DOCKER_DOWNLOAD_URL)."
#	@wget --directory-prefix=$(BUILD_TOOLS_DIR) $(DOCKER_DOWNLOAD_URL) >/dev/null 2>&1
#	@echo "Extract $(BUILD_TOOLS_DIR)/$(DOCKER_PACKAGE) to $(BUILD_TOOLS_DIR)/docker after download..."
#	@tar -zxf $(BUILD_TOOLS_DIR)/$(DOCKER_PACKAGE) -C $(BUILD_TOOLS_DIR)
#	@rm -f $(BUILD_TOOLS_DIR)/$(DOCKER_PACKAGE)
	
subsystem:
	mkdir -p $(SUB_MODULES_PREFIX)
	mkdir -p $(OUTPUT_DIR)/heapster
	@echo "Git clone from $(GITHUB_PROJECT_URL) to $(SUB_MODULES_PREFIX)$(SUB_MODULES_HEAPSTER)... TODO remote branch switch to test after initial version done."
	@git clone --single-branch --branch test $(GITHUB_PROJECT_URL) $(SUB_MODULES_PREFIX)$(SUB_MODULES_HEAPSTER) >/dev/null 2>&1
	OUTPUT_DIR=$(OUTPUT_DIR)/heapster PREFIX=$(PREFIX) make -C $(addprefix $(SUB_MODULES_PREFIX),$(SUB_MODULES))

push:
	@echo "Push all images to repository"
	DOCKERHUB_USER=$(DOCKERHUB_USER) DOCKERHUB_PWD=$(DOCKERHUB_PWD) make push -C $(addprefix $(SUB_MODULES_PREFIX),$(SUB_MODULES))

uninit-docker-centos:
	@echo "Stop docker daemon."
	@systemctl stop docker
	@echo "Remove docker packages..."
	@yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
	
clean: uninit-docker-centos
	rm -rf $(BUILD_TOOLS_DIR)
	rm -rf $(OUTPUT_DIR)
	rm -rf $(SUB_MODULES_GO)