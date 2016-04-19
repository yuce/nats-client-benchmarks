// Copyright 2015 Apcera Inc. All rights reserved.
// +build ignore

// Adapted from: https://github.com/nats-io/nats/blob/master/examples/nats-bench.go

package main

import (
	"fmt"
	"log"
	"sync"
	"time"
    "os"
    "strconv"

	"github.com/nats-io/nats"
)

const subj = "0123456789012345"
const payload = "0123456789012345012345678901234501234567890123450123456789012345"
const numPubs = 1
const numSubs = 1

func main() {
    if len(os.Args) != 3 {
        fmt.Printf("Usage: go run bench.go nats://HOST:PORT message_count\n")
        os.Exit(0);
    }
    
    url := os.Args[1];
    msgCount, err := strconv.Atoi(os.Args[2])
    if (err != nil) {
        fmt.Printf("Not a valid message count: %d", msgCount);
        os.Exit(2);
    }
    
	var startwg sync.WaitGroup
	var donewg sync.WaitGroup

	donewg.Add(numPubs + numSubs)

	start := time.Now()

	// Run Subscribers first
	startwg.Add(numSubs)
	for i := 0; i < numSubs; i++ {
		go runSubscriber(&startwg, &donewg, url, msgCount * numPubs)
	}
	startwg.Wait()

	// Now Publishers
	startwg.Add(numPubs)
	for i := 0; i < numPubs; i++ {
		go runPublisher(&startwg, &donewg, url, msgCount)
	}

	startwg.Wait()

	donewg.Wait()
	delta := time.Since(start).Seconds()
	total := float64(msgCount * numPubs)
	if numSubs > 0 {
		total *= float64(numSubs)
	}
    fmt.Printf("%d %d %d\n", int64(total), int64(delta * 1000000), int64(total / delta))
}

func runSubscriber(startwg, donewg *sync.WaitGroup, url string, msgCount int) {
	nc, err := nats.Connect(url)
	if err != nil {
		log.Fatalf("Can't connect: %v\n", err)
	}

	received := 0
	nc.Subscribe(subj, func(msg *nats.Msg) {
		received++
		if received >= msgCount {
			donewg.Done()
			nc.Close()
		}
	})
	nc.Flush()
	startwg.Done()
}

func runPublisher(startwg, donewg *sync.WaitGroup, url string, msgCount int) {
	nc, err := nats.Connect(url)
	if err != nil {
		log.Fatalf("Can't connect: %v\n", err)
	}
	defer nc.Close()
	startwg.Done()

	for i := 0; i < msgCount; i++ {
		nc.Publish(subj, []byte(payload))
	}
	nc.Flush()
	donewg.Done()
}
