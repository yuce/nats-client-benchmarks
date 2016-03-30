
import sys
import time
import tornado.ioloop
import tornado.gen
import time
from nats.io.utils import new_inbox
from nats.io.client import Client as NATS

subject = "0123456789012345"
payload = "0123456789012345012345678901234501234567890123450123456789012345"


class Client(object):
    
    def __init__(self, nc):
        self.nc = nc
        self.total = 0
        
    def connect(self, **kwargs):
        return self.nc.connect(**kwargs)
        
    def on_receive(self, msg=None):
        self.total += 1
        
    def subscribe(self, subject):
        return self.nc.subscribe(subject, '', self.on_receive)
    
    def publish(self, subject, payload):
        self.total += 1
        return self.nc.publish(subject, payload)
        

@tornado.gen.coroutine
def main():
    if len(sys.argv) != 3:
        print 'Usage: python bench.py nats://HOST:PORT message_count'
        sys.exit(1)
    url = sys.argv[1]
    msg_count = int(sys.argv[2])
    
    pub = Client(NATS())
    yield pub.connect(verbose=False, servers=[url])
    
    sub = Client(NATS())
    yield sub.connect(verbose=True, servers=[url])
    yield sub.subscribe(subject)
    
    tic = time.time()
    for i in xrange(msg_count):
        yield pub.publish(subject, payload)
    tac = time.time()
    
    yield tornado.gen.sleep(1)
    
    secs = tac - tic
    usec = secs * 1000000
    ops = msg_count / secs
    print msg_count, int(usec), int(round(ops))

if __name__ == '__main__':
    tornado.ioloop.IOLoop.instance().run_sync(main)
