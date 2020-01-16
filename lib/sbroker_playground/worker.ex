defmodule SbrokerPlayground.Worker do
  @moduledoc false

  # Worker simulator with configurable delay and jitter

  use GenServer

  def start_link(config) do
    jitter = config[:jitter] || 0

    GenServer.start_link(__MODULE__, jitter)
  end

  def work(worker, delay) do
    GenServer.call(worker, {:work, delay}, :infinity)
  end

  @impl true
  def init(jitter) do
    {:ok, jitter}
  end

  @impl true
  def handle_call({:work, base_delay}, _from, jitter) do
    delta = if jitter > 0, do: :rand.uniform(jitter), else: 0
    delay = base_delay + delta

    if delay > 0 do
      Process.sleep(delay)
    end

    {:reply, :ok, jitter}
  end
end
