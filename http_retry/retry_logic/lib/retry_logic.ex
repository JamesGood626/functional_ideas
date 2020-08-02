defmodule RetryLogic do
  @moduledoc """
  Documentation for `RetryLogic`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RetryLogic.hello()
      :world

  """
  def test do
    # Without delays
    make_http_request_with_retries(
      fn -> HTTPoison.get("http://localhost:3000/") end,
      3
    )

    # With delays
    make_http_request_with_retries(
      [
        fn -> HTTPoison.get("http://localhost:3000/") end,
        fn -> Process.sleep(2000) end
      ],
      3
    )
  end

  def replicate(x, n), do: for(_x <- 1..n, do: x)

  def make_http_request_with_retries(func, n_retries) do
    replicate(func, n_retries)
    |> make_http_request(n_retries)
  end

  # 1. make request and either return body of success result or notify retries failed
  def make_http_request([[http_func, _delay_func] | []], n_retries) do
    http_func.()
    |> parse_response
    |> retry_decision(n_retries, :last_retry)
  end

  def make_http_request([http_func | []], n_retries) do
    http_func.()
    |> parse_response
    |> retry_decision(n_retries, :last_retry)
  end

  def make_http_request([[http_func, delay_func] | xs], n_retries) do
    http_func.()
    |> parse_response
    |> retry_decision(n_retries, xs, {:delay, delay_func})
  end

  # 2. make request and either return body of success result or detect failure and recursively
  #    invoke itself with the rest of the functions.
  def make_http_request([http_func | xs], n_retries) do
    http_func.()
    |> parse_response
    |> retry_decision(n_retries, xs)
  end

  # TODO: This can probably be refined.
  def parse_response(res) do
    case res do
      {:ok,
       %HTTPoison.Response{
         body: body,
         status_code: 200
       }} ->
        {:ok, Jason.decode!(body)}

      _ ->
        {:err, "API_REQUEST_FAILED"}
    end
  end

  def retry_decision({:ok, body}, __n_retries, _funcs), do: {:ok, body}
  def retry_decision({:ok, body}, _n_retries, :last_retry), do: {:ok, body}

  def retry_decision({:err, _msg}, n_retries, funcs) when is_list(funcs) do
    make_http_request(funcs, n_retries)
  end

  def retry_decision({:err, _msg}, n_retries, :last_retry) do
    # Potentially log:
    # request_url
    # status_code
    {:err, "API requests failed after #{n_retries} retries"}
  end

  def retry_decision({:ok, body}, _n_retries, _funcs, {:delay, _delay_func}) do
    {:ok, body}
  end

  def retry_decision({:err, msg}, n_retries, funcs, {:delay, delay_func}) do
    delay_func.()
    retry_decision({:err, msg}, n_retries, funcs)
  end
end
