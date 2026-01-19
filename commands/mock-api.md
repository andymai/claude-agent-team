# Mock API

Generate mock API responses from types, schemas, or existing endpoints.

## Usage

- `/mock-api User` - Generate mock data for User type
- `/mock-api src/types/api.ts` - Mock all types in file
- `/mock-api --endpoint=/api/users` - Mock based on existing route
- `/mock-api --count=10` - Generate array of 10 items
- `/mock-api --realistic` - Use realistic fake data (names, emails, etc.)

## Task

Parse from: {{RAW_PROMPT}}

### 1. Find the Type/Schema

**By type name:**
```bash
# Find type definition
rg "^(export )?(type|interface) TYPE_NAME" --type ts
```

**By file:**
Read all type definitions from the file.

**By endpoint:**
Find the route handler and extract response type:
```bash
rg "router\.(get|post).*ENDPOINT" --type ts -A 20
```

### 2. Parse the Type Structure

Extract fields and their types:

```typescript
interface User {
  id: string
  name: string
  email: string
  age: number
  isActive: boolean
  role: 'admin' | 'user' | 'guest'
  profile: {
    avatar: string
    bio: string | null
  }
  tags: string[]
  createdAt: Date
}
```

Parse into structure:
```
- id: string
- name: string
- email: string
- age: number
- isActive: boolean
- role: union('admin', 'user', 'guest')
- profile: object
  - avatar: string
  - bio: string | null
- tags: array(string)
- createdAt: Date
```

### 3. Generate Mock Data

**Basic mode (default):**
Use simple placeholder values:

```typescript
const mockUser: User = {
  id: "user_1",
  name: "Test User",
  email: "test@example.com",
  age: 25,
  isActive: true,
  role: "user",
  profile: {
    avatar: "https://example.com/avatar.png",
    bio: "Test bio"
  },
  tags: ["tag1", "tag2"],
  createdAt: new Date("2024-01-15T10:30:00Z")
}
```

**Realistic mode (--realistic):**
Use realistic fake data:

```typescript
const mockUser: User = {
  id: "usr_a1b2c3d4e5f6",
  name: "Sarah Johnson",
  email: "sarah.johnson@gmail.com",
  age: 34,
  isActive: true,
  role: "admin",
  profile: {
    avatar: "https://i.pravatar.cc/150?u=sarah",
    bio: "Product designer with 10 years of experience in fintech."
  },
  tags: ["design", "ux", "fintech"],
  createdAt: new Date("2023-06-12T08:45:23Z")
}
```

**Array mode (--count=N):**
```typescript
const mockUsers: User[] = [
  { id: "usr_001", name: "Sarah Johnson", ... },
  { id: "usr_002", name: "Mike Chen", ... },
  { id: "usr_003", name: "Emma Williams", ... },
  // ... N items
]
```

### 4. Type-Specific Generation

| Type | Basic | Realistic |
|------|-------|-----------|
| `string` | `"test"` | Context-aware (name, email, etc.) |
| `number` | `1` | Reasonable range for context |
| `boolean` | `true` | Random true/false |
| `Date` | `new Date()` | Recent realistic date |
| `string[]` | `["a", "b"]` | Contextual items |
| `enum/union` | First value | Random from options |
| `null \| T` | Non-null value | Occasionally null |
| `optional` | Include it | Sometimes omit |
| `uuid/id` | `"id_1"` | UUID-like string |
| `email` | `"test@example.com"` | Realistic email |
| `url` | `"https://example.com"` | Realistic URL |

**Detect field intent from name:**
- `*Id`, `*_id` → UUID-like string
- `*email*` → Email format
- `*url*`, `*link*` → URL format
- `*name*` → Person/thing name
- `*phone*` → Phone format
- `*date*`, `*At` → Date object
- `*price*`, `*amount*` → Currency number
- `*count*`, `*total*` → Integer
- `*is*`, `*has*`, `*can*` → Boolean
- `*avatar*`, `*image*` → Image URL

### 5. Generate Output

```markdown
## Mock Data: User

### Single Object

```typescript
export const mockUser: User = {
  id: "usr_a1b2c3d4",
  name: "Sarah Johnson",
  email: "sarah.johnson@example.com",
  age: 34,
  isActive: true,
  role: "admin",
  profile: {
    avatar: "https://i.pravatar.cc/150?u=a1b2c3",
    bio: "Product designer specializing in fintech applications."
  },
  tags: ["design", "ux", "fintech"],
  createdAt: new Date("2023-06-12T08:45:23Z")
}
```

### Factory Function

```typescript
export function createMockUser(overrides?: Partial<User>): User {
  return {
    id: `usr_${Math.random().toString(36).slice(2, 10)}`,
    name: "Test User",
    email: "test@example.com",
    age: 25,
    isActive: true,
    role: "user",
    profile: {
      avatar: "https://example.com/avatar.png",
      bio: null
    },
    tags: [],
    createdAt: new Date(),
    ...overrides
  }
}
```

### Array of Mocks

```typescript
export const mockUsers: User[] = [
  createMockUser({ id: "usr_001", name: "Sarah Johnson", role: "admin" }),
  createMockUser({ id: "usr_002", name: "Mike Chen", role: "user" }),
  createMockUser({ id: "usr_003", name: "Emma Williams", role: "guest" }),
]
```

### JSON (for API mocking)

```json
{
  "id": "usr_a1b2c3d4",
  "name": "Sarah Johnson",
  "email": "sarah.johnson@example.com",
  "age": 34,
  "isActive": true,
  "role": "admin",
  "profile": {
    "avatar": "https://i.pravatar.cc/150?u=a1b2c3",
    "bio": "Product designer specializing in fintech applications."
  },
  "tags": ["design", "ux", "fintech"],
  "createdAt": "2023-06-12T08:45:23.000Z"
}
```
```

### 6. Framework-Specific Output

**Jest:**
```typescript
jest.mock('../api/users', () => ({
  getUser: jest.fn().mockResolvedValue(mockUser),
  getUsers: jest.fn().mockResolvedValue(mockUsers),
}))
```

**MSW (Mock Service Worker):**
```typescript
import { rest } from 'msw'

export const handlers = [
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(ctx.json(mockUser))
  }),
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json(mockUsers))
  }),
]
```

**Faker.js integration:**
```typescript
import { faker } from '@faker-js/faker'

export function createMockUser(overrides?: Partial<User>): User {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    age: faker.number.int({ min: 18, max: 80 }),
    isActive: faker.datatype.boolean(),
    role: faker.helpers.arrayElement(['admin', 'user', 'guest']),
    profile: {
      avatar: faker.image.avatar(),
      bio: faker.person.bio()
    },
    tags: faker.helpers.arrayElements(['tech', 'design', 'marketing'], 3),
    createdAt: faker.date.past(),
    ...overrides
  }
}
```

## Quality Checklist

- [ ] All required fields included
- [ ] Types match exactly (no type errors)
- [ ] Nested objects handled correctly
- [ ] Arrays have appropriate content
- [ ] Dates are valid Date objects or ISO strings
- [ ] Union types use valid values
- [ ] Optional fields handled appropriately
- [ ] Generated code is copy-paste ready
