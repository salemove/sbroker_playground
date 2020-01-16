defmodule SbrokerPlayground.WorkerPool do
  @moduledoc false

  @pool_name __MODULE__
  @worker SbrokerPlayground.Worker

  def start_link(config) do
    pool_settings = [
      worker_module: @worker,
      name: {:local, @pool_name},
      size: config[:worker][:pool_size] || 100
    ]

    {:ok, _pid} = :poolboy.start_link(pool_settings, config[:worker])
    {:ok, @pool_name}
  end

  def stop(pool_name) do
    :poolboy.stop(pool_name)
  end

  def work(delay) do
    :poolboy.transaction(@pool_name, &@worker.work(&1, delay), :infinity)
  end
end
