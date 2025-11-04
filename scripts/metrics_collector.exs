#!/usr/bin/env elixir

# AI Self-Improvement: Metrics Collector
# This script collects various code metrics and stores them for trend analysis

defmodule MetricsCollector do
  @moduledoc """
  Collects and analyzes code metrics for quality tracking.
  """

  def run do
    IO.puts("🔬 Collecting Code Metrics...")
    IO.puts("")

    metrics = %{
      timestamp: DateTime.utc_now() |> DateTime.to_string(),
      code_stats: collect_code_stats(),
      test_stats: collect_test_stats(),
      documentation_stats: collect_documentation_stats(),
      complexity_stats: collect_complexity_stats(),
      dependency_stats: collect_dependency_stats()
    }

    save_metrics(metrics)
    print_summary(metrics)

    IO.puts("")
    IO.puts("✅ Metrics collection complete!")
  end

  defp collect_code_stats do
    lib_files = find_files("lib", ".ex")
    test_files = find_files("test", ".exs")

    %{
      total_modules: length(lib_files),
      total_test_files: length(test_files),
      total_lib_lines: count_total_lines(lib_files),
      total_test_lines: count_total_lines(test_files),
      average_module_size: average_lines(lib_files)
    }
  end

  defp collect_test_stats do
    lib_files = find_files("lib", ".ex")
    test_files = find_files("test", ".exs")

    modules_with_tests =
      Enum.count(lib_files, fn lib_file ->
        test_file = lib_to_test_path(lib_file)
        File.exists?(test_file)
      end)

    %{
      modules_with_tests: modules_with_tests,
      modules_without_tests: length(lib_files) - modules_with_tests,
      test_coverage_percentage: calculate_coverage_percentage(modules_with_tests, length(lib_files))
    }
  end

  defp collect_documentation_stats do
    lib_files = find_files("lib", ".ex")

    documented_modules =
      Enum.count(lib_files, fn file ->
        file
        |> File.read!()
        |> String.contains?("@moduledoc")
      end)

    total_public_functions =
      Enum.reduce(lib_files, 0, fn file, acc ->
        content = File.read!(file)
        count = count_occurrences(content, ~r/^\s*def\s+/)
        acc + count
      end)

    total_docs =
      Enum.reduce(lib_files, 0, fn file, acc ->
        content = File.read!(file)
        count = count_occurrences(content, ~r/@doc\s+/)
        acc + count
      end)

    total_specs =
      Enum.reduce(lib_files, 0, fn file, acc ->
        content = File.read!(file)
        count = count_occurrences(content, ~r/@spec\s+/)
        acc + count
      end)

    %{
      documented_modules: documented_modules,
      documentation_coverage: calculate_coverage_percentage(documented_modules, length(lib_files)),
      total_public_functions: total_public_functions,
      documented_functions: total_docs,
      function_doc_coverage: calculate_coverage_percentage(total_docs, total_public_functions),
      functions_with_specs: total_specs,
      spec_coverage: calculate_coverage_percentage(total_specs, total_public_functions)
    }
  end

  defp collect_complexity_stats do
    lib_files = find_files("lib", ".ex")

    long_functions =
      Enum.reduce(lib_files, 0, fn file, acc ->
        # Simple heuristic for long functions
        content = File.read!(file)
        lines = String.split(content, "\n")

        long_func_count =
          lines
          |> Enum.chunk_while(
            nil,
            fn line, acc ->
              cond do
                String.match?(line, ~r/^\s*def\s+/) -> {:cont, 0}
                String.match?(line, ~r/^\s*end\s*$/) -> if acc && acc > 50, do: {:cont, 1, nil}, else: {:cont, nil}
                acc != nil -> {:cont, acc + 1}
                true -> {:cont, acc}
              end
            end,
            fn acc -> {:cont, acc, []} end
          )
          |> Enum.filter(&(&1 == 1))
          |> length()

        acc + long_func_count
      end)

    todo_count =
      Enum.reduce(lib_files, 0, fn file, acc ->
        content = File.read!(file)
        count = count_occurrences(content, ~r/TODO|FIXME/)
        acc + count
      end)

    %{
      long_functions: long_functions,
      todo_fixme_comments: todo_count
    }
  end

  defp collect_dependency_stats do
    mix_exs_path = "mix.exs"

    if File.exists?(mix_exs_path) do
      content = File.read!(mix_exs_path)

      # Simple count of dependencies
      dep_count = count_occurrences(content, ~r/\{:[\w_]+,/)

      %{
        total_dependencies: dep_count,
        mix_exs_exists: true
      }
    else
      %{
        total_dependencies: 0,
        mix_exs_exists: false
      }
    end
  end

  defp find_files(dir, extension) do
    if File.dir?(dir) do
      Path.wildcard("#{dir}/**/*#{extension}")
    else
      []
    end
  end

  defp count_total_lines(files) do
    Enum.reduce(files, 0, fn file, acc ->
      lines = File.read!(file) |> String.split("\n") |> length()
      acc + lines
    end)
  end

  defp average_lines(files) do
    if length(files) > 0 do
      total = count_total_lines(files)
      Float.round(total / length(files), 2)
    else
      0
    end
  end

  defp lib_to_test_path(lib_file) do
    lib_file
    |> String.replace("lib/", "test/")
    |> String.replace(".ex", "_test.exs")
  end

  defp calculate_coverage_percentage(count, total) when total > 0 do
    Float.round(count / total * 100, 2)
  end

  defp calculate_coverage_percentage(_, _), do: 0.0

  defp count_occurrences(string, regex) do
    case Regex.scan(regex, string) do
      matches when is_list(matches) -> length(matches)
      _ -> 0
    end
  end

  defp save_metrics(metrics) do
    # Create metrics directory if it doesn't exist
    File.mkdir_p!(".metrics")

    # Save as JSON
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    filename = ".metrics/metrics_#{timestamp}.json"

    json =
      Jason.encode!(metrics, pretty: true)

    File.write!(filename, json)
    IO.puts("📊 Metrics saved to: #{filename}")
  end

  defp print_summary(metrics) do
    IO.puts("")
    IO.puts("=" |> String.duplicate(50))
    IO.puts("METRICS SUMMARY")
    IO.puts("=" |> String.duplicate(50))
    IO.puts("")

    IO.puts("📝 Code Statistics:")
    IO.puts("  • Total modules: #{metrics.code_stats.total_modules}")
    IO.puts("  • Total test files: #{metrics.code_stats.total_test_files}")
    IO.puts("  • Production lines: #{metrics.code_stats.total_lib_lines}")
    IO.puts("  • Test lines: #{metrics.code_stats.total_test_lines}")
    IO.puts("  • Average module size: #{metrics.code_stats.average_module_size} lines")

    IO.puts("")
    IO.puts("🧪 Test Statistics:")
    IO.puts("  • Modules with tests: #{metrics.test_stats.modules_with_tests}")
    IO.puts("  • Modules without tests: #{metrics.test_stats.modules_without_tests}")
    IO.puts("  • Test coverage: #{metrics.test_stats.test_coverage_percentage}%")

    IO.puts("")
    IO.puts("📚 Documentation Statistics:")
    IO.puts("  • Documented modules: #{metrics.documentation_stats.documented_modules}")
    IO.puts("  • Module doc coverage: #{metrics.documentation_stats.documentation_coverage}%")
    IO.puts("  • Public functions: #{metrics.documentation_stats.total_public_functions}")
    IO.puts("  • Function doc coverage: #{metrics.documentation_stats.function_doc_coverage}%")
    IO.puts("  • Type spec coverage: #{metrics.documentation_stats.spec_coverage}%")

    IO.puts("")
    IO.puts("🔍 Complexity Statistics:")
    IO.puts("  • Long functions (>50 lines): #{metrics.complexity_stats.long_functions}")
    IO.puts("  • TODO/FIXME comments: #{metrics.complexity_stats.todo_fixme_comments}")

    IO.puts("")
    IO.puts("📦 Dependency Statistics:")
    IO.puts("  • Total dependencies: #{metrics.dependency_stats.total_dependencies}")

    IO.puts("")
    IO.puts("=" |> String.duplicate(50))
  end
end

# Ensure Jason is available (for JSON encoding)
# In a real scenario, this would be in mix.exs dependencies
Code.ensure_loaded?(Jason) || IO.puts("Warning: Jason not available for JSON encoding")

# Run the collector
MetricsCollector.run()
