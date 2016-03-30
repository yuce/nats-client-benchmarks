// Adapted from: https://github.com/nats-io/node-nats/blob/master/benchmark/pub_sub_perf.js

var nats = require('nats'); 

if (process.argv.length != 4) {
    console.log('Usage: node bench.js nats://HOST:PORT message_count');
    process.exit(0);
}

const url = process.argv[2]
const subject = "0123456789012345"
const payload = "0123456789012345012345678901234501234567890123450123456789012345"
const msg_count = parseInt(process.argv[3]);
var pub = nats.connect({url: url});
var sub = nats.connect({url: url});

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