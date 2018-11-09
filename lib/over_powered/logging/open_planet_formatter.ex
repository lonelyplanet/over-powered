defmodule OverPowered.Logging.OpenPlanetFormatter do
  @moduledoc """
  Standard Open Planet formatter. Adapted version of Google Cloud Logger.

  More details at:
  https://github.com/lonelyplanet/open-planet/blob/develop/src/main/resources/schemas/data/log_message.json
  """

  @behaviour LoggerJSON.Formatter

  @severity_levels %{
    debug: "DEBUG",
    info: "INFO",
    warn: "WARNING",
    error: "ERROR"
  }

  @ignored_metadata_keys ~w[pid file line function module application request_id error_logger]a

  def format_event(level, msg, ts, md, md_keys) do
    Map.merge(
      %{
        "@timestamp": format_timestamp(ts),
        level: Map.get(@severity_levels, level, "INFO"),
        message: IO.iodata_to_binary(msg || "")
      },
      format_metadata(md, md_keys)
    )
  end

  defp format_metadata(md, md_keys) do
    LoggerJSON.take_metadata(md, md_keys, @ignored_metadata_keys)
    |> maybe_put(:stack_trace, format_process_crash(md))
    |> maybe_put(:logger_name, format_logger_name(md))
    |> maybe_put(:thread_name, format_thread_name(md))
    |> maybe_put(:tracetoken, format_trace_token(md))
  end

  defp format_thread_name(md) do
    if pid = Keyword.get(md, :pid) do
      stringified_pid = :erlang.pid_to_list(pid) |> to_string
      "#PID#{stringified_pid}"
    end
  end

  defp format_trace_token(md) do
    if trace_token = Keyword.get(md, :request_id) do
      trace_token
    else
      "unknown"
    end
  end

  defp format_process_crash(md) do
    if crash_reason = Keyword.get(md, :crash_reason) do
      format_crash_reason(crash_reason)
    end
  end

  defp format_crash_reason({:throw, reason}) do
    Exception.format(:throw, reason)
  end

  defp format_crash_reason({:exit, reason}) do
    Exception.format(:exit, reason)
  end

  defp format_crash_reason({%{} = exception, stacktrace}) do
    Exception.format(:error, exception, stacktrace)
  end

  defp format_logger_name(metadata) do
    if function = Keyword.get(metadata, :function) do
      module = Keyword.get(metadata, :module)

      format_function(module, function)
    else
      if initial_call = Keyword.get(metadata, :initial_call) do
        format_initial_call(initial_call)
      end
    end
  end

  defp format_initial_call(nil), do: nil
  defp format_initial_call({module, function, arity}), do: format_function(module, function, arity)

  defp format_function(nil, function), do: function
  defp format_function(module, function), do: "#{module}.#{function}"
  defp format_function(module, function, arity), do: "#{module}.#{function}/#{arity}"

  defp format_timestamp({date, time}) do
    [format_date(date), format_time(time)]
    |> Enum.map(&IO.iodata_to_binary/1)
    |> Enum.join("T")
    |> Kernel.<>("Z")
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp format_time({hh, mi, ss, ms}) do
    [pad2(hh), ?:, pad2(mi), ?:, pad2(ss), ?., pad3(ms)]
  end

  defp format_date({yy, mm, dd}) do
    [Integer.to_string(yy), ?-, pad2(mm), ?-, pad2(dd)]
  end

  defp pad3(int) when int < 10, do: [?0, ?0, Integer.to_string(int)]
  defp pad3(int) when int < 100, do: [?0, Integer.to_string(int)]
  defp pad3(int), do: Integer.to_string(int)

  defp pad2(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad2(int), do: Integer.to_string(int)
end