defmodule Bench do    
    @subject "0123456789012345"
    @payload "0123456789012345012345678901234501234567890123450123456789012345"
    
    def go(nats_conf, msg_count) do
        subject = @subject
        payload = @payload
        start_subscribe(self, nats_conf, subject, msg_count)
        :timer.sleep(1000)  # Ensure we are subscribed
        f = fn ->
            publish_and_receive(nats_conf, subject, payload, msg_count)
        end
        {usec, :ok} = :timer.tc(f)
        ops = ops(usec, msg_count)
        {msg_count, usec, ops}
    end
    
    defp publish_and_receive(nats_conf, subject, payload, msg_count) do
        start_publish(nats_conf, subject, payload, msg_count)
        receive do
            :done -> :ok
        end
    end
    
    defp ops(usec, msg_count) do
        round(msg_count / (usec / 1_000_000))
    end
    
    def subscribe(parent, sub, subject, msg_count) do
        Nats.Client.sub(sub, self, subject)
        loop(sub, msg_count)
        send parent, :done
    end

    defp loop(_, 0) do
        :ok
    end
    
    defp loop(conn, msg_count) do
        receive do
            {:msg, _, _, _, _} ->
                loop(conn, msg_count - 1)
        end
    end
    
    def publish(_, _, _, 0) do
        :ok
    end

    def publish(conn, subject, payload, left) do
        Nats.Client.pub(conn, subject, payload)
        publish(conn, subject, payload, left - 1)
    end
    
    def start_subscribe(parent, nats_conf, subject, msg_count) do
        {:ok, sub} = Nats.Client.start_link(nats_conf)
        spawn(fn -> subscribe(parent, sub, subject, msg_count) end)
    end
    
    def start_publish(nats_conf, subject, payload, msg_count) do
        {:ok, pub} = Nats.Client.start_link(nats_conf)
        spawn(fn -> publish(pub, subject, payload, msg_count) end)
    end
end

defmodule ArgvParser do
    def nats_conf do
        <<"nats://", host_port :: binary>> = :lists.nth(1, System.argv)
        [host, bin_port] = :binary.split(host_port, ":")
        port = :erlang.binary_to_integer(bin_port)
        %{host: host, port: port}
    end
    
    def message_count do
        :erlang.binary_to_integer(:lists.nth(2, System.argv))
    end

end

if length(System.argv) == 2 do
    {msg_count, usec, ops} = Bench.go(ArgvParser.nats_conf,
                                      ArgvParser.message_count)
    IO.puts "#{msg_count} #{usec} #{ops}"
else
    IO.puts "Usage: iex bench.exs nats://HOST:PORT message_count"
end

