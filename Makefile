all: build

#Before Build, need to set CREDENTIAL_FILE_PATH

HOME=$(shell pwd)
TMP_DIR=$(HOME)/tmp/

#Credential Path
DOCKERHUB_USER=$(CREDENTIAL_FILE_PATH)/dockerhub/user
DOCKERHUB_PWD=$(CREDENTIAL_FILE_PATH)/dockerhub/pwd
#GITHUB_USER=$(CREDENTIAL_FILE_PATH)/github/user
#GITHUB_PWD=$(CREDENTIAL_FILE_PATH)/github/pwd

#GO Envs
TOOLS_DIR=$(TMP_DIR)/heapster-tools
GOPACKAGE=go$(GOLANG_VERSION).linux-amd64.tar.gz
GODOWNLOAD_URL=https://dl.google.com/go/$(GOPACKAGE)
GOROOT=$(TOOLS_DIR)/go
GOPATH=$(HOME)
PATH:=$(PATH):$(GOROOT)/bin:$(GOPATH)

#Project Envs
GOLANG_VERSION?=1.12.7
SUPPORTED_KUBE_VERSIONS=1.9.3
GITHUB_PROJECT_URL=https://github.com/JaneWangQuest/heapster.git

#Submodules
SUB_MODULES_PREFIX=src/k8s.io/
SUB_MODULES_HEAPSTER=heapster
SUB_MODULES_SECURITY=security
SUB_MODULES=$(SUB_MODULES_HEAPSTER) $(SUB_MODULES_SECURITY)

build: clean init-tmp init-go

init-tmp:
	mkdir -p $(TMP_DIR)

init-go:
	mkdir -p $(TOOLS_DIR)
	@echo "Download go from $(GODOWNLOAD_URL)."
	@wget --directory-prefix=$(TOOLS_DIR) $(GODOWNLOAD_URL) >/dev/null 2>&1
	@echo "Extract $(TOOLS_DIR)/$(GOPACKAGE) to $(TOOLS_DIR)/go after download..."
	@tar -zxf $(TOOLS_DIR)/$(GOPACKAGE) -C $(TOOLS_DIR)
	@rm -f $(TOOLS_DIR)/$(GOPACKAGE)

subsystem:
	mkdir -p $(SUB_MODULES_PREFIX)
	git clone $(GITHUB_PROJECT_URL) $(SUB_MODULES_PREFIX)$(SUB_MODULES_HEAPSTER)
	make -C $(addprefix $(SUB_MODULES_PREFIX),$(SUB_MODULES))
	
clean:
	rm -rf $(TMP_DIR)
	rm -rf $(TOOLS_DIR)