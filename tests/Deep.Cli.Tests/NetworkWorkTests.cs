using System.Net;
using System.Net.Sockets;
using System.Text.Json;

namespace Deep.Cli.Tests;

public sealed class NetworkWorkTests
{
    [Fact]
    public async Task RealHttpStartStopAreCorrelatedWithoutExportingUrl()
    {
        using var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        var serve = Task.Run(async () =>
        {
            using var socket = await listener.AcceptTcpClientAsync(deadline.Token);
            using var stream = socket.GetStream();
            var buffer = new byte[4096];
            var length = await stream.ReadAsync(buffer, deadline.Token);
            var headers = System.Text.Encoding.ASCII.GetString(buffer, 0, length);
            Assert.DoesNotContain("traceparent:", headers, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("tracestate:", headers, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("Request-ID:", headers, StringComparison.OrdinalIgnoreCase);
            await stream.WriteAsync("HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"u8.ToArray(), deadline.Token);
        }, deadline.Token);
        using var work = new NetworkWork();
        using var handler = new SocketsHttpHandler { UseProxy = false };
        using var client = new HttpClient(handler);
        using var response = await client.GetAsync($"http://127.0.0.1:{port}/api/ingress/v1/frame?DO-NOT-EXPORT", deadline.Token);
        await serve;
        var json = JsonSerializer.Serialize(work.Snapshot());
        Assert.DoesNotContain("127.0.0.1", json);
        Assert.DoesNotContain("DO-NOT-EXPORT", json);
        using var parsed = JsonDocument.Parse(json);
        var row = parsed.RootElement.EnumerateArray().Single(x => x.GetProperty("group").GetString() == "Other");
        Assert.True(row.GetProperty("started").GetInt64() >= 1);
        Assert.True(row.GetProperty("completed").GetInt64() >= 1);
        Assert.True(row.GetProperty("nonSuccess").GetInt64() >= 1);
    }
}
