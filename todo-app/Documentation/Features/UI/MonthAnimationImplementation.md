# Month Animation Implementation

## Current Implementation

The app currently uses a custom `MonthAnimator` component to create a smooth bottom-to-top animation effect for both the month and year in the Upcoming view. This implementation has several advantages:

- Works without external dependencies
- Provides a smooth, professional animation
- Supports both word-based and character-by-character animation
- Visually similar to the AtBottomTopEffect from the AnimateText library

## Integrating the AnimateText Library (Future)

To integrate the AnimateText library and use its AtBottomTopEffect animation:

1. Open the project in Xcode

2. Add the AnimateText dependency to the project using one of these methods:
   - **Using Swift Package Manager in Xcode**:
     - File > Add Package Dependencies...
     - Enter URL: `https://github.com/jasudev/AnimateText.git`
     - Select branch: `main`
     - Click Add Package
   
   - **Or by manually editing Package.swift**:
     ```swift
     dependencies: [
         .package(url: "https://github.com/jasudev/AnimateText.git", .branch("main"))
     ],
     targets: [
         .executableTarget(
             name: "TodoApp",
             dependencies: [
                 .product(name: "AnimateText", package: "AnimateText")
             ],
             // ...
         ),
     ]
     ```

3. Let Xcode resolve the package dependencies

4. Update the MonthHeaderView to use the AnimateText library:
   ```swift
   import SwiftUI
   import AnimateText

   struct MonthHeaderView: View {
       // ...
       var body: some View {
           HStack(spacing: 8) {
               // Month name with animation
               AnimatedText(
                   text: currentMonthName,
                   animationType: .atBottomTopEffect(
                       base: .word,           // Animate the month name as a single word
                       height: 30,            // Vertical movement distance
                       duration: 0.3,         // Animation duration
                       delayFactor: 0,        // No delay since we're animating by word
                       easingFunction: .easeInOut
                   )
               )
               .font(.system(size: 24, weight: .bold))
               
               // Year - also animated
               AnimatedText(
                   text: currentYearString,
                   animationType: .atBottomTopEffect(
                       base: .word,
                       height: 30,
                       duration: 0.3,
                       delayFactor: 0,
                       easingFunction: .easeInOut
                   )
               )
               .font(.system(size: 24, weight: .bold))
           }
           // ...
       }
   }
   ```

5. Test the animation by running the app and changing months in the Upcoming view

## Comparison

The custom `MonthAnimator` provides a similar visual effect to the AnimateText library's AtBottomTopEffect, with both the month and year animating from bottom to top with a fade-in effect. The main differences are:

- The AnimateText library has more sophisticated animation options and timing controls
- The library allows for more complex text animations beyond what our custom implementation provides
- The custom implementation is more tightly integrated with our codebase and doesn't require external dependencies

For the specific requirement of animating the month name in the Upcoming view, both implementations achieve a similar visual result.
