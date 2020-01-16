defmodule Mix.Tasks.Play do
  @moduledoc """
  Run the workload simulation against sregulator with configured parameters.

  Run `mix play --help` for more information.
  """

  use Mix.Task

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:sbroker_playground)

    parse_result =
      cli_opts()
      |> Optimus.new!()
      |> Optimus.parse!(args)

    config = build_config(parse_result)

    if parse_result.flags.show_config do
      Mix.Shell.IO.info(
        "Running simulation with the following config: \n#{inspect(config, pretty: true)}"
      )
    end

    SbrokerPlayground.run(parse_result.options.requests, config)
  end

  defp build_config(parse_result) do
    flags = parse_result.flags
    options = parse_result.options

    rps = options.rps

    worker_config = [
      delay: options.worker_delay,
      jitter: options.worker_jitter,
      pool_size: options.worker_pool_size
    ]

    queue_config =
      {options.queue_handler,
       %{
         drop: options.queue_drop,
         target: options.queue_target,
         interval: options.queue_interval,
         min: options.queue_min,
         max: options.queue_max,
         timeout: options.queue_timeout
       }}

    valve_config =
      {options.valve_handler,
       %{
         target: options.valve_target,
         interval: options.valve_interval,
         limit: options.valve_limit,
         min: options.valve_min,
         max: options.valve_max
       }}

    protector_config =
      if flags.enable_protector do
        [
          ask: %{target: options.protector_ask_target, interval: options.protector_ask_interval},
          ask_r: %{
            target: options.protector_ask_r_target,
            interval: options.protector_ask_r_interval
          },
          update: options.protector_update,
          min: options.protector_min,
          max: options.protector_max
        ]
      else
        nil
      end

    [
      rps: rps,
      worker: worker_config,
      queue: queue_config,
      valve: valve_config,
      protector: protector_config
    ]
  end

  @allowed_queue_handlers ~w[sbroker_codel_queue sbroker_drop_queue sbroker_timeout_queue]
  @allowed_valve_handlers ~w[sregulator_codel_valve sregulator_open_valve sregulator_rate_valve sregulator_relative_valve]

  def cli_opts do
    [
      name: "play",
      description: "Runs the simulation workload against :sregulator with configured parameters",
      about: "Playground for testing different parameters for https://hexdocs.pm/sbroker/.",
      allow_unknown_args: false,
      options: [
        requests: [
          short: "-r",
          long: "--requests",
          help: "The number of requests to send to worker",
          parser: :integer,
          required: false,
          default: 1000
        ],
        rps: [
          short: "-s",
          long: "--rps",
          help: "The pace of incoming work requests, per second",
          parser: :integer,
          required: false,
          default: 1000
        ],
        worker_pool_size: [
          short: "-w",
          long: "--worker-pool-size",
          help: "How many workers to spawn for processing",
          parser: :integer,
          required: false,
          default: 10
        ],
        worker_delay: [
          short: "-d",
          long: "--worker-delay",
          help: "How long each worker should process every request, in milliseconds",
          parser: :integer,
          required: false,
          default: 0
        ],
        worker_jitter: [
          short: "-j",
          long: "--worker-jitter",
          help: "Variance in time delay in milliseconds added to the worker baseline delay",
          required: false,
          default: 0
        ],
        queue_handler: [
          short: "-q",
          long: "--queue-handler",
          help: "sregulator queue handler (one of: #{Enum.join(@allowed_queue_handlers, ", ")})",
          required: false,
          default: :sbroker_codel_queue,
          parser: enum_parser(@allowed_queue_handlers, &String.to_existing_atom/1)
        ],
        queue_target: [
          long: "--queue-target",
          help: ":target setting in milliseconds for sbroker queue (if handler supports it)",
          required: false,
          default: 100,
          parser: :integer
        ],
        queue_interval: [
          long: "--queue-interval",
          help: ":interval setting in milliseconds for sbroker queue (if handler supports it)",
          required: false,
          default: 1000,
          parser: :integer
        ],
        queue_drop: [
          long: "--queue-drop",
          help: ":drop setting for sbroker queue (if handler supports it)",
          required: false,
          default: :drop_r,
          parser: enum_parser(~w[drop drop_r], &String.to_existing_atom/1)
        ],
        queue_min: [
          long: "--queue-min",
          help: ":min setting for sbroker queue (if handler supports it)",
          required: false,
          default: 0,
          parser: :integer
        ],
        queue_max: [
          long: "--queue-max",
          help: ":max setting for sbroker queue (if handler supports it)",
          required: false,
          default: :infinity,
          parser: :integer
        ],
        queue_timeout: [
          long: "--queue-timeout",
          help: ":timeout setting in milliseconds for sbroker queue (if handler supports it)",
          required: false,
          default: 5000,
          parser: :integer
        ],
        valve_handler: [
          short: "-v",
          long: "--valve-handler",
          help: "sregulator valve handler (one of: #{Enum.join(@allowed_valve_handlers, ", ")})",
          required: false,
          default: :sregulator_open_valve,
          parser: enum_parser(@allowed_valve_handlers, &String.to_existing_atom/1)
        ],
        valve_target: [
          long: "--valve-target",
          help: ":target setting in milliseconds for sregulator valve (if handler supports it)",
          required: false,
          default: 100,
          parser: :integer
        ],
        valve_interval: [
          long: "--valve-interval",
          help: ":interval setting in milliseconds for sregulator valve (if handler supports it)",
          required: false,
          default: 1000,
          parser: :integer
        ],
        valve_min: [
          long: "--valve-min",
          help: ":min setting for sregulator valve (if handler supports it)",
          required: false,
          default: 0,
          parser: :integer
        ],
        valve_max: [
          long: "--valve-max",
          help: ":max setting for sregulator valve (if handler supports it)",
          required: false,
          default: :infinity,
          parser: :integer
        ],
        valve_limit: [
          long: "--valve-limit",
          help: ":limit setting for sregulator valve (if handler supports it)",
          required: false,
          default: 100,
          parser: :integer
        ],
        protector_ask_target: [
          long: "--protector-ask-target",
          help: ":target setting in milliseconds for sprotector_pie_meter's ask queue",
          required: false,
          default: 100,
          parser: :integer
        ],
        protector_ask_interval: [
          long: "--protector-ask-interval",
          help: ":interval setting in milliseconds for sprotector_pie_meter's ask queue",
          required: false,
          default: 1000,
          parser: :integer
        ],
        protector_ask_r_target: [
          long: "--protector-ask-r-target",
          help: ":target setting in milliseconds for sprotector_pie_meter's ask_r queue",
          required: false,
          default: 100,
          parser: :integer
        ],
        protector_ask_r_interval: [
          long: "--protector-ask-r-interval",
          help: ":interval setting in milliseconds for sprotector_pie_meter's ask_r queue",
          required: false,
          default: 1000,
          parser: :integer
        ],
        protector_update: [
          long: "--protector-update",
          help: ":update setting in milliseconds for sprotector_pie_meter",
          required: false,
          default: 100,
          parser: :integer
        ],
        protector_min: [
          long: "--protector-min",
          help: ":min setting for sprotector_pie_meter",
          required: false,
          default: 0,
          parser: :integer
        ],
        protector_max: [
          long: "--protector-max",
          help: ":max setting for sprotector_pie_meter",
          required: false,
          default: :infinity,
          parser: :integer
        ]
      ],
      flags: [
        enable_protector: [
          short: "-p",
          long: "--enable-protector",
          help:
            "Route requests to :sregulator through :sprotector which acts as a circuit breaker",
          multiple: false
        ],
        show_config: [
          long: "--show-config",
          help: "Print simulation config before running the simulation",
          multiple: false
        ]
      ]
    ]
  end

  defp enum_parser(allowed_values_map, transformer) do
    &parse_enum_value(allowed_values_map, &1, transformer)
  end

  defp parse_enum_value(allowed_values, value, transformer) do
    if value in allowed_values do
      {:ok, transformer.(value)}
    else
      {:error, "allowed values are [ #{Enum.join(allowed_values, ", ")} ]"}
    end
  end
end
