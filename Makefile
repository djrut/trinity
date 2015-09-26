USER=djrut
REPO=trinity
BUILDDIR=Docker

VERSION=`git describe --tags`
BRANCH=`git branch|cut -d " " -f 2`
IMAGE=$(USER)/$(REPO):$(VERSION)

all: prepare build cleanup

prepare:
	./Docker/build_dockerrun.sh > Dockerrun.aws.json
	git archive -o $(BUILDDIR)/$(REPO)_$(VERSION).tar HEAD

build:
	docker build -t $(IMAGE) --rm $(BUILDDIR)

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

test:

push:
	docker push $(IMAGE)

cleanup:
	rm $(BUILDDIR)/$(REPO).tar
