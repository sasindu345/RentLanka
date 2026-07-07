using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Serilog.Context;

namespace RentLanka.Api.Middleware;

public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private const string CorrelationIdHeaderKey = "X-Correlation-ID";

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // 1. Generate or extract correlation ID from incoming request headers
        string correlationId;
        if (context.Request.Headers.TryGetValue(CorrelationIdHeaderKey, out var headerValue) && !string.IsNullOrWhiteSpace(headerValue))
        {
            correlationId = headerValue.ToString();
        }
        else
        {
            correlationId = Guid.NewGuid().ToString();
        }

        // 2. Set Correlation ID in the current HTTP Response context headers
        context.Response.OnStarting(() =>
        {
            if (!context.Response.Headers.ContainsKey(CorrelationIdHeaderKey))
            {
                context.Response.Headers[CorrelationIdHeaderKey] = correlationId;
            }
            return Task.CompletedTask;
        });

        // 3. Push Correlation ID into Serilog LogContext so that all child logs capture it automatically
        using (LogContext.PushProperty("CorrelationId", correlationId))
        {
            await _next(context);
        }
    }
}
