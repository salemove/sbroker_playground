defmodule SbrokerPlayground.RateLimiter do
  @moduledoc false

  @behaviour :sregulator

  def start_link(config) do
    :sregulator.start_link(__MODULE__, config[:rps] || 1000, [])
  end

  def stop(regulator) do
    :gen.stop(regulator)
  end

  def run(regulator, fun) do
    case :sregulator.ask(regulator) do
      {:go, ref, _, _, _} ->
        try do
          fun.()
        after
          :sregulator.done(regulator, ref)
        end

      {:drop, time} ->
        raise "The task has been dropped by the rate limiter after #{time} ms"
    end
  end

  @impl true
  def init(max_rps) do
    queue_spec = {:sbroker_drop_queue, %{}}
    valve_spec = {:sregulator_rate_valve, %{limit: max_rps}}
    meters_spec = []
    {:ok, {queue_spec, valve_spec, meters_spec}}
  end
end
