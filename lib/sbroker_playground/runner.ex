defmodule SbrokerPlayground.Runner do
  @moduledoc false

  alias SbrokerPlayground.{RateLimiter, Regulator, WorkerPool}

  defstruct [:rate_limiter, :regulator, :worker_pool, :worker_delay, :config, :use_sprotector?]

  def new(config) do
    %__MODULE__{
      config: config,
      use_sprotector?: !is_nil(config[:protector]),
      worker_delay: config[:worker][:delay] || 0
    }
  end

  def setup(runner) do
    %{
      runner
      | rate_limiter: start!(runner, RateLimiter),
        worker_pool: start!(runner, WorkerPool),
        regulator: start!(runner, Regulator)
    }
  end

  def start_task(runner) do
    Task.async(fn ->
      Regulator.run(runner.regulator, runner.use_sprotector?, fn ->
        WorkerPool.work(runner.worker_delay)
      end)
    end)
  end

  def tear_down(runner) do
    RateLimiter.stop(runner.rate_limiter)
    WorkerPool.stop(runner.worker_pool)
    Regulator.stop(runner.regulator)

    %{runner | rate_limiter: nil, worker_pool: nil, regulator: nil}
  end

  defp start!(runner, mod) do
    {:ok, pid} = mod.start_link(runner.config)
    pid
  end
end
