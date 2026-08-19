# SwiftUI Best Practices and Guidelines

## Project Structure
- **Sources**: Contains the main application files.
  - **App**: Main application files.
  - **Views**: Divided into sections like `Home` and `Profile`, each with their respective `ViewModels`.
  - **Shared**: Reusable components and modifiers.
  - **Models**: Data models.
  - **ViewModels**: View-specific logic.
  - **Services**: Includes `Network` for networking and `Persistence` for data storage.
  - **Utilities**: Extensions, constants, and helper functions.
- **Resources**:
  - **Assets**: Images and colors.
  - **Localization**: Localized strings.
  - **Fonts**: Custom fonts.
- **Tests**:
  - **UnitTests**: Unit testing.
  - **UITests**: UI testing.

## SwiftUI UI Design Rules
1. **Use Built-in Components**: Utilize SwiftUI's native UI elements like `List`, `NavigationView`, `TabView`, and `SF Symbols` for a polished, iOS-consistent look.
2. **Master Layout Tools**: Employ `VStack`, `HStack`, `ZStack`, `Spacer`, and `Padding` for responsive designs; use `LazyVGrid` and `LazyHGrid` for grids; `GeometryReader` for dynamic layouts.
3. **Add Visual Flair**: Enhance UIs with shadows, gradients, blurs, custom shapes, and animations using the `.animation()` modifier for smooth transitions.
4. **Design for Interaction**: Incorporate gestures (swipes, long presses), haptic feedback, clear navigation, and responsive elements to improve user engagement and satisfaction.

## Coding Standards
- **Functional Components**: Prefer functional components and avoid class components.
- **Variable Declarations**: Use `const` over `let` for variable declarations.
- **Naming Conventions**: Use `camelCase` for variables and functions, and `PascalCase` for component names.

## Performance Optimization
- **React.memo**: Use `React.memo` on pure function components.
- **Lazy Loading**: Implement lazy loading for routing components.
- **useEffect Dependencies**: Optimize `useEffect` dependencies to prevent unnecessary re-renders.

## Testing Requirements
- **Unit Tests**: Write unit tests using `Jest` and `React Testing Library`.
- **Test Coverage**: Ensure test coverage reaches at least 80%.
- **Snapshot Testing**: Use snapshot testing for UI components.

## Documentation
- **JSDoc**: Write comments for functions and components in JSDoc format.
- **PropTypes**: Components must include `PropTypes` validation.
- **README.md**: Each main directory must contain a `README.md` file.
- **Multilingual README**: Provide both English and Chinese versions of the `README.md` file.

## Error Handling
- **try/catch**: Use `try/catch` blocks to handle asynchronous operations.
- **Error Boundary**: Implement a global error boundary component.
