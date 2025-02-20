#!/usr/bin/make -f

RELEASE_VERSION ?= v0.6.7.1

.PHONY: local-test local-build local-build-static docker-test docker-build docker-build-static build-bats docker-acceptance release update-deps build-single-target

copy-new-bin:
	cp ./bin/kubeconform /home/redacid/.local/share/helm/plugins/helm-kubeconform/kubeconform
	chmod +x /home/redacid/.local/share/helm/plugins/helm-kubeconform/kubeconform
	sudo cp ./bin/kubeconform /usr/bin/kubeconform
	sudo chmod +x /usr/bin/kubeconform

local-test:
	go test -race ./... -count=1

local-build:
	git config --global --add safe.directory $$PWD
	go build -o bin/ ./...

local-build-static:
	CGO_ENABLED=0 GOFLAGS=-mod=vendor GOOS=linux GOARCH=amd64 GO111MODULE=on go build -trimpath -tags=netgo -ldflags "-extldflags=\"-static\""  -a -o bin/ ./...

# These only used for development. Release artifacts and docker images are produced by goreleaser.
docker-test:
	docker run -t -v $$PWD:/go/src/github.com/redacid/kubeconform -w /go/src/github.com/redacid/kubeconform golang:1.22.5 make local-test

docker-build:
	docker run -t -v $$PWD:/go/src/github.com/redacid/kubeconform -w /go/src/github.com/redacid/kubeconform golang:1.22.5 make local-build

docker-build-static:
	docker run -t -v $$PWD:/go/src/github.com/redacid/kubeconform -w /go/src/github.com/redacid/kubeconform golang:1.22.5 make local-build-static

build-bats:
	docker build -t bats -f Dockerfile.bats .

docker-acceptance: build-bats
	docker run -t bats -p acceptance.bats
	docker run --network none -t bats -p acceptance-nonetwork.bats

goreleaser-build-static:
	docker run -t -e GOOS=linux -e GOARCH=amd64 -v $$PWD:/go/src/github.com/redacid/kubeconform -w /go/src/github.com/redacid/kubeconform goreleaser/goreleaser:v2.1.0 build --clean --single-target --snapshot
	cp dist/kubeconform_linux_amd64_v1/kubeconform bin/

release:
	#echo $(GITHUB_TOKEN)
	docker run -e GITHUB_TOKEN -e GIT_OWNER -it -v /var/run/docker.sock:/var/run/docker.sock -v $$PWD:/go/src/github.com/redacid/kubeconform -w /go/src/github.com/redacid/kubeconform goreleaser/goreleaser:v2.1.0 release --clean

update-deps:
	go get -u ./...
	go mod tidy

update-junit-xsd:
	curl https://raw.githubusercontent.com/junit-team/junit5/main/platform-tests/src/test/resources/jenkins-junit.xsd > fixtures/junit.xsd
