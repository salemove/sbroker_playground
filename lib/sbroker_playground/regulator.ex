defmodule SbrokerPlayground.Regulator do
  @moduledoc false

  @behaviour :sregulator

  def start_link(config) do
    queue_spec = Keyword.fetch!(config, :queue)
    valve_spec = Keyword.fetch!(config, :valve)

    meters_spec =
      if protector_opts = config[:protector] do
        [{:sprotector_pie_meter, Map.new(protector_opts)}]
      else
        []
      end

    start_link(queue_spec, valve_spec, meters_spec)
  end

  def start_link(queue_spec, valve_spec, meters_spec) do
    :sregulator.start_link(__MODULE__, {queue_spec, valve_spec, meters_spec}, [])
  end

  def stop(regulator) do
    :gen.stop(regulator)
  end

  def run(regulator, use_protector?, fun) do
    via =
      if use_protector? do
        {:via, :sprotector, {regulator, :ask}}
      else
        regulator
      end

    {queue_time, result} = :timer.tc(:sregulator, :ask, [via])

    case result do
      {:go, ref, _, _, _} ->
        {work_time, _} = :timer.tc(fun)
        :sregulator.done(regulator, ref)

        {:processed, queue_time, work_time}

      # Rejected by :sprotector
      {:drop, 0} ->
        {:rejected, queue_time}

      # Dropped from the queue
      {:drop, _} ->
        {:dropped, queue_time}
    end
  end

  @impl true
  def init(config) do
    {:ok, config}
  end
end
