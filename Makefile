USER=djrut
REPO=trinity
BUILDDIR=Docker

VERSION=`git describe --tags`
BRANCH=`git branch|cut -d " " -f 2`
IMAGE=$(USER)/$(REPO):$(VERSION)

all: prep build push clean

prep:
	git archive -o $(BUILDDIR)/$(REPO).tar HEAD

build:
	docker build -t $(IMAGE) --rm $(BUILDDIR)
	./Docker/build_dockerrun.sh > Dockerrun.aws.json

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

test:

push:
	docker push $(IMAGE)

clean:
	rm $(BUILDDIR)/$(REPO).tar
