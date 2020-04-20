defmodule Schedule do
  @moduledoc """
  Object representing the scheduling of a data ingestion pipeline. Use `new/1` to
  create a new instance.

  ## Init options

  * `id` - ID of this instance of a schedule. Typically a UUID.
  * `dataset_id` - Dataset identifier.
  * `subset_id` - Dataset's subset identifier.
  * `cron` - Crontab string for pipeline cadence. Supports basic or
  [extended](https://hexdocs.pm/crontab/basic-usage.html#content) formats.
  * `compaction_cron` - Crontab string for table compaction cadence. Supports basic
  or extended formats. See
  [Presto.Table.Compactor](../../definition_presto/lib/presto/table/compactor.ex) for
  more information on table compaction.
  * `extract` - `Extract` event struct to send based on `cron` value.
  * `transform` - `Transform` event struct to send based on `cron` value.
  * `transform` - `Transform` event struct to send based on `cron` value.
  * `load` - List of `Load` event structs to send based on `cron` value.
  """
  use Definition, schema: Schedule.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          cron: String.t(),
          compaction_cron: String.t(),
          extract: Extract.t(),
          transform: Transform.t(),
          load: list
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            cron: nil,
            compaction_cron: "@default",
            extract: nil,
            transform: nil,
            load: []
end
