USER=djrut
REPO=trinity
BUILDDIR=Docker

VERSION=`git describe --tags`
BRANCH=`git branch|cut -d " " -f 2`
IMAGE=$(USER)/$(REPO):$(VERSION)#$(BRANCH)

all: prepare build cleanup

prepare:
	git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	docker build -t $(IMAGE) --rm $(BUILDDIR)

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

test:
	nosetests -sv

push:
	docker push $(IMAGE)

cleanup:
	rm $(BUILDDIR)/$(REPO).tar
