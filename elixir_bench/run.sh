source ../common/setup-run.sh
MIX_ENV=prod mix run bench.exs $nats_url $msg_count
