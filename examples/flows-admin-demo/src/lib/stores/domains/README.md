# Domain-Driven Store Architecture

This directory contains domain-specific stores following Svelte best practices for MVVM pattern.

## Structure

```
domains/
├── client/           # Client management domain
│   ├── client.store.ts
│   ├── client.service.ts
│   └── client.types.ts
├── people/          # People/Employee management
│   ├── people.store.ts
│   ├── people.service.ts
│   └── people.types.ts
├── invitation/      # Invitation system
│   ├── invitation.store.ts
│   ├── invitation.service.ts
│   └── invitation.types.ts
├── tfc/            # Thepia Flow Credits
│   ├── tfc.store.ts
│   ├── tfc.service.ts
│   └── tfc.types.ts
└── process/        # Process management
    ├── process.store.ts
    ├── process.service.ts
    └── process.types.ts
```

## Principles

1. **Separation of Concerns**
   - `.store.ts` - Svelte stores and state management
   - `.service.ts` - API calls and business logic
   - `.types.ts` - TypeScript interfaces and types

2. **Single Responsibility**
   - Each domain handles only its own data
   - Cross-domain communication via events or actions

3. **Reactive State Management**
   - Use Svelte stores for all shared state
   - Derived stores for computed values
   - Custom stores for complex state logic

4. **Error Handling**
   - Centralized error handling in services
   - Consistent error reporting
   - Loading and error states in stores

5. **Testing**
   - Services are easily testable
   - Stores can be tested in isolation
   - Clear boundaries for mocking