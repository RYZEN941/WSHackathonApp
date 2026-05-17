import Foundation

struct Recipe: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let author: String
    let prepTime: String
    let cookTime: String
    let servings: Int
    let imageUrl: URL?
    let ingredients: [String]
    let instructions: [String]
    
    // Mock Data
    static let mockCoqAuVin = Recipe(
        id: "recipe_coq_au_vin_001",
        title: "Classic Coq au Vin",
        subtitle: "A rustic French classic",
        description: "Chicken braised in red wine with bacon, mushrooms, and pearl onions. This hearty dish is perfect for a cozy weekend dinner and pairs beautifully with crusty bread or mashed potatoes.",
        author: "Williams Sonoma Test Kitchen",
        prepTime: "30 mins",
        cookTime: "1 hr 15 mins",
        servings: 4,
        imageUrl: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&q=80&w=1600&h=900"),
        ingredients: [
            "1 whole chicken (about 4 lbs), cut into 8 pieces",
            "Kosher salt and freshly ground black pepper",
            "1/2 lb thick-cut bacon, cut into lardons",
            "1 large onion, chopped",
            "2 carrots, peeled and sliced",
            "2 cloves garlic, minced",
            "2 tablespoons tomato paste",
            "1 bottle (750ml) dry red wine, such as Burgundy or Pinot Noir",
            "1 cup chicken broth",
            "1 bouquet garni (thyme, parsley, bay leaf)",
            "1/2 lb pearl onions, peeled",
            "1/2 lb cremini mushrooms, halved",
            "2 tablespoons unsalted butter",
            "Chopped fresh flat-leaf parsley for garnish"
        ],
        instructions: [
            "Season the chicken pieces generously with salt and pepper.",
            "In a large Dutch oven over medium heat, cook the bacon until crisp. Remove with a slotted spoon and set aside.",
            "In the same Dutch oven with the bacon fat, brown the chicken pieces on all sides in batches. Remove the chicken and set aside.",
            "Add the chopped onion and carrots to the pot and sauté until softened, about 5 minutes. Stir in the garlic and tomato paste and cook for 1 minute.",
            "Pour in the red wine and chicken broth, scraping up any browned bits from the bottom of the pot. Return the chicken and bacon to the pot along with the bouquet garni.",
            "Bring to a simmer, cover, and cook over low heat until the chicken is tender, about 45 minutes.",
            "While the chicken is cooking, melt the butter in a separate skillet over medium heat. Sauté the pearl onions and mushrooms until golden brown.",
            "Add the onions and mushrooms to the Dutch oven during the last 15 minutes of cooking.",
            "Discard the bouquet garni, garnish with fresh parsley, and serve immediately."
        ]
    )
    
    static let mockRibeye = Recipe(
        id: "recipe_ribeye_002",
        title: "Pan-Seared Ribeye",
        subtitle: "Steakhouse quality at home",
        description: "A perfectly cooked ribeye steak with a garlic-herb butter crust. The key to this recipe is a ripping hot cast-iron skillet for an unbeatable sear.",
        author: "Williams Sonoma Test Kitchen",
        prepTime: "10 mins",
        cookTime: "10 mins",
        servings: 2,
        imageUrl: URL(string: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=1600&h=900"),
        ingredients: [
            "2 bone-in ribeye steaks (about 1.5 inches thick)",
            "Kosher salt and freshly ground black pepper",
            "2 tablespoons canola oil",
            "3 tablespoons unsalted butter",
            "3 cloves garlic, crushed",
            "3 sprigs fresh thyme",
            "1 sprig fresh rosemary"
        ],
        instructions: [
            "Pat the steaks completely dry with paper towels and season generously with salt and pepper on both sides.",
            "Heat a large cast-iron skillet over high heat until smoking hot. Add the canola oil.",
            "Carefully place the steaks in the skillet and cook without moving them for 3-4 minutes to form a crust.",
            "Flip the steaks. Add the butter, garlic, thyme, and rosemary to the skillet.",
            "As the butter melts, tilt the skillet and continuously baste the steaks with the foaming butter using a spoon.",
            "Cook until an instant-read thermometer registers 130°F for medium-rare.",
            "Transfer the steaks to a cutting board and let them rest for at least 5 minutes before slicing."
        ]
    )
    
    static let mockCaprese = Recipe(
        id: "recipe_caprese_003",
        title: "Summer Caprese Salad",
        subtitle: "Fresh and vibrant",
        description: "A simple, elegant salad celebrating the best of summer produce. Ripe heirloom tomatoes, fresh mozzarella, and aromatic basil layered beautifully.",
        author: "Williams Sonoma Test Kitchen",
        prepTime: "15 mins",
        cookTime: "0 mins",
        servings: 4,
        imageUrl: URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=1600&h=900"),
        ingredients: [
            "4 large heirloom tomatoes, assorted colors",
            "1 lb fresh mozzarella cheese, sliced",
            "1 cup fresh basil leaves",
            "1/4 cup extra-virgin olive oil",
            "2 tablespoons balsamic glaze",
            "Flaky sea salt (like Maldon)",
            "Freshly ground black pepper"
        ],
        instructions: [
            "Using a sharp chef's knife and a sturdy cutting board, carefully slice the heirloom tomatoes into 1/4-inch thick rounds.",
            "Slice the fresh mozzarella into similar sized rounds.",
            "On a large serving platter, arrange the tomato and mozzarella slices in an alternating, overlapping pattern.",
            "Tuck the fresh basil leaves between the slices.",
            "Drizzle generously with the extra-virgin olive oil and balsamic glaze.",
            "Finish with a sprinkle of flaky sea salt and freshly ground black pepper."
        ]
    )
    
    static let allMocks: [Recipe] = [mockCoqAuVin, mockRibeye, mockCaprese]
}
