package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
)

func servePage(sizeMB int) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		bytesToSend := int64(sizeMB) * 1024 * 1024
		w.Header().Set("Content-Type", "application/octet-stream")
		w.Header().Set("Content-Length", strconv.FormatInt(bytesToSend, 10))
		w.WriteHeader(http.StatusOK)

		buf := make([]byte, 1024*1024)
		for i := range buf {
			buf[i] = byte(i % 256)
		}

		sent := int64(0)
		for sent < bytesToSend {
			toWrite := buf
			if bytesToSend-sent < int64(len(buf)) {
				toWrite = buf[:bytesToSend-sent]
			}
			w.Write(toWrite)
			sent += int64(len(toWrite))
		}
	}
}

func main() {
	http.HandleFunc("/page1", servePage(50))
	http.HandleFunc("/page2", servePage(100))
	http.HandleFunc("/page3", servePage(150))

	fmt.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
