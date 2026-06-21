using System;

namespace RentLanka.Api.Models.Requests;

public record PayoutRequest(
    decimal Amount,
    string BankName,
    string AccountNumber,
    string AccountName);
