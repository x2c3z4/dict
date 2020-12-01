PWD := $(shell pwd)
MODULE ?= $(shell head -n 1 go.mod | awk '{print $$2}')
GOPATH := $(shell go env GOPATH)
BUILD_TIME := $(shell date)
COMMIT_ID := $(shell git rev-parse --short HEAD)
ORG_PATH="github.com"
REPO_PATH="vonnyfly/dict"

# for rpm build
VERSION_LONG_STR=$(shell git describe --tags --long)
VERSION=$(shell echo "${VERSION_LONG_STR}"| awk -F- '{print $$1}' | tr -d v || echo "unknown version")
GIT_COUNT=$(shell echo "${VERSION_LONG_STR}"| awk -F- '{print $$2}')
GIT_TAG=$(shell echo "${VERSION_LONG_STR}"| awk -F- '{print $$3}')
DIST_TARBALL=${VERSION}.tar.gz
TOP_DIR=$(shell pwd)/rpm/rpmbuild
ARCH=$(shell arch)

LDFLAGS := -X '${ORG_PATH}/${REPO_PATH}/pkg/common.Version=$(VERSION)' -X '${ORG_PATH}/${REPO_PATH}/pkg/common.BuildTime=$(BUILD_TIME)' -X ${ORG_PATH}/${REPO_PATH}/pkg/common.CommitID=$(COMMIT_ID)

GOARCH := $(shell go env GOARCH)
GOOS := $(shell go env GOOS)

TAG ?= "vonnyfly/dict:$(VERSION)"

all: build

verifiers: fmt lint vet

.PHONY: deps
deps:
	go get golang.org/x/tools/cmd/goimports
	go get github.com/segmentio/golines
	go get github.com/axw/gocov
	go get github.com/AlekSi/gocov-xml
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.31.0

.PHONY: goinstall
goinstall:
	curl https://dl.google.com/go/go1.15.linux-amd64.tar.gz | tar -xz -C /usr/local

.PHONY: fmt
fmt:
	@echo "Running $@ check"
	@go mod tidy
	@goimports  -local ${MODULE} -w pkg .
	@GO111MODULE=on gofmt -l -s -w .
	@golines -m 120 -w .

.PHONY: vet
vet:
	go vet ./...

.PHONY: lint
lint:
	@echo "Running $@ check"
	@GO111MODULE=on CGO_ENABLED=0 ${GOPATH}/bin/golangci-lint cache clean
	@GO111MODULE=on CGO_ENABLED=0 ${GOPATH}/bin/golangci-lint run --timeout=5m --config ./.golangci.yml

.PHONY: cover
cover:
	@GO111MODULE=on CGO_ENABLED=0 go test -race -count=1 -p 1 -coverpkg=./... -coverprofile=coverage.data ./...
	@go tool cover -html=coverage.data -o coverage.html
	@go tool cover -func=coverage.data -o coverage.txt
	@gocov convert coverage.data | gocov-xml > coverage.xml

.PHONY: doc
doc:
	@echo "Open here: http://`hostname -I | awk '{print $$1}'`:6060/pkg/${ORG_PATH}/${REPO_PATH}"
	@godoc -http=:6060

.PHONY: test
test:
	@echo "Running unit tests"
	@GO111MODULE=on CGO_ENABLED=0 go test -race -count=1 -p 1 ./... -v

.PHONY: integration
integration:
	@echo "Running integration tests"
	@GO111MODULE=on CGO_ENABLED=0 go test -tags=integration -race -vet -count=1 ./...

.PHONY: build
build: fmt
	@echo "Building dict binary to './dict'"
	@GO111MODULE=on CGO_ENABLED=0 go build -mod=mod -trimpath --ldflags "$(LDFLAGS) -X '${ORG_PATH}/${REPO_PATH}/pkg/common.ChangeLog=`git log --oneline -10`'" -o $(PWD)/dict

.PHONY: rpm
rpm:
	@mkdir -p ${TOP_DIR}/{RPMS,SRPMS,SOURCES,BUILD,SPECS}
	@git archive --format=tar HEAD | gzip >${TOP_DIR}/SOURCES/${DIST_TARBALL}
	@rpmbuild --define "ARCHIVE ${DIST_TARBALL}" \
		--define "VERSION ${VERSION}" \
		--define "GITTAG ${GIT_COUNT}.${GIT_TAG}" \
		--define "_topdir ${TOP_DIR}" \
		-bb rpm/dict.spec
	@rm -rf rpm/${ARCH}
	@mkdir -p rpm/${ARCH}
	@mv -v ${TOP_DIR}/RPMS/${ARCH}/*.rpm rpm/${ARCH}/

.PHONY: clean
clean:
	@echo "Cleaning up all the generated files"
	@rm -rvf dict
	@rm -rvf coverage.*
