FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod .
RUN go mod edit -go=1.23
COPY main.go .
RUN CGO_ENABLED=0 go build -o frontend .

FROM alpine:3.20
COPY --from=build /app/frontend /usr/local/bin/frontend
EXPOSE 8080
CMD ["frontend"]
