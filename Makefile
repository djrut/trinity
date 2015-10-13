USER=djrut
REPO=trinity
BUILDDIR=Docker

VERSION=`git describe --tags`
IMAGE=$(USER)/$(REPO):$(VERSION)

all: prep test build push clean

prep:
	git archive -o $(BUILDDIR)/$(REPO).tar HEAD

test:
	docker build -t $(IMAGE) --rm $(BUILDDIR)
	docker rmi $(IMAGE)

build:
	./Docker/build_dockerrun.sh > Dockerrun.aws.json
	git add Dockerrun.aws.json
	git commit --amend --no-edit
	docker build -t $(IMAGE) --rm $(BUILDDIR)

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

test:

push:
	docker push $(IMAGE)

clean:
	rm $(BUILDDIR)/$(REPO).tar
