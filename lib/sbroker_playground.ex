defmodule SbrokerPlayground do
  @moduledoc """
  Sbroker regulator simulator for testing various regulator configurations from iex console.

  ## Usage

  Run from `iex`:

      Transporter.Regulator.Simulator.run(iterations, config)

  Returns performance report, grouped into buckets. Each bucket contains the following items:

    * `:count` - how many items is in the bucket
    * `:main` - the average value of all items in the bucket
    * `:min` - the minimum value in the bucket
    * `:max` - the maximum value in the bucket
    * `:p50`, `:p75`, `:p95`, `:p99` - 50th, 75th, 95th and 99th percentiles of values
      in the bucket

  The report may contain the following buckets:

    * `:allowed` - contains statistics about queue delay for requests that were allowed to execute
      by the regulator.
    * `:rejected` - contains statistics about queue delay for requests that were dropped by :sprotector
    * `:dropped` - contains statistics about queue delay for requests that were dropped by :sregulator
    * `:processed` - contains statistics about processing time for requests that were processed by the worker pool

  The following configuration parameters are supported:

    * `:rps` - regulates the pace of incoming work requests, per second (default is 1000)
    * `:worker` (keyword):
      * `:pool_size` - worker pool size
      * `:delay` (milliseconds) - how long each worker processes every request (default is 0).
      * `:jitter` (milliseconds) - how much jitter time to add to every request processing (default is 0)
    * `:queue` (tuple `{handler_module, handler_opts}`) - regulator queue spec, see
      https://hexdocs.pm/sbroker/sregulator.html for examples
    * `:valve` (tuple `{handler_module, handler_opts}`) - regulator valve spec, see
      https://hexdocs.pm/sbroker/sregulator.html for examples
    * `:protector` (keyword | map, optional) - `:sprotector_pie_meter` spec. If omitted,
      `:sprotector` will not be used during the test. See https://hexdocs.pm/sbroker/sprotector_pie_meter.html
      for more info.

  Other configuration parameters are passed directly to `Transporter.Regulator`, check its documentation
  for supported parameters.

  ## Example

      # Run 10 000 iterations with arrival speed 2000 rps. Set regulator's max concurrency to 30
      # and target time to 40 ms with maximum queue size of 1000. Worker delay is 5 ms.
      #{__MODULE__}.run(10000, rps: 2000, max_concurrency: 30, target: 40, max_queue_size: 1000, worker_delay: 5)
  """

  alias __MODULE__.{Report, Runner}

  def run(iterations \\ 1000, config \\ []) do
    with_runner(config, fn runner ->
      1..iterations
      |> Enum.map(fn _ -> Runner.start_task(runner) end)
      |> Enum.map(&Task.await(&1, :infinity))
      |> Enum.reduce(Report.new(), &Report.add(&2, &1))
      |> Report.finish()
      |> Report.print()
    end)
  end

  defp with_runner(config, fun) do
    runner =
      config
      |> Runner.new()
      |> Runner.setup()

    try do
      fun.(runner)
    after
      Runner.tear_down(runner)
    end
  end
end
