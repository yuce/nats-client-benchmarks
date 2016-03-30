if [ -d "ve" ]
then
    exit 0
fi

virtualenv ve
PYTHON=`pwd`/ve/bin/python2.7
PIP=`pwd`/ve/bin/pip

git clone https://github.com/nats-io/python-nats
cd python-nats
$PIP install -r requirements.txt
$PYTHON setup.py install

cd ..

echo 'source ../common/setup-run.sh' > run.sh
echo $PYTHON `pwd`/bench.py '$nats_url' '$msg_count' >> run.sh
chmod +x run.sh

