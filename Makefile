NAME := rdrp
SRCS := $(shell find . -type f -name '*.go')
PKGS := $(shell go list ./... | grep -v /vendor)

.PHONY: all coverage clean fmt fmt-save get-tools install lint test vet
.DEFAULT: all

all: rdrp

install:
	@echo "+ $@"
	@go install $(PKGS)

get-tools:
	@echo "+ $@"
	@go get -u -v github.com/golang/lint/golint

clean:
	@echo "+ $@"
	rm -rf build ./$(NAME)
	mkdir -p build

rdrp: $(SRCS)
	@echo "+ $@"
	@go build -o ./$(NAME) ./cmd/rdrp

fmt:
	@echo "+ $@"
	@test -z "$$(gofmt -s -l . 2>&1 | grep -v ^vendor/ | tee /dev/stderr)" || \
		(echo >&2 "+ please format Go code with 'gofmt -s', or use 'make fmt-save'" && false)

fmt-save:
	@echo "+ $@"
	@gofmt -s -l . 2>&1 | grep -v ^vendor/ | xargs gofmt -s -l -w

vet:
	@echo "+ $@"
	@go vet $(PKGS)

lint:
	@echo "+ $@"
	$(if $(shell which golint || echo ''), , \
		$(error Please install golint: `make get-tools`))
	@test -z "$$(golint ./... 2>&1 | grep -v ^vendor/ | grep -v mock/ | tee /dev/stderr)"

test:
	@echo "+ $@"
	@go test -race -v $(PKGS)

coverage:
	@echo "+ $@"
	@for pkg in $(PKGS); do \
		go test -test.short -race -coverprofile="../../../$$pkg/coverage.txt" $${pkg} || exit 1; \
	done

binaries: darwin linux windows

##### DARWIN BUILDS #####

darwin: build/darwin_amd64.tar.gz

build/darwin_amd64.tar.gz: $(SRCS)
	$(call build,darwin,amd64,)
	$(call tar,darwin,amd64)

##### LINUX BUILDS #####

linux: build/linux_arm.tar.gz build/linux_arm64.tar.gz build/linux_386.tar.gz build/linux_amd64.tar.gz

build/linux_386.tar.gz: $(SRCS)
	$(call build,linux,386,)
	$(call tar,linux,386)

build/linux_amd64.tar.gz: $(SRCS)
	$(call build,linux,amd64,)
	$(call tar,linux,amd64)

build/linux_arm.tar.gz: $(SRCS)
	$(call build,linux,arm,)
	$(call tar,linux,arm)

build/linux_arm64.tar.gz: $(SRCS)
	$(call build,linux,arm64,)
	$(call tar,linux,arm64)

##### WINDOWS BUILDS #####

windows: build/windows_386.zip build/windows_amd64.zip

build/windows_386.zip: $(SRCS)
	$(call build,windows,386,.exe)
	$(call zip,windows,386,.exe)

build/windows_amd64.zip: $(SRCS)
	$(call build,windows,amd64,.exe)
	$(call zip,windows,amd64,.exe)
