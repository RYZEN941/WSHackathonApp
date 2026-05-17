import Foundation
import Combine
import SwiftUI

@MainActor
final class RecipeViewModel: ObservableObject {
    
    // MARK: - Inputs
    let recipe: Recipe
    
    // MARK: - Outputs
    @Published private(set) var recommendation: RecipeRecommendation?
    @Published private(set) var isAnalyzing = false
    
    // MARK: - Dependencies
    private let aiService = FoundationModelService.shared
    private let catalogService = ProductCatalogService.shared
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    // MARK: - Actions
    
    func analyzeRecipe() async {
        guard recommendation == nil else { return } // Already analyzed
        
        isAnalyzing = true
        
        // Ensure catalog is loaded
        await catalogService.loadIfNeeded()
        
        let result = await aiService.generateRecipeRecommendations(
            recipe: recipe,
            allProducts: catalogService.products
        )
        
        // Artificial delay for better UI feeling of "AI thinking"
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        withAnimation(.spring(response: 0.5)) {
            self.recommendation = result
            self.isAnalyzing = false
        }
    }
}
