defmodule SbrokerPlayground.Report do
  @moduledoc false

  def new do
    %{}
  end

  def add(report, {:processed, queue_time, processing_time}) do
    report
    |> add(:allowed, queue_time)
    |> add(:processed, processing_time)
  end

  def add(report, {bucket, time}) do
    add(report, bucket, time)
  end

  defp add(report, bucket, time) do
    time_ms = time / 1000
    Map.update(report, bucket, [time_ms], &[time_ms | &1])
  end

  def finish(report) do
    for {bucket, values} <- report do
      %{
        result: bucket,
        count: Enum.count(values),
        min: Statistics.min(values),
        max: Statistics.max(values),
        median: Statistics.median(values),
        p95: Statistics.percentile(values, 95),
        p99: Statistics.percentile(values, 99)
      }
    end
  end

  def print(report) do
    IO.ANSI.Table.format(report, headers: [:result, :count, :min, :median, :p95, :p99, :max])
  end
end
