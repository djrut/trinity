USER = djrut
REPO = trinity
BUILDDIR = Docker

VERSION = `git describe --tags`
IMAGE != $(USER)/$(REPO):$(VERSION)

all: prep test build push clean

prep:
	git archive -o $(BUILDDIR)/$(REPO).tar HEAD

test:
	docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)
	docker rmi $(IMAGE)

build:
	./Docker/build_dockerrun.sh > Dockerrun.aws.json
	docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)
	git add Dockerrun.aws.json
	git commit --amend --no-edit

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

test:

push:
	docker push $(IMAGE)

clean:
	rm $(BUILDDIR)/$(REPO).tar
