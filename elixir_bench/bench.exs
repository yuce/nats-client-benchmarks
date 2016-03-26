defmodule Bench do
    def go(subject, payload, msg_count) do
        start_subscribe(self, subject, msg_count)
        :timer.sleep(1000)  # Ensure we are subscribed
        {usec, :ok} = :timer.tc(fn -> publish_and_receive(subject, payload, msg_count) end)
        ops = ops(usec, msg_count)
        {msg_count, usec, ops}
    end
    
    defp nats_conf do
        %{host: "127.0.0.1", port: 4222}
    end
    
    defp publish_and_receive(subject, payload, msg_count) do
        start_publish(subject, payload, msg_count)
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
    
    def start_subscribe(parent, subject, msg_count) do
        {:ok, sub} = Nats.Client.start_link(nats_conf)
        spawn(fn -> subscribe(parent, sub, subject, msg_count) end)
    end
    
    def start_publish(subject, payload, msg_count) do
        {:ok, pub} = Nats.Client.start_link(nats_conf)
        spawn(fn -> publish(pub, subject, payload, msg_count) end)
    end
end

subject = "0123456789012345"
payload = "0123456789012345012345678901234501234567890123450123456789012345"
{msg_count, usec, ops} = Bench.go(subject, payload, 1_000_000)
IO.puts "#{msg_count} #{usec} #{ops}"
