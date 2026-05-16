//
//  LLMService.swift
//  WSHackathonApp
//

import Foundation

struct LLMRecommendation: Codable {
    let productId: String
    let reason: String
}

struct LLMResponse: Codable {
    let recommendations: [LLMRecommendation]
}

class LLMService {
    static let shared = LLMService()
    
    // Hardcoded for hackathon speed
    private let apiKey = "AIzaSyBc_UYgErmUDPZrKb1u5_S26mhdJMFT2z8"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func fetchSmartPairings(currentCartItems: [String], catalog: [ProductItemDTO]) async throws -> [LLMRecommendation] {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let cartItemsString = currentCartItems.joined(separator: ", ")
        let catalogString = catalog.map { "- \($0.name) (ID: \($0.id))" }.joined(separator: "\n")
        
        let prompt = """
        You are an expert Williams Sonoma culinary advisor.
        The user currently has these items in their cart: [\(cartItemsString)]
        
        Based on what they already have, recommend exactly 2 complementary items from this catalog:
        \(catalogString)
        
        Respond ONLY in valid JSON format matching this structure perfectly. Do not include markdown code blocks like ```json.
        {
          "recommendations": [
             { "productId": "id from catalog", "reason": "Why it pairs perfectly with what they have" }
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Error Status: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Gemini API Error Response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Parse Gemini response structure
        struct GeminiResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable {
                        let text: String
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard var jsonText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        // Clean up any markdown formatting the LLM might have included
        jsonText = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonText.hasPrefix("```json") {
            jsonText = String(jsonText.dropFirst(7))
        } else if jsonText.hasPrefix("```") {
            jsonText = String(jsonText.dropFirst(3))
        }
        if jsonText.hasSuffix("```") {
            jsonText = String(jsonText.dropLast(3))
        }
        
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        let llmResponse = try JSONDecoder().decode(LLMResponse.self, from: jsonData)
        return llmResponse.recommendations
    }
}
