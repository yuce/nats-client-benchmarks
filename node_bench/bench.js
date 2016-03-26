// Adapted from: https://github.com/nats-io/node-nats/blob/master/benchmark/pub_sub_perf.js

const subject = "0123456789012345"
const payload = "0123456789012345012345678901234501234567890123450123456789012345"
const num_pubs = 1
const num_subs = 1
const msg_count = 1000000

var pub = require('nats').connect();
var sub = require('nats').connect();

sub.on('connect', () => {
    var received = 0;
    var start = new Date();

    sub.subscribe(subject, () => {
        received += 1;

        if (received === msg_count) {
            var stop = new Date();
            var usec = (stop - start) * 1000;
            var ops = Math.round(msg_count / ((stop - start) / 1000));
            console.log(`${msg_count} ${usec} ${ops}`);
            process.exit();
        }
    });

    sub.flush(() => {
        for (var i = 0; i < msg_count; i++) {
            pub.publish(subject, payload);
        }
    });

});