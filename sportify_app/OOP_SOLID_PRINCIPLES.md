# OOP and SOLID Principles Implementation

This document outlines how Object-Oriented Programming (OOP) principles and SOLID principles are applied in the Sportify application.

## OOP Principles Applied

### 1. Encapsulation ✅
**How it's implemented:**
- Services use private fields (`_auth`, `_firestore`, `_userRepository`, etc.) to hide internal implementation
- Data access is controlled through public methods only
- Repository pattern encapsulates all data access operations, hiding Firestore implementation details

**Examples:**
- `AuthService` uses private `_auth` and `_userRepository` fields
- `FirestoreService` uses private `_firestore`, `_userRepository`, `_roomRepository`, and `_friendshipRepository`
- `UserRepository`, `RoomRepository`, and `FriendshipRepository` encapsulate all Firestore operations

**Location:** All service and repository classes in `lib/services/` and `lib/repositories/`

### 2. Inheritance ✅
**How it's implemented:**
- `BaseRoom` abstract class serves as base for different room types
- Concrete implementations (`PublicRoom`, `PrivateRoom`, `RivalRoom`) extend `BaseRoom`
- `AuthenticationStrategy` abstract class serves as base for authentication methods
- `EmailPasswordStrategy` extends `AuthenticationStrategy`

**Example:**
```dart
// lib/models/rooms/base_room.dart
abstract class BaseRoom {
  // Common properties and abstract methods
}

class PublicRoom extends BaseRoom {
  // Public room specific implementation
}

class PrivateRoom extends BaseRoom {
  // Private room specific implementation
}

class RivalRoom extends BaseRoom {
  // Rival room specific implementation
}
```

**Location:** `lib/models/rooms/base_room.dart`, `lib/services/auth/authentication_strategy.dart`

### 3. Polymorphism ✅
**How it's implemented:**
- Services implement interfaces, allowing different implementations to be used interchangeably
- Strategy pattern allows different authentication strategies to be used polymorphically
- Factory pattern creates different room types polymorphically based on `RoomType`
- All `BaseRoom` subclasses can be used wherever `BaseRoom` is expected

**Example:**
```dart
// RoomFactory returns BaseRoom but creates specific implementations
BaseRoom room = RoomFactory.createRoom(
  roomType: RoomType.public, // Creates PublicRoom
  // ... other parameters
);
```

**Location:** `lib/models/rooms/room_factory.dart`, service interfaces in `lib/services/interfaces/`

### 4. Abstraction ✅
**How it's implemented:**
- Interfaces (`IAuthService`, `IFirestoreService`, `IProfileService`) define abstract contracts
- Abstract classes (`BaseRoom`, `AuthenticationStrategy`) provide abstract contracts
- Repository pattern abstracts data access details from business logic
- Services depend on interfaces and repositories, not concrete implementations

**Example:**
```dart
// Services depend on interfaces, not concrete classes
class AuthService implements IAuthService {
  final UserRepository _userRepository; // Depends on abstraction
}
```

**Location:** `lib/services/interfaces/`, `lib/models/rooms/base_room.dart`

## SOLID Principles Applied

### 1. Single Responsibility Principle (SRP) ✅
**Principle:** Each class should have only one reason to change.

**How it's implemented:**
- **`AuthService`**: Handles only authentication operations (sign in, sign up, sign out)
- **`ProfileService`**: Handles only profile operations (get, update profile)
- **`FirestoreService`**: Coordinates between repositories (acts as facade/orchestrator)
- **`UserRepository`**: Handles only user data access operations
- **`RoomRepository`**: Handles only room data access operations
- **`FriendshipRepository`**: Handles only friendship data access operations

**Code Evidence:**
```dart
// lib/services/auth_service.dart - Only authentication
class AuthService implements IAuthService {
  Future<User?> signUpWithEmail(...) { ... }
  Future<User?> signInWithEmail(...) { ... }
  Future<User?> signInWithGoogle() { ... }
  Future<void> signOut() { ... }
}

// lib/repositories/user_repository.dart - Only user data access
class UserRepository {
  Future<UserModel?> getUserById(String uid) { ... }
  Future<void> createUser(UserModel user) { ... }
  Future<void> updateUser(UserModel user) { ... }
}
```

**Location:** All service and repository classes maintain single responsibility

### 2. Dependency Inversion Principle (DIP) ✅
**Principle:** High-level modules should not depend on low-level modules. Both should depend on abstractions.

**How it's implemented:**
- **Interfaces created**: `IAuthService`, `IFirestoreService`, `IProfileService` define abstractions
- **Services implement interfaces**: `AuthService implements IAuthService`, etc.
- **Dependency injection**: Services accept repositories through constructors (optional parameters with defaults)
- **Provider pattern**: In `main.dart`, services are provided as interfaces, not concrete classes

**Code Evidence:**
```dart
// lib/services/interfaces/auth_service_interface.dart
abstract class IAuthService {
  Future<User?> signUpWithEmail(...);
  Future<User?> signInWithEmail(...);
  // ... other methods
}

// lib/services/auth_service.dart
class AuthService implements IAuthService {
  final UserRepository _userRepository; // Depends on abstraction
  AuthService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();
}

// lib/main.dart - Services provided as interfaces
Provider<IAuthService>(
  create: (_) => AuthService(),
),
```

**Location:** `lib/services/interfaces/`, service implementations, `lib/main.dart`

### 3. Open/Closed Principle (OCP) ✅
**Principle:** Software entities should be open for extension but closed for modification.

**How it's implemented:**
- **Room types**: New room types can be added by extending `BaseRoom` without modifying existing code
- **Authentication strategies**: New auth methods can be added by extending `AuthenticationStrategy` without modifying existing code
- **Factory pattern**: `RoomFactory` can handle new room types by adding cases to the switch statement (minimal modification) or by using a registry pattern

**Code Evidence:**
```dart
// lib/models/rooms/base_room.dart
abstract class BaseRoom {
  // Common interface - closed for modification
  bool validate();
  Room toRoomModel();
  RoomType get roomType;
}

// Adding a new room type doesn't require modifying BaseRoom or existing room types
class TournamentRoom extends BaseRoom {
  // New room type implementation
}
```

**Location:** `lib/models/rooms/base_room.dart`, `lib/services/auth/authentication_strategy.dart`, `lib/models/rooms/room_factory.dart`

### 4. Interface Segregation Principle (ISP) ✅
**Principle:** Clients should not be forced to depend on interfaces they do not use.

**How it's implemented:**
- **Separate interfaces**: `IAuthService`, `IFirestoreService`, and `IProfileService` are completely separate
- **Focused contracts**: Each interface contains only methods relevant to its specific domain
- **No fat interfaces**: No single interface forces clients to implement unused methods

**Code Evidence:**
```dart
// lib/services/interfaces/auth_service_interface.dart
abstract class IAuthService {
  // Only authentication-related methods
  Future<User?> signUpWithEmail(...);
  Future<User?> signInWithEmail(...);
  Future<User?> signInWithGoogle();
  Future<void> signOut();
}

// lib/services/interfaces/profile_service_interface.dart
abstract class IProfileService {
  // Only profile-related methods
  Future<void> updateUserProfile(UserModel user);
  Future<UserModel?> getUserProfile(String uid);
}

// A component needing only authentication doesn't need IProfileService
```

**Location:** `lib/services/interfaces/` - Each interface is focused and separate

### 5. Liskov Substitution Principle (LSP) ✅
**Principle:** Subtypes must be substitutable for their base types without altering the correctness of the program.

**How it's implemented:**
- **Room types**: Any `BaseRoom` subclass (`PublicRoom`, `PrivateRoom`, `RivalRoom`) can be used wherever `BaseRoom` is expected
- **Service implementations**: Any class implementing `IAuthService` can replace `AuthService` without breaking functionality
- **All subclasses properly implement abstract methods**: Each `BaseRoom` subclass implements `validate()` and `toRoomModel()` correctly

**Code Evidence:**
```dart
// All BaseRoom subclasses can be used interchangeably
BaseRoom room1 = PublicRoom(...);
BaseRoom room2 = PrivateRoom(...);
BaseRoom room3 = RivalRoom(...);

// All implement the same interface
bool isValid1 = room1.validate();
bool isValid2 = room2.validate();
bool isValid3 = room3.validate();

// RoomFactory returns BaseRoom but creates specific types
BaseRoom room = RoomFactory.createRoom(roomType: RoomType.public);
// Can be used as BaseRoom without knowing the concrete type
```

**Location:** `lib/models/rooms/base_room.dart`, service interface implementations


## File Structure

```
lib/
├── services/
│   ├── interfaces/          # Interfaces (DIP, ISP)
│   │   ├── auth_service_interface.dart
│   │   ├── firestore_service_interface.dart
│   │   └── profile_service_interface.dart
│   ├── auth/                # Authentication strategies (OCP, Polymorphism)
│   │   └── authentication_strategy.dart
│   ├── auth_service.dart    # Implements IAuthService (SRP, DIP)
│   ├── firestore_service.dart # Implements IFirestoreService (SRP, DIP, Facade)
│   └── profile_service.dart  # Implements IProfileService (SRP, DIP)
├── repositories/            # Repository pattern (SRP, Abstraction, Encapsulation)
│   ├── user_repository.dart
│   ├── room_repository.dart
│   └── friendship_repository.dart
└── models/
    └── rooms/               # Inheritance, Polymorphism, OCP, LSP
        ├── base_room.dart   # Abstract base class
        └── room_factory.dart # Factory pattern
```

## Summary

✅ **All 4 OOP Principles**: Encapsulation, Inheritance, Polymorphism, Abstraction

✅ **All 5 SOLID Principles**:
1. **Single Responsibility Principle (SRP)** - Each class has one clear responsibility
2. **Dependency Inversion Principle (DIP)** - Dependencies on abstractions (interfaces)
3. **Open/Closed Principle (OCP)** - Open for extension via inheritance, closed for modification
4. **Interface Segregation Principle (ISP)** - Separate, focused interfaces
5. **Liskov Substitution Principle (LSP)** - Subtypes are substitutable for base types

The codebase follows best practices with proper separation of concerns, abstraction, extensibility, and maintainability.
