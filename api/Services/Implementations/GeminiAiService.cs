using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class GeminiAiService : IAiService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GeminiAiService> _logger;

    public GeminiAiService(HttpClient httpClient, IConfiguration configuration, ILogger<GeminiAiService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<ListingGenerationResponse> GenerateListingFromImageAsync(string? imageUrl, string? categoryHint)
    {
        string geminiKey = _configuration["GeminiSettings:ApiKey"] ?? string.Empty;
        string groqKey = _configuration["GroqSettings:ApiKey"] ?? string.Empty;

        // Try downloading image first if URL provided
        string base64Image = string.Empty;
        string mimeType = "image/jpeg";
        if (!string.IsNullOrEmpty(imageUrl))
        {
            try
            {
                var imageBytes = await _httpClient.GetByteArrayAsync(imageUrl);
                base64Image = Convert.ToBase64String(imageBytes);
                if (imageUrl.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                {
                    mimeType = "image/png";
                }
                else if (imageUrl.EndsWith(".webp", StringComparison.OrdinalIgnoreCase))
                {
                    mimeType = "image/webp";
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, $"Failed to download image from '{imageUrl}' for AI analysis. Falling back to metadata-only generation.");
            }
        }

        string systemInstruction = @"You are an expert equipment rental assistant for 'RentLanka' in Sri Lanka.
Analyze the uploaded image of the equipment and generate listing metadata. If no image is provided, generate it based on the category hint and prompt details.
Return strict JSON format matching this schema:
{
  ""title"": ""Clear, concise title of the item"",
  ""description"": ""Engaging description detailing key features, condition, and what is included"",
  ""category"": ""One of these exact categories: Photography, Camping, Electronics, Tools, Fashion, Sports & Outdoors, Books, Other"",
  ""suggestedPricePerDay"": 1500.00,
  ""suggestedSecurityDeposit"": 5000.00
}
Rules:
- Do not hallucinate brand models unless clearly visible in the image.
- Category must be one of the listed categories.
- Prices must be realistic Sri Lankan Rupees (LKR) for renting such equipment daily.
- Only return the raw JSON object.";

        string prompt = $"Generate listing details. Category hint: {categoryHint ?? "None"}. Image URL: {imageUrl ?? "None"}.";

        // Try Gemini First
        if (!string.IsNullOrEmpty(geminiKey))
        {
            try
            {
                _logger.LogInformation("Attempting to generate listing details using Google Gemini...");
                var response = await CallGeminiAsync(geminiKey, systemInstruction, prompt, base64Image, mimeType);
                if (response != null)
                {
                    return response;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gemini API call failed. Trying Groq fallback...");
            }
        }

        // Try Groq Fallback
        if (!string.IsNullOrEmpty(groqKey))
        {
            try
            {
                _logger.LogInformation("Attempting to generate listing details using Groq...");
                var response = await CallGroqListingAsync(groqKey, systemInstruction, prompt, base64Image, mimeType);
                if (response != null)
                {
                    return response;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Groq API call failed. Falling back to Mock generator...");
            }
        }

        // Ultimate Mock Fallback
        _logger.LogWarning("AI keys missing or failed. Generating mock listing details...");
        return GenerateMockListing(imageUrl, categoryHint);
    }

    public async Task<List<SemanticSearchResult>> SemanticSearchAsync(string query, List<ListingSearchSummaryDto> listings)
    {
        if (listings == null || listings.Count == 0)
        {
            return new List<SemanticSearchResult>();
        }

        string geminiKey = _configuration["GeminiSettings:ApiKey"] ?? string.Empty;
        string groqKey = _configuration["GroqSettings:ApiKey"] ?? string.Empty;

        string systemInstruction = @"You are the search ranking engine for 'RentLanka' equipment rentals in Sri Lanka.
Your task is to match the user's natural language search query against the list of available rental listings provided in JSON format.
Analyze the user's intent, requirements (e.g. location/district, category, type of item, daily price range), and match them against the listings.

Return a JSON array of objects representing matching listings, ordered by relevance (matchScore from 0.0 to 1.0).
Only include listings that are genuinely relevant (matchScore >= 0.5).
JSON Output Schema:
[
  {
    ""listingId"": ""GUID"",
    ""matchScore"": 0.95,
    ""reason"": ""Explain briefly in 1 sentence why this matches the user query (e.g. 'This is a premium surfboard located in Matara district near Hiriketiya').""
  }
]
Rules:
- Never return any listing ID that is not present in the input listings.
- Only return the raw JSON array. Do not wrap in markdown fences.";

        string prompt = $"Search Query: \"{query}\"\nAvailable Listings:\n{JsonSerializer.Serialize(listings)}";

        // Try Gemini First
        if (!string.IsNullOrEmpty(geminiKey))
        {
            try
            {
                _logger.LogInformation("Attempting semantic search using Google Gemini...");
                var results = await CallGeminiSearchAsync(geminiKey, systemInstruction, prompt);
                if (results != null)
                {
                    return results;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gemini API semantic search failed. Trying Groq fallback...");
            }
        }

        // Try Groq Fallback
        if (!string.IsNullOrEmpty(groqKey))
        {
            try
            {
                _logger.LogInformation("Attempting semantic search using Groq...");
                var results = await CallGroqSearchAsync(groqKey, systemInstruction, prompt);
                if (results != null)
                {
                    return results;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Groq API semantic search failed. Falling back to Mock keyword search...");
            }
        }

        // Mock Keyword Fallback (Zero Hallucination, completely offline)
        _logger.LogWarning("AI keys missing or failed. Performing mock keyword search filtering...");
        return RunMockSearch(query, listings);
    }

    #region Gemini API Helper Methods

    private async Task<ListingGenerationResponse?> CallGeminiAsync(string apiKey, string systemInstruction, string prompt, string base64Image, string mimeType)
    {
        string model = _configuration["GeminiSettings:Model"] ?? "gemini-2.5-flash";
        string url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

        var parts = new List<object> { new { text = prompt } };
        if (!string.IsNullOrEmpty(base64Image))
        {
            parts.Add(new
            {
                inlineData = new
                {
                    mimeType = mimeType,
                    data = base64Image
                }
            });
        }

        var requestBody = new
        {
            system_instruction = new
            {
                parts = new[] { new { text = systemInstruction } }
            },
            contents = new[]
            {
                new { parts = parts.ToArray() }
            },
            generationConfig = new
            {
                responseMimeType = "application/json"
            }
        };

        var response = await _httpClient.PostAsJsonAsync(url, requestBody);
        response.EnsureSuccessStatusCode();

        var jsonRes = await response.Content.ReadFromJsonAsync<JsonElement>();
        var text = jsonRes.GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        if (string.IsNullOrEmpty(text)) return null;

        return JsonSerializer.Deserialize<ListingGenerationResponse>(text, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    private async Task<List<SemanticSearchResult>?> CallGeminiSearchAsync(string apiKey, string systemInstruction, string prompt)
    {
        string model = _configuration["GeminiSettings:Model"] ?? "gemini-2.5-flash";
        string url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

        var requestBody = new
        {
            system_instruction = new
            {
                parts = new[] { new { text = systemInstruction } }
            },
            contents = new[]
            {
                new { parts = new[] { new { text = prompt } } }
            },
            generationConfig = new
            {
                responseMimeType = "application/json"
            }
        };

        var response = await _httpClient.PostAsJsonAsync(url, requestBody);
        response.EnsureSuccessStatusCode();

        var jsonRes = await response.Content.ReadFromJsonAsync<JsonElement>();
        var text = jsonRes.GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        if (string.IsNullOrEmpty(text)) return null;

        return JsonSerializer.Deserialize<List<SemanticSearchResult>>(text, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    #endregion

    #region Groq API Helper Methods

    private async Task<ListingGenerationResponse?> CallGroqListingAsync(string apiKey, string systemInstruction, string prompt, string base64Image, string mimeType)
    {
        string model = _configuration["GroqSettings:Model"] ?? "llama-3.3-70b-versatile";
        
        // If image exists, switch to llama-3.2-11b-vision-preview automatically
        if (!string.IsNullOrEmpty(base64Image))
        {
            model = "llama-3.2-11b-vision-preview";
        }

        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

        object userContent;
        if (!string.IsNullOrEmpty(base64Image))
        {
            userContent = new object[]
            {
                new { type = "text", text = prompt },
                new { type = "image_url", image_url = new { url = $"data:{mimeType};base64,{base64Image}" } }
            };
        }
        else
        {
            userContent = prompt;
        }

        var requestBody = new
        {
            model = model,
            messages = new[]
            {
                new { role = "system", content = (object)systemInstruction },
                new { role = "user", content = (object)userContent }
            },
            response_format = new { type = "json_object" }
        };

        request.Content = JsonContent.Create(requestBody);
        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var jsonRes = await response.Content.ReadFromJsonAsync<JsonElement>();
        var text = jsonRes.GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrEmpty(text)) return null;

        return JsonSerializer.Deserialize<ListingGenerationResponse>(text, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    private async Task<List<SemanticSearchResult>?> CallGroqSearchAsync(string apiKey, string systemInstruction, string prompt)
    {
        string model = _configuration["GroqSettings:Model"] ?? "llama-3.3-70b-versatile";

        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

        var requestBody = new
        {
            model = model,
            messages = new[]
            {
                new { role = "system", content = systemInstruction },
                new { role = "user", content = prompt }
            },
            response_format = new { type = "json_object" }
        };

        request.Content = JsonContent.Create(requestBody);
        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var jsonRes = await response.Content.ReadFromJsonAsync<JsonElement>();
        var text = jsonRes.GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrEmpty(text)) return null;

        // Groq returns JSON object, wrap if needed but if schema is list we can parse directly
        return JsonSerializer.Deserialize<List<SemanticSearchResult>>(text, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }

    #endregion

    #region Mock Fallback Implementation

    private ListingGenerationResponse GenerateMockListing(string? imageUrl, string? categoryHint)
    {
        string titleHint = string.Empty;
        if (!string.IsNullOrEmpty(imageUrl))
        {
            titleHint = Path.GetFileNameWithoutExtension(imageUrl).ToLower();
        }
        if (!string.IsNullOrEmpty(categoryHint))
        {
            titleHint += " " + categoryHint.ToLower();
        }

        if (titleHint.Contains("camera") || titleHint.Contains("photo") || titleHint.Contains("dslr"))
        {
            return new ListingGenerationResponse(
                Title: "Canon EOS R5 DSLR Camera",
                Description: "High-performance full-frame mirrorless camera. 45 Megapixels, 8K video recording, excellent low-light capability. Package includes body, 24-105mm F4 lens, lens hood, 2 batteries, and a 128GB memory card. Perfect for wedding shoots, cinematography, and wildlife photography.",
                Category: "Photography",
                SuggestedPricePerDay: 4500.00m,
                SuggestedSecurityDeposit: 15000.00m
            );
        }
        else if (titleHint.Contains("tent") || titleHint.Contains("camping") || titleHint.Contains("outdoor") || titleHint.Contains("camp"))
        {
            return new ListingGenerationResponse(
                Title: "Coleman 4-Person Waterproof Camping Tent",
                Description: "Durable dome tent with WeatherTec system to keep you dry. Spacious interior fits up to 4 sleeping bags. Easy setup in less than 10 minutes. Features mesh ventilation windows and storage pockets. Perfect for camping in Ella, Knuckles, or Horton Plains.",
                Category: "Camping",
                SuggestedPricePerDay: 1200.00m,
                SuggestedSecurityDeposit: 4000.00m
            );
        }
        else if (titleHint.Contains("drill") || titleHint.Contains("tool") || titleHint.Contains("hammer") || titleHint.Contains("saw"))
        {
            return new ListingGenerationResponse(
                Title: "Bosch Cordless Rotary Hammer Drill",
                Description: "Heavy-duty 18V cordless rotary hammer drill. Offers high drilling rates and chiseling power. Ergonomic handle design. Includes carrying case, battery charger, and 3 drill bits. Ideal for DIY renovations and light construction work.",
                Category: "Tools",
                SuggestedPricePerDay: 1800.00m,
                SuggestedSecurityDeposit: 5000.00m
            );
        }
        else
        {
            return new ListingGenerationResponse(
                Title: "Premium Equipment for Rent",
                Description: "Top-grade equipment in pristine condition, fully serviced and checked. Reliable performance for your personal or commercial requirements. Flexible daily rental terms. Contact owner for custom extensions.",
                Category: "Other",
                SuggestedPricePerDay: 2000.00m,
                SuggestedSecurityDeposit: 8000.00m
            );
        }
    }

    private List<SemanticSearchResult> RunMockSearch(string query, List<ListingSearchSummaryDto> listings)
    {
        var results = new List<SemanticSearchResult>();
        string lowerQuery = query.ToLower();

        foreach (var l in listings)
        {
            double score = 0.0;
            string reason = string.Empty;

            // 1. Check exact contains
            if (l.Title.ToLower().Contains(lowerQuery) || l.Description.ToLower().Contains(lowerQuery))
            {
                score = 0.95;
                reason = $"Found exact match for '{query}' in listing details.";
            }
            else if (l.Category.ToLower().Contains(lowerQuery))
            {
                score = 0.85;
                reason = $"Category '{l.Category}' matches search query.";
            }
            else
            {
                // 2. Perform word-by-word fuzzy matching (handles spelling errors like 'camara' -> 'camera')
                var queryWords = lowerQuery.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                var titleWords = l.Title.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
                var descWords = l.Description.ToLower().Split(new[] { ' ', '.', ',', '!', '?' }, StringSplitOptions.RemoveEmptyEntries);
                var allWords = titleWords.Concat(descWords).Distinct().ToList();

                double maxWordScore = 0.0;
                string bestMatchText = "";

                foreach (var qw in queryWords)
                {
                    if (qw.Length < 3) continue;

                    foreach (var tw in allWords)
                    {
                        if (tw.Length < 3) continue;

                        int distance = LevenshteinDistance(qw, tw);
                        int maxLen = Math.Max(qw.Length, tw.Length);
                        
                        // Allow 1 typo for short words, 2 typos for words > 5 letters
                        int allowedDiff = qw.Length > 5 ? 2 : 1;
                        if (distance <= allowedDiff)
                        {
                            double similarity = 1.0 - ((double)distance / maxLen);
                            double wordScore = 0.50 + (similarity * 0.40); // Max score 0.90
                            if (wordScore > maxWordScore)
                            {
                                maxWordScore = wordScore;
                                bestMatchText = $"'{qw}' (matched with '{tw}')";
                            }
                        }
                    }
                }

                if (maxWordScore >= 0.50)
                {
                    score = maxWordScore;
                    reason = $"Semantic match: {bestMatchText}.";
                }
            }

            if (score >= 0.5)
            {
                results.Add(new SemanticSearchResult(l.Id, score, reason));
            }
        }

        return results.OrderByDescending(r => r.MatchScore).ToList();
    }

    private int LevenshteinDistance(string s, string t)
    {
        if (string.IsNullOrEmpty(s)) return string.IsNullOrEmpty(t) ? 0 : t.Length;
        if (string.IsNullOrEmpty(t)) return s.Length;

        int n = s.Length;
        int m = t.Length;
        int[,] d = new int[n + 1, m + 1];

        for (int i = 0; i <= n; d[i, 0] = i++) ;
        for (int j = 0; j <= m; d[0, j] = j++) ;

        for (int i = 1; i <= n; i++)
        {
            for (int j = 1; j <= m; j++)
            {
                int cost = (t[j - 1] == s[i - 1]) ? 0 : 1;
                d[i, j] = Math.Min(
                    Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1),
                    d[i - 1, j - 1] + cost);
            }
        }
        return d[n, m];
    }

    #endregion
}
