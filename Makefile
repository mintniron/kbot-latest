VERSION:

format: 
	gofmt -s -w ./
build:
	go build -v -o kbot -ldflags "-X="github.com/vit-um/kbot/cmd.appVersion=${VERSION}
