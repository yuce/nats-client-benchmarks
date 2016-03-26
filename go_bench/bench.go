// Copyright 2015 Apcera Inc. All rights reserved.
// +build ignore

// Adapted from: https://github.com/nats-io/nats/blob/master/examples/nats-bench.go

package main

import (
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/nats-io/nats"
)

const subj = "0123456789012345"
const payload = "0123456789012345012345678901234501234567890123450123456789012345"
const numPubs = 1
const numSubs = 1
const MsgCount = 1000000

func main() {
	opts := nats.DefaultOptions
	opts.Secure = false

	var startwg sync.WaitGroup
	var donewg sync.WaitGroup

	donewg.Add(numPubs + numSubs)

	start := time.Now()

	// Run Subscribers first
	startwg.Add(numSubs)
	for i := 0; i < numSubs; i++ {
		go runSubscriber(&startwg, &donewg, opts, MsgCount * numPubs)
	}
	startwg.Wait()

	// Now Publishers
	startwg.Add(numPubs)
	for i := 0; i < numPubs; i++ {
		go runPublisher(&startwg, &donewg, opts, MsgCount)
	}

	startwg.Wait()

	donewg.Wait()
	delta := time.Since(start).Seconds()
	total := float64(MsgCount * numPubs)
	if numSubs > 0 {
		total *= float64(numSubs)
	}
    fmt.Printf("%d %d %d\n", int64(total), int64(delta * 1000000), int64(total/delta))
}

func runPublisher(startwg, donewg *sync.WaitGroup, opts nats.Options, MsgCount int) {
	nc, err := opts.Connect()
	if err != nil {
		log.Fatalf("Can't connect: %v\n", err)
	}
	defer nc.Close()
	startwg.Done()

	for i := 0; i < MsgCount; i++ {
		nc.Publish(subj, []byte(payload))
	}
	nc.Flush()
	donewg.Done()
}

func runSubscriber(startwg, donewg *sync.WaitGroup, opts nats.Options, MsgCount int) {
	nc, err := opts.Connect()
	if err != nil {
		log.Fatalf("Can't connect: %v\n", err)
	}

	received := 0
	nc.Subscribe(subj, func(msg *nats.Msg) {
		received++
		if received >= MsgCount {
			donewg.Done()
			nc.Close()
		}
	})
	nc.Flush()
	startwg.Done()
}
