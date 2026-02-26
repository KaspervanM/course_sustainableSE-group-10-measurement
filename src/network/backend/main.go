package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

func sendJSON(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(payload)
}

/**
	Seed the database

	#count/5 suppliers added,
	#count CPUs added with random price and in 50 stock
	Per CPU:
		One link to random supplier with random supply_price
		Three orders
	
	Example request: GET /seed?count=500
*/
func seedDatabase(w http.ResponseWriter, r *http.Request) {
	countStr := r.URL.Query().Get("count")
	count, _ := strconv.Atoi(countStr)
	if count <= 5 { count = 5 }

	tx, _ := db.Begin()
	
	supplierIds := []int64{}
	for i := 0; i < (count/5)+1; i++ {
		res, _ := tx.Exec("INSERT INTO suppliers (name, country) VALUES (?, ?)", 
			fmt.Sprintf("Supplier-%d", i), "Global")
		id, _ := res.LastInsertId()
		supplierIds = append(supplierIds, id)
	}

	for i := 0; i < count; i++ {
		res, _ := tx.Exec("INSERT INTO cpus (brand, model, price, stock) VALUES (?, ?, ?, ?)",
			"StressBrand", fmt.Sprintf("Power-Model-%d", i), 100.00+rand.Float64()*500, 50)
		cpuId, _ := res.LastInsertId()

		// Link CPU to a random supplier
		sId := supplierIds[rand.Intn(len(supplierIds))]
		tx.Exec("INSERT INTO cpu_supplier (cpu_id, supplier_id, supply_price) VALUES (?, ?, ?)",
			cpuId, sId, 80.00+rand.Float64()*400)

		for j := 0; j < 3; j++ {
			tx.Exec(`INSERT INTO orders (cpu_id, customer_name, quantity, order_date, total_price) 
				VALUES (?, ?, ?, ?, ?)`,
				cpuId, fmt.Sprintf("Customer-%d", rand.Intn(1000)), rand.Intn(5)+1, 
				time.Now().Format("2026-02-19"), 500.00)
		}
	}

	tx.Commit()
	sendJSON(w, 200, map[string]string{"message": "Database seeded successfully"})
}

/**
	Perform a database query

	This query cross joins 3 out of 4 tables.

	This query is repeated #intensity times.

	Load also depends on #entries in the database.
	
	Example request: GET /stress/sql?intensity=2
*/
func heavyRelationalSQL(w http.ResponseWriter, r *http.Request) {
	intensity, _ := strconv.Atoi(r.URL.Query().Get("intensity"))

	if intensity <= 0 { intensity = 1 }

	query := `
		SELECT 
			c1.brand, s.name, SUM(o.total_price) as revenue
		FROM cpus c1
		CROSS JOIN suppliers s
		CROSS JOIN orders o
        GROUP BY c1.brand, s.name ORDER BY revenue DESC
	`

	start := time.Now()
	result := [][]byte{}
	for i := 0; i < intensity; i++ {
		rows, err := db.Query(query)
		if err != nil {
			sendJSON(w, 500, map[string]string{"error": err.Error()})
			return
		}

		cols, _ := rows.Columns()
		for rows.Next() {
			raw := make([][]byte, len(cols))
			scanArgs := make([]any, len(cols))
			for j := range raw {
				scanArgs[j] = &raw[j]
			}
			if err := rows.Scan(scanArgs...); err != nil {
				sendJSON(w, 500, map[string]string{"error": err.Error()})
				rows.Close()
				return
			}

			rowBytes := []byte{}
			for _, col := range raw {
				if col != nil {
					rowBytes = append(rowBytes, col...)
				}
			}
			result = append(result, rowBytes)
		}
    	rows.Close()
	}

	strResult := make([]string, len(result))
	for i, r := range result {
		strResult[i] = strings.Repeat(string(r), 10000)
	}

	sendJSON(w, 200, map[string]interface{}{
		"status":      "Query Loop Completed",
		"iterations":  intensity,
		"duration_ms": time.Since(start).Milliseconds(),
		"data":        strResult,
	})
}

/**
	Perform CPU action

	This endpoint repeats a hashing algorithm to achieve high cpu load.

	#threads amount of cores will be assigned this load for a duration of #seconds.
	
	Example request: GET /stress/cpu?threads=1&seconds=5
*/
func stressCPU(w http.ResponseWriter, r *http.Request) {
	threads, _ := strconv.Atoi(r.URL.Query().Get("threads"))
	seconds, _ := strconv.Atoi(r.URL.Query().Get("seconds"))

	if threads <= 0 { threads = 1 }
	if seconds <= 0 { seconds = 5 }

	var wg sync.WaitGroup
	for i := 0; i < threads; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			end := time.Now().Add(time.Duration(seconds) * time.Second)
			for time.Now().Before(end) {
				_ = sha256.Sum256([]byte("heavy_load"))
			}
		}()
	}

	wg.Wait()
	sendJSON(w, 200, "CPU Spike Finished")
}

/**
	Perform RAM action

	This endpoint allocates and writes #size_mb MB of memory to the RAM for a
	duration of #seconds and returns the allocated data over the network.
	
	Example request: GET /stress/mem?size_mb=128&seconds=5
*/
func stressMem(w http.ResponseWriter, r *http.Request) {
	sizeMB, _ := strconv.Atoi(r.URL.Query().Get("size_mb"))
	duration, _ := strconv.Atoi(r.URL.Query().Get("seconds"))

	if sizeMB <= 0 { sizeMB = 128 }
	if duration <= 0 { duration = 5 }

	bytesToAllocate := int64(sizeMB) * 1024 * 1024
	data := make([]byte, bytesToAllocate)

	for i := 0; i < len(data); i += 4096 {
		data[i] = 1
	}

	time.Sleep(time.Duration(duration) * time.Second)
	
	w.Header().Set("Content-Type", "application/octet-stream")
    w.Header().Set("Content-Length", strconv.FormatInt(bytesToAllocate, 10))
    w.WriteHeader(http.StatusOK)
    _, _ = w.Write(data)
	
	data = nil
	runtime.GC()
	debug.FreeOSMemory()
}

func main() {
	var err error
	dsn := os.Getenv("MYSQL_DSN")
	if dsn == "" {
		dsn = "user:pass@tcp(127.0.0.1:3306)/hw_shop?parseTime=true"
	}
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/seed", seedDatabase)
	http.HandleFunc("/stress/sql", heavyRelationalSQL)
	http.HandleFunc("/stress/cpu", stressCPU)
	http.HandleFunc("/stress/mem", stressMem)

	fmt.Println("Server running on :8081")
	log.Fatal(http.ListenAndServe(":8081", nil))
}