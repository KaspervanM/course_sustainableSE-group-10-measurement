FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod edit -go=1.23 && go mod download
COPY main.go .
RUN CGO_ENABLED=0 go build -o backend .

FROM alpine:3.20
COPY --from=build /app/backend /usr/local/bin/backend
EXPOSE 8081
CMD ["backend"]
