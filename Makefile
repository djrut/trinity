USER = djrut
REPO = trinity
BUILDDIR = Docker

VERSION := `git describe --tags`
IMAGE := $(USER)/$(REPO):$(VERSION)

all: prep dry-run build push commit clean

prep:
	$(info +++ Entering git archive preparation phase +++)
	git archive -o $(BUILDDIR)/$(REPO).tar HEAD

dry-run:
	$(info +++ Entering image build dry-run phase +++)
	docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)
	docker rmi $(IMAGE)

build:
	$(info +++ Entering image build phase +++)
	Docker/build_dockerrun.sh > Dockerrun.aws.json
	docker build -t $(IMAGE) --force-rm --rm $(BUILDDIR)

tag_latest:
	docker tag $(IMAGE) $(USER)/$(REPO):latest

push:
	$(info +++ Entering image push phase +++)
	docker push $(IMAGE)

commit:
	$(info +++ Entering Dockerrun.aws.json commit phase +++)
	git add Dockerrun.aws.json
	git commit --amend --no-edit

clean:
	$(info +++ Entering working files clean-up phase +++)
	rm $(BUILDDIR)/$(REPO).tar
